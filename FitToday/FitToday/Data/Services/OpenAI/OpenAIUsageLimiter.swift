//
//  OpenAIUsageLimiter.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

protocol OpenAIUsageLimiting: Sendable {
    func canUseAI(userId: UUID, on date: Date) async -> Bool
    func registerUsage(userId: UUID, on date: Date) async
}

actor OpenAIUsageLimiter: OpenAIUsageLimiting {
    private struct Record: Codable {
        var date: Date
        var count: Int
    }

    private let storageKey = "openai_usage_records"
    private let dailyLimit: Int
    private var records: [UUID: Record] = [:]

    /// Limite diário padrão: 2 gerações via IA para usuários PRO.
    /// Limite reduzido para controlar custos de API; fallback local disponível após limite.
    init(dailyLimit: Int = 2) {
        self.dailyLimit = dailyLimit
        load()
    }
    
    /// Reseta o contador de uso para um usuário específico (útil para debug/testes)
    func resetUsage(for userId: UUID) async {
        records.removeValue(forKey: userId)
        persist()
    }
    
    /// Limpa todos os registros de uso (útil para debug/testes)
    func resetAllUsage() async {
        records.removeAll()
        persist()
    }

    func canUseAI(userId: UUID, on date: Date) async -> Bool {
        guard let record = records[userId] else { return true }
        if Calendar.current.isDate(record.date, inSameDayAs: date) {
            return record.count < dailyLimit
        } else {
            return true
        }
    }

    func registerUsage(userId: UUID, on date: Date) async {
        if var record = records[userId], Calendar.current.isDate(record.date, inSameDayAs: date) {
            record.count += 1
            records[userId] = record
        } else {
            records[userId] = Record(date: date, count: 1)
        }
        persist()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([UUID: Record].self, from: data)
        else { return }
        records = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}




