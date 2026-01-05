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

    /// Carrega configuração do arquivo OpenAIConfig.plist no bundle.
    /// Retorna nil se o arquivo não existir ou a API key não estiver configurada.
    static func loadFromBundle() -> OpenAIConfiguration? {
        // Tentar carregar do OpenAIConfig.plist primeiro
        if let config = loadFromConfigFile() {
            return config
        }
        
        // Fallback: tentar carregar do Info.plist (legacy)
        return loadFromInfoPlist()
    }
    
    private static func loadFromConfigFile() -> OpenAIConfiguration? {
        guard let url = Bundle.main.url(forResource: "OpenAIConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let config = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let apiKey = config["OPENAI_API_KEY"] as? String,
              !apiKey.isEmpty
        else {
            return nil
        }

        let model = config["OPENAI_MODEL"] as? String ?? "gpt-4o-mini"
        let baseURLString = config["OPENAI_BASE_URL"] as? String ?? "https://api.openai.com/v1/chat/completions"
        guard let baseURL = URL(string: baseURLString) else {
            return nil
        }

        let timeout = (config["OPENAI_TIMEOUT_SECONDS"] as? NSNumber)?.doubleValue ?? 20
        let maxTokens = (config["OPENAI_MAX_TOKENS"] as? NSNumber)?.intValue ?? 800
        let temperature = (config["OPENAI_TEMPERATURE"] as? NSNumber)?.doubleValue ?? 0.2
        let cacheTTL = (config["OPENAI_CACHE_TTL_SECONDS"] as? NSNumber)?.doubleValue ?? 300

        return OpenAIConfiguration(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            timeout: timeout,
            maxTokens: maxTokens,
            temperature: temperature,
            cacheTTL: cacheTTL
        )
    }
    
    private static func loadFromInfoPlist() -> OpenAIConfiguration? {
        guard
            let info = Bundle.main.infoDictionary,
            let apiKey = info["OPENAI_API_KEY"] as? String,
            !apiKey.isEmpty
        else {
            return nil
        }

        let model = info["OPENAI_MODEL"] as? String ?? "gpt-4o-mini"
        let baseURLString = info["OPENAI_BASE_URL"] as? String ?? "https://api.openai.com/v1/chat/completions"
        guard let baseURL = URL(string: baseURLString) else {
            return nil
        }

        let timeout = info["OPENAI_TIMEOUT_SECONDS"] as? Double ?? 20
        let maxTokens = info["OPENAI_MAX_TOKENS"] as? Int ?? 800
        let temperature = info["OPENAI_TEMPERATURE"] as? Double ?? 0.2
        let cacheTTL = info["OPENAI_CACHE_TTL_SECONDS"] as? Double ?? 300

        return OpenAIConfiguration(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            timeout: timeout,
            maxTokens: maxTokens,
            temperature: temperature,
            cacheTTL: cacheTTL
        )
    }
}

