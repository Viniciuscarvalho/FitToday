//
//  ExerciseImageView.swift
//  FitToday
//
//  Created by Claude on 03/03/26.
//

import SwiftUI
import UIKit

/// Displays an exercise image from ExerciseImageCache with loading/fallback states.
/// Three states: loading (ProgressView) → image → fallback (SF Symbol).
struct ExerciseImageView: View {
    let exerciseId: String
    let imageIndex: Int
    var cornerRadius: CGFloat = 12

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FitTodayColor.surface)
                    ProgressView()
                        .tint(FitTodayColor.brandSecondary)
                }
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
        .task(id: "\(exerciseId)_\(imageIndex)") {
            isLoading = true
            image = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: imageIndex)
            isLoading = false
        }
    }
}
