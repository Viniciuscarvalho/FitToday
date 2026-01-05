//
//  ExerciseMediaImage.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

/// Componente reutilizável para exibir mídia de exercícios com placeholder e fallback.
/// Aceita URL diretamente para máxima flexibilidade.
struct ExerciseMediaImageURL: View {
  let url: URL?
  let size: CGSize
  var contentMode: ContentMode = .fill
  var cornerRadius: CGFloat = FitTodayRadius.md

  var body: some View {
    Group {
      if let url = url {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            placeholderView
              .redacted(reason: .placeholder)
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: contentMode)
          case .failure:
            placeholderView
              .onAppear {
                #if DEBUG
                // Extrai exerciseId da URL se possível, senão usa a URL completa
                let exerciseId = url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
                PerformanceLogger.logMediaLoadFailure(
                  exerciseId: exerciseId,
                  source: "AsyncImage"
                )
                #endif
              }
          @unknown default:
            placeholderView
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
}

/// Versão com tamanho fixo para thumbnails em listas.
/// Prioriza GIF sobre imagem estática.
struct ExerciseThumbnail: View {
  let media: ExerciseMedia?
  var size: CGFloat = 50

  var body: some View {
    ExerciseMediaImageURL(
      url: media?.gifURL ?? media?.imageURL,
      size: CGSize(width: size, height: size),
      cornerRadius: FitTodayRadius.sm
    )
  }
}

/// Versão grande para tela de detalhes.
/// Prioriza GIF sobre imagem estática.
struct ExerciseHeroImage: View {
  let media: ExerciseMedia?
  var height: CGFloat = 220

  var body: some View {
    GeometryReader { geometry in
      ExerciseMediaImageURL(
        url: media?.gifURL ?? media?.imageURL,
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
