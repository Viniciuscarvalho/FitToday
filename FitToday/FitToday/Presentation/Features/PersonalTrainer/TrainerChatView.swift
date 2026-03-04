//
//  TrainerChatView.swift
//  FitToday
//
//  Chat interface for communicating with a personal trainer.
//

import SwiftUI
import Swinject

struct TrainerChatView: View {
    @State private var viewModel: TrainerChatViewModel

    init(trainerId: String, trainerName: String, currentUserId: String, resolver: Resolver) {
        _viewModel = State(wrappedValue: TrainerChatViewModel(
            trainerId: trainerId,
            trainerName: trainerName,
            currentUserId: currentUserId,
            resolver: resolver
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(FitTodayColor.brandPrimary)
                Spacer()
            } else if viewModel.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                messagesView
            }

            Divider()
                .overlay(FitTodayColor.outline)

            inputBar
        }
        .background(FitTodayColor.background)
        .task {
            await viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // MARK: - Messages

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            message: message,
                            isFromCurrentUser: viewModel.isFromCurrentUser(message)
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) {
                if let lastId = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "message")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("trainer.chat.empty".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            TextField("trainer.chat.placeholder".localized, text: $viewModel.newMessageText, axis: .vertical)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, 10)
                .background(FitTodayColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(viewModel.canSend ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSend)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.backgroundElevated)
    }
}
