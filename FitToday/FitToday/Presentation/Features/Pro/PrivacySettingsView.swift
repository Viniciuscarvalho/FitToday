//
//  PrivacySettingsView.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import SwiftUI
import Swinject

// MARK: - PrivacySettingsView

struct PrivacySettingsView: View {
    @Environment(\.dependencyResolver) private var resolver
    @State private var viewModel: PrivacySettingsViewModel

    init(resolver: Resolver) {
        _viewModel = State(initialValue: PrivacySettingsViewModel(resolver: resolver))
    }

    var body: some View {
        Form {
            Section {
                Toggle("Compartilhar treinos com grupos", isOn: $viewModel.shareWorkoutData)
                    .disabled(viewModel.isLoading || viewModel.isSaving)
                    .onChange(of: viewModel.shareWorkoutData) { _, _ in
                        Task {
                            await viewModel.updateSettings()
                        }
                    }
            } header: {
                Text("Compartilhamento de Dados")
            } footer: {
                Text("Seus treinos concluídos (contagem e datas) são compartilhados com membros do grupo para o ranking. Detalhes dos exercícios e planos de treino nunca são compartilhados.")
                    .font(.caption)
            }

            Section {
                Toggle("Sincronizar com Apple Health", isOn: $viewModel.healthKitSyncEnabled)
                    .disabled(viewModel.isLoading)
                    .onChange(of: viewModel.healthKitSyncEnabled) { _, newValue in
                        Task {
                            await viewModel.updateHealthKitSync(enabled: newValue)
                        }
                    }
            } header: {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Apple Health")
                }
            } footer: {
                Text("Treinos concluídos são automaticamente exportados para o Apple Health. Calorias queimadas do Apple Watch são importadas após o treino.")
                    .font(.caption)
            }

            Section {
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    HStack(spacing: FitTodaySpacing.sm) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(FitTodayColor.brandPrimary)
                        Text("Sua privacidade é prioridade")
                            .font(.subheadline.weight(.medium))
                    }

                    Text("Apenas dados agregados são sincronizados. Nunca compartilhamos detalhes específicos dos seus exercícios, séries ou repetições.")
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                .padding(.vertical, FitTodaySpacing.xs)
            }
        }
        .navigationTitle("Privacidade")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSettings()
        }
        .showErrorAlert(errorMessage: $viewModel.errorMessage)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView(resolver: Container())
    }
}
