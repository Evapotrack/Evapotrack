// © 2026 Evapotrack. All rights reserved.
// PickedImageFile.swift
// Evapotrack
//
// A photo chosen in PhotosPicker, received as a file and copied into this
// launch's .incoming folder. FileRepresentation hands the app a file instead
// of loading the whole original (a 48 MP or ProRAW photo can be 50 MB or
// more) into memory. The picker runs outside the app, so no Photos
// permission is requested and only the chosen photo is shared.

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

nonisolated struct PickedImageFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            let directory = try PhotoStore.shared.makeSessionIncomingDirectory()
            let fileExtension = received.file.pathExtension.isEmpty ? "image" : received.file.pathExtension
            let destination = directory.appending(path: "source-\(UUID().uuidString).\(fileExtension)")
            // The received file is only valid inside this closure.
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedImageFile(url: destination)
        }
    }
}
