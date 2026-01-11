//
//  ImageCacheConfiguration.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation

/// Configuração para o serviço de cache de imagens
struct ImageCacheConfiguration {
    /// Tamanho máximo do cache em disco (bytes)
    let maxDiskSize: Int64
    
    /// Tamanho máximo do cache em memória (bytes)
    let maxMemorySize: Int
    
    /// Diretório onde o cache em disco será armazenado
    let cacheDirectory: URL
    
    /// Número máximo de downloads paralelos durante prefetch
    let prefetchConcurrency: Int
    
    /// Configuração padrão para produção
    static let `default`: ImageCacheConfiguration = {
        let cacheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("ImageCache", isDirectory: true)
        
        return ImageCacheConfiguration(
            maxDiskSize: 500 * 1024 * 1024, // 500 MB
            maxMemorySize: 50 * 1024 * 1024, // 50 MB
            cacheDirectory: cacheDirectory,
            prefetchConcurrency: 5
        )
    }()
    
    /// Configuração para testes (menor e em diretório temporário)
    static let test: ImageCacheConfiguration = {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageCacheTests-\(UUID().uuidString)", isDirectory: true)
        
        return ImageCacheConfiguration(
            maxDiskSize: 10 * 1024 * 1024, // 10 MB
            maxMemorySize: 5 * 1024 * 1024, // 5 MB
            cacheDirectory: tempDirectory,
            prefetchConcurrency: 3
        )
    }()
}

