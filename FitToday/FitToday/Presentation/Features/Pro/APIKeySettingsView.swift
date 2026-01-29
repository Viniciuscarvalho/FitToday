//
//  APIKeySettingsView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

/// View para configuração da chave de API do usuário (OpenAI)
/// A API do Wger é gratuita e não requer chave
struct APIKeySettingsView: View {
    @StateObject private var keyStore = UserAPIKeyStore()
    @State private var apiKeyInput: String = ""
    @State private var showingKeyInput: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                headerSection
                
                if keyStore.hasOpenAIKey {
                    configuredKeySection
                } else {
                    noKeySection
                }
                
                benefitsSection
                
                helpSection
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Configurar IA")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingKeyInput) {
            apiKeyInputSheet
        }
        .alert("Remover Chave", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Remover", role: .destructive) {
                keyStore.removeOpenAIKey()
            }
        } message: {
            Text("Tem certeza que deseja remover sua chave de API? Você precisará configurá-la novamente para usar recursos de IA.")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Image(systemName: "brain")
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                
                Text("Assistente de IA")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }
            
            Text("Configure sua própria chave de API para usar recursos avançados de inteligência artificial no seu treino.")
                .font(.system(.body))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
    
    // MARK: - Key Status
    
    private var configuredKeySection: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(FitTodayColor.success)
                    Text("Chave Configurada")
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
                
                if let maskedKey = keyStore.getMaskedKey(for: .openAI) {
                    Text(maskedKey)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                
                HStack(spacing: FitTodaySpacing.md) {
                    Button("Alterar") {
                        showingKeyInput = true
                    }
                    .fitSecondaryStyle()
                    
                    Button("Remover") {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(FitTodayColor.error)
                }
            }
        }
    }
    
    private var noKeySection: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: "key")
                        .foregroundStyle(FitTodayColor.warning)
                    Text("Nenhuma Chave Configurada")
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
                
                Text("Para usar recursos de IA, você precisa configurar sua própria chave de API da OpenAI.")
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)
                
                Button("Configurar Chave") {
                    showingKeyInput = true
                }
                .fitPrimaryStyle()
            }
        }
    }
    
    // MARK: - Benefits
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Benefícios da IA")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            VStack(spacing: FitTodaySpacing.sm) {
                benefitRow(icon: "sparkles", text: "Treinos mais personalizados")
                benefitRow(icon: "brain.head.profile", text: "Ajustes inteligentes por DOMS")
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Progressão otimizada")
                benefitRow(icon: "figure.run", text: "Seleção de exercícios adaptativa")
            }
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(.body))
                .foregroundStyle(FitTodayColor.textSecondary)
            
            Spacer()
        }
        .padding(.vertical, FitTodaySpacing.xs)
    }
    
    // MARK: - Help
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Como obter sua chave")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                stepRow(number: 1, text: "Acesse platform.openai.com")
                stepRow(number: 2, text: "Crie uma conta ou faça login")
                stepRow(number: 3, text: "Vá em API Keys")
                stepRow(number: 4, text: "Crie uma nova chave")
                stepRow(number: 5, text: "Copie e cole aqui")
            }
            
            if let helpURL = UserAPIKeyManager.APIService.openAI.helpURL {
                Link(destination: helpURL) {
                    HStack {
                        Text("Abrir OpenAI Platform")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                }
                .padding(.top, FitTodaySpacing.xs)
            }
            
            // Aviso sobre custo
            HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(FitTodayColor.warning)
                
                Text("O uso da API da OpenAI pode gerar custos na sua conta. Consulte os preços em openai.com/pricing")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding()
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
        }
    }
    
    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Text("\(number)")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(FitTodayColor.brandPrimary)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(.body))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
    
    // MARK: - Input Sheet
    
    private var apiKeyInputSheet: some View {
        NavigationStack {
            VStack(spacing: FitTodaySpacing.lg) {
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    Text("Insira sua chave de API")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    
                    Text("A chave será armazenada de forma segura no seu dispositivo.")
                        .font(.system(.body))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                
                SecureField("sk-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if let error = keyStore.validationError {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(error)
                    }
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.error)
                }
                
                Spacer()
                
                Button {
                    Task {
                        if await keyStore.saveOpenAIKey(apiKeyInput) {
                            apiKeyInput = ""
                            showingKeyInput = false
                        }
                    }
                } label: {
                    if keyStore.isValidating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Salvar Chave")
                    }
                }
                .fitPrimaryStyle()
                .disabled(apiKeyInput.isEmpty || keyStore.isValidating)
            }
            .padding()
            .background(FitTodayColor.background.ignoresSafeArea())
            .navigationTitle("Chave de API")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        apiKeyInput = ""
                        showingKeyInput = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        APIKeySettingsView()
    }
}
