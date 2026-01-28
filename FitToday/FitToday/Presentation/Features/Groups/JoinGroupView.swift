//
//  JoinGroupView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI
import Swinject

// MARK: - JoinGroupView

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: JoinGroupViewModel

    let groupId: String
    let onJoined: () -> Void

    init(groupId: String, resolver: Resolver, onJoined: @escaping () -> Void) {
        self.groupId = groupId
        self.onJoined = onJoined
        _viewModel = State(initialValue: JoinGroupViewModel(resolver: resolver))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let group = viewModel.groupPreview {
                    groupPreviewContent(group)
                } else {
                    errorContent
                }
            }
            .navigationTitle("Entrar no Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .showErrorAlert(errorMessage: $viewModel.errorMessage)
        }
        .task {
            await viewModel.loadGroupPreview(groupId: groupId)
        }
    }

    @ViewBuilder
    private func groupPreviewContent(_ group: SocialGroup) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text(group.name)
                    .font(.title2.bold())

                Text("\(group.memberCount) \(group.memberCount == 1 ? "membro" : "membros")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        if await viewModel.joinGroup(groupId: groupId) {
                            dismiss()
                            onJoined()
                        }
                    }
                } label: {
                    if viewModel.isJoining {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Entrar em \(group.name)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isJoining)

                Text("Você poderá sair do grupo a qualquer momento")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var errorContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Grupo não encontrado")
                .font(.headline)

            Text("O convite pode estar expirado ou o grupo foi removido.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let container = Container()
    container.register(GroupRepository.self) { _ in MockGroupRepository() }
    container.register(JoinGroupUseCase.self) { _ in
        JoinGroupUseCase(
            groupRepository: MockGroupRepository(),
            userRepository: MockUserRepository(),
            authRepository: MockAuthRepository()
        )
    }

    return JoinGroupView(groupId: "test", resolver: container) {
        print("Joined group")
    }
}

// MARK: - Preview Mocks

private final class MockGroupRepository: GroupRepository, @unchecked Sendable {
    func createGroup(name: String, ownerId: String, ownerDisplayName: String, ownerPhotoURL: URL?) async throws -> SocialGroup {
        SocialGroup(id: "test", name: name, createdAt: Date(), createdBy: ownerId, memberCount: 1, isActive: true)
    }
    func getGroup(_ groupId: String) async throws -> SocialGroup? {
        SocialGroup(id: groupId, name: "Galera da Academia", createdAt: Date(), createdBy: "test", memberCount: 3, isActive: true)
    }
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
    func currentUser() async throws -> SocialUser? {
        SocialUser(id: "test", displayName: "Test User", email: nil, photoURL: nil, authProvider: .email, currentGroupId: nil, privacySettings: PrivacySettings(), createdAt: Date())
    }
    func signInWithApple() async throws -> SocialUser { fatalError() }
    func signInWithGoogle() async throws -> SocialUser { fatalError() }
    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser { fatalError() }
    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser { fatalError() }
    func signOut() async throws {}
    func observeAuthState() -> AsyncStream<SocialUser?> { AsyncStream { _ in } }
}
