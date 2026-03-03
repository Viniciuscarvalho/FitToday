//
//  ExerciseAnimatedView.swift
//  FitToday
//
//  Created by Claude on 03/03/26.
//

import Combine
import SwiftUI
import UIKit

/// Alternates between image 0 and image 1 every 1.2s to simulate a GIF.
/// Falls back to a static image if only image 0 exists.
/// Timer stops when the view disappears to prevent memory leaks.
struct ExerciseAnimatedView: View {
    let exerciseId: String
    var cornerRadius: CGFloat = 12

    @State private var image0: UIImage?
    @State private var image1: UIImage?
    @State private var showingIndex0 = true
    @State private var isLoaded = false

    private let timer = Timer.publish(every: 1.2, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?

    var body: some View {
        Group {
            if !isLoaded {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FitTodayColor.surface)
                    ProgressView()
                        .tint(FitTodayColor.brandSecondary)
                }
            } else if let currentImage {
                Image(uiImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .animation(.easeInOut(duration: 0.3), value: showingIndex0)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FitTodayColor.surface)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: exerciseId) {
            await loadImages()
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var currentImage: UIImage? {
        if showingIndex0 {
            return image0
        }
        return image1 ?? image0
    }

    private func loadImages() async {
        image0 = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)
        image1 = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 1)
        isLoaded = true
        if image1 != nil {
            startTimer()
        }
    }

    private func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = timer.autoconnect().sink { _ in
            showingIndex0.toggle()
        }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
