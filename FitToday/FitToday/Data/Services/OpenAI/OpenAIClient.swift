//
//  OpenAIClient.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

protocol OpenAIClienting: Sendable {
    func sendJSONPrompt(prompt: String, cachedKey: String?) async throws -> Data
}

enum OpenAIClientError: Error, LocalizedError {
    case configurationMissing
    case invalidResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "Configuração do OpenAI não encontrada."
        case .invalidResponse:
            return "Resposta inválida do serviço OpenAI."
        case .httpError(let status, let message):
            return "Falha \(status) ao chamar OpenAI: \(message)"
        }
    }
}

actor OpenAIClient: OpenAIClienting {
    struct Metrics {
        let duration: TimeInterval
        let cacheHit: Bool
        let bytesIn: Int
    }

    private let configuration: OpenAIConfiguration
    private let cache: OpenAIResponseCache
    private let session: URLSession
    private let metricsHandler: (Metrics) -> Void

    init(configuration: OpenAIConfiguration, metricsHandler: @escaping (Metrics) -> Void = { metrics in
        print("[OpenAI] duration=\(metrics.duration)s cacheHit=\(metrics.cacheHit) bytes=\(metrics.bytesIn)")
    }) {
        self.configuration = configuration
        self.cache = OpenAIResponseCache(ttl: configuration.cacheTTL)
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        self.session = URLSession(configuration: sessionConfig)
        self.metricsHandler = metricsHandler
    }

    func sendJSONPrompt(prompt: String, cachedKey: String?) async throws -> Data {
        if let key = cachedKey, let cached = await cache.value(for: key) {
            metricsHandler(Metrics(duration: 0, cacheHit: true, bytesIn: cached.count))
            return cached
        }

        var request = URLRequest(url: configuration.baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        // Formato correto para Chat Completions API (/v1/chat/completions)
        let messages: [[String: String]] = [
            [
                "role": "system",
                "content": "Você é um personal trainer experiente que monta treinos personalizados. Sempre responda em JSON válido seguindo o schema solicitado."
            ],
            [
                "role": "user",
                "content": prompt
            ]
        ]
        
        let payload: [String: Any] = [
            "model": configuration.model,
            "messages": messages,
            "max_tokens": configuration.maxTokens,
            "temperature": configuration.temperature,
            "response_format": ["type": "json_object"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let start = Date()
        let (data, response) = try await session.data(for: request)
        metricsHandler(Metrics(duration: Date().timeIntervalSince(start), cacheHit: false, bytesIn: data.count))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Sem detalhes"
            throw OpenAIClientError.httpError(httpResponse.statusCode, message)
        }

        if let key = cachedKey {
            await cache.insert(data, for: key)
        }

        return data
    }
}

