// © 2026 Evapotrack. All rights reserved.
// ImageProcessingService.swift
// Evapotrack
//
// Pure, stateless photo processing for watering-log images.
// Downscales to AppConstants.maxPhotoDimension on the longest edge,
// strips all metadata (EXIF, GPS), and compresses to JPEG, stepping
// quality down until the result fits AppConstants.maxPhotoBytes.
// Uses ImageIO thumbnailing so the full-resolution camera image is
// never decoded into memory.

import Foundation
import ImageIO
import UniformTypeIdentifiers
import UIKit

nonisolated enum ImageProcessingService {

    /// JPEG qualities tried in order until the encoded size fits maxPhotoBytes.
    private static let qualitySteps: [Double] = [
        AppConstants.photoJPEGQuality, 0.5, 0.35, 0.25, 0.15
    ]

    /// Process raw image data (any format ImageIO reads) into a stored photo:
    /// oriented upright, longest edge ≤ maxPhotoDimension, metadata stripped,
    /// JPEG ≤ maxPhotoBytes. Returns nil if the data is not a decodable image
    /// or cannot be compressed under the cap.
    static func processForStorage(_ data: Data) -> Data? {
        guard let downscaled = downsampledCGImage(
            from: data,
            maxPixelSize: AppConstants.maxPhotoDimension
        ) else { return nil }

        for quality in qualitySteps {
            guard let encoded = encodeJPEG(downscaled, quality: quality) else { continue }
            if encoded.count <= AppConstants.maxPhotoBytes {
                return encoded
            }
        }
        return nil
    }

    /// Convenience for camera capture: encodes the UIImage, then runs the
    /// standard storage pipeline (downscale, strip metadata, size cap).
    static func processForStorage(_ image: UIImage) -> Data? {
        guard let raw = image.jpegData(compressionQuality: 0.9) else { return nil }
        return processForStorage(raw)
    }

    /// Decode stored photo data into a UIImage sized for display.
    /// Pass a small maxPixelSize (e.g. 300) for list thumbnails to avoid
    /// decoding the full stored image.
    static func displayImage(from data: Data, maxPixelSize: Int) -> UIImage? {
        guard let cgImage = downsampledCGImage(from: data, maxPixelSize: maxPixelSize) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Private

    /// Memory-safe downscale via ImageIO. Applies EXIF orientation so the
    /// output pixels are upright; never inflates the source beyond the
    /// requested thumbnail size. Metadata is not carried over.
    private static func downsampledCGImage(from data: Data, maxPixelSize: Int) -> CGImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary)
    }

    /// Encode a CGImage as JPEG with no metadata dictionary attached.
    private static func encodeJPEG(_ image: CGImage, quality: Double) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
