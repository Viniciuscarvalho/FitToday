//
//  UserAPIKeyManager.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Security
import Combine

/// Gerenciador de chaves de API fornecidas pelo usuário
/// Armazena as chaves de forma segura usando Keychain
final class UserAPIKeyManager: Sendable {
    
    enum APIService: String, CaseIterable {
        case openAI = "com.fittoday.openai.apikey"
        case exerciseDB = "com.fittoday.exercisedb.apikey"
        
        var displayName: String {
            switch self {
            case .openAI: return "OpenAI"
            case .exerciseDB: return "ExerciseDB (RapidAPI)"
            }
        }
        
        var helpURL: URL? {
            switch self {
            case .openAI: return URL(string: "https://platform.openai.com/api-keys")
            case .exerciseDB: return URL(string: "https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb/")
            }
        }
    }
    
    static let shared = UserAPIKeyManager()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Verifica se o usuário tem uma chave configurada para o serviço
    func hasAPIKey(for service: APIService) -> Bool {
        return getAPIKey(for: service) != nil
    }
    
    /// Obtém a chave de API para o serviço especificado
    func getAPIKey(for service: APIService) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: "user_api_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8),
              !apiKey.isEmpty else {
            return nil
        }
        
        return apiKey
    }
    
    /// Salva uma chave de API para o serviço especificado
    @discardableResult
    func saveAPIKey(_ apiKey: String, for service: APIService) -> Bool {
        // Primeiro, tenta deletar qualquer chave existente
        deleteAPIKey(for: service)
        
        guard !apiKey.isEmpty,
              let data = apiKey.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: "user_api_key",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Remove a chave de API para o serviço especificado
    @discardableResult
    func deleteAPIKey(for service: APIService) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: "user_api_key"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Valida o formato básico de uma chave de API
    func validateAPIKeyFormat(_ apiKey: String, for service: APIService) -> Bool {
        switch service {
        case .openAI:
            // OpenAI keys começam com "sk-" e têm pelo menos 20 caracteres
            return apiKey.hasPrefix("sk-") && apiKey.count >= 20
        case .exerciseDB:
            // RapidAPI keys são strings alfanuméricas de pelo menos 30 caracteres
            return apiKey.count >= 30 && !apiKey.isEmpty
        }
    }
}

// MARK: - Observable Wrapper for SwiftUI

@MainActor
final class UserAPIKeyStore: ObservableObject {
    @Published private(set) var hasOpenAIKey: Bool = false
    @Published private(set) var hasExerciseDBKey: Bool = false
    @Published var isValidating: Bool = false
    @Published var validationError: String?
    
    private let manager = UserAPIKeyManager.shared
    
    init() {
        refreshKeyStatus()
    }
    
    func refreshKeyStatus() {
        hasOpenAIKey = manager.hasAPIKey(for: .openAI)
        hasExerciseDBKey = manager.hasAPIKey(for: .exerciseDB)
    }
    
    func saveOpenAIKey(_ key: String) async -> Bool {
        isValidating = true
        validationError = nil
        
        defer {
            isValidating = false
            refreshKeyStatus()
        }
        
        // Validar formato
        guard manager.validateAPIKeyFormat(key, for: .openAI) else {
            validationError = "Formato inválido. A chave deve começar com 'sk-'"
            return false
        }
        
        // Tentar validar com a API (opcional - pode ser caro)
        // Por enquanto, apenas salvar
        let success = manager.saveAPIKey(key, for: .openAI)
        
        if !success {
            validationError = "Erro ao salvar a chave. Tente novamente."
        }
        
        return success
    }
    
    func removeOpenAIKey() {
        manager.deleteAPIKey(for: .openAI)
        refreshKeyStatus()
    }
    
    func saveExerciseDBKey(_ key: String) async -> Bool {
        isValidating = true
        validationError = nil
        
        defer {
            isValidating = false
            refreshKeyStatus()
        }
        
        // Validar formato
        guard manager.validateAPIKeyFormat(key, for: .exerciseDB) else {
            validationError = "Formato inválido. A chave deve ter pelo menos 30 caracteres."
            return false
        }
        
        let success = manager.saveAPIKey(key, for: .exerciseDB)
        
        if !success {
            validationError = "Erro ao salvar a chave. Tente novamente."
        }
        
        return success
    }
    
    func removeExerciseDBKey() {
        manager.deleteAPIKey(for: .exerciseDB)
        refreshKeyStatus()
    }
    
    /// Obtém a chave mascarada para exibição
    func getMaskedKey(for service: UserAPIKeyManager.APIService) -> String? {
        guard let key = manager.getAPIKey(for: service) else { return nil }
        
        // Mostrar apenas os últimos 4 caracteres
        let suffix = String(key.suffix(4))
        switch service {
        case .openAI:
            return "sk-•••••••••\(suffix)"
        case .exerciseDB:
            return "••••••••\(suffix)"
        }
    }
}

