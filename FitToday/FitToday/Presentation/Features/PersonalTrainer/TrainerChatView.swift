//
//  TrainerChatView.swift
//  FitToday
//
//  Chat interface for communicating with a personal trainer.
//

import SwiftUI

struct TrainerChatView: View {
    @State private var viewModel: TrainerChatViewModel

    init(trainerId: String, trainerName: String) {
        _viewModel = State(wrappedValue: TrainerChatViewModel(trainerId: trainerId, trainerName: trainerName))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: FitTodaySpacing.sm) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(
                                message: message,
                                isFromCurrentUser: !message.isFromTrainer
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

            Divider()
                .overlay(FitTodayColor.outline)

            // Input Bar
            inputBar
        }
        .background(FitTodayColor.background)
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
