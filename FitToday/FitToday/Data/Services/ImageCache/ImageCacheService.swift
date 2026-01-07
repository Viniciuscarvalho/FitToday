//
//  ImageCacheService.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation
import UIKit

/// Protocol para serviço de cache de imagens
protocol ImageCaching: Sendable {
    /// Cacheia uma imagem da URL fornecida
    func cacheImage(from url: URL) async throws
    
    /// Retorna imagem cacheada se disponível
    func cachedImage(for url: URL) async -> UIImage?
    
    /// Pre-fetcha múltiplas imagens em paralelo
    func prefetchImages(_ urls: [URL]) async
    
    /// Remove todos os dados do cache
    func clearCache() async
    
    /// Retorna o tamanho total do cache em bytes
    func cacheSize() async -> Int64
}

/// Serviço de cache de imagens com arquitetura híbrida (URLCache + DiskCache)
final class ImageCacheService: ImageCaching, @unchecked Sendable {
    private let urlCache: URLCache
    private let diskCache: DiskImageCache
    private let session: URLSession
    private let config: ImageCacheConfiguration
    
    /// Inicializa o serviço de cache
    /// - Parameters:
    ///   - configuration: Configuração do cache
    ///   - urlCache: URLCache para cache em memória (padrão: .shared)
    ///   - session: URLSession para downloads (padrão: .shared)
    init(
        configuration: ImageCacheConfiguration,
        urlCache: URLCache? = nil,
        session: URLSession = .shared
    ) {
        self.config = configuration
        self.diskCache = DiskImageCache(configuration: configuration)
        self.session = session
        
        // Configurar URLCache customizado se não fornecido
        if let urlCache = urlCache {
            self.urlCache = urlCache
        } else {
            self.urlCache = URLCache(
                memoryCapacity: configuration.maxMemorySize,
                diskCapacity: 0 // Não usar disk cache do URLCache (temos custom)
            )
        }
        
        // Configurar URLCache como padrão da sessão
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.urlCache = self.urlCache
        sessionConfig.requestCachePolicy = .returnCacheDataElseLoad
    }
    
    /// Cacheia uma imagem da URL fornecida
    /// - Parameter url: URL da imagem
    /// - Throws: ImageCacheError se houver falha no download ou salvamento
    func cacheImage(from url: URL) async throws {
        // Verificar se já está em cache
        if await cachedImage(for: url) != nil {
            return
        }
        
        // Download da imagem
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, response) = try await session.data(for: request)
        
        // Validar resposta HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageCacheError.invalidResponse(statusCode: 0)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImageCacheError.invalidResponse(statusCode: httpResponse.statusCode)
        }
        
        // Validar que os dados são uma imagem válida
        guard UIImage(data: data) != nil else {
            throw ImageCacheError.invalidImageData
        }
        
        // Salvar no disk cache
        try await diskCache.save(data, for: url)
        
        // URLCache já cacheia automaticamente via URLSession
        #if DEBUG
        logCacheStats()
        #endif
    }
    
    /// Retorna imagem cacheada se disponível
    /// - Parameter url: URL da imagem
    /// - Returns: UIImage se encontrada em cache, nil caso contrário
    func cachedImage(for url: URL) async -> UIImage? {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        // 1. Tentar URLCache (memória) primeiro - mais rápido
        if let cachedResponse = urlCache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            #if DEBUG
            print("[ImageCache] Memory cache HIT: \(url.lastPathComponent)")
            #endif
            return image
        }
        
        // 2. Tentar DiskCache
        if let data = await diskCache.data(for: url),
           let image = UIImage(data: data) {
            #if DEBUG
            print("[ImageCache] Disk cache HIT: \(url.lastPathComponent)")
            #endif
            
            // Popular URLCache para próximas leituras
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let cachedResponse = CachedURLResponse(response: response, data: data)
            urlCache.storeCachedResponse(cachedResponse, for: request)
            
            return image
        }
        
        // 3. Cache MISS
        #if DEBUG
        print("[ImageCache] Cache MISS: \(url.lastPathComponent)")
        #endif
        return nil
    }
    
    /// Pre-fetcha múltiplas imagens em paralelo com concurrency controlada
    /// - Parameter urls: Array de URLs para prefetch
    func prefetchImages(_ urls: [URL]) async {
        #if DEBUG
        print("[ImageCache] Prefetching \(urls.count) images...")
        let startTime = Date()
        #endif
        
        await withTaskGroup(of: Void.self) { group in
            var pendingURLs = urls
            var activeTasksCount = 0
            
            while !pendingURLs.isEmpty || activeTasksCount > 0 {
                // Adicionar novas tasks até o limite de concurrency
                while activeTasksCount < config.prefetchConcurrency && !pendingURLs.isEmpty {
                    let url = pendingURLs.removeFirst()
                    activeTasksCount += 1
                    
                    group.addTask { [weak self] in
                        defer { }
                        do {
                            try await self?.cacheImage(from: url)
                        } catch {
                            #if DEBUG
                            print("[ImageCache] Prefetch failed for \(url.lastPathComponent): \(error)")
                            #endif
                        }
                    }
                }
                
                // Aguardar pelo menos uma task completar
                if activeTasksCount > 0 {
                    await group.next()
                    activeTasksCount -= 1
                }
            }
        }
        
        #if DEBUG
        let duration = Date().timeIntervalSince(startTime)
        print("[ImageCache] Prefetch completed in \(String(format: "%.2f", duration))s")
        logCacheStats()
        #endif
    }
    
    /// Remove todos os dados do cache (memória + disco)
    func clearCache() async {
        urlCache.removeAllCachedResponses()
        await diskCache.clearAll()
        
        #if DEBUG
        print("[ImageCache] Cache cleared")
        #endif
    }
    
    /// Retorna o tamanho total do cache em bytes (memória + disco)
    /// - Returns: Tamanho total em bytes
    func cacheSize() async -> Int64 {
        let memorySize = Int64(urlCache.currentMemoryUsage)
        let diskSize = await diskCache.totalSize()
        return memorySize + diskSize
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    private func logCacheStats() {
        Task {
            let memoryKB = urlCache.currentMemoryUsage / 1024
            let diskMB = await diskCache.totalSize() / 1024 / 1024
            print("[ImageCache] Memory: \(memoryKB)KB | Disk: \(diskMB)MB")
        }
    }
    #endif
}

// MARK: - Mock for Testing

/// Mock do ImageCacheService para testes
final class MockImageCacheService: ImageCaching {
    var cachedImages: [URL: UIImage] = [:]
    var shouldThrowError = false
    var prefetchedURLs: [URL] = []
    
    func cacheImage(from url: URL) async throws {
        if shouldThrowError {
            throw ImageCacheError.invalidResponse(statusCode: 404)
        }
        // Simular imagem cacheada
        cachedImages[url] = UIImage()
    }
    
    func cachedImage(for url: URL) async -> UIImage? {
        return cachedImages[url]
    }
    
    func prefetchImages(_ urls: [URL]) async {
        prefetchedURLs.append(contentsOf: urls)
        for url in urls {
            try? await cacheImage(from: url)
        }
    }
    
    func clearCache() async {
        cachedImages.removeAll()
        prefetchedURLs.removeAll()
    }
    
    func cacheSize() async -> Int64 {
        return Int64(cachedImages.count * 1024) // Simular 1KB por imagem
    }
}

