//
//  OpenAIConfiguration.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct OpenAIConfiguration: Sendable {
    let apiKey: String
    let model: String
    let baseURL: URL
    let timeout: TimeInterval
    let maxTokens: Int
    let temperature: Double
    let cacheTTL: TimeInterval

    /// Configuração padrão (sem chave - será fornecida pelo usuário)
    static let defaultSettings = DefaultSettings()

    struct DefaultSettings {
        let model = "gpt-4o-mini"
        let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
        let timeout: TimeInterval = 60 // Aumentado para 60s (treino completo)
        let maxTokens = 2000 // Aumentado para suportar resposta JSON completa

        // Temperature: controla variabilidade das respostas
        // 0.55 = produção (balanceado: variado mas coerente), 0.7 = debug (mais variado)
        #if DEBUG
        let temperature = 0.7 // Higher for testing variety
        let cacheTTL: TimeInterval = 0 // No cache in DEBUG for testing
        #else
        let temperature = 0.55 // Balanced: varied exercises but coherent workout structure
        let cacheTTL: TimeInterval = 300 // 5 minutos - permite variação mais frequente
        #endif
    }

    /// Cria configuração usando a chave fornecida pelo usuário (armazenada no Keychain)
    /// Retorna nil se o usuário não tiver configurado uma chave
    static func loadFromUserKey() -> OpenAIConfiguration? {
        guard let apiKey = UserAPIKeyManager.shared.getAPIKey(for: .openAI),
              !apiKey.isEmpty else {
            return nil
        }

        #if DEBUG
        print("[OpenAIConfiguration] DEBUG mode: temperature=\(defaultSettings.temperature), cacheTTL=\(defaultSettings.cacheTTL)")
        #endif

        return OpenAIConfiguration(
            apiKey: apiKey,
            model: defaultSettings.model,
            baseURL: defaultSettings.baseURL,
            timeout: defaultSettings.timeout,
            maxTokens: defaultSettings.maxTokens,
            temperature: defaultSettings.temperature,
            cacheTTL: defaultSettings.cacheTTL
        )
    }

    /// Cria configuração com uma chave específica (para testes ou uso direto)
    static func with(apiKey: String) -> OpenAIConfiguration {
        return OpenAIConfiguration(
            apiKey: apiKey,
            model: defaultSettings.model,
            baseURL: defaultSettings.baseURL,
            timeout: defaultSettings.timeout,
            maxTokens: defaultSettings.maxTokens,
            temperature: defaultSettings.temperature,
            cacheTTL: defaultSettings.cacheTTL
        )
    }
    
    /// Verifica se o usuário tem uma chave de API configurada
    static var isUserKeyConfigured: Bool {
        return UserAPIKeyManager.shared.hasAPIKey(for: .openAI)
    }
}
