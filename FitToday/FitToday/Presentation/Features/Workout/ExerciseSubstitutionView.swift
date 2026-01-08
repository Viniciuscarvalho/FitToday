//
//  ExerciseSubstitutionView.swift
//  FitToday
//
//  UI para substituição de exercícios.
//

import SwiftUI

// MARK: - Substitution Sheet

struct ExerciseSubstitutionSheet: View {
    let exercise: WorkoutExercise
    let userProfile: UserProfile
    let onSelect: (AlternativeExercise) -> Void
    let onDismiss: () -> Void
    
    @State private var isLoading = true
    @State private var alternatives: [AlternativeExercise] = []
    @State private var errorMessage: String?
    @State private var selectedReason: SubstitutionReason?
    
    private var substitutionService: ExerciseSubstituting? {
        ExerciseSubstitutionServiceFactory.create()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if alternatives.isEmpty {
                    noAlternativesView
                } else {
                    alternativesList
                }
            }
            .background(FitTodayColor.background.ignoresSafeArea())
            .navigationTitle("Substituir exercício")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        onDismiss()
                    }
                }
            }
        }
        .task {
            await loadAlternatives()
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Buscando alternativas...")
                .font(FitTodayFont.ui(size: 17, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
            
            Text("A IA está analisando opções compatíveis com seu perfil")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.orange)
            
            Text(message)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Tentar novamente") {
                Task { await loadAlternatives() }
            }
            .fitSecondaryStyle()
            
            Spacer()
        }
    }
    
    private var noAlternativesView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Spacer()
            
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)
            
            Text("Não encontramos alternativas")
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            Text("Tente pular este exercício ou ajustar seu perfil")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var alternativesList: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.md) {
                // Header
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text("Alternativas para")
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                    
                    Text(exercise.name)
                        .font(FitTodayFont.ui(size: 18, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Alternatives
                ForEach(alternatives) { alternative in
                    AlternativeExerciseCard(
                        alternative: alternative,
                        isRecommended: alternatives.first?.id == alternative.id
                    ) {
                        onSelect(alternative)
                    }
                    .padding(.horizontal)
                }
                
                // Footer hint
                Text("Sugestões personalizadas por IA")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary.opacity(0.6))
                    .padding(.top, FitTodaySpacing.md)
                    .padding(.bottom, FitTodaySpacing.lg)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAlternatives() async {
        isLoading = true
        errorMessage = nil
        
        guard let service = substitutionService else {
            errorMessage = "Substituição por IA não disponível no momento. Tente pular o exercício."
            isLoading = false
            return
        }
        
        do {
            alternatives = try await service.suggestAlternatives(
                for: exercise,
                userProfile: userProfile,
                reason: selectedReason
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Alternative Card

struct AlternativeExerciseCard: View {
    let alternative: AlternativeExercise
    let isRecommended: Bool
    let onSelect: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: FitTodaySpacing.xs) {
                        Text(alternative.name)
                            .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                        
                        if isRecommended {
                            Text("RECOMENDADO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FitTodayColor.brandPrimary.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: FitTodaySpacing.sm) {
                        Label(alternative.targetMuscle, systemImage: "figure.strengthtraining.traditional")
                        Label(alternative.equipment, systemImage: "dumbbell.fill")
                        Label(alternative.difficulty, systemImage: "speedometer")
                    }
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            
            // Why good
            Text(alternative.whyGood)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .italic()
            
            // Instructions (expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text("Instruções:")
                        .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    
                    ForEach(Array(alternative.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: FitTodaySpacing.xs) {
                            Text("\(index + 1).")
                                .font(FitTodayFont.ui(size: 13, weight: .medium))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                            Text(instruction)
                                .font(FitTodayFont.ui(size: 13, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }
                .padding(.top, FitTodaySpacing.xs)
            }
            
            // Select button
            Button(action: onSelect) {
                Text("Usar este exercício")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                            .fill(
                                LinearGradient(
                                    colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(isRecommended ? FitTodayColor.brandPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Substitution Badge

struct SubstitutionBadge: View {
    let alternativeName: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 12))
                .foregroundStyle(FitTodayColor.brandSecondary)
            
            Text("Substituído: \(alternativeName)")
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(
            Capsule()
                .fill(FitTodayColor.brandSecondary.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview("Substitution Sheet") {
    ExerciseSubstitutionSheet(
        exercise: WorkoutExercise(
            id: "1",
            name: "Supino Reto",
            mainMuscle: .chest,
            equipment: .barbell,
            instructions: []
        ),
        userProfile: UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 4
        ),
        onSelect: { _ in },
        onDismiss: {}
    )
}

