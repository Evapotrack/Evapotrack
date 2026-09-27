// © 2026 Evapotrack. All rights reserved.
// PhotoViewer.swift
// Evapotrack
//
// Full-screen, closable viewer for a watering photo, so the grower can look
// at the plant larger and up close:
//   - pinch to zoom up to 4x, double-tap to zoom in at a point and back out,
//     drag to pan while zoomed;
//   - close with the X button, by swiping down when not zoomed, or with the
//     VoiceOver escape gesture (two-finger scrub);
//   - black background in both appearances; the watering's date and time are
//     shown at the bottom while the photo is not zoomed.
// The photo is decoded off the main actor at no more than 2048 px.

import SwiftUI
import UIKit

struct PhotoViewerItem: Identifiable, Equatable {
    let source: PhotoSource
    let date: Date
    var id: UUID { source.id }
}

struct PhotoViewer: View {
    let item: PhotoViewerItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var image: UIImage?
    @State private var isMissing = false
    @State private var isZoomed = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                ZoomableImageView(
                    image: image,
                    isZoomed: $isZoomed,
                    accessibilityLabel: Strings.wateringPhotoLabel(item.date.longFormatted),
                    onSwipeDown: { close() }
                )
                .ignoresSafeArea()
            } else if isMissing {
                Label(Strings.photoUnavailable, systemImage: "photo")
                    .foregroundStyle(.white)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.55)))
            }
            .padding(16)
            .accessibilityLabel(Strings.closePhoto)
        }
        .overlay(alignment: .bottom) {
            if !isZoomed {
                Text(item.date.longFormatted)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .padding(.bottom, 24)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityAction(.escape) { close() }
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
        .task { await load() }
    }

    /// Closes the viewer (without the slide-down animation when Reduce Motion
    /// is on).
    private func close() {
        var transaction = Transaction()
        transaction.disablesAnimations = reduceMotion
        withTransaction(transaction) {
            dismiss()
        }
    }

    private func load() async {
        let source = item.source
        let loaded = await Task.detached(priority: .userInitiated) {
            PhotoImageLoader.loadDetail(source)
        }.value
        if let loaded {
            image = loaded
        } else {
            isMissing = true
        }
    }
}

// MARK: - Zoomable Image

/// UIScrollView-based zooming: reliable pinch anchoring, pan limits and
/// double-tap zoom on iOS 17, which SwiftUI gestures alone do not give.
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    @Binding var isZoomed: Bool
    let accessibilityLabel: String
    let onSwipeDown: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ZoomingScrollView {
        let scrollView = ZoomingScrollView(image: image)
        scrollView.delegate = context.coordinator
        scrollView.imageView.accessibilityLabel = accessibilityLabel

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let swipeDown = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        swipeDown.maximumNumberOfTouches = 1
        swipeDown.delegate = context.coordinator
        scrollView.addGestureRecognizer(swipeDown)
        // Panning a zoomed photo waits for the swipe-down to decline, which it
        // does at once unless the photo is at fit size and the drag is downward.
        scrollView.panGestureRecognizer.require(toFail: swipeDown)

        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ scrollView: ZoomingScrollView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: ZoomableImageView
        weak var scrollView: ZoomingScrollView?

        init(parent: ZoomableImageView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            (scrollView as? ZoomingScrollView)?.imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            (scrollView as? ZoomingScrollView)?.centerImage()
            let zoomed = scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
            guard parent.isZoomed != zoomed else { return }
            // Zoom can change during a layout pass (rotation), so the SwiftUI
            // state is updated afterwards rather than in the middle of it.
            DispatchQueue.main.async { [weak self] in
                self?.parent.isZoomed = zoomed
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale + 0.01 {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = gesture.location(in: scrollView.imageView)
                let scale = min(2.5, scrollView.maximumZoomScale)
                let size = CGSize(width: scrollView.bounds.width / scale, height: scrollView.bounds.height / scale)
                let target = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height)
                scrollView.zoom(to: target, animated: true)
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scrollView else { return }
            let translation = gesture.translation(in: scrollView)
            switch gesture.state {
            case .changed:
                scrollView.transform = CGAffineTransform(translationX: 0, y: max(0, translation.y))
            case .ended, .cancelled, .failed:
                let velocity = gesture.velocity(in: scrollView)
                if gesture.state == .ended, translation.y > 120 || velocity.y > 1000 {
                    parent.onSwipeDown()
                } else {
                    UIView.animate(withDuration: 0.2) {
                        scrollView.transform = .identity
                    }
                }
            default:
                break
            }
        }

        /// Swipe-down only begins when the photo is not zoomed and the drag is
        /// mostly downward; otherwise the scroll view pans the zoomed photo.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let scrollView else { return true }
            guard scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01 else { return false }
            let velocity = pan.velocity(in: scrollView)
            return velocity.y > abs(velocity.x)
        }
    }
}

/// Scroll view that fits the image at 1x and keeps it centered while zooming.
/// A size change (rotation, Split View) returns to fit size.
final class ZoomingScrollView: UIScrollView {
    let imageView: UIImageView
    private var fittedBoundsSize: CGSize = .zero

    init(image: UIImage) {
        imageView = UIImageView(image: image)
        super.init(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .image
        addSubview(imageView)
        minimumZoomScale = 1
        maximumZoomScale = 4
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        backgroundColor = .clear
        decelerationRate = .fast
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != fittedBoundsSize {
            fitImage()
        }
        centerImage()
    }

    private func fitImage() {
        guard let size = imageView.image?.size,
              size.width > 0, size.height > 0,
              bounds.width > 0, bounds.height > 0 else { return }
        fittedBoundsSize = bounds.size
        if zoomScale != minimumZoomScale {
            zoomScale = minimumZoomScale
        }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        imageView.frame = CGRect(origin: .zero, size: fitted)
        contentSize = fitted
    }

    func centerImage() {
        let horizontal = max((bounds.width - contentSize.width) / 2, 0)
        let vertical = max((bounds.height - contentSize.height) / 2, 0)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}
