//
//  PerformanceLogger.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import OSLog

/// Logger de performance e observabilidade para diagnóstico em DEBUG
enum PerformanceLogger {
    private static let subsystem = "com.fittoday.performance"
    
    // MARK: - Loggers
    
    static let media = Logger(subsystem: subsystem, category: "media")
    static let lists = Logger(subsystem: subsystem, category: "lists")
    static let openai = Logger(subsystem: subsystem, category: "openai")
    static let cache = Logger(subsystem: subsystem, category: "cache")
    
    // MARK: - Media Logging
    
    static func logMediaLoadStart(exerciseId: String, source: String) {
        #if DEBUG
        media.debug("🖼️ Carregando mídia: exerciseId=\(exerciseId, privacy: .public) source=\(source, privacy: .public)")
        #endif
    }
    
    static func logMediaLoadSuccess(exerciseId: String, source: String, duration: TimeInterval? = nil) {
        #if DEBUG
        if let duration = duration {
            let ms = Int(duration * 1000)
            media.info("✅ Mídia carregada: exerciseId=\(exerciseId, privacy: .public) source=\(source, privacy: .public) duration=\(ms)ms")
        } else {
            media.info("✅ Mídia carregada: exerciseId=\(exerciseId, privacy: .public) source=\(source, privacy: .public)")
        }
        #endif
    }
    
    static func logMediaLoadFailure(exerciseId: String, source: String, error: Error? = nil) {
        #if DEBUG
        if let error = error {
            media.error("❌ Falha ao carregar mídia: exerciseId=\(exerciseId, privacy: .public) source=\(source, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
        } else {
            media.error("❌ Falha ao carregar mídia: exerciseId=\(exerciseId, privacy: .public) source=\(source, privacy: .public)")
        }
        #endif
    }
    
    static func logMediaCacheHit(exerciseId: String) {
        #if DEBUG
        cache.debug("💾 Cache hit: exerciseId=\(exerciseId, privacy: .public)")
        #endif
    }
    
    static func logMediaCacheMiss(exerciseId: String) {
        #if DEBUG
        cache.debug("💨 Cache miss: exerciseId=\(exerciseId, privacy: .public)")
        #endif
    }
    
    // MARK: - List Performance
    
    static func logListRender(itemsCount: Int, viewName: String) {
        #if DEBUG
        lists.debug("📋 Renderizando lista: view=\(viewName, privacy: .public) items=\(itemsCount, privacy: .public)")
        #endif
    }
    
    static func logListScrollPerformance(viewName: String, frameDrops: Int? = nil) {
        #if DEBUG
        if let frameDrops = frameDrops, frameDrops > 0 {
            lists.warning("⚠️ Frame drops durante scroll: view=\(viewName, privacy: .public) drops=\(frameDrops, privacy: .public)")
        }
        #endif
    }
    
    // MARK: - OpenAI Performance
    
    static func logOpenAICallStart(userId: String) {
        #if DEBUG
        openai.debug("🤖 Chamada OpenAI iniciada: userId=\(userId, privacy: .public)")
        #endif
    }
    
    static func logOpenAICallSuccess(userId: String, duration: TimeInterval, tokens: Int? = nil) {
        #if DEBUG
        let ms = Int(duration * 1000)
        if let tokens = tokens {
            openai.info("✅ OpenAI sucesso: userId=\(userId, privacy: .public) duration=\(ms)ms tokens=\(tokens, privacy: .public)")
        } else {
            openai.info("✅ OpenAI sucesso: userId=\(userId, privacy: .public) duration=\(ms)ms")
        }
        #endif
    }
    
    static func logOpenAICallFailure(userId: String, error: Error) {
        #if DEBUG
        openai.error("❌ OpenAI falhou: userId=\(userId, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
        #endif
    }
    
    static func logOpenAICacheHit(promptHash: String) {
        #if DEBUG
        cache.debug("💾 Cache hit OpenAI: hash=\(promptHash.prefix(8), privacy: .public)")
        #endif
    }
    
    // MARK: - Cache Performance
    
    static func logCacheOperation(operation: String, key: String, hit: Bool) {
        #if DEBUG
        let emoji = hit ? "💾" : "💨"
        cache.debug("\(emoji) Cache \(operation): key=\(key.prefix(16), privacy: .public) hit=\(hit, privacy: .public)")
        #endif
    }
}

