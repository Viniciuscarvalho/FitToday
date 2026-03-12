//
//  SocialFeedView.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import SwiftUI
import Swinject

// MARK: - Social Feed View

struct SocialFeedView: View {
    @State private var viewModel: SocialFeedViewModel
    @State private var showComments: FeedPost?
    @Environment(\.dependencyResolver) private var resolver

    init(viewModel: SocialFeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.posts) { post in
                    FeedPostCardView(
                        post: post,
                        isLiked: viewModel.isPostLiked(post),
                        isOwnPost: viewModel.isCurrentUser(post.authorId),
                        onLike: {
                            Task { await viewModel.toggleLike(postId: post.id) }
                        },
                        onComment: {
                            showComments = post
                        },
                        onDelete: {
                            Task { await viewModel.deletePost(post.id) }
                        }
                    )
                }

                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    emptyFeedView
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.vertical, FitTodaySpacing.xl)
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.stopObserving()
            viewModel.startObserving()
        }
        .task {
            viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .navigationTitle("Feed")
        .sheet(item: $showComments) { post in
            if let feedRepo = resolver.resolve(FeedRepository.self),
               let authRepo = resolver.resolve(AuthenticationRepository.self) {
                FeedCommentsView(
                    viewModel: FeedCommentsViewModel(
                        feedRepository: feedRepo,
                        authRepository: authRepo,
                        postId: post.id
                    )
                )
                .presentationDetents([.medium, .large])
            }
        }
        .alert("Erro", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var emptyFeedView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("Nenhum post ainda")
                .font(.headline)

            Text("Complete um treino e compartilhe com seu grupo!")
                .font(.subheadline)
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}
