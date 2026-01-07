//
//  ExerciseDBTargetCatalog.swift
//  FitToday
//
//  Created by AI on 05/01/26.
//

import Foundation

/// Protocolo para gerenciar o catálogo de targets (músculo-alvo) do ExerciseDB.
protocol ExerciseDBTargetCataloging: Sendable {
    /// Carrega a lista de targets válidos, usando cache quando disponível.
    /// - Parameter forceRefresh: Se true, ignora cache e busca da API.
    func loadTargets(forceRefresh: Bool) async throws -> [String]
    
    /// Verifica se um target é válido (está na lista cacheada).
    func isValidTarget(_ target: String) async -> Bool
}

/// Gerencia o cache de targets do ExerciseDB com TTL.
actor ExerciseDBTargetCatalog: ExerciseDBTargetCataloging {
    private let service: ExerciseDBServicing
    private let userDefaults: UserDefaults
    private let ttl: TimeInterval
    
    // Cache em memória para acesso rápido
    private var cachedTargets: [String]?
    private var lastLoadDate: Date?
    
    // Chave para persistência
    private static let cacheKey = "exercisedb_target_list_v1"
    private static let timestampKey = "exercisedb_target_list_timestamp_v1"
    
    /// Inicializa o catálogo.
    /// - Parameters:
    ///   - service: Serviço para buscar dados do ExerciseDB.
    ///   - userDefaults: UserDefaults para persistência (padrão: .standard).
    ///   - ttl: Time-To-Live do cache em segundos (padrão: 7 dias).
    init(
        service: ExerciseDBServicing,
        userDefaults: UserDefaults = .standard,
        ttl: TimeInterval = 7 * 24 * 60 * 60 // 7 dias
    ) {
        self.service = service
        self.userDefaults = userDefaults
        self.ttl = ttl
    }
    
    func loadTargets(forceRefresh: Bool = false) async throws -> [String] {
        // 1. Se forçar refresh, busca da API
        if forceRefresh {
            return try await fetchAndCacheTargets()
        }
        
        // 2. Verifica cache em memória
        if let cached = cachedTargets, !isCacheExpired() {
            #if DEBUG
            print("[TargetCatalog] Cache em memória válido: \(cached.count) targets")
            #endif
            return cached
        }
        
        // 3. Tenta carregar do UserDefaults
        if let persisted = loadPersistedTargets(), !isCacheExpired() {
            cachedTargets = persisted
            #if DEBUG
            print("[TargetCatalog] Cache persistido carregado: \(persisted.count) targets")
            #endif
            return persisted
        }
        
        // 4. Cache expirado ou inexistente, busca da API
        return try await fetchAndCacheTargets()
    }
    
    func isValidTarget(_ target: String) async -> Bool {
        do {
            let targets = try await loadTargets()
            let normalizedInput = target.lowercased().trimmingCharacters(in: .whitespaces)
            return targets.contains { $0.lowercased() == normalizedInput }
        } catch {
            #if DEBUG
            print("[TargetCatalog] Erro ao verificar target '\(target)': \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchAndCacheTargets() async throws -> [String] {
        let targets = try await service.fetchTargetList()
        
        // Cacheia em memória
        cachedTargets = targets
        lastLoadDate = Date()
        
        // Persiste em UserDefaults
        persistTargets(targets)
        
        #if DEBUG
        print("[TargetCatalog] Targets fetched e cacheados: \(targets.count)")
        #endif
        
        return targets
    }
    
    private func loadPersistedTargets() -> [String]? {
        guard let data = userDefaults.data(forKey: Self.cacheKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode([String].self, from: data)
    }
    
    private func persistTargets(_ targets: [String]) {
        guard let data = try? JSONEncoder().encode(targets) else {
            return
        }
        
        userDefaults.set(data, forKey: Self.cacheKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: Self.timestampKey)
    }
    
    private func isCacheExpired() -> Bool {
        let timestamp = userDefaults.double(forKey: Self.timestampKey)
        
        // Se timestamp for 0, significa que nunca foi persistido
        guard timestamp > 0 else {
            return true
        }
        
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let elapsed = Date().timeIntervalSince(cacheDate)
        
        return elapsed > ttl
    }
    
    /// Limpa o cache (útil para testes e debug).
    func clearCache() {
        cachedTargets = nil
        lastLoadDate = nil
        userDefaults.removeObject(forKey: Self.cacheKey)
        userDefaults.removeObject(forKey: Self.timestampKey)
        
        #if DEBUG
        print("[TargetCatalog] Cache limpo")
        #endif
    }
}


