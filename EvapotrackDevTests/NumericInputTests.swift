// © 2026 Evapotrack. All rights reserved.
// NumericInputTests.swift
// EvapotrackDevTests
//
// Locale-aware parsing of typed and pasted numbers. Covers regions that use
// a comma as the decimal separator (es_ES, de_DE, fr_FR, pt_BR) and ones
// that use a period (en_US, es_MX).

import XCTest
@testable import EvapotrackDev

final class NumericInputTests: XCTestCase {

    private func parse(_ text: String, _ identifier: String) -> Double? {
        NumericInput.parse(text, locale: Locale(identifier: identifier))
    }

    private func assertParses(_ text: String, _ identifier: String, _ expected: Double, file: StaticString = #filePath, line: UInt = #line) {
        guard let value = parse(text, identifier) else {
            return XCTFail("\"\(text)\" in \(identifier) did not parse", file: file, line: line)
        }
        XCTAssertEqual(value, expected, accuracy: 1e-12, "\"\(text)\" in \(identifier)", file: file, line: line)
    }

    // MARK: - Decimal comma regions

    func test_commaDecimal_inCommaRegions() {
        for identifier in ["es_ES", "de_DE", "fr_FR", "pt_BR"] {
            assertParses("1,5", identifier, 1.5)
            assertParses("0,25", identifier, 0.25)
            assertParses(",5", identifier, 0.5)
        }
    }

    func test_periodDecimal_isAlsoAcceptedInCommaRegions() {
        // A value pasted from a US source.
        for identifier in ["es_ES", "de_DE", "fr_FR", "pt_BR"] {
            assertParses("1.5", identifier, 1.5)
        }
    }

    func test_groupedNumbers_inCommaRegions() {
        assertParses("1.500", "es_ES", 1500)
        assertParses("1.234,5", "es_ES", 1234.5)
        assertParses("2.000,75", "de_DE", 2000.75)
        assertParses("1.234.567", "de_DE", 1_234_567)
        assertParses("1.234,56", "pt_BR", 1234.56)
        assertParses("1\u{202F}234,5", "fr_FR", 1234.5)
        assertParses("1 234,5", "fr_FR", 1234.5)
    }

    // MARK: - Decimal period regions

    func test_periodDecimal_inPeriodRegions() {
        assertParses("1.5", "en_US", 1.5)
        assertParses(".5", "en_US", 0.5)
        assertParses("5.", "en_US", 5)
        assertParses("1.5", "es_MX", 1.5)
    }

    func test_singleCommaInPeriodRegion_isDecimalUnlessItGroupsThousands() {
        assertParses("1,5", "en_US", 1.5)
        assertParses("0,250", "en_US", 0.25)
        assertParses("1,500", "en_US", 1500)
        assertParses("1,234.5", "en_US", 1234.5)
    }

    // MARK: - Signs and whitespace

    func test_signsAndWhitespace() {
        assertParses("  2 ", "en_US", 2)
        assertParses("+2", "en_US", 2)
        assertParses("-1,5", "es_ES", -1.5)
        assertParses("\u{2212}1.5", "en_US", -1.5)
    }

    // MARK: - Rejected input

    func test_rejectsMalformedAndNonDecimalInput() {
        let rejected: [(String, String)] = [
            ("", "en_US"), ("   ", "en_US"), ("abc", "en_US"), ("1..2", "en_US"), ("1,2,3", "en_US"),
            ("1e3", "en_US"), ("nan", "en_US"), ("inf", "en_US"), ("0x10", "en_US"), (".", "en_US"),
            ("1.2.3", "de_DE"), ("1,234,5", "en_US"), ("12,34.5", "en_US"), ("--2", "en_US")
        ]
        for (text, identifier) in rejected {
            XCTAssertNil(parse(text, identifier), "\"\(text)\" in \(identifier) should be rejected")
        }
    }

    // MARK: - Round trip with the region's own formatting

    func test_valuesFormattedByEachRegion_parseBack() {
        for identifier in ["en_US", "es_ES", "de_DE", "fr_FR", "pt_BR"] {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: identifier)
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            for value in [0.25, 1.5, 12.75, 1234.5] {
                guard let text = formatter.string(from: NSNumber(value: value)) else {
                    XCTFail("formatter failed for \(identifier)")
                    continue
                }
                assertParses(text, identifier, value)
            }
        }
    }
}
