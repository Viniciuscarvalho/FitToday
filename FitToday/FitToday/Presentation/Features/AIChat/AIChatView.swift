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
    @State private var showClearConfirmation = false


    init(resolver: Resolver) {
        self.resolver = resolver
        self._viewModel = State(initialValue: AIChatViewModel(resolver: resolver))
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
                if !viewModel.messages.isEmpty {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
        }
        .task {
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
        .sheet(isPresented: $viewModel.showPaywall) {
            OptimizedPaywallView(
                onPurchaseSuccess: {
                    viewModel.showPaywall = false
                },
                onDismiss: {
                    viewModel.showPaywall = false
                }
            )
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.xl) {
                Spacer(minLength: FitTodaySpacing.xl)

                FitOrbView()

                // Daily usage badge (shown only for free users with usage)
                if viewModel.dailyMessagesUsed > 0 {
                    dailyUsageBadge
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
                                    viewModel.inputText = action
                                    viewModel.sendMessage()
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

    // MARK: - Daily Usage Badge

    private var dailyUsageBadge: some View {
        let isAtLimit = viewModel.dailyMessagesUsed >= viewModel.dailyMessagesLimit
        let label = isAtLimit
            ? "fitorb.daily_limit_reached".localized
            : String(format: "fitorb.daily_limit".localized, viewModel.dailyMessagesUsed, viewModel.dailyMessagesLimit)

        return Text(label)
            .font(FitTodayFont.ui(size: 12, weight: .medium))
            .foregroundStyle(isAtLimit ? FitTodayColor.error : FitTodayColor.textTertiary)
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, 6)
            .background(
                (isAtLimit ? FitTodayColor.error : FitTodayColor.textTertiary).opacity(0.1)
            )
            .clipShape(Capsule())
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
                    viewModel.sendMessage()
                }

            Button {
                viewModel.sendMessage()
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

}
