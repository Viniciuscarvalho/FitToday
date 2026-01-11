//
//  LibraryExerciseDetailView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

/// Tela de detalhe de exercício para a Biblioteca (fora de sessão ativa).
/// Exibe mídia (GIF/imagem), instruções, prescrição e dicas.
struct LibraryExerciseDetailView: View {
  let prescription: ExercisePrescription

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
        // Hero Image
        ExerciseHeroImage(media: prescription.exercise.media, height: 260)
          .fitCardShadow()

        // Título e músculo principal
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
          Text(prescription.exercise.name)
            .font(.system(.title2, weight: .bold))
            .foregroundStyle(FitTodayColor.textPrimary)

          HStack(spacing: FitTodaySpacing.sm) {
            FitBadge(text: prescription.exercise.mainMuscle.displayTitle, style: .info)
            FitBadge(text: prescription.exercise.equipment.displayName, style: .success)
          }
        }

        // Prescrição
        prescriptionSection

        // Instruções
        if !prescription.exercise.instructions.isEmpty {
          instructionsSection
        }

        // Dica do coach
        if let tip = prescription.tip {
          tipSection(tip)
        }
      }
      .padding()
    }
    .background(FitTodayColor.background.ignoresSafeArea())
    .navigationTitle("Execução")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
  }

  // MARK: - Prescrição

  private var prescriptionSection: some View {
    VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
      SectionHeader(title: "Prescrição", actionTitle: nil)

      HStack(spacing: FitTodaySpacing.md) {
        PrescriptionCard(
          icon: "repeat",
          value: "\(prescription.sets)",
          label: "Séries"
        )
        PrescriptionCard(
          icon: "number",
          value: prescription.reps.display,
          label: "Repetições"
        )
        PrescriptionCard(
          icon: "timer",
          value: "\(Int(prescription.restInterval))s",
          label: "Descanso"
        )
      }
    }
  }

  // MARK: - Instruções

  private var instructionsSection: some View {
    VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
      SectionHeader(title: "Como executar", actionTitle: nil)

      VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
        ForEach(Array(prescription.exercise.instructions.enumerated()), id: \.offset) { index, instruction in
          HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            Text("\(index + 1)")
              .font(.system(.caption, weight: .bold))
              .foregroundStyle(FitTodayColor.brandPrimary)
              .frame(width: 20, height: 20)
              .background(FitTodayColor.brandPrimary.opacity(0.15))
              .clipShape(Circle())

            Text(instruction)
              .font(.system(.body))
              .foregroundStyle(FitTodayColor.textSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .padding()
      .background(FitTodayColor.surface)
      .cornerRadius(FitTodayRadius.md)
    }
  }

  // MARK: - Dica

  private func tipSection(_ tip: String) -> some View {
    VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
      SectionHeader(title: "Dica do coach", actionTitle: nil)

      HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
        Image(systemName: "lightbulb.fill")
          .font(.system(.title3))
          .foregroundStyle(FitTodayColor.brandSecondary)

        Text(tip)
          .font(.system(.body))
          .foregroundStyle(FitTodayColor.textSecondary)
      }
      .padding()
      .background(FitTodayColor.brandSecondary.opacity(0.1))
      .cornerRadius(FitTodayRadius.md)
    }
  }
}

// MARK: - Subviews

private struct PrescriptionCard: View {
  let icon: String
  let value: String
  let label: String

  var body: some View {
    VStack(spacing: FitTodaySpacing.xs) {
      Image(systemName: icon)
        .font(.system(.title3))
        .foregroundStyle(FitTodayColor.brandPrimary)

      Text(value)
        .font(.system(.headline, weight: .bold))
        .foregroundStyle(FitTodayColor.textPrimary)

      Text(label)
        .font(.system(.caption))
        .foregroundStyle(FitTodayColor.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(FitTodayColor.surface)
    .cornerRadius(FitTodayRadius.md)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(value) \(label)")
  }
}

#Preview {
  NavigationStack {
    LibraryExerciseDetailView(
      prescription: ExercisePrescription(
        exercise: WorkoutExercise(
          id: "test",
          name: "Supino Reto com Barra",
          mainMuscle: .chest,
          equipment: .barbell,
          instructions: [
            "Deite no banco com os pés firmemente apoiados",
            "Pegada um pouco mais larga que os ombros",
            "Desça a barra controladamente até tocar o peito",
            "Empurre explosivamente mantendo as escápulas retraídas"
          ],
          media: nil
        ),
        sets: 4,
        reps: IntRange(6, 8),
        restInterval: 120,
        tip: "Mantenha as escápulas retraídas durante todo o movimento"
      )
    )
  }
}

