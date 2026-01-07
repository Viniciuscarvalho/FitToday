//
//  DiskImageCache.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation

/// Actor thread-safe para gerenciar cache de imagens em disco com política LRU
actor DiskImageCache {
    private let config: ImageCacheConfiguration
    private let fileManager: FileManager
    private let cacheDirectory: URL
    
    /// Inicializa o cache em disco
    /// - Parameter configuration: Configuração do cache
    init(configuration: ImageCacheConfiguration) {
        self.config = configuration
        self.fileManager = FileManager.default
        self.cacheDirectory = configuration.cacheDirectory
        
        // Criar diretório de cache se não existir
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    /// Retorna dados da imagem cacheada se disponível
    /// - Parameter url: URL da imagem
    /// - Returns: Dados da imagem ou nil se não encontrado
    func data(for url: URL) -> Data? {
        let fileURL = cacheFileURL(for: url)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Atualizar timestamp de último acesso
        updateAccessTime(for: fileURL)
        
        return try? Data(contentsOf: fileURL)
    }
    
    /// Salva dados da imagem no cache
    /// - Parameters:
    ///   - data: Dados da imagem
    ///   - url: URL da imagem
    func save(_ data: Data, for url: URL) throws {
        let fileURL = cacheFileURL(for: url)
        
        // Verificar se precisa fazer eviction antes de salvar
        let dataSize = Int64(data.count)
        try evictLRUIfNeeded(toFit: dataSize)
        
        // Salvar arquivo
        do {
            try data.write(to: fileURL, options: .atomic)
            updateAccessTime(for: fileURL)
        } catch {
            throw ImageCacheError.diskWriteFailed(underlying: error)
        }
    }
    
    /// Remove todos os arquivos do cache
    func clearAll() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
    
    /// Calcula o tamanho total do cache em bytes
    /// - Returns: Tamanho total em bytes
    func totalSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }
        
        return files.reduce(0) { total, fileURL in
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
    
    // MARK: - Private Methods
    
    /// Gera URL do arquivo de cache para uma URL de imagem
    /// - Parameter url: URL da imagem original
    /// - Returns: URL do arquivo no cache
    private func cacheFileURL(for url: URL) -> URL {
        let filename = Hashing.sha256(url.absoluteString)
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    /// Atualiza o timestamp de último acesso de um arquivo
    /// - Parameter fileURL: URL do arquivo
    private func updateAccessTime(for fileURL: URL) {
        // Usar setResourceValues para atualizar contentAccessDate
        var resourceValues = URLResourceValues()
        resourceValues.contentAccessDate = Date()
        var mutableURL = fileURL
        try? mutableURL.setResourceValues(resourceValues)
    }
    
    /// Remove arquivos mais antigos (LRU) se necessário para liberar espaço
    /// - Parameter requiredSize: Tamanho necessário em bytes
    private func evictLRUIfNeeded(toFit requiredSize: Int64) throws {
        let currentSize = totalSize()
        
        // Se há espaço suficiente, não precisa fazer nada
        guard currentSize + requiredSize > config.maxDiskSize else {
            return
        }
        
        // Obter todos os arquivos com suas datas de acesso
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey]
        ) else {
            return
        }
        
        // Ordenar por data de acesso (mais antigos primeiro)
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? .distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? .distantPast
            return date1 < date2
        }
        
        // Remover arquivos mais antigos até liberar espaço suficiente
        var freedSpace: Int64 = 0
        let spaceNeeded = (currentSize + requiredSize) - config.maxDiskSize
        
        for file in sortedFiles {
            guard freedSpace < spaceNeeded else {
                break
            }
            
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            try? fileManager.removeItem(at: file)
            freedSpace += Int64(size)
        }
        
        // Verificar se conseguimos liberar espaço suficiente
        let newSize = totalSize()
        if newSize + requiredSize > config.maxDiskSize {
            throw ImageCacheError.cacheSizeExceeded
        }
    }
}

/// Erros relacionados ao cache de imagens
enum ImageCacheError: Error, LocalizedError {
    case invalidResponse(statusCode: Int)
    case diskWriteFailed(underlying: Error)
    case cacheSizeExceeded
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let code):
            return "Resposta inválida: HTTP \(code)"
        case .diskWriteFailed(let error):
            return "Falha ao escrever no disco: \(error.localizedDescription)"
        case .cacheSizeExceeded:
            return "Limite de tamanho do cache excedido"
        case .invalidImageData:
            return "Os dados baixados não são uma imagem válida"
        }
    }
}

