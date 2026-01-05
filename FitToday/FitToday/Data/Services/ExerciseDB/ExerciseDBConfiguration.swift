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

  /// Carrega configuração do bundle (Info.plist ou arquivo dedicado).
  static func loadFromBundle() -> ExerciseDBConfiguration? {
    // Primeiro tenta carregar de ExerciseDBConfig.plist
    if let plistPath = Bundle.main.path(forResource: "ExerciseDBConfig", ofType: "plist"),
       let plistData = FileManager.default.contents(atPath: plistPath),
       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
       let apiKey = plist["EXERCISEDB_API_KEY"] as? String,
       !apiKey.isEmpty {
      let host = (plist["EXERCISEDB_HOST"] as? String) ?? defaultHost
      let baseURLString = (plist["EXERCISEDB_BASE_URL"] as? String) ?? "https://\(host)"
      let baseURL = URL(string: baseURLString) ?? defaultBaseURL
      return ExerciseDBConfiguration(apiKey: apiKey, host: host, baseURL: baseURL)
    }

    // Fallback para Info.plist
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "EXERCISEDB_API_KEY") as? String,
       !apiKey.isEmpty {
      let host = (Bundle.main.object(forInfoDictionaryKey: "EXERCISEDB_HOST") as? String) ?? defaultHost
      return ExerciseDBConfiguration(apiKey: apiKey, host: host)
    }

    return nil
  }

  /// Headers necessários para autenticação na API RapidAPI.
  var authHeaders: [String: String] {
    [
      "x-rapidapi-key": apiKey,
      "x-rapidapi-host": host
    ]
  }
}


