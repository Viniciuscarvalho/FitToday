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
        let timeout: TimeInterval = 20
        let maxTokens = 800
        let temperature = 0.2
        let cacheTTL: TimeInterval = 300
    }
    
    /// Cria configuração usando a chave fornecida pelo usuário (armazenada no Keychain)
    /// Retorna nil se o usuário não tiver configurado uma chave
    static func loadFromUserKey() -> OpenAIConfiguration? {
        guard let apiKey = UserAPIKeyManager.shared.getAPIKey(for: .openAI),
              !apiKey.isEmpty else {
            return nil
        }
        
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
