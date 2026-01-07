//
//  ErrorToastView.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import SwiftUI

/// Toast para apresentação de erros ao usuário com animações suaves
struct ErrorToastView: View {
  let errorMessage: ErrorMessage
  let onDismiss: () -> Void
  
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  @State private var isPresented = false
  @State private var autoDismissTask: Task<Void, Never>?
  
  var body: some View {
    VStack(spacing: FitTodaySpacing.sm) {
      // Header com ícone, título, mensagem e botão fechar
      HStack(alignment: .top, spacing: FitTodaySpacing.md) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(.title3, weight: .semibold))
          .foregroundStyle(FitTodayColor.warning)
        
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
          Text(errorMessage.title)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(FitTodayColor.textPrimary)
          
          Text(errorMessage.message)
            .font(.system(size: 13))
            .foregroundStyle(FitTodayColor.textSecondary)
            .multilineTextAlignment(.leading)
        }
        
        Spacer()
        
        Button(action: {
          dismissWithAnimation()
        }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(.title3))
            .foregroundStyle(FitTodayColor.textTertiary)
        }
      }
      
      // Botão de ação se disponível
      if let action = errorMessage.action {
        Button(action: {
          action.execute()
          dismissWithAnimation()
        }) {
          Label(action.label, systemImage: action.systemImage)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.sm)
        }
        .buttonStyle(FitSecondaryButtonStyle())
      }
    }
    .padding(FitTodaySpacing.md)
    .background(
      RoundedRectangle(cornerRadius: FitTodayRadius.md)
        .fill(FitTodayColor.surface)
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    )
    .padding(.horizontal, FitTodaySpacing.md)
    .offset(y: isPresented ? 0 : -200)
    .animation(
      reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.4, dampingFraction: 0.8),
      value: isPresented
    )
    .onAppear {
      withAnimation {
        isPresented = true
      }
      
      // Auto-dismiss após 4 segundos
      autoDismissTask = Task {
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        dismissWithAnimation()
      }
    }
    .onDisappear {
      autoDismissTask?.cancel()
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(errorMessage.title). \(errorMessage.message)")
    .accessibilityAddTraits(.isStaticText)
  }
  
  private func dismissWithAnimation() {
    withAnimation {
      isPresented = false
    }
    Task {
      try? await Task.sleep(for: .seconds(0.3))
      onDismiss()
    }
  }
}

// MARK: - View Modifier

extension View {
  /// Adiciona toast de erro à view
  /// - Parameter errorMessage: Binding para ErrorMessage (exibido quando não-nil)
  /// - Returns: View com toast overlay
  func errorToast(errorMessage: Binding<ErrorMessage?>) -> some View {
    ZStack(alignment: .top) {
      self
      
      if let message = errorMessage.wrappedValue {
        ErrorToastView(errorMessage: message) {
          errorMessage.wrappedValue = nil
        }
        .padding(.top, FitTodaySpacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(999)
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: errorMessage.wrappedValue?.id)
  }
}

// MARK: - Preview

#Preview("Error Toast - Network") {
  VStack {
    Spacer()
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(FitTodayColor.background)
  .errorToast(errorMessage: .constant(ErrorMessage(
    title: "Sem conexão",
    message: "Verifique sua internet e tente novamente.",
    action: .openSettings
  )))
}

#Preview("Error Toast - Retry") {
  VStack {
    Spacer()
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(FitTodayColor.background)
  .errorToast(errorMessage: .constant(ErrorMessage(
    title: "Tempo esgotado",
    message: "A operação demorou muito. Tente novamente.",
    action: .retry({})
  )))
}

#Preview("Error Toast - Dismiss") {
  VStack {
    Spacer()
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(FitTodayColor.background)
  .errorToast(errorMessage: .constant(ErrorMessage(
    title: "Ops!",
    message: "Algo inesperado aconteceu. Tente novamente.",
    action: .dismiss
  )))
}

