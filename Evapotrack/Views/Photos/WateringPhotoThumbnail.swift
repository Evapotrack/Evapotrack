// © 2026 Evapotrack. All rights reserved.
// WateringPhotoThumbnail.swift
// Evapotrack
//
// A watering photo's thumbnail, decoded off the main actor and cached.
// Shows "Photo unavailable" if the file is missing; the watering log itself
// stays fully usable.

import SwiftUI
import UIKit

struct WateringPhotoThumbnail: View {
    let source: PhotoSource
    var maxHeight: CGFloat = 120

    @State private var image: UIImage?
    @State private var isMissing = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .frame(maxHeight: maxHeight, alignment: .leading)
            } else if isMissing {
                Label(Strings.photoUnavailable, systemImage: "photo")
                    .font(.callout)
                    .foregroundStyle(Color.evSecondaryText)
            } else {
                ProgressView()
                    .frame(width: maxHeight * 0.75, height: maxHeight * 0.5)
            }
        }
        .task(id: source.id) { await load() }
    }

    private func load() async {
        if let cached = PhotoThumbnailCache.shared.image(for: source.id) {
            image = cached
            return
        }
        let source = source
        let loaded = await Task.detached(priority: .userInitiated) {
            PhotoImageLoader.loadThumbnail(source)
        }.value
        if let loaded {
            PhotoThumbnailCache.shared.insert(loaded, for: source.id)
            image = loaded
        } else {
            isMissing = true
        }
    }
}
