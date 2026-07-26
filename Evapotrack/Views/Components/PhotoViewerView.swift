// © 2026 Evapotrack. All rights reserved.
// PhotoViewerView.swift
// Evapotrack
//
// Full-screen viewer for a watering-log photo.
// Pinch to zoom (1×–4×), double-tap to toggle zoom, Close button to dismiss.
// Presented as a fullScreenCover from the expanded watering log row.

import SwiftUI
import UIKit

struct PhotoViewerView: View {
    let photoData: Data

    @Environment(\.dismiss) private var dismiss
    @State private var loadedImage: UIImage?
    @State private var zoomScale: CGFloat = 1.0
    @State private var steadyZoom: CGFloat = 1.0

    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 4.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .gesture(magnification)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            let target: CGFloat = steadyZoom > minZoom ? minZoom : 2.0
                            steadyZoom = target
                            zoomScale = target
                        }
                    }
                    .accessibilityLabel(Strings.wateringPhoto)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(8)
            .accessibilityLabel(Strings.close)
        }
        .task {
            // Decode off the main thread at full stored resolution.
            let data = photoData
            loadedImage = await Task.detached(priority: .userInitiated) {
                ImageProcessingService.displayImage(
                    from: data,
                    maxPixelSize: AppConstants.maxPhotoDimension
                )
            }.value
        }
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoomScale = min(max(steadyZoom * value, minZoom), maxZoom)
            }
            .onEnded { _ in
                steadyZoom = zoomScale
            }
    }
}
