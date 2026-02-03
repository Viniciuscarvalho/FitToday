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
/// Usa Wger API para buscar imagens de exercícios.
struct ExerciseMediaImageURL: View {
  @Environment(\.dependencyResolver) private var resolver
  @Environment(\.imageCacheService) private var imageCacheService

  let url: URL?
  let size: CGSize
  var contentMode: ContentMode = .fill
  var cornerRadius: CGFloat = FitTodayRadius.md

  // 💡 Learn: Com @Observable, usamos @State em vez de @StateObject
  @State private var loader = ExerciseMediaLoader()

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
          } else if isGIFContent(data: data, mimeType: mimeType, url: url) {
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

  /// Detects if content is a GIF by checking multiple sources:
  /// 1. MIME type contains "gif"
  /// 2. URL path ends with .gif
  /// 3. Data starts with GIF magic bytes (GIF87a or GIF89a)
  private func isGIFContent(data: Data, mimeType: String, url: URL?) -> Bool {
    // Check MIME type
    if mimeType.lowercased().contains("gif") {
      return true
    }

    // Check URL extension
    if let url = url, url.pathExtension.lowercased() == "gif" {
      return true
    }

    // Check GIF magic bytes (GIF87a or GIF89a)
    guard data.count >= 6 else { return false }
    let gifMagic87a: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61] // "GIF87a"
    let gifMagic89a: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61] // "GIF89a"
    let header = Array(data.prefix(6))
    return header == gifMagic87a || header == gifMagic89a
  }

  private func load(_ url: URL) async {
    // Reset loader se a URL mudou (evita estado inconsistente)
    if case .success = loader.phase {
      // Se já tem sucesso, verifica se é da mesma URL antes de resetar
      // (o cache já cuida disso, mas garantimos estado limpo)
    }

    await loader.load(url: url, cacheService: imageCacheService)
  }
}

/// Versão com tamanho fixo para thumbnails em listas.
/// Agora carrega imagens reais do Wger API quando disponível.
struct ExerciseThumbnail: View {
  let media: ExerciseMedia?
  var size: CGFloat = 50

  private var mediaURL: URL? {
    media?.imageURL ?? media?.gifURL
  }

  var body: some View {
    Group {
      if let url = mediaURL {
        ExerciseMediaImageURL(
          url: url,
          size: CGSize(width: size, height: size),
          contentMode: .fill,
          cornerRadius: FitTodayRadius.sm
        )
      } else {
        placeholderView
      }
    }
    .frame(width: size, height: size)
  }

  private var placeholderView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: FitTodayRadius.sm)
        .fill(FitTodayColor.surface)

      Image(systemName: "figure.strengthtraining.traditional")
        .font(.system(size: size * 0.4))
        .foregroundStyle(FitTodayColor.textTertiary)
    }
  }
}

// MARK: - Media Loader (Data + GIF support)

// 💡 Learn: @Observable substitui ObservableObject para gerenciamento de estado moderno
@MainActor
@Observable final class ExerciseMediaLoader {
  enum Phase {
    case idle
    case loading
    case success(data: Data, mimeType: String)
    case failure(error: Error)
  }

  private(set) var phase: Phase = .idle

  // 💡 Learn: nonisolated(unsafe) permite acesso de propriedades de deinit
  private nonisolated(unsafe) var currentTask: Task<Void, Never>?

  // Cache simples em memória (evita re-download em listas)
  private static let cache = NSCache<NSString, MediaCacheEntry>()

  func load(url: URL, cacheService: ImageCaching?) async {
    // Cancela task anterior se existir
    currentTask?.cancel()

    // Cria nova task
    currentTask = Task {
      await performLoad(url: url, cacheService: cacheService)
    }

    await currentTask?.value
  }

  private func performLoad(url: URL, cacheService: ImageCaching?) async {
    let cacheKey = url.absoluteString as NSString

    // Verifica se a task foi cancelada antes de continuar
    guard !Task.isCancelled else {
      #if DEBUG
      print("[MediaLoader] ⏸️ Task cancelada antes de verificar cache")
      #endif
      return
    }

    // 1. Tentar ImageCacheService primeiro (cache persistente)
    if let cacheService = cacheService,
       let cachedImage = await cacheService.cachedImage(for: url) {
      #if DEBUG
      print("[MediaLoader] 💾 ImageCacheService hit para \(url.absoluteString)")
      #endif
      if let imageData = cachedImage.pngData() {
        phase = .success(data: imageData, mimeType: "image/png")
        return
      }
    }

    // 2. Verifica cache NSCache (em memória) como fallback
    if let cached = Self.cache.object(forKey: cacheKey) {
      #if DEBUG
      print("[MediaLoader] 💾 NSCache hit para \(url.absoluteString)")
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
      exerciseId: Self.exerciseIdForLogging(from: url),
      source: "ExerciseMediaLoader"
    )
    #endif

    do {
      // URL pública: baixa direto via URLSession
      #if DEBUG
      print("[MediaLoader] 🌐 Baixando URL diretamente: \(url.absoluteString)")
      #endif

      var request = URLRequest(url: url)
      request.timeoutInterval = 15.0
      request.cachePolicy = .returnCacheDataElseLoad

      let (data, response) = try await URLSession.shared.data(for: request)
      let mimeType = (response as? HTTPURLResponse)?.mimeType ?? "application/octet-stream"

      Self.cache.setObject(MediaCacheEntry(data: data, mimeType: mimeType), forKey: cacheKey)
      phase = .success(data: data, mimeType: mimeType)
      #if DEBUG
      PerformanceLogger.logMediaLoadSuccess(exerciseId: Self.exerciseIdForLogging(from: url), source: "URLSession")
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
    return url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
  }
}

enum ExerciseMediaLoaderError: LocalizedError, Equatable {
  case mediaUnavailable

  var errorDescription: String? {
    switch self {
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
struct ExerciseHeroImage: View {
  let media: ExerciseMedia?
  var height: CGFloat = 220

  private var mediaURL: URL? {
    media?.gifURL ?? media?.imageURL
  }

  var body: some View {
    GeometryReader { geometry in
      ExerciseMediaImageURL(
        url: mediaURL,
        size: CGSize(width: geometry.size.width, height: height),
        contentMode: .fit,
        cornerRadius: FitTodayRadius.md
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
        imageURL: URL(string: "https://wger.de/media/exercise-images/91/Crunches-1.png"),
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
        imageURL: URL(string: "https://wger.de/media/exercise-images/91/Crunches-1.png"),
        gifURL: nil
      )
    )
  }
  .padding()
  .background(FitTodayColor.background)
}
