// © 2026 Evapotrack. All rights reserved.
// PhotoStore.swift
// Evapotrack
//
// Local file storage for optional watering-log photos.
//
//   Application Support/WateringPhotos/
//       <id>.heic              detail image (≤ 2048 px; .jpg if HEIC is unavailable)
//       <id>_thumb.heic        thumbnail (≤ 360 px)
//       .incoming/<launch>/    photos being prepared in the Add Watering form
//                              (excluded from backups)
//
// The database stores only the photo ID (WateringLog.photoFileID), never a
// path. Application Support is included in device backups, is not shown in
// the Files app, and is removed with the app. Nothing is ever uploaded.
//
// Ordering keeps the database from pointing at missing files:
//   add     prepare into .incoming → copy into place → save the log → remove
//           the incoming copy (a failed save removes the placed copy instead,
//           so the grower can retry with the same photo)
//   delete  save the deletion first → then delete the files
//   launch  remove files no log refers to, and .incoming folders left by
//           earlier launches
// Orphans are found by comparing against the IDs in the database, never by
// file dates, so no file-timestamp API is used.

import Foundation
import OSLog

/// A processed photo waiting in .incoming until its watering log is saved.
nonisolated struct PreparedPhoto: Equatable, Sendable {
    let id: UUID
    let detailURL: URL
    let thumbnailURL: URL
    let fileExtension: String
    let pixelWidth: Int
    let pixelHeight: Int
    let byteCount: Int
}

nonisolated struct PhotoUsage: Equatable, Sendable {
    let photoCount: Int
    let totalBytes: Int64
}

nonisolated struct PhotoStore: Sendable {

    let rootDirectory: URL

    static let shared = PhotoStore(
        rootDirectory: URL.applicationSupportDirectory.appending(path: "WateringPhotos", directoryHint: .isDirectory)
    )

    /// One .incoming folder per app launch, so launch cleanup never touches a
    /// photo the grower is preparing right now.
    static let sessionID = UUID()

    static let thumbnailSuffix = "_thumb"
    static let fileExtensions = ["heic", "jpg"]

    var incomingRoot: URL {
        rootDirectory.appending(path: ".incoming", directoryHint: .isDirectory)
    }

    var sessionIncomingDirectory: URL {
        incomingRoot.appending(path: Self.sessionID.uuidString, directoryHint: .isDirectory)
    }

    // MARK: - Lookup

    /// The stored detail image, or nil if it is missing.
    func detailURL(for id: UUID) -> URL? {
        existingFile(id: id, suffix: "")
    }

    /// The stored thumbnail, or nil if it is missing.
    func thumbnailURL(for id: UUID) -> URL? {
        existingFile(id: id, suffix: Self.thumbnailSuffix)
    }

    func makeSessionIncomingDirectory() throws -> URL {
        try FileManager.default.createDirectory(at: sessionIncomingDirectory, withIntermediateDirectories: true)
        // Photos still being prepared don't belong in device backups.
        var root = incomingRoot
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? root.setResourceValues(values)
        return sessionIncomingDirectory
    }

    // MARK: - Add and Delete

    /// Copies a prepared photo into place. The incoming copy is kept until
    /// `discard(_:)` so a failed save can be retried. On failure nothing is
    /// left half-copied.
    func commit(_ photo: PreparedPhoto) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let detail = fileURL(id: photo.id, suffix: "", fileExtension: photo.fileExtension)
        let thumbnail = fileURL(id: photo.id, suffix: Self.thumbnailSuffix, fileExtension: photo.fileExtension)
        removeIfPresent(detail)
        removeIfPresent(thumbnail)
        do {
            try fileManager.copyItem(at: photo.detailURL, to: detail)
            try fileManager.copyItem(at: photo.thumbnailURL, to: thumbnail)
        } catch {
            removeIfPresent(detail)
            removeIfPresent(thumbnail)
            throw error
        }
    }

    /// Removes a stored photo's files. Missing files are not an error.
    func deletePhoto(id: UUID) {
        for suffix in ["", Self.thumbnailSuffix] {
            for fileExtension in Self.fileExtensions {
                removeIfPresent(fileURL(id: id, suffix: suffix, fileExtension: fileExtension))
            }
        }
    }

    /// Removes a prepared photo's incoming files.
    func discard(_ photo: PreparedPhoto) {
        removeIfPresent(photo.detailURL)
        removeIfPresent(photo.thumbnailURL)
    }

    // MARK: - Maintenance

    /// Deletes files whose photo ID is not in `referencedIDs`, and .incoming
    /// folders from earlier launches. Returns how many items were removed.
    @discardableResult
    func sweep(referencedIDs: Set<UUID>) -> Int {
        let fileManager = FileManager.default
        var removed = 0

        if let sessions = try? fileManager.contentsOfDirectory(at: incomingRoot, includingPropertiesForKeys: nil) {
            for folder in sessions where folder.lastPathComponent != Self.sessionID.uuidString {
                if (try? fileManager.removeItem(at: folder)) != nil { removed += 1 }
            }
        }

        guard let files = try? fileManager.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return removed }

        for file in files {
            guard let id = Self.photoID(fromFileName: file.lastPathComponent),
                  !referencedIDs.contains(id) else { continue }
            if (try? fileManager.removeItem(at: file)) != nil { removed += 1 }
        }
        return removed
    }

    /// Number of stored photos and the bytes they use (detail + thumbnail).
    /// Reads file sizes only.
    func usage() -> PhotoUsage {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return PhotoUsage(photoCount: 0, totalBytes: 0) }

        var ids = Set<UUID>()
        var bytes: Int64 = 0
        for file in files {
            guard let id = Self.photoID(fromFileName: file.lastPathComponent) else { continue }
            ids.insert(id)
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            bytes += Int64(size)
        }
        return PhotoUsage(photoCount: ids.count, totalBytes: bytes)
    }

    /// Parses "<uuid>.heic" or "<uuid>_thumb.jpg"; nil for anything else.
    static func photoID(fromFileName name: String) -> UUID? {
        guard let dot = name.lastIndex(of: ".") else { return nil }
        var stem = String(name[..<dot])
        if stem.hasSuffix(thumbnailSuffix) {
            stem.removeLast(thumbnailSuffix.count)
        }
        return UUID(uuidString: stem)
    }

    // MARK: - Private

    private func fileURL(id: UUID, suffix: String, fileExtension: String) -> URL {
        rootDirectory.appending(path: "\(id.uuidString)\(suffix).\(fileExtension)")
    }

    private func existingFile(id: UUID, suffix: String) -> URL? {
        for fileExtension in Self.fileExtensions {
            let url = fileURL(id: id, suffix: suffix, fileExtension: fileExtension)
            if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) { return url }
        }
        return nil
    }

    private func removeIfPresent(_ url: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            Logger.photos.error("Could not delete a photo file: \(error.localizedDescription, privacy: .public)")
        }
    }
}
