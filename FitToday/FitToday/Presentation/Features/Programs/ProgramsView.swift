//
//  ProgramsView.swift
//  FitToday
//
//  Nova tab "Programas" - substitui a antiga "Biblioteca".
//  Exibe programas em formato de coleção (cards) com imagem de fundo.
//

import SwiftUI
import Swinject

struct ProgramsView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    // 💡 Learn: Com @Observable, usamos @State em vez de @StateObject
    @State private var viewModel: ProgramsViewModel?
    @State private var dependencyError: String?

    init(resolver: Resolver) {
        if let repository = resolver.resolve(ProgramRepository.self) {
            _viewModel = State(initialValue: ProgramsViewModel(repository: repository))
            _dependencyError = State(initialValue: nil)
        } else {
            _viewModel = State(initialValue: nil)
            _dependencyError = State(initialValue: "Erro de configuração: repositório de programas não está registrado.")
        }
    }
    
    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func contentView(viewModel: ProgramsViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                    .padding(.horizontal, FitTodaySpacing.md)
                programsGrid(viewModel: viewModel)
                    .padding(.horizontal, FitTodaySpacing.md)
            }
            .padding(.vertical, FitTodaySpacing.md)
        }
        .task {
            await viewModel.loadPrograms()
        }
        .refreshable {
            await viewModel.loadPrograms()
        }
        .alert("Ops!", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Algo inesperado aconteceu.")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Programas")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("Escolha um programa e siga seu plano de treino")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, FitTodaySpacing.md)
    }
    
    // MARK: - Programs Grid

    @ViewBuilder
    private func programsGrid(viewModel: ProgramsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.programs.isEmpty {
            EmptyStateView(
                title: "Nenhum programa disponível",
                message: "Em breve teremos programas de treino para você!",
                systemIcon: "rectangle.stack"
            )
            .padding(.vertical, FitTodaySpacing.xl)
        } else {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.programs) { program in
                    ProgramCardLarge(program: program) {
                        router.push(.programDetail(program.id), on: .programs)
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

// 💡 Learn: @Observable substitui ObservableObject para gerenciamento de estado moderno
@MainActor
@Observable final class ProgramsViewModel {
    private(set) var programs: [Program] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let repository: ProgramRepository

    init(repository: ProgramRepository) {
        self.repository = repository
    }
    
    func loadPrograms() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            programs = try await repository.listPrograms()
        } catch {
            errorMessage = "Não foi possível carregar os programas: \(error.localizedDescription)"
        }
    }
}

// MARK: - Program Card Large

struct ProgramCardLarge: View {
    let program: Program
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // Imagem de fundo do programa - limitada ao tamanho do container
                    Image(program.heroImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: 340)
                        .clipped()
                    
                    // Overlay escuro gradiente para legibilidade
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.6), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Conteúdo
                    VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                        // Tag do objetivo - posição superior
                        HStack(spacing: FitTodaySpacing.xs) {
                            Image(systemName: program.goalTag.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(program.goalTag.displayName)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .padding(.horizontal, FitTodaySpacing.sm + 2)
                        .padding(.vertical, FitTodaySpacing.xs + 2)
                        .background(FitTodayColor.surface.opacity(0.9))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Nome
                        Text(program.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        // Subtítulo
                        Text(program.subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                        
                        // Metadados com ícones
                        HStack(spacing: FitTodaySpacing.md) {
                            Label(program.durationDescription, systemImage: "calendar")
                            Label(program.sessionsDescription, systemImage: "flame")
                            Label("\(program.estimatedMinutesPerSession) min", systemImage: "clock")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, FitTodaySpacing.xs)
                        
                        // CTA com texto escuro para contraste adequado
                        Text("Começar programa")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(FitTodayColor.textInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FitTodaySpacing.sm + 4)
                            .background(FitTodayColor.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                            .padding(.top, FitTodaySpacing.sm)
                    }
                    .padding(FitTodaySpacing.lg)
                }
            }
            .frame(height: 340)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                    .stroke(FitTodayColor.outline.opacity(0.4), lineWidth: 1)
            )
            .fitCardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(program.name), \(program.durationDescription), \(program.sessionsDescription)")
        .accessibilityHint("Toque para ver detalhes e começar o programa")
    }
}

#Preview {
    let container = Container()
    NavigationStack {
        ProgramsView(resolver: container)
            .environment(AppRouter())
    }
}

