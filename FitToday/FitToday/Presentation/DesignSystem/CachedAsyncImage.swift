//
//  CachedAsyncImage.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import SwiftUI

/// SwiftUI component que carrega imagens via ImageCacheService com suporte offline
struct CachedAsyncImage: View {
  let url: URL?
  let placeholder: Image
  let size: CGSize?
  
  @Environment(\.imageCacheService) private var cacheService
  @State private var image: UIImage?
  @State private var isLoading = true
  
  init(
    url: URL?,
    placeholder: Image = Image(systemName: "photo"),
    size: CGSize? = nil
  ) {
    self.url = url
    self.placeholder = placeholder
    self.size = size
  }
  
  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(FitTodayColor.surface)
      } else {
        // Fallback placeholder
        placeholder
          .resizable()
          .scaledToFit()
          .foregroundStyle(FitTodayColor.textTertiary)
          .padding()
          .background(FitTodayColor.surface)
      }
    }
    .task(id: url) {
      await loadImage()
    }
  }
  
  private func loadImage() async {
    guard let url = url else {
      isLoading = false
      return
    }
    
    // Tentar carregar do cache primeiro
    if let cachedImage = await cacheService?.cachedImage(for: url) {
      self.image = cachedImage
      self.isLoading = false
      return
    }
    
    // Se não está em cache, tentar fazer download
    do {
      try await cacheService?.cacheImage(from: url)
      
      // Após download, recuperar do cache
      if let downloadedImage = await cacheService?.cachedImage(for: url) {
        self.image = downloadedImage
      }
    } catch {
      #if DEBUG
      print("[CachedAsyncImage] Failed to load image: \(error)")
      #endif
    }
    
    isLoading = false
  }
}

// MARK: - Environment Key

private struct ImageCacheServiceKey: EnvironmentKey {
  static let defaultValue: ImageCaching? = nil
}

extension EnvironmentValues {
  var imageCacheService: ImageCaching? {
    get { self[ImageCacheServiceKey.self] }
    set { self[ImageCacheServiceKey.self] = newValue }
  }
}

// MARK: - View Extension

extension View {
  /// Injeta ImageCacheService no environment
  func imageCacheService(_ service: ImageCaching) -> some View {
    environment(\.imageCacheService, service)
  }
}

// MARK: - Previews

#Preview("CachedAsyncImage - Loading") {
  CachedAsyncImage(
    url: URL(string: "https://example.com/image.jpg"),
    placeholder: Image(systemName: "figure.run")
  )
  .frame(width: 200, height: 200)
  .background(FitTodayColor.background)
}

#Preview("CachedAsyncImage - Placeholder") {
  CachedAsyncImage(
    url: nil,
    placeholder: Image(systemName: "figure.strengthtraining.traditional")
  )
  .frame(width: 200, height: 200)
  .background(FitTodayColor.background)
}

