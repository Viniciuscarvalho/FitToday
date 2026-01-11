//
//  PrintExerciseDBTargets.swift
//  Script para buscar e exibir os targets oficiais do ExerciseDB
//
//  Usage: swift PrintExerciseDBTargets.swift
//

import Foundation

// Estrutura para configuração da API
struct Config {
    let apiKey: String
    let host: String
    let baseURL: String
}

// Função para carregar configuração
func loadConfig() -> Config? {
    // Tenta ler do ambiente
    if let apiKey = ProcessInfo.processInfo.environment["EXERCISEDB_API_KEY"], !apiKey.isEmpty {
        return Config(
            apiKey: apiKey,
            host: "exercisedb.p.rapidapi.com",
            baseURL: "https://exercisedb.p.rapidapi.com"
        )
    }

    // Fallback: tenta ler de arquivo ExerciseDBConfig.plist
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let plistPath = "\(currentPath)/FitToday/FitToday/Data/Resources/ExerciseDBConfig.plist"

    if fileManager.fileExists(atPath: plistPath),
       let plistData = fileManager.contents(atPath: plistPath),
       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
       let apiKey = plist["EXERCISEDB_API_KEY"] as? String,
       !apiKey.isEmpty {
        print("📋 Usando configuração do plist")
        return Config(
            apiKey: apiKey,
            host: "exercisedb.p.rapidapi.com",
            baseURL: "https://exercisedb.p.rapidapi.com"
        )
    }

    return nil
}

// Função para buscar targets
func fetchTargetList(config: Config) async throws -> [String] {
    let urlString = "\(config.baseURL)/exercises/targetList"

    guard let url = URL(string: urlString) else {
        throw NSError(domain: "Invalid URL", code: 1, userInfo: nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 12.0
    request.addValue(config.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    request.addValue(config.host, forHTTPHeaderField: "x-rapidapi-host")

    print("📡 Fazendo requisição para: \(urlString)\n")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "Invalid response", code: 2, userInfo: nil)
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        let responseBody = String(data: data, encoding: .utf8) ?? "sem corpo"
        throw NSError(
            domain: "HTTP Error \(httpResponse.statusCode)",
            code: httpResponse.statusCode,
            userInfo: ["response": responseBody]
        )
    }

    let decoder = JSONDecoder()
    let targets = try decoder.decode([String].self, from: data)

    return targets.sorted()  // Ordenar alfabeticamente
}

// Main execution
Task {
    print("🔍 Buscando targets oficiais do ExerciseDB")
    print("==========================================\n")

    guard let config = loadConfig() else {
        print("❌ Erro: Chave da API não encontrada")
        print("\nConfigurações possíveis:")
        print("1. Exportar variável de ambiente:")
        print("   export EXERCISEDB_API_KEY='sua_chave_aqui'")
        print("\n2. Ou criar ExerciseDBConfig.plist no projeto")
        exit(1)
    }

    do {
        let targets = try await fetchTargetList(config: config)

        print("✅ \(targets.count) targets oficiais encontrados:\n")
        print("─────────────────────────────────────────")
        for (index, target) in targets.enumerated() {
            print("\(String(format: "%2d", index + 1)). \(target)")
        }
        print("─────────────────────────────────────────\n")

        // Exportar para usar no código
        print("📝 Para usar no código Swift:")
        print("let validTargets = [")
        for target in targets {
            print("    \"\(target)\",")
        }
        print("]\n")

        exit(0)
    } catch {
        print("❌ Erro ao buscar targets: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("Detalhes: \(nsError.userInfo)")
        }
        exit(1)
    }
}

// Manter script rodando até Task completar
RunLoop.main.run()
