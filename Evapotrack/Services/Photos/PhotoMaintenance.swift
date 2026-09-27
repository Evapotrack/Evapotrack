// © 2026 Evapotrack. All rights reserved.
// PhotoMaintenance.swift
// Evapotrack
//
// Launch-time cleanup of photo files: removes files that no watering log
// refers to (for example after a crash between copying a photo and saving
// its log) and .incoming folders left by earlier launches.
//
// Runs on the main actor, like every add and delete, so it can never run in
// the middle of one. If the store cannot be read it does nothing.

import Foundation
import OSLog
import SwiftData

@MainActor
enum PhotoMaintenance {

    static func removeOrphanedFiles(context: ModelContext, store: PhotoStore = .shared) {
        let referenced: Set<UUID>
        do {
            referenced = Set(try context.fetch(FetchDescriptor<WateringLog>()).compactMap(\.photoFileID))
        } catch {
            Logger.photos.error("Photo cleanup skipped: \(error.localizedDescription, privacy: .public)")
            return
        }
        let removed = store.sweep(referencedIDs: referenced)
        if removed > 0 {
            Logger.photos.info("Removed \(removed) unreferenced photo item(s)")
        }
    }
}
