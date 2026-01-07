//
//  KeychainBootstrap.swift
//  FitToday
//
//  Popula o Keychain com chaves de API a partir de um arquivo local (Secrets.plist).
//  Este bootstrap roda APENAS em builds DEBUG e NUNCA em Release.
//  O arquivo Secrets.plist deve estar ignorado pelo git.
//

import Foundation

/// Bootstrap de segredos para ambiente de desenvolvimento.
/// Popula o Keychain com chaves de API a partir de um arquivo Secrets.plist local.
enum KeychainBootstrap {
    
    private static let bootstrapCompletedKey = "keychain_bootstrap_completed_v1"
    
    /// Executa o bootstrap se necessário (apenas em DEBUG).
    /// Deve ser chamado uma vez no launch do app (ex: em FitTodayApp.init).
    static func runIfNeeded() {
        #if DEBUG
        // Evita rodar múltiplas vezes
        guard !UserDefaults.standard.bool(forKey: bootstrapCompletedKey) else {
            return
        }
        
        populateFromSecretsPlist()
        UserDefaults.standard.set(true, forKey: bootstrapCompletedKey)
        #endif
    }
    
    /// Força o bootstrap novamente (útil para testes ou reset).
    static func forceRun() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: bootstrapCompletedKey)
        populateFromSecretsPlist()
        UserDefaults.standard.set(true, forKey: bootstrapCompletedKey)
        #endif
    }
    
    /// Reseta o flag de bootstrap (não remove as chaves do Keychain).
    static func resetBootstrapFlag() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: bootstrapCompletedKey)
        #endif
    }
    
    // MARK: - Private
    
    private static func populateFromSecretsPlist() {
        guard let plistPath = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            print("[KeychainBootstrap] ⚠️ Secrets.plist não encontrado no bundle. Crie o arquivo para popular as chaves automaticamente.")
            return
        }
        
        guard let plistData = FileManager.default.contents(atPath: plistPath),
              let secrets = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: String] else {
            print("[KeychainBootstrap] ⚠️ Não foi possível ler Secrets.plist. Verifique o formato.")
            return
        }
        
        let manager = UserAPIKeyManager.shared
        var keysPopulated = 0
        
        // OpenAI API Key
        if let openAIKey = secrets["OPENAI_API_KEY"], !openAIKey.isEmpty, openAIKey != "YOUR_OPENAI_API_KEY_HERE" {
            if !manager.hasAPIKey(for: .openAI) {
                if manager.saveAPIKey(openAIKey, for: .openAI) {
                    keysPopulated += 1
                    print("[KeychainBootstrap] ✅ OpenAI API Key populada no Keychain")
                }
            } else {
                print("[KeychainBootstrap] ℹ️ OpenAI API Key já existe no Keychain")
            }
        }
        
        // RapidAPI Key (ExerciseDB)
        if let rapidAPIKey = secrets["RAPIDAPI_KEY"], !rapidAPIKey.isEmpty, rapidAPIKey != "YOUR_RAPIDAPI_KEY_HERE" {
            if !manager.hasAPIKey(for: .exerciseDB) {
                if manager.saveAPIKey(rapidAPIKey, for: .exerciseDB) {
                    keysPopulated += 1
                    print("[KeychainBootstrap] ✅ RapidAPI Key populada no Keychain")
                }
            } else {
                print("[KeychainBootstrap] ℹ️ RapidAPI Key já existe no Keychain")
            }
        }
        
        if keysPopulated > 0 {
            print("[KeychainBootstrap] 🎉 Bootstrap concluído: \(keysPopulated) chave(s) populada(s)")
        } else {
            print("[KeychainBootstrap] ℹ️ Nenhuma chave nova foi populada")
        }
    }
}


