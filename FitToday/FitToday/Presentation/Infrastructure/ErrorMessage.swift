//
//  ErrorMessage.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation
import UIKit

/// Modelo de mensagem de erro para apresentação ao usuário
struct ErrorMessage: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let action: ErrorAction?
  
  init(title: String, message: String, action: ErrorAction? = nil) {
    self.title = title
    self.message = message
    self.action = action
  }
  
  static func == (lhs: ErrorMessage, rhs: ErrorMessage) -> Bool {
    lhs.id == rhs.id
  }
}

/// Ações disponíveis em mensagens de erro
enum ErrorAction: Equatable {
  case retry(() -> Void)
  case openSettings
  case dismiss
  
  /// Label do botão de ação
  var label: String {
    switch self {
    case .retry:
      return "error.action.retry".localized
    case .openSettings:
      return "error.action.open_settings".localized
    case .dismiss:
      return "error.action.dismiss".localized
    }
  }
  
  /// Ícone do sistema para o botão
  var systemImage: String {
    switch self {
    case .retry:
      return "arrow.clockwise"
    case .openSettings:
      return "gearshape"
    case .dismiss:
      return "xmark"
    }
  }
  
  /// Executa a ação apropriada
  func execute() {
    switch self {
    case .retry(let closure):
      closure()
    case .openSettings:
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    case .dismiss:
      break // View dismisses automatically
    }
  }
  
  /// Equatability baseada no case, ignorando closures
  static func == (lhs: ErrorAction, rhs: ErrorAction) -> Bool {
    switch (lhs, rhs) {
    case (.retry, .retry):
      return true
    case (.openSettings, .openSettings):
      return true
    case (.dismiss, .dismiss):
      return true
    default:
      return false
    }
  }
}

