//
//  GroupsView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI
import Swinject

// MARK: - GroupsView

struct GroupsView: View {
    @Environment(\.dependencyResolver) private var resolver
    @State private var viewModel: GroupsViewModel
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingNotifications = false
    @State private var showingManageGroup = false
    @State private var joinGroupId: String?

    init(resolver: Resolver) {
        _viewModel = State(initialValue: GroupsViewModel(resolver: resolver))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.currentGroup == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let group = viewModel.currentGroup {
                    GroupDashboardView(
                        group: group,
                        members: viewModel.members,
                        isAdmin: viewModel.isAdmin,
                        currentUserId: viewModel.currentUserId,
                        resolver: resolver,
                        onInviteTapped: handleInviteTapped,
                        onLeaveTapped: handleLeaveTapped,
                        onManageGroupTapped: {
                            showingManageGroup = true
                        }
                    )
                } else {
                    EmptyGroupsView {
                        showingCreateGroup = true
                    }
                }
            }
            .navigationTitle("Grupos")
            .toolbar {
                if viewModel.currentGroup != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingNotifications = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))

                                if viewModel.unreadNotificationsCount > 0 {
                                    Text("\(min(viewModel.unreadNotificationsCount, 99))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showingNotifications) {
                NotificationFeedView(
                    viewModel: NotificationFeedViewModel(resolver: resolver)
                )
                .onDisappear {
                    viewModel.clearUnreadCount()
                    Task {
                        await viewModel.loadUnreadNotificationsCount()
                    }
                }
            }
            .refreshable {
                await viewModel.loadCurrentGroup()
                await viewModel.loadUnreadNotificationsCount()
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(resolver: resolver) { group in
                    Task {
                        await viewModel.loadCurrentGroup()
                    }
                }
            }
            .sheet(isPresented: $showingManageGroup) {
                if let group = viewModel.currentGroup {
                    ManageGroupView(
                        group: group,
                        members: viewModel.members,
                        currentUserId: viewModel.currentUserId,
                        onRemoveMember: { userId in
                            Task {
                                await viewModel.removeMember(userId: userId)
                            }
                        },
                        onDeleteGroup: {
                            Task {
                                await viewModel.deleteGroup()
                            }
                        }
                    )
                }
            }
            .sheet(item: Binding(
                get: { joinGroupId.map { GroupIdWrapper(id: $0) } },
                set: { joinGroupId = $0?.id }
            )) { wrapper in
                JoinGroupView(groupId: wrapper.id, resolver: resolver) {
                    Task {
                        await viewModel.loadCurrentGroup()
                    }
                }
            }
            .showErrorAlert(errorMessage: $viewModel.errorMessage)
        }
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Actions

    private func handleInviteTapped() {
        // Share sheet will be handled in the toolbar menu or dashboard
    }

    private func handleLeaveTapped() {
        Task {
            await viewModel.leaveGroup()
        }
    }

    func handleGroupInvite(groupId: String) {
        joinGroupId = groupId
    }
}

// MARK: - GroupIdWrapper

private struct GroupIdWrapper: Identifiable {
    let id: String
}

// MARK: - Preview

#Preview {
    let container = Container()
    container.register(AuthenticationRepository.self) { _ in MockAuthRepository() }
    container.register(GroupRepository.self) { _ in MockGroupRepository() }
    container.register(LeaveGroupUseCase.self) { _ in
        LeaveGroupUseCase(
            groupRepository: MockGroupRepository(),
            userRepository: MockUserRepository(),
            authRepository: MockAuthRepository()
        )
    }

    return GroupsView(resolver: container)
        .environment(\.dependencyResolver, container)
}

// MARK: - Preview Mocks

private final class MockGroupRepository: GroupRepository, @unchecked Sendable {
    func createGroup(name: String, ownerId: String) async throws -> SocialGroup {
        SocialGroup(id: "test", name: name, createdAt: Date(), createdBy: ownerId, memberCount: 1, isActive: true)
    }
    func getGroup(_ groupId: String) async throws -> SocialGroup? { nil }
    func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {}
    func removeMember(groupId: String, userId: String) async throws {}
    func leaveGroup(groupId: String, userId: String) async throws {}
    func deleteGroup(_ groupId: String) async throws {}
    func getMembers(groupId: String) async throws -> [GroupMember] { [] }
}

private final class MockUserRepository: UserRepository, @unchecked Sendable {
    func getUser(_ userId: String) async throws -> SocialUser? { nil }
    func updateUser(_ user: SocialUser) async throws {}
    func updatePrivacySettings(_ userId: String, settings: PrivacySettings) async throws {}
    func updateCurrentGroup(_ userId: String, groupId: String?) async throws {}
}

private final class MockAuthRepository: AuthenticationRepository, @unchecked Sendable {
    func currentUser() async throws -> SocialUser? { nil }
    func signInWithApple() async throws -> SocialUser { fatalError() }
    func signInWithGoogle() async throws -> SocialUser { fatalError() }
    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser { fatalError() }
    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser { fatalError() }
    func signOut() async throws {}
    func observeAuthState() -> AsyncStream<SocialUser?> { AsyncStream { _ in } }
}
