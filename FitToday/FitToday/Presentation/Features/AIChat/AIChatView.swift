//
//  AIChatView.swift
//  FitToday
//
//  Main AI chat screen with feature gating for FitPal.
//

import SwiftUI
import Swinject

struct AIChatView: View {

    let resolver: Resolver

    @Environment(AppRouter.self) private var router
    @State private var viewModel: AIChatViewModel
    @State private var entitlement: ProEntitlement = .free

    private let entitlementRepository: EntitlementRepository?

    init(resolver: Resolver) {
        self.resolver = resolver
        self._viewModel = State(initialValue: AIChatViewModel(resolver: resolver))
        self.entitlementRepository = resolver.resolve(EntitlementRepository.self)
    }

    var body: some View {
        ZStack {
            FitTodayColor.background.ignoresSafeArea()

            if entitlement.isPro {
                proChatView
            } else {
                upsellView
            }
        }
        .navigationTitle("FitPal")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEntitlement()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Pro Chat View

    @ViewBuilder
    private var proChatView: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty {
                emptyStateView
            } else {
                messagesListView
            }

            inputBar
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.xl) {
                Spacer(minLength: FitTodaySpacing.xl)

                FitPalOrbView()

                // Quick action chips
                VStack(spacing: FitTodaySpacing.sm) {
                    Text("Try asking:")
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FitTodaySpacing.sm) {
                            ForEach(AIChatViewModel.quickActions, id: \.self) { action in
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
                            Text("Thinking...")
                                .font(FitTodayFont.ui(size: 14, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, FitTodaySpacing.md)
                        .id("loading")
                    }
                }
                .padding(.vertical, FitTodaySpacing.sm)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
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
            TextField("Ask FitPal...", text: $viewModel.inputText)
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
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.surface)
    }

    // MARK: - Upsell View

    private var upsellView: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.xl) {
                Spacer(minLength: FitTodaySpacing.xl)

                FitPalOrbView()

                // Benefits list
                VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                    benefitRow(icon: "brain.head.profile", text: "Personalized workout plans")
                    benefitRow(icon: "figure.run", text: "Exercise suggestions & alternatives")
                    benefitRow(icon: "heart.text.square", text: "Recovery & nutrition tips")
                    benefitRow(icon: "clock.arrow.circlepath", text: "Warm-up & cool-down routines")
                }
                .padding(.horizontal, FitTodaySpacing.lg)

                // Upgrade button
                Button {
                    router.push(.paywall)
                } label: {
                    Text("Upgrade to Pro")
                        .font(FitTodayFont.ui(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FitTodaySpacing.md)
                        .background(FitTodayColor.gradientPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                }
                .padding(.horizontal, FitTodaySpacing.lg)

                Spacer(minLength: FitTodaySpacing.xl)
            }
        }
    }

    // MARK: - Helpers

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: FitTodaySpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 32)

            Text(text)
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
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
