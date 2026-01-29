//
//  SetConfigurationRow.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import SwiftUI

/// Row for configuring a single set (reps and weight)
struct SetConfigurationRow: View {
    let setNumber: Int
    let set: WorkoutSet
    let onUpdate: (Int?, Double?) -> Void
    let onRemove: (() -> Void)?

    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("Set \(setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            // Reps input
            HStack(spacing: 4) {
                TextField("Reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: repsText) { _, newValue in
                        let reps = Int(newValue)
                        onUpdate(reps, Double(weightText))
                    }

                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Weight input
            HStack(spacing: 4) {
                TextField("kg", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: weightText) { _, newValue in
                        let weight = Double(newValue)
                        onUpdate(Int(repsText), weight)
                    }

                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Remove button
            if let onRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            repsText = set.targetReps.map { String($0) } ?? ""
            weightText = set.targetWeight.map { String(format: "%.1f", $0) } ?? ""
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SetConfigurationRow(
            setNumber: 1,
            set: WorkoutSet(targetReps: 10, targetWeight: 60),
            onUpdate: { _, _ in },
            onRemove: {}
        )

        SetConfigurationRow(
            setNumber: 2,
            set: WorkoutSet(targetReps: 8, targetWeight: 65),
            onUpdate: { _, _ in },
            onRemove: nil
        )
    }
    .padding()
}
