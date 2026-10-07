// © 2026 Evapotrack. All rights reserved.
// PhotoProcessor.swift
// Evapotrack
//
// Turns a photo picked from the library into a small, private copy:
//   1. Reads the file with ImageIO without decoding the full-size image.
//   2. Downsamples to at most 2048 px on the long edge, applying the photo's
//      orientation to the pixels.
//   3. Encodes HEIC (JPEG if HEIC encoding is unavailable) with no metadata
//      dictionary, so EXIF, GPS location, TIFF camera data and maker notes
//      from the original are never written.
//   4. Keeps the detail image under 1.5 MB, lowering quality and then size
//      if needed, and writes a 360 px thumbnail from the detail image.
//
// Runs off the main actor: callers use Task.detached. Nothing here touches
// the network or the Photos library.

import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

nonisolated enum PhotoProcessor {

    nonisolated struct Limits: Sendable {
        var detailMaxPixelSize = AppConstants.photoDetailMaxPixelSize
        var fallbackMaxPixelSize = 1600
        var thumbnailMaxPixelSize = AppConstants.photoThumbnailMaxPixelSize
        var detailQuality = 0.70
        var fallbackQuality = 0.55
        var thumbnailQuality = 0.60
        var maxDetailBytes = 1_500_000

        static let standard = Limits()
    }

    nonisolated enum ProcessingError: Error {
        case unreadableImage
        case encodingFailed
    }

    nonisolated enum EncodedFormat: Sendable {
        case heic
        case jpeg

        var typeIdentifier: CFString {
            (self == .heic ? UTType.heic : UTType.jpeg).identifier as CFString
        }

        var fileExtension: String {
            self == .heic ? "heic" : "jpg"
        }
    }

    /// Processes the image at `sourceURL` and writes the detail image and
    /// thumbnail into `outputDirectory`, named after `id`.
    static func process(
        sourceURL: URL,
        outputDirectory: URL,
        id: UUID = UUID(),
        limits: Limits = .standard
    ) throws -> PreparedPhoto {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, sourceOptions),
              CGImageSourceGetCount(source) > 0,
              var detail = downsample(source, maxPixelSize: limits.detailMaxPixelSize) else {
            throw ProcessingError.unreadableImage
        }

        var format = EncodedFormat.heic
        var detailData: Data
        do {
            detailData = try encode(detail, as: format, quality: limits.detailQuality)
        } catch {
            format = .jpeg
            detailData = try encode(detail, as: format, quality: limits.detailQuality)
        }
        if detailData.count > limits.maxDetailBytes {
            detailData = try encode(detail, as: format, quality: limits.fallbackQuality)
        }
        if detailData.count > limits.maxDetailBytes,
           let smaller = downsample(source, maxPixelSize: limits.fallbackMaxPixelSize) {
            detail = smaller
            detailData = try encode(detail, as: format, quality: limits.fallbackQuality)
        }

        // The thumbnail comes from the small, already-oriented detail image.
        guard let detailSource = CGImageSourceCreateWithData(detailData as CFData, nil),
              let thumbnail = downsample(detailSource, maxPixelSize: limits.thumbnailMaxPixelSize) else {
            throw ProcessingError.unreadableImage
        }
        let thumbnailData = try encode(thumbnail, as: format, quality: limits.thumbnailQuality)

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let detailURL = outputDirectory.appending(path: "\(id.uuidString).\(format.fileExtension)")
        let thumbnailURL = outputDirectory.appending(path: "\(id.uuidString)\(PhotoStore.thumbnailSuffix).\(format.fileExtension)")
        try detailData.write(to: detailURL, options: .atomic)
        try thumbnailData.write(to: thumbnailURL, options: .atomic)

        return PreparedPhoto(
            id: id,
            detailURL: detailURL,
            thumbnailURL: thumbnailURL,
            fileExtension: format.fileExtension,
            pixelWidth: detail.width,
            pixelHeight: detail.height,
            byteCount: detailData.count + thumbnailData.count
        )
    }

    /// Decodes a downsampled, correctly oriented image without loading the
    /// full-size bitmap into memory.
    static func downsample(_ source: CGImageSource, maxPixelSize: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// Encodes pixels only. No metadata dictionary is passed, so nothing from
    /// the original file's EXIF, GPS or TIFF data is written.
    static func encode(_ image: CGImage, as format: EncodedFormat, quality: Double) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, format.typeIdentifier, 1, nil) else {
            throw ProcessingError.encodingFailed
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.encodingFailed
        }
        return data as Data
    }
}
