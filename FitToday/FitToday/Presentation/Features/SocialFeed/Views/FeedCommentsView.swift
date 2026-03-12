//
//  FeedCommentsView.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import SwiftUI

// MARK: - Feed Comments View

struct FeedCommentsView: View {
    @State private var viewModel: FeedCommentsViewModel

    init(viewModel: FeedCommentsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Comments list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                        ForEach(viewModel.comments) { comment in
                            commentRow(comment)
                        }

                        if viewModel.comments.isEmpty && !viewModel.isLoading {
                            Text("Nenhum comentário ainda. Seja o primeiro!")
                                .font(.subheadline)
                                .foregroundStyle(FitTodayColor.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FitTodaySpacing.xl)
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding()
                }

                Divider()

                // Input field
                HStack(spacing: FitTodaySpacing.sm) {
                    TextField("Adicionar comentário...", text: $viewModel.commentText)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await viewModel.addComment() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(viewModel.canSubmit ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                    }
                    .disabled(!viewModel.canSubmit)
                }
                .padding()
            }
            .navigationTitle("Comentários")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.startObserving()
            }
            .onDisappear {
                viewModel.stopObserving()
            }
        }
    }

    private func commentRow(_ comment: FeedComment) -> some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            AsyncImage(url: comment.authorPhotoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(FitTodayColor.brandPrimary.opacity(0.2))
                    .overlay {
                        Text(String(comment.authorName.prefix(1)).uppercased())
                            .font(.caption2.bold())
                            .foregroundStyle(FitTodayColor.brandPrimary)
                    }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(comment.authorName)
                        .font(.caption.weight(.semibold))
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Text(comment.text)
                    .font(.subheadline)
            }

            Spacer()
        }
    }
}
