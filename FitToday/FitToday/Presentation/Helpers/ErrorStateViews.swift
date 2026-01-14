//
//  ErrorStateViews.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//
//  💡 Learn: Views centralizadas para diferentes estados de erro
//  Reutilizáveis em toda a aplicação, evitando duplicação de código

import SwiftUI

// MARK: - Error State Enum

/// Tipos de estados de erro suportados
enum ErrorState: Equatable {
    case dependency(message: String)
    case network(message: String)
    case api(message: String, code: Int?)
    case generic(title: String, message: String)

    var title: String {
        switch self {
        case .dependency:
            return "Erro de Configuração"
        case .network:
            return "Erro de Conexão"
        case .api:
            return "Erro do Servidor"
        case .generic(let title, _):
            return title
        }
    }

    var message: String {
        switch self {
        case .dependency(let msg),
             .network(let msg):
            return msg
        case .api(let msg, let code):
            if let code = code {
                return "\(msg) (Código: \(code))"
            }
            return msg
        case .generic(_, let msg):
            return msg
        }
    }

    var iconName: String {
        switch self {
        case .dependency:
            return "exclamationmark.triangle.fill"
        case .network:
            return "wifi.exclamationmark"
        case .api:
            return "server.rack"
        case .generic:
            return "exclamationmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .dependency, .api:
            return .red
        case .network:
            return .orange
        case .generic:
            return .red
        }
    }
}

// MARK: - Generic Error State View

/// View genérica para exibir qualquer tipo de estado de erro
struct ErrorStateView: View {
    let state: ErrorState
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: state.iconName)
                .font(.system(size: 48))
                .foregroundStyle(state.iconColor)

            Text(state.title)
                .font(.title3.bold())
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(state.message)
                .font(.body)
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button("Tentar Novamente", action: retryAction)
                    .fitPrimaryStyle()
                    .padding(.top, FitTodaySpacing.sm)
            }
        }
        .padding()
    }
}

// MARK: - Specialized Error Views

/// View para erro de dependência (Dependency Injection)
struct DependencyErrorView: View {
    let message: String

    var body: some View {
        ErrorStateView(state: .dependency(message: message))
    }
}

/// View para erro de rede
struct NetworkErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            state: .network(message: message),
            retryAction: retryAction
        )
    }
}

/// View para erro de API
struct APIErrorView: View {
    let message: String
    let code: Int?
    var retryAction: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            state: .api(message: message, code: code),
            retryAction: retryAction
        )
    }
}

/// View para erro genérico
struct GenericErrorView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            state: .generic(title: title, message: message),
            retryAction: retryAction
        )
    }
}

// 💡 Learn: EmptyStateView já existe em CardsAndBadges.swift (DesignSystem)
// Não duplicamos aqui para manter consistência visual do design system

// MARK: - Preview

#Preview("Dependency Error") {
    DependencyErrorView(
        message: "Erro de configuração: repositórios não estão registrados."
    )
}

#Preview("Network Error") {
    NetworkErrorView(
        message: "Não foi possível conectar ao servidor. Verifique sua conexão com a internet."
    ) {
        print("Retry tapped")
    }
}

#Preview("API Error") {
    APIErrorView(
        message: "Falha ao processar requisição.",
        code: 500
    ) {
        print("Retry tapped")
    }
}

#Preview("Generic Error") {
    GenericErrorView(
        title: "Algo deu errado",
        message: "Ocorreu um erro inesperado. Por favor, tente novamente."
    )
}
