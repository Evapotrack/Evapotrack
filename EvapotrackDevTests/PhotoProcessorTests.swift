// © 2026 Evapotrack. All rights reserved.
// PhotoProcessorTests.swift
// EvapotrackDevTests
//
// Photo processing: size limits, orientation, format, and above all that
// the stored copy carries no GPS location or camera metadata from the
// original photo.

import XCTest
import ImageIO
@testable import EvapotrackDev

final class PhotoProcessorTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = try TestImages.makeTemporaryDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func fixture(width: Int, height: Int, orientation: Int = 1) throws -> URL {
        let url = directory.appending(path: "fixture-\(UUID().uuidString).jpg")
        try TestImages.writeJPEG(width: width, height: height, orientation: orientation, to: url)
        return url
    }

    private func process(_ source: URL, limits: PhotoProcessor.Limits = .standard) throws -> PreparedPhoto {
        try PhotoProcessor.process(
            sourceURL: source,
            outputDirectory: directory.appending(path: "out", directoryHint: .isDirectory),
            limits: limits
        )
    }

    // MARK: - Metadata

    func test_fixture_containsGPSAndCameraMetadata() throws {
        // Guards the tests below: the source really has what must be removed.
        let properties = TestImages.properties(of: try fixture(width: 400, height: 300))
        let gps = try XCTUnwrap(properties[kCGImagePropertyGPSDictionary] as? [CFString: Any])
        XCTAssertEqual(try XCTUnwrap(gps[kCGImagePropertyGPSLatitude] as? Double), TestImages.gpsLatitude, accuracy: 0.001)
        let tiff = try XCTUnwrap(properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any])
        XCTAssertEqual(tiff[kCGImagePropertyTIFFMake] as? String, TestImages.cameraMake)
    }

    func test_process_removesGPSAndCameraMetadata_fromDetailAndThumbnail() throws {
        let photo = try process(try fixture(width: 1200, height: 900))

        for url in [photo.detailURL, photo.thumbnailURL] {
            let properties = TestImages.properties(of: url)
            XCTAssertNil(properties[kCGImagePropertyGPSDictionary], "GPS in \(url.lastPathComponent)")
            let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            XCTAssertNil(tiff?[kCGImagePropertyTIFFMake], "camera make in \(url.lastPathComponent)")
            XCTAssertNil(tiff?[kCGImagePropertyTIFFModel], "camera model in \(url.lastPathComponent)")
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
            XCTAssertNil(exif?[kCGImagePropertyExifUserComment], "EXIF comment in \(url.lastPathComponent)")
            XCTAssertNil(exif?[kCGImagePropertyExifLensModel], "lens model in \(url.lastPathComponent)")

            // Belt and braces: the raw bytes don't contain the fixture strings.
            let bytes = try Data(contentsOf: url)
            XCTAssertNil(bytes.range(of: Data(TestImages.cameraMake.utf8)))
            XCTAssertNil(bytes.range(of: Data(TestImages.exifComment.utf8)))
        }
    }

    // MARK: - Size and orientation

    func test_process_downsamplesLargePhotos_toTheLimits() throws {
        let photo = try process(try fixture(width: 4032, height: 3024))

        let detail = try XCTUnwrap(TestImages.pixelSize(of: photo.detailURL))
        XCTAssertLessThanOrEqual(max(detail.width, detail.height), AppConstants.photoDetailMaxPixelSize)
        XCTAssertGreaterThan(detail.width, detail.height, "landscape stays landscape")
        XCTAssertEqual(photo.pixelWidth, detail.width)
        XCTAssertEqual(photo.pixelHeight, detail.height)

        let thumbnail = try XCTUnwrap(TestImages.pixelSize(of: photo.thumbnailURL))
        XCTAssertLessThanOrEqual(max(thumbnail.width, thumbnail.height), AppConstants.photoThumbnailMaxPixelSize)
    }

    func test_process_neverUpscalesSmallPhotos() throws {
        let photo = try process(try fixture(width: 300, height: 200))
        let detail = try XCTUnwrap(TestImages.pixelSize(of: photo.detailURL))
        XCTAssertEqual(detail.width, 300)
        XCTAssertEqual(detail.height, 200)
    }

    func test_process_appliesOrientationToThePixels() throws {
        // Stored 1200 × 800 with orientation 6: the photo is displayed portrait.
        let photo = try process(try fixture(width: 1200, height: 800, orientation: 6))

        let detail = try XCTUnwrap(TestImages.pixelSize(of: photo.detailURL))
        XCTAssertEqual(detail.width, 800)
        XCTAssertEqual(detail.height, 1200)
        let orientation = TestImages.properties(of: photo.detailURL)[kCGImagePropertyOrientation] as? Int
        XCTAssertTrue(orientation == nil || orientation == 1, "orientation is baked in, not left as a tag")
    }

    func test_process_staysWithinTheByteBudget() throws {
        let photo = try process(try fixture(width: 4032, height: 3024))
        let detailBytes = try XCTUnwrap(try photo.detailURL.resourceValues(forKeys: [.fileSizeKey]).fileSize)
        XCTAssertLessThanOrEqual(detailBytes, PhotoProcessor.Limits.standard.maxDetailBytes)
        XCTAssertEqual(photo.byteCount, detailBytes + (try XCTUnwrap(try photo.thumbnailURL.resourceValues(forKeys: [.fileSizeKey]).fileSize)))
    }

    func test_process_whenOverBudget_fallsBackToTheSmallerSize() throws {
        var limits = PhotoProcessor.Limits.standard
        limits.maxDetailBytes = 1 // impossible, so both fallbacks run
        let photo = try process(try fixture(width: 4032, height: 3024), limits: limits)
        let detail = try XCTUnwrap(TestImages.pixelSize(of: photo.detailURL))
        XCTAssertLessThanOrEqual(max(detail.width, detail.height), limits.fallbackMaxPixelSize)
    }

    // MARK: - Format and naming

    func test_process_writesHEICOrJPEG_matchingTheExtension() throws {
        let id = UUID()
        let output = directory.appending(path: "out", directoryHint: .isDirectory)
        let photo = try PhotoProcessor.process(sourceURL: try fixture(width: 640, height: 480), outputDirectory: output, id: id)

        XCTAssertEqual(photo.id, id)
        XCTAssertTrue(["heic", "jpg"].contains(photo.fileExtension))
        XCTAssertEqual(photo.detailURL.lastPathComponent, "\(id.uuidString).\(photo.fileExtension)")
        XCTAssertEqual(photo.thumbnailURL.lastPathComponent, "\(id.uuidString)_thumb.\(photo.fileExtension)")
        let expectedType = photo.fileExtension == "heic" ? "public.heic" : "public.jpeg"
        XCTAssertEqual(TestImages.typeIdentifier(of: photo.detailURL), expectedType)
        XCTAssertEqual(TestImages.typeIdentifier(of: photo.thumbnailURL), expectedType)
    }

    func test_process_unreadableFile_throws() throws {
        let url = directory.appending(path: "not-an-image.jpg")
        try Data("definitely not an image".utf8).write(to: url)
        XCTAssertThrowsError(try process(url)) { error in
            XCTAssertEqual(error as? PhotoProcessor.ProcessingError, .unreadableImage)
        }
    }
}
