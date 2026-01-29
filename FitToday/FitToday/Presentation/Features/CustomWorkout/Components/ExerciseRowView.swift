//
//  ExerciseRowView.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import SwiftUI

/// Row view for displaying an exercise in the workout builder
struct ExerciseRowView: View {
    let exercise: CustomExerciseEntry
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    let onUpdateSet: (Int, Int?, Double?) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack(spacing: 12) {
                // GIF thumbnail
                ExerciseGifThumbnail(gifURL: exercise.exerciseGifURL)

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.headline)
                        .lineLimit(2)

                    if let bodyPart = exercise.bodyPart {
                        Text(bodyPart.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }

            // Sets section (expandable)
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        SetConfigurationRow(
                            setNumber: index + 1,
                            set: set,
                            onUpdate: { reps, weight in
                                onUpdateSet(index, reps, weight)
                            },
                            onRemove: exercise.sets.count > 1 ? {
                                onRemoveSet(index)
                            } : nil
                        )
                    }

                    // Add set button
                    Button {
                        onAddSet()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - GIF Thumbnail

struct ExerciseGifThumbnail: View {
    let gifURL: String?

    var body: some View {
        Group {
            if let urlString = gifURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 60, height: 60)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    ExerciseRowView(
        exercise: CustomExerciseEntry(
            exerciseId: "test",
            exerciseName: "Barbell Bench Press",
            bodyPart: "chest",
            equipment: "barbell",
            orderIndex: 0,
            sets: [WorkoutSet(), WorkoutSet(), WorkoutSet()]
        ),
        onAddSet: {},
        onRemoveSet: { _ in },
        onUpdateSet: { _, _, _ in }
    )
    .padding()
}
