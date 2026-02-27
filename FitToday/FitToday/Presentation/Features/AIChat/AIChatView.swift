//
//  AIChatView.swift
//  FitToday
//
//  Main AI chat screen with feature gating for FitOrb.
//

import SwiftUI
import Swinject

struct AIChatView: View {

    let resolver: Resolver

    @Environment(AppRouter.self) private var router
    @State private var viewModel: AIChatViewModel
    @State private var entitlement: ProEntitlement = .free
    @State private var showClearConfirmation = false

    private let entitlementRepository: EntitlementRepository?

    init(resolver: Resolver) {
        self.resolver = resolver
        self._viewModel = State(initialValue: AIChatViewModel(resolver: resolver))
        self.entitlementRepository = resolver.resolve(EntitlementRepository.self)
    }

    var body: some View {
        ZStack {
            FitTodayColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesListView
                }

                inputBar
            }
        }
        .navigationTitle("fitorb.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: FitTodaySpacing.sm) {
                    if !viewModel.messages.isEmpty {
                        Button {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                    Button {
                        router.push(.apiKeySettings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
        }
        .task {
            await loadEntitlement()
            await viewModel.loadHistory()
        }
        .alert(
            viewModel.errorMessage?.title ?? "",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage?.message ?? "")
        }
        .confirmationDialog(
            "fitorb.clear_chat_confirm".localized,
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("fitorb.clear_chat".localized, role: .destructive) {
                Task { await viewModel.clearHistory() }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.xl) {
                Spacer(minLength: FitTodaySpacing.xl)

                FitOrbView()

                // API key missing banner
                if !viewModel.isChatAvailable {
                    HStack(spacing: FitTodaySpacing.sm) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(FitTodayColor.brandPrimary)
                        Text("fitorb.error_no_api_key".localized)
                            .font(FitTodayFont.ui(size: 13, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                    .padding(FitTodaySpacing.md)
                    .background(FitTodayColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    .padding(.horizontal, FitTodaySpacing.md)
                }

                // Quick action chips
                VStack(spacing: FitTodaySpacing.sm) {
                    Text("fitorb.try_asking".localized)
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FitTodaySpacing.sm) {
                            ForEach(viewModel.quickActions, id: \.self) { action in
                                Button {
                                    if entitlement.isPro {
                                        viewModel.inputText = action
                                        viewModel.sendMessage()
                                    } else {
                                        router.push(.paywall)
                                    }
                                } label: {
                                    Text(action)
                                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                                        .foregroundStyle(FitTodayColor.brandPrimary)
                                        .padding(.horizontal, FitTodaySpacing.md)
                                        .padding(.vertical, FitTodaySpacing.sm)
                                        .background(FitTodayColor.surfaceElevated)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, FitTodaySpacing.md)
                    }
                }

                Spacer(minLength: FitTodaySpacing.xl)
            }
        }
    }

    // MARK: - Messages List

    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(for: message)
                            .id(message.id)
                    }

                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .tint(FitTodayColor.brandPrimary)
                            Text("fitorb.thinking".localized)
                                .font(FitTodayFont.ui(size: 14, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, FitTodaySpacing.md)
                        .id("loading")
                    } else if viewModel.isTyping {
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(FitTodayColor.brandPrimary)
                                    .frame(width: 6, height: 6)
                                    .opacity(0.6)
                                    .animation(
                                        .easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(i) * 0.15),
                                        value: viewModel.isTyping
                                    )
                            }
                            Spacer()
                        }
                        .padding(.horizontal, FitTodaySpacing.md)
                        .id("typing")
                    }
                }
                .padding(.vertical, FitTodaySpacing.sm)
            }
            .onChange(of: viewModel.messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.messages.last?.content) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(for message: AIChatMessage) -> some View {
        let isUser = message.role == .user

        return HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.content)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(isUser ? .white : FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, 10)
                .background(isUser ? FitTodayColor.brandPrimary : FitTodayColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, FitTodaySpacing.md)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            TextField("fitorb.input_placeholder".localized, text: $viewModel.inputText)
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, 10)
                .background(FitTodayColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
                .onSubmit {
                    if entitlement.isPro {
                        viewModel.sendMessage()
                    } else {
                        router.push(.paywall)
                    }
                }

            Button {
                if entitlement.isPro {
                    viewModel.sendMessage()
                } else {
                    router.push(.paywall)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? FitTodayColor.textTertiary
                            : FitTodayColor.brandPrimary
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading || viewModel.isTyping)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.surface)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func loadEntitlement() async {
        guard let repo = entitlementRepository else { return }
        do {
            entitlement = try await repo.currentEntitlement()
        } catch {
            entitlement = .free
        }
    }
}
