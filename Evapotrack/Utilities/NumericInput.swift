// © 2026 Evapotrack. All rights reserved.
// NumericInput.swift
// Evapotrack
//
// The one place user-typed numbers are parsed. Accepts the region's decimal
// separator (a comma in Spain, Germany, France, Brazil and many other
// regions) as well as a period, so values typed on any keyboard or pasted
// from elsewhere are understood.
//
// Rules, in order:
//   1. Surrounding whitespace is ignored. Spaces, no-break spaces and
//      apostrophes inside the number are treated as grouping marks.
//   2. If both "." and "," appear, the last one is the decimal separator and
//      the other must group digits in threes ("1.234,5", "1,234.5").
//   3. If one separator appears several times, it groups digits in threes
//      ("1.234.567").
//   4. A single separator is a decimal mark ("1,5", "1.5") unless it is the
//      region's grouping separator followed by exactly three digits
//      ("1.500" in Spain is 1500; "1,500" in the US is 1500).
//   5. Only plain decimal digits: no exponents, hex, "nan" or "inf".

import Foundation

nonisolated enum NumericInput {

    static func parse(_ text: String, locale: Locale = .current) -> Double? {
        var body = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{2212}", with: "-")
        guard !body.isEmpty else { return nil }

        var sign = ""
        if let first = body.first, first == "-" || first == "+" {
            sign = String(first)
            body.removeFirst()
        }
        body.removeAll { groupingMarks.contains($0) }
        guard !body.isEmpty else { return nil }

        let dots = body.filter { $0 == "." }.count
        let commas = body.filter { $0 == "," }.count
        let normalized: String

        if dots > 0 && commas > 0 {
            guard let lastDot = body.lastIndex(of: "."),
                  let lastComma = body.lastIndex(of: ",") else { return nil }
            let decimal: Character = lastDot > lastComma ? "." : ","
            let grouping: Character = decimal == "." ? "," : "."
            let parts = pieces(of: body, separatedBy: decimal)
            guard parts.count == 2,
                  isDigits(parts[1]),
                  isGrouped(parts[0], by: grouping) else { return nil }
            normalized = parts[0].filter { $0 != grouping } + "." + parts[1]
        } else if dots > 0 || commas > 0 {
            let separator: Character = dots > 0 ? "." : ","
            if max(dots, commas) > 1 {
                guard isGrouped(body, by: separator) else { return nil }
                normalized = body.filter { $0 != separator }
            } else {
                let parts = pieces(of: body, separatedBy: separator)
                guard parts.count == 2 else { return nil }
                let integerPart = parts[0]
                let fraction = parts[1]
                if isRegionGrouping(separator, locale: locale), isGrouped(body, by: separator) {
                    normalized = integerPart + fraction
                } else {
                    guard integerPart.isEmpty || isDigits(integerPart),
                          fraction.isEmpty || isDigits(fraction),
                          !(integerPart.isEmpty && fraction.isEmpty) else { return nil }
                    normalized = (integerPart.isEmpty ? "0" : integerPart) + "." + (fraction.isEmpty ? "0" : fraction)
                }
            }
        } else {
            guard isDigits(body) else { return nil }
            normalized = body
        }

        guard let value = Double(sign + normalized), value.isFinite else { return nil }
        return value
    }

    // MARK: - Private

    private static let groupingMarks: Set<Character> = [" ", "\u{00A0}", "\u{202F}", "\u{2009}", "'", "\u{2019}"]

    private static func pieces(of text: String, separatedBy separator: Character) -> [String] {
        text.split(separator: separator, omittingEmptySubsequences: false).map(String.init)
    }

    private static func isDigits(_ text: String) -> Bool {
        !text.isEmpty && text.allSatisfy { $0.isASCII && $0.isNumber }
    }

    /// "1.234.567" style: a first group of 1–3 digits that does not start
    /// with 0, then groups of exactly 3 digits.
    private static func isGrouped(_ text: String, by separator: Character) -> Bool {
        let groups = pieces(of: text, separatedBy: separator)
        guard groups.count >= 2,
              let first = groups.first,
              isDigits(first),
              (1...3).contains(first.count),
              first.first != "0" else { return false }
        return groups.dropFirst().allSatisfy { isDigits($0) && $0.count == 3 }
    }

    private static func isRegionGrouping(_ separator: Character, locale: Locale) -> Bool {
        let symbol = String(separator)
        return locale.groupingSeparator == symbol && locale.decimalSeparator != symbol
    }
}
