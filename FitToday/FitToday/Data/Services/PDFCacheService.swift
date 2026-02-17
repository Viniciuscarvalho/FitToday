//
//  PDFCacheService.swift
//  FitToday
//
//  Serviço de cache para PDFs de treinos do Personal.
//

import Foundation

/// Protocolo para cache de PDFs de treinos do Personal.
public protocol PDFCaching: Sendable {
    func getPDF(for workout: PersonalWorkout) async throws -> URL
    func isCached(workoutId: String, fileType: PersonalWorkout.FileType) async -> Bool
}

/// Serviço de cache para PDFs de treinos do Personal.
/// Baixa arquivos do Firebase Storage e mantém cache local.
actor PDFCacheService: PDFCaching {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 dias

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("PersonalWorkoutPDFs", isDirectory: true)

        // Criar diretório se não existir
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    // MARK: - Public Methods

    /// Retorna o PDF do cache ou baixa do Firebase Storage.
    /// - Parameter workout: O treino do personal
    /// - Returns: URL local do arquivo PDF
    func getPDF(for workout: PersonalWorkout) async throws -> URL {
        let localURL = localFileURL(for: workout.id, fileType: workout.fileType)

        // Verificar cache local
        if fileManager.fileExists(atPath: localURL.path) {
            #if DEBUG
            print("[PDFCache] Cache hit para \(workout.id)")
            #endif
            return localURL
        }

        // Baixar do Firebase Storage
        guard let remoteURL = workout.fileURLValue else {
            throw PDFCacheError.invalidURL
        }

        #if DEBUG
        print("[PDFCache] Baixando \(workout.id) de \(remoteURL)")
        #endif

        let (data, response) = try await URLSession.shared.data(from: remoteURL)

        // Verificar resposta HTTP
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw PDFCacheError.downloadFailed(statusCode: httpResponse.statusCode)
        }

        // Salvar no cache
        try data.write(to: localURL)

        #if DEBUG
        print("[PDFCache] Salvo em \(localURL.path)")
        #endif

        return localURL
    }

    /// Verifica se um PDF está em cache.
    /// - Parameter workoutId: ID do treino
    /// - Returns: true se o arquivo existe no cache
    func isCached(workoutId: String, fileType: PersonalWorkout.FileType) -> Bool {
        let localURL = localFileURL(for: workoutId, fileType: fileType)
        return fileManager.fileExists(atPath: localURL.path)
    }

    /// Limpa o cache de PDFs antigos.
    func clearOldCache() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)

        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoffDate {
                try fileManager.removeItem(at: fileURL)
                #if DEBUG
                print("[PDFCache] Removido cache antigo: \(fileURL.lastPathComponent)")
                #endif
            }
        }
    }

    /// Limpa todo o cache.
    func clearAllCache() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }

        #if DEBUG
        print("[PDFCache] Cache limpo completamente")
        #endif
    }

    /// Retorna o tamanho total do cache em bytes.
    func cacheSize() throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )

        return try contents.reduce(0) { total, fileURL in
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            return total + size
        }
    }

    // MARK: - Private Helpers

    private func localFileURL(for workoutId: String, fileType: PersonalWorkout.FileType) -> URL {
        let fileExtension = fileType == .pdf ? "pdf" : "jpg"
        return cacheDirectory.appendingPathComponent("\(workoutId).\(fileExtension)")
    }
}

// MARK: - Errors

enum PDFCacheError: LocalizedError {
    case invalidURL
    case downloadFailed(statusCode: Int)
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("pdf.error.invalid_url", comment: "")
        case .downloadFailed(let code):
            return String(format: NSLocalizedString("pdf.error.download_failed", comment: ""), code)
        case .fileNotFound:
            return NSLocalizedString("pdf.error.not_found", comment: "")
        }
    }
}
