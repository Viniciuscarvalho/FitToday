//
//  ExerciseMediaImage.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import UIKit
import WebKit
import Combine
import Swinject

/// Componente reutilizável para exibir mídia de exercícios com placeholder e fallback.
/// Aceita URL diretamente para máxima flexibilidade.
/// Converte automaticamente URLs antigas (v2.exercisedb.io) para RapidAPI com resolution.
struct ExerciseMediaImageURL: View {
  @Environment(\.dependencyResolver) private var resolver
  @Environment(\.imageCacheService) private var imageCacheService

  let url: URL?
  let size: CGSize
  var contentMode: ContentMode = .fill
  var cornerRadius: CGFloat = FitTodayRadius.md
  var context: MediaDisplayContext = .thumbnail  // Contexto para determinar resolution

  @StateObject private var loader = ExerciseMediaLoader()

  var body: some View {
    Group {
      if let url = url {
        switch loader.phase {
        case .idle:
          placeholderView
            .redacted(reason: .placeholder)
            .task(id: url.absoluteString) { await load(url) }
        case .loading:
          placeholderView
            .redacted(reason: .placeholder)
        case .success(let data, let mimeType):
          if data.isEmpty {
            placeholderView
          } else if mimeType.lowercased().contains("gif") {
            ExerciseGIFWebView(
              data: data,
              contentMode: contentMode
            )
          } else if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: contentMode)
          } else {
            placeholderView
          }
        case .failure(let error):
          placeholderView
            .onAppear {
              // Ignora erros de cancelamento (esperados quando a view sai da tela)
              if error is CancellationError { return }
              if let urlError = error as? URLError, urlError.code == .cancelled { return }
              #if DEBUG
              PerformanceLogger.logMediaLoadFailure(
                exerciseId: ExerciseMediaLoader.exerciseIdForLogging(from: url),
                source: "ExerciseMediaLoader",
                error: error
              )
              #endif
            }
        }
      } else {
        placeholderView
      }
    }
    .frame(width: size.width, height: size.height)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .accessibilityLabel("Imagem do exercício")
  }

  private var placeholderView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(FitTodayColor.surface)
      Image(systemName: "figure.strengthtraining.traditional")
        .font(.system(size: min(size.width, size.height) * 0.4))
        .foregroundStyle(FitTodayColor.textTertiary)
    }
  }

  private func load(_ url: URL) async {
    // Reset loader se a URL mudou (evita estado inconsistente)
    if case .success = loader.phase {
      // Se já tem sucesso, verifica se é da mesma URL antes de resetar
      // (o cache já cuida disso, mas garantimos estado limpo)
    }
    
    let service = resolver.resolve(ExerciseDBServicing.self)
    await loader.load(url: url, service: service, context: context, cacheService: imageCacheService)
  }
}

/// Versão com tamanho fixo para thumbnails em listas.
/// NÃO carrega mídia (apenas placeholder) para melhor performance em listas.
/// A mídia será carregada apenas na tela de detalhe.
struct ExerciseThumbnail: View {
  let media: ExerciseMedia?
  var size: CGFloat = 50

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: FitTodayRadius.sm)
        .fill(FitTodayColor.surface)
        .frame(width: size, height: size)
      
      Image(systemName: "figure.strengthtraining.traditional")
        .font(.system(size: size * 0.4))
        .foregroundStyle(FitTodayColor.textTertiary)
    }
  }
}

// MARK: - Media Loader (Data + GIF support)

@MainActor
final class ExerciseMediaLoader: ObservableObject {
  enum Phase {
    case idle
    case loading
    case success(data: Data, mimeType: String)
    case failure(error: Error)
  }

  @Published private(set) var phase: Phase = .idle
  
  // Rastreia tasks em andamento para evitar requisições duplicadas
  private var currentTask: Task<Void, Never>?

  // Cache simples em memória (evita re-download em listas)
  private static let cache = NSCache<NSString, MediaCacheEntry>()

  func load(url: URL, service: ExerciseDBServicing?, context: MediaDisplayContext = .thumbnail, cacheService: ImageCaching?) async {
    // Cancela task anterior se existir
    currentTask?.cancel()
    
    // Cria nova task
    currentTask = Task {
      await performLoad(url: url, service: service, context: context, cacheService: cacheService)
    }
    
    await currentTask?.value
  }
  
  private func performLoad(url: URL, service: ExerciseDBServicing?, context: MediaDisplayContext, cacheService: ImageCaching?) async {
    // 1. PRIMEIRO: Detecta e converte URLs antigas (v2.exercisedb.io) para RapidAPI
    // Isso deve acontecer ANTES de qualquer verificação ou log
    let finalURL: URL
    let isLegacyURL = url.host?.contains("exercisedb.io") == true && 
                      url.pathComponents.count >= 2 && 
                      url.pathComponents[1] == "image"
    
    if isLegacyURL {
      #if DEBUG
      print("[MediaLoader] 🔍 Detectada URL antiga: \(url.absoluteString)")
      print("[MediaLoader]   host=\(url.host ?? "nil"), path=\(url.path)")
      #endif
      
      if let convertedURL = await convertLegacyURLIfNeeded(url: url, service: service, context: context) {
        finalURL = convertedURL
        #if DEBUG
        print("[MediaLoader] ✅ URL convertida para RapidAPI: \(finalURL.absoluteString)")
        print("[MediaLoader]   host=\(finalURL.host ?? "nil"), path=\(finalURL.path), query=\(finalURL.query ?? "nil")")
        #endif
      } else {
        #if DEBUG
        print("[MediaLoader] ⚠️ Falha ao converter URL antiga, usando original (pode falhar)")
        #endif
        finalURL = url
      }
    } else {
      finalURL = url
      #if DEBUG
      print("[MediaLoader] 📥 Recebendo URL para carregar: \(url.absoluteString)")
      print("[MediaLoader]   host=\(url.host ?? "nil"), path=\(url.path), query=\(url.query ?? "nil")")
      #endif
    }
    
    let cacheKey = finalURL.absoluteString as NSString
    
    // Verifica se a task foi cancelada antes de continuar
    guard !Task.isCancelled else {
      #if DEBUG
      print("[MediaLoader] ⏸️ Task cancelada antes de verificar cache")
      #endif
      return
    }
    
    // 1. Tentar ImageCacheService primeiro (cache persistente)
    if let cacheService = cacheService,
       let cachedImage = await cacheService.cachedImage(for: finalURL) {
      #if DEBUG
      print("[MediaLoader] 💾 ImageCacheService hit para \(finalURL.absoluteString)")
      #endif
      if let imageData = cachedImage.pngData() {
        phase = .success(data: imageData, mimeType: "image/png")
        return
      }
    }
    
    // 2. Verifica cache NSCache (em memória) como fallback
    if let cached = Self.cache.object(forKey: cacheKey) {
      #if DEBUG
      print("[MediaLoader] 💾 NSCache hit para \(finalURL.absoluteString)")
      #endif
      phase = .success(data: cached.data, mimeType: cached.mimeType)
      return
    }

    // Verifica se a task foi cancelada antes de iniciar requisição
    guard !Task.isCancelled else {
      #if DEBUG
      print("[MediaLoader] ⏸️ Task cancelada antes de iniciar requisição")
      #endif
      return
    }
    
    // Reset para loading antes de iniciar nova requisição
    phase = .loading
    #if DEBUG
    PerformanceLogger.logMediaLoadStart(
      exerciseId: Self.exerciseIdForLogging(from: finalURL),
      source: "ExerciseMediaLoader"
    )
    #endif

    do {
      // 1) Se for RapidAPI (/image), precisamos de headers -> usa ExerciseDBServicing
      if let payload = Self.parseRapidAPIImageURL(finalURL) {
        #if DEBUG
        print("[MediaLoader] ✅ Parse RapidAPI bem-sucedido: exerciseId=\(payload.exerciseId), resolution=\(payload.resolution.rawValue)")
        #endif
        guard let service else {
          #if DEBUG
          print("[MediaLoader] ❌ ExerciseDBServicing não configurado para exercício \(payload.exerciseId)")
          #endif
          phase = .failure(error: ExerciseMediaLoaderError.serviceNotConfigured)
          return
        }

        do {
          #if DEBUG
          print("[MediaLoader] 📡 Chamando fetchImageData para exercício \(payload.exerciseId) com resolution \(payload.resolution.rawValue)")
          #endif
          
          if let result = try await service.fetchImageData(
            exerciseId: payload.exerciseId,
            resolution: payload.resolution
          ) {
            #if DEBUG
            print("[MediaLoader] ✅ Mídia carregada: \(result.mimeType) (\(result.data.count) bytes) para exercício \(payload.exerciseId)")
            print("[MediaLoader] 📊 Primeiros bytes: \(result.data.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " "))")
            #endif
            
            // Validação: data não pode estar vazio
            guard !result.data.isEmpty else {
              #if DEBUG
              print("[MediaLoader] ❌ Data vazio recebido do serviço para exercício \(payload.exerciseId)")
              #endif
              phase = .failure(error: ExerciseMediaLoaderError.mediaUnavailable)
              return
            }
            
            Self.cache.setObject(MediaCacheEntry(data: result.data, mimeType: result.mimeType), forKey: cacheKey)
            phase = .success(data: result.data, mimeType: result.mimeType)
            #if DEBUG
            PerformanceLogger.logMediaLoadSuccess(exerciseId: payload.exerciseId, source: "ExerciseDBServicing")
            #endif
            return
          } else {
            #if DEBUG
            print("[MediaLoader] ⚠️ fetchImageData retornou nil para exercício \(payload.exerciseId)")
            #endif
            phase = .failure(error: ExerciseMediaLoaderError.mediaUnavailable)
            return
          }
        } catch let error as URLError where error.code == .cancelled {
          // Cancelamentos são esperados (ex: view saiu da tela)
          #if DEBUG
          print("[MediaLoader] ⏸️ Requisição cancelada para exercício \(payload.exerciseId) (esperado - view pode ter saído da tela)")
          print("[MediaLoader]   URLError code: \(error.code.rawValue), description: \(error.localizedDescription)")
          #endif
          return // Não trata como erro
        } catch let error as ExerciseDBError {
          // Erros específicos do ExerciseDB
          #if DEBUG
          print("[MediaLoader] ❌ ExerciseDBError ao buscar mídia para exercício \(payload.exerciseId): \(error.localizedDescription)")
          #endif
          throw error // Re-lança para ser capturado pelo catch externo
        } catch {
          #if DEBUG
          print("[MediaLoader] ❌ Erro ao chamar fetchImageData para exercício \(payload.exerciseId)")
          print("[MediaLoader]   Tipo: \(type(of: error))")
          print("[MediaLoader]   Descrição: \(error.localizedDescription)")
          if let urlError = error as? URLError {
            print("[MediaLoader]   URLError code: \(urlError.code.rawValue)")
          }
          #endif
          throw error // Re-lança para ser capturado pelo catch externo
        }
      }

      // 2) URL pública ou não-RapidAPI: baixa direto (sem headers)
      // Nota: Se chegou aqui, a URL não é RapidAPI /image (pode ser URL pública ou outro formato)
      #if DEBUG
      if finalURL.host?.contains("exercisedb.io") == true {
        print("[MediaLoader] ⚠️ URL ainda é antiga após conversão, tentando baixar diretamente (pode falhar): \(finalURL.absoluteString)")
      } else {
        print("[MediaLoader] 🌐 URL pública, baixando diretamente: \(finalURL.absoluteString)")
      }
      #endif
      
      var request = URLRequest(url: finalURL)
      request.timeoutInterval = 15.0
      request.cachePolicy = .returnCacheDataElseLoad

      let (data, response) = try await URLSession.shared.data(for: request)
      let mimeType = (response as? HTTPURLResponse)?.mimeType ?? "application/octet-stream"

      Self.cache.setObject(MediaCacheEntry(data: data, mimeType: mimeType), forKey: cacheKey)
      phase = .success(data: data, mimeType: mimeType)
      #if DEBUG
      PerformanceLogger.logMediaLoadSuccess(exerciseId: Self.exerciseIdForLogging(from: finalURL), source: "URLSession")
      #endif
    } catch is CancellationError {
      // Cancelamentos são esperados quando a view sai da tela; não tratar como erro.
      return
    } catch let urlError as URLError where urlError.code == .cancelled {
      // URLSession.cancelled também é esperado quando a view sai da tela.
      return
    } catch {
      phase = .failure(error: error)
    }
  }

  static func exerciseIdForLogging(from url: URL) -> String {
    if let payload = parseRapidAPIImageURL(url) {
      return payload.exerciseId
    }
    // Tenta extrair exerciseId de URLs antigas (v2.exercisedb.io/image/{id})
    if url.host?.contains("exercisedb.io") == true, url.pathComponents.count >= 2, url.pathComponents[1] == "image" {
      return url.lastPathComponent
    }
    return url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
  }
  
  /// Converte URLs antigas (v2.exercisedb.io) para RapidAPI com resolution e exerciseId.
  private func convertLegacyURLIfNeeded(url: URL, service: ExerciseDBServicing?, context: MediaDisplayContext) async -> URL? {
    // Detecta URLs do formato antigo: v2.exercisedb.io/image/{exerciseId}
    guard url.host?.contains("exercisedb.io") == true,
          url.pathComponents.count >= 2,
          url.pathComponents[1] == "image" else {
      // Não é URL antiga
      return nil
    }
    
    // Extrai exerciseId da URL antiga (último componente do path)
    let exerciseId = url.lastPathComponent
    guard !exerciseId.isEmpty else {
      #if DEBUG
      print("[MediaLoader] ⚠️ Não foi possível extrair exerciseId da URL antiga: \(url.absoluteString)")
      #endif
      return nil
    }
    
    #if DEBUG
    print("[MediaLoader] 🔄 Detectada URL antiga, convertendo para RapidAPI: exerciseId=\(exerciseId), resolution=\(context.resolution.rawValue)")
    #endif
    
    // Se temos service, usa fetchImageURL para construir a URL correta
    guard let service = service else {
      #if DEBUG
      print("[MediaLoader] ⚠️ Service não disponível para converter URL antiga")
      #endif
      // Fallback: constrói URL RapidAPI manualmente
      return buildRapidAPIURL(exerciseId: exerciseId, resolution: context.resolution)
    }
    
    do {
      if let rapidAPIURL = try await service.fetchImageURL(
        exerciseId: exerciseId,
        resolution: context.resolution
      ) {
        #if DEBUG
        print("[MediaLoader] ✅ URL convertida via service: \(rapidAPIURL.absoluteString)")
        #endif
        return rapidAPIURL
      } else {
        #if DEBUG
        print("[MediaLoader] ⚠️ fetchImageURL retornou nil, usando fallback manual")
        #endif
        // Fallback: constrói URL RapidAPI manualmente
        return buildRapidAPIURL(exerciseId: exerciseId, resolution: context.resolution)
      }
    } catch let error as URLError where error.code == .cancelled {
      #if DEBUG
      print("[MediaLoader] ⏸️ Conversão cancelada (esperado), usando fallback manual")
      #endif
      // Fallback: constrói URL RapidAPI manualmente mesmo se cancelado
      return buildRapidAPIURL(exerciseId: exerciseId, resolution: context.resolution)
    } catch {
      #if DEBUG
      print("[MediaLoader] ❌ Erro ao converter URL antiga via service: \(error.localizedDescription), usando fallback manual")
      #endif
      // Fallback: constrói URL RapidAPI manualmente
      return buildRapidAPIURL(exerciseId: exerciseId, resolution: context.resolution)
    }
    
    return nil
  }
  
  /// Constrói URL RapidAPI manualmente (fallback quando service não está disponível).
  private func buildRapidAPIURL(exerciseId: String, resolution: ExerciseImageResolution) -> URL? {
    var components = URLComponents(string: "https://exercisedb.p.rapidapi.com/image")
    components?.queryItems = [
      URLQueryItem(name: "resolution", value: resolution.rawValue),
      URLQueryItem(name: "exerciseId", value: exerciseId)
    ]
    return components?.url
  }

  private static func parseRapidAPIImageURL(_ url: URL) -> (exerciseId: String, resolution: ExerciseImageResolution)? {
    guard url.host == "exercisedb.p.rapidapi.com", url.path == "/image" else {
      // Não loga aqui para evitar logs confusos - a URL pode não ser RapidAPI por design
      // (ex: URLs públicas que devem ser baixadas diretamente)
      return nil
    }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems else {
      #if DEBUG
      print("[MediaLoader] Não foi possível parsear queryItems da URL: \(url.absoluteString)")
      #endif
      return nil
    }

    guard let exerciseId = queryItems.first(where: { $0.name == "exerciseId" })?.value,
          let resolutionRaw = queryItems.first(where: { $0.name == "resolution" })?.value,
          let resolution = ExerciseImageResolution(rawValue: resolutionRaw) else {
      #if DEBUG
      let exerciseIdFound = queryItems.first(where: { $0.name == "exerciseId" })?.value ?? "nil"
      let resolutionFound = queryItems.first(where: { $0.name == "resolution" })?.value ?? "nil"
      print("[MediaLoader] QueryItems incompletos: exerciseId=\(exerciseIdFound), resolution=\(resolutionFound)")
      #endif
      return nil
    }

    #if DEBUG
    print("[MediaLoader] ✅ Parse da URL RapidAPI bem-sucedido: exerciseId=\(exerciseId), resolution=\(resolutionRaw)")
    #endif
    
    return (exerciseId: exerciseId, resolution: resolution)
  }
}

enum ExerciseMediaLoaderError: LocalizedError, Equatable {
  case serviceNotConfigured
  case mediaUnavailable

  var errorDescription: String? {
    switch self {
    case .serviceNotConfigured:
      return "ExerciseDBServicing não configurado"
    case .mediaUnavailable:
      return "Mídia indisponível"
    }
  }
}

final class MediaCacheEntry: NSObject {
  let data: Data
  let mimeType: String

  init(data: Data, mimeType: String) {
    self.data = data
    self.mimeType = mimeType
  }
}

// MARK: - GIF rendering via WKWebView (supports animation)

struct ExerciseGIFWebView: UIViewRepresentable {
  let data: Data
  let contentMode: ContentMode
  
  // Cache do HTML para evitar re-renderizações desnecessárias
  private var cachedHTML: String {
    let base64 = data.base64EncodedString()
    let objectFit = (contentMode == .fill) ? "cover" : "contain"
    
    return """
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          html, body { width: 100%; height: 100%; background: transparent; overflow: hidden; }
          img { 
            width: 100%; 
            height: 100%; 
            object-fit: \(objectFit); 
            display: block;
            image-rendering: -webkit-optimize-contrast;
            image-rendering: crisp-edges;
          }
        </style>
      </head>
      <body>
        <img src="data:image/gif;base64,\(base64)" alt="Exercise GIF" />
      </body>
    </html>
    """
  }

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.scrollView.isScrollEnabled = false
    webView.scrollView.bounces = false
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    
    // Configurações para melhor performance
    webView.configuration.allowsInlineMediaPlayback = true
    webView.configuration.mediaTypesRequiringUserActionForPlayback = []
    
    #if DEBUG
    print("[GIFWebView] Criando WKWebView para GIF (\(data.count) bytes)")
    #endif
    
    // Carrega o HTML imediatamente
    webView.loadHTMLString(cachedHTML, baseURL: nil)
    
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    // Só re-carrega se os dados mudaram (evita re-renderizações desnecessárias)
    // Como o data é um valor, o SwiftUI já cuida disso, mas garantimos que não há re-load desnecessário
    #if DEBUG
    print("[GIFWebView] updateUIView chamado (\(data.count) bytes)")
    #endif
    
    // Verifica se já tem conteúdo carregado para evitar re-load
    if webView.url == nil || webView.isLoading {
      webView.loadHTMLString(cachedHTML, baseURL: nil)
    }
  }
}

/// Versão grande para tela de detalhes.
/// Prioriza GIF sobre imagem estática.
/// Reconstroi a URL com resolução alta (.detail) se for RapidAPI.
struct ExerciseHeroImage: View {
  let media: ExerciseMedia?
  var height: CGFloat = 220
  
  // Reconstrói URL com resolução alta se for RapidAPI
  private var highResURL: URL? {
    guard let originalURL = media?.gifURL ?? media?.imageURL else { return nil }
    
    // Se não for RapidAPI, retorna a URL original
    guard originalURL.host == "exercisedb.p.rapidapi.com", originalURL.path == "/image" else {
      return originalURL
    }
    
    // Extrai exerciseId da URL original
    guard let components = URLComponents(url: originalURL, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems,
          let exerciseId = queryItems.first(where: { $0.name == "exerciseId" })?.value else {
      return originalURL
    }
    
    // Reconstrói URL com resolução alta (.detail = 720)
    var newComponents = URLComponents()
    newComponents.scheme = originalURL.scheme
    newComponents.host = originalURL.host
    newComponents.path = originalURL.path
    newComponents.queryItems = [
      URLQueryItem(name: "resolution", value: ExerciseImageResolution.r720.rawValue),
      URLQueryItem(name: "exerciseId", value: exerciseId)
    ]
    
    #if DEBUG
    if let newURL = newComponents.url {
      print("[HeroImage] 🔄 Reconstruindo URL: \(originalURL.absoluteString) -> \(newURL.absoluteString)")
    }
    #endif
    
    return newComponents.url ?? originalURL
  }

  var body: some View {
    GeometryReader { geometry in
      ExerciseMediaImageURL(
        url: highResURL,
        size: CGSize(width: geometry.size.width, height: height),
        contentMode: .fit,
        cornerRadius: FitTodayRadius.md,
        context: .detail  // Hero image sempre usa resolução alta
      )
    }
    .frame(height: height)
  }
}

// MARK: - Previews

#Preview("Thumbnail") {
  HStack(spacing: 16) {
    ExerciseThumbnail(media: nil)
    ExerciseThumbnail(
      media: ExerciseMedia(
        imageURL: URL(string: "https://v2.exercisedb.io/image/0001"),
        gifURL: nil
      )
    )
  }
  .padding()
  .background(FitTodayColor.background)
}

#Preview("Hero Image") {
  VStack {
    ExerciseHeroImage(media: nil)
    ExerciseHeroImage(
      media: ExerciseMedia(
        imageURL: URL(string: "https://v2.exercisedb.io/image/0001"),
        gifURL: URL(string: "https://v2.exercisedb.io/image/0001")
      )
    )
  }
  .padding()
  .background(FitTodayColor.background)
}
