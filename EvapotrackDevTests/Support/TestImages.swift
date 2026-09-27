// © 2026 Evapotrack. All rights reserved.
// TestImages.swift
// EvapotrackDevTests
//
// Generated image files for photo tests, including a fixture that carries
// GPS location, camera make/model and EXIF comments, so tests can prove the
// processed copy contains none of it. Also a PhotoStore rooted in a
// temporary folder, so tests never touch the app's real photo folder.

import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers
@testable import EvapotrackDev

enum TestImages {

    struct FixtureError: Error {}

    static let gpsLatitude = 37.3349
    static let gpsLongitude = 122.0090
    static let cameraMake = "FixtureMake"
    static let exifComment = "private fixture note"

    /// Writes a JPEG of `width` × `height` stored pixels with the given EXIF
    /// orientation (6 = displayed rotated 90° clockwise, so it shows as
    /// height × width). Includes GPS, TIFF and EXIF metadata unless
    /// `withMetadata` is false.
    static func writeJPEG(
        width: Int,
        height: Int,
        orientation: Int = 1,
        withMetadata: Bool = true,
        to url: URL
    ) throws {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw FixtureError() }

        // Soft blocks of color: compresses like a photo, not like noise.
        let block = 64
        for y in stride(from: 0, to: height, by: block) {
            for x in stride(from: 0, to: width, by: block) {
                context.setFillColor(
                    red: CGFloat(x % 256) / 255,
                    green: CGFloat(y % 256) / 255,
                    blue: 0.45,
                    alpha: 1
                )
                context.fill(CGRect(x: x, y: y, width: block, height: block))
            }
        }
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw FixtureError() }

        var properties: [CFString: Any] = [
            kCGImagePropertyOrientation: orientation,
            kCGImageDestinationLossyCompressionQuality: 0.9
        ]
        if withMetadata {
            properties[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: gpsLatitude,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: gpsLongitude,
                kCGImagePropertyGPSLongitudeRef: "W"
            ] as [CFString: Any]
            properties[kCGImagePropertyTIFFDictionary] = [
                kCGImagePropertyTIFFMake: cameraMake,
                kCGImagePropertyTIFFModel: "FixtureModel"
            ] as [CFString: Any]
            properties[kCGImagePropertyExifDictionary] = [
                kCGImagePropertyExifUserComment: exifComment,
                kCGImagePropertyExifLensModel: "FixtureLens"
            ] as [CFString: Any]
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FixtureError() }
    }

    /// The image's metadata as ImageIO reads it back.
    static func properties(of url: URL) -> [CFString: Any] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return [:] }
        return properties
    }

    /// Stored pixel size (before any orientation is applied).
    static func pixelSize(of url: URL) -> (width: Int, height: Int)? {
        let properties = properties(of: url)
        guard let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (width, height)
    }

    /// The file's type as ImageIO detects it from its contents.
    static func typeIdentifier(of url: URL) -> String? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let type = CGImageSourceGetType(source) else { return nil }
        return type as String
    }

    /// A fresh temporary folder; the caller removes it in tearDown.
    static func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "EvapotrackTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A photo store rooted in `directory`.
    static func makeStore(in directory: URL) -> PhotoStore {
        PhotoStore(rootDirectory: directory.appending(path: "WateringPhotos", directoryHint: .isDirectory))
    }

    /// Processes a generated JPEG into the store's incoming folder, as the
    /// Add Watering form does when a photo is picked.
    static func preparePhoto(in store: PhotoStore, scratch: URL) throws -> PreparedPhoto {
        let source = scratch.appending(path: "source-\(UUID().uuidString).jpg")
        try writeJPEG(width: 800, height: 600, to: source)
        return try PhotoProcessor.process(sourceURL: source, outputDirectory: try store.makeSessionIncomingDirectory())
    }

    static func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }
}
