//
//  ErrorPresenting.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation

/// Protocol para ViewModels que apresentam erros ao usuário
protocol ErrorPresenting: AnyObject {
  var errorMessage: ErrorMessage? { get set }
  func handleError(_ error: Error)
}

extension ErrorPresenting where Self: ObservableObject {
  /// Implementação default que mapeia erro técnico para mensagem user-friendly
  func handleError(_ error: Error) {
    // Log técnico para debugging
    #if DEBUG
    print("""
      [Error] \(type(of: self))
      Type: \(type(of: error))
      Description: \(error.localizedDescription)
      """)
    #else
    print("[Error] \(type(of: self)): \(error)")
    #endif
    
    // Mapear para mensagem user-friendly
    let mapped = ErrorMapper.userFriendlyMessage(for: error)
    
    // Publicar no main thread
    Task { @MainActor in
      errorMessage = mapped
    }
  }
}

