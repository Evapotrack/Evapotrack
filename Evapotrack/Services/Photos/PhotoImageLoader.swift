// © 2026 Evapotrack. All rights reserved.
// PhotoImageLoader.swift
// Evapotrack
//
// Decoding stored photos for display: off the main actor, at the size the
// screen needs, with a small cache of decoded thumbnails.

import UIKit
import ImageIO

/// Where a photo shown in the UI comes from: a saved watering log, or a
/// photo prepared in the Add Watering form but not saved yet.
nonisolated enum PhotoSource: Equatable, Sendable {
    case stored(UUID)
    case prepared(PreparedPhoto)

    var id: UUID {
        switch self {
        case .stored(let id): return id
        case .prepared(let photo): return photo.id
        }
    }

    /// Checks the file system; call off the main actor.
    var thumbnailURL: URL? {
        switch self {
        case .stored(let id): return PhotoStore.shared.thumbnailURL(for: id)
        case .prepared(let photo): return photo.thumbnailURL
        }
    }

    /// Checks the file system; call off the main actor.
    var detailURL: URL? {
        switch self {
        case .stored(let id): return PhotoStore.shared.detailURL(for: id)
        case .prepared(let photo): return photo.detailURL
        }
    }
}

nonisolated enum PhotoImageLoader {

    /// Decodes the image at `url`, downsampled to at most `maxPixelSize` on its
    /// long edge. Returns nil if the file is missing or unreadable.
    static func loadImage(at url: URL, maxPixelSize: Int) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let image = PhotoProcessor.downsample(source, maxPixelSize: maxPixelSize) else { return nil }
        return UIImage(cgImage: image)
    }

    static func loadThumbnail(_ source: PhotoSource) -> UIImage? {
        guard let url = source.thumbnailURL else { return nil }
        return loadImage(at: url, maxPixelSize: AppConstants.photoThumbnailMaxPixelSize)
    }

    static func loadDetail(_ source: PhotoSource) -> UIImage? {
        guard let url = source.detailURL else { return nil }
        return loadImage(at: url, maxPixelSize: AppConstants.photoDetailMaxPixelSize)
    }
}

/// Decoded thumbnails keyed by photo ID. A photo ID is never reused, so an
/// entry never goes stale; NSCache evicts under memory pressure.
@MainActor
final class PhotoThumbnailCache {
    static let shared = PhotoThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.totalCostLimit = 24 * 1024 * 1024
    }

    func image(for id: UUID) -> UIImage? {
        cache.object(forKey: id.uuidString as NSString)
    }

    func insert(_ image: UIImage, for id: UUID) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        cache.setObject(image, forKey: id.uuidString as NSString, cost: Int(pixels * 4))
    }
}
