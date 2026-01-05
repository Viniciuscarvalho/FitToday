//
//  ExerciseDBConfiguration.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Configuração para a API ExerciseDB via RapidAPI.
struct ExerciseDBConfiguration: Sendable {
  let apiKey: String
  let host: String
  let baseURL: URL

  static let defaultHost = "exercisedb-api1.p.rapidapi.com"
  static let defaultBaseURL = URL(string: "https://exercisedb-api1.p.rapidapi.com")!

  init(apiKey: String, host: String = defaultHost, baseURL: URL = defaultBaseURL) {
    self.apiKey = apiKey
    self.host = host
    self.baseURL = baseURL
  }

  /// Carrega configuração da chave do usuário (Keychain) - método preferido
  /// Retorna nil se o usuário não tiver configurado uma chave
  static func loadFromUserKey() -> ExerciseDBConfiguration? {
    guard let apiKey = UserAPIKeyManager.shared.getAPIKey(for: .exerciseDB),
          !apiKey.isEmpty else {
      return nil
    }
    
    return ExerciseDBConfiguration(apiKey: apiKey, host: defaultHost, baseURL: defaultBaseURL)
  }
  
  /// Carrega configuração do bundle (Info.plist ou arquivo dedicado) - DEPRECATED
  /// Use loadFromUserKey() para usar chave do usuário
  static func loadFromBundle() -> ExerciseDBConfiguration? {
    // Primeiro tenta carregar da chave do usuário (preferido)
    if let config = loadFromUserKey() {
      return config
    }
    
    // Fallback para plist (legado - apenas para desenvolvimento)
    if let plistPath = Bundle.main.path(forResource: "ExerciseDBConfig", ofType: "plist"),
       let plistData = FileManager.default.contents(atPath: plistPath),
       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
       let apiKey = plist["EXERCISEDB_API_KEY"] as? String,
       !apiKey.isEmpty {
      #if DEBUG
      print("[ExerciseDB] ⚠️ Usando chave do plist - considere migrar para Keychain")
      #endif
      let host = (plist["EXERCISEDB_HOST"] as? String) ?? defaultHost
      let baseURLString = (plist["EXERCISEDB_BASE_URL"] as? String) ?? "https://\(host)"
      let baseURL = URL(string: baseURLString) ?? defaultBaseURL
      return ExerciseDBConfiguration(apiKey: apiKey, host: host, baseURL: baseURL)
    }

    return nil
  }
  
  /// Verifica se o usuário tem uma chave de API configurada
  static var isUserKeyConfigured: Bool {
    return UserAPIKeyManager.shared.hasAPIKey(for: .exerciseDB)
  }

  /// Headers necessários para autenticação na API RapidAPI.
  var authHeaders: [String: String] {
    [
      "x-rapidapi-key": apiKey,
      "x-rapidapi-host": host
    ]
  }
}


