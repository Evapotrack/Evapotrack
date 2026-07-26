// © 2026 Evapotrack. All rights reserved.
// ImageProcessingTests.swift
// EvapotrackDevTests
//
// Tests for ImageProcessingService: dimension cap, byte cap,
// metadata stripping, small-image passthrough, and invalid input.

import XCTest
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import EvapotrackDev

final class ImageProcessingTests: XCTestCase {

    // MARK: - Helpers

    /// Render a test image at an exact pixel size (scale 1).
    private func makeImage(width: Int, height: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: width, height: height)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            // Add variation so JPEG output is not trivially small
            for i in stride(from: 0, to: width, by: 40) {
                UIColor(hue: CGFloat(i % 255) / 255.0, saturation: 0.8, brightness: 0.8, alpha: 1).setFill()
                context.fill(CGRect(x: CGFloat(i), y: 0, width: 20, height: CGFloat(height)))
            }
        }
    }

    private func pixelSize(of data: Data) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (width, height)
    }

    /// JPEG data carrying EXIF and GPS metadata dictionaries.
    private func makeImageDataWithMetadata() -> Data {
        let image = makeImage(width: 800, height: 600)
        let raw = image.jpegData(compressionQuality: 0.9)!
        let source = CGImageSourceCreateWithData(raw as CFData, nil)!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)!
        let metadata: [CFString: Any] = [
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "test comment"],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 42.05,
                kCGImagePropertyGPSLongitude: -71.88
            ]
        ]
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        CGImageDestinationFinalize(destination)
        return output as Data
    }

    // MARK: - Dimension Cap

    func test_process_largeImage_capsLongestEdge() {
        let image = makeImage(width: 4000, height: 3000)
        let result = ImageProcessingService.processForStorage(image)
        XCTAssertNotNil(result)
        let size = pixelSize(of: result!)
        XCTAssertNotNil(size)
        XCTAssertLessThanOrEqual(max(size!.width, size!.height), AppConstants.maxPhotoDimension)
        // Aspect ratio preserved (4:3)
        let ratio = Double(size!.width) / Double(size!.height)
        XCTAssertEqual(ratio, 4.0 / 3.0, accuracy: 0.02)
    }

    func test_process_smallImage_keepsDimensions() {
        let image = makeImage(width: 640, height: 480)
        let result = ImageProcessingService.processForStorage(image)
        XCTAssertNotNil(result)
        let size = pixelSize(of: result!)
        XCTAssertNotNil(size)
        XCTAssertLessThanOrEqual(max(size!.width, size!.height), 640)
    }

    // MARK: - Byte Cap

    func test_process_output_underByteCap() {
        let image = makeImage(width: 4000, height: 3000)
        let result = ImageProcessingService.processForStorage(image)
        XCTAssertNotNil(result)
        XCTAssertLessThanOrEqual(result!.count, AppConstants.maxPhotoBytes)
    }

    // MARK: - Metadata Stripping

    func test_process_stripsExifAndGPS() {
        let dataWithMetadata = makeImageDataWithMetadata()

        // Confirm the fixture actually carries metadata
        let sourceProps = CGImageSourceCopyPropertiesAtIndex(
            CGImageSourceCreateWithData(dataWithMetadata as CFData, nil)!, 0, nil
        ) as? [CFString: Any]
        XCTAssertNotNil(sourceProps?[kCGImagePropertyGPSDictionary])

        let result = ImageProcessingService.processForStorage(dataWithMetadata)
        XCTAssertNotNil(result)

        let props = CGImageSourceCopyPropertiesAtIndex(
            CGImageSourceCreateWithData(result! as CFData, nil)!, 0, nil
        ) as? [CFString: Any]
        XCTAssertNil(props?[kCGImagePropertyGPSDictionary], "GPS metadata must be stripped")
        if let exif = props?[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            XCTAssertNil(exif[kCGImagePropertyExifUserComment], "EXIF user data must be stripped")
        }
    }

    // MARK: - Invalid Input

    func test_process_invalidData_returnsNil() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        XCTAssertNil(ImageProcessingService.processForStorage(garbage))
    }

    // MARK: - Display Decode

    func test_displayImage_respectsMaxPixelSize() {
        let image = makeImage(width: 2000, height: 1500)
        let stored = ImageProcessingService.processForStorage(image)!
        let thumbnail = ImageProcessingService.displayImage(from: stored, maxPixelSize: 300)
        XCTAssertNotNil(thumbnail)
        XCTAssertLessThanOrEqual(max(thumbnail!.size.width, thumbnail!.size.height), 300)
    }

    // MARK: - Model Integration

    func test_wateringLog_photoData_defaultsToNil() {
        let log = WateringLog(waterAdded: 1.0, runoffCollected: 0.1, dateTime: Date())
        XCTAssertNil(log.photoData)
    }

    func test_wateringLog_storesPhotoData() {
        let image = makeImage(width: 1000, height: 800)
        let processed = ImageProcessingService.processForStorage(image)
        XCTAssertNotNil(processed)
        let log = WateringLog(
            waterAdded: 1.0, runoffCollected: 0.1, dateTime: Date(), photoData: processed
        )
        XCTAssertEqual(log.photoData, processed)
    }
}
