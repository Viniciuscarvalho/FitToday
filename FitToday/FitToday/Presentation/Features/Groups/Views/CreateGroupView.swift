//
//  CreateGroupView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI
import Swinject

// MARK: - CreateGroupView

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyResolver) private var resolver
    @State private var viewModel: CreateGroupViewModel

    let onGroupCreated: (SocialGroup) -> Void

    init(resolver: Resolver, onGroupCreated: @escaping (SocialGroup) -> Void) {
        self.onGroupCreated = onGroupCreated
        _viewModel = State(initialValue: CreateGroupViewModel(resolver: resolver))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome do Grupo", text: $viewModel.groupName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Informações do Grupo")
                } footer: {
                    Text("Escolha um nome para o seu grupo de treino")
                }
            }
            .navigationTitle("Criar Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        Task {
                            if let group = await viewModel.createGroup() {
                                dismiss()
                                onGroupCreated(group)
                            }
                        }
                    }
                    .disabled(!viewModel.canCreate || viewModel.isLoading)
                }
            }
            .disabled(viewModel.isLoading)
            .showErrorAlert(errorMessage: $viewModel.errorMessage)
        }
    }
}

#Preview {
    let container = Container()
    container.register(CreateGroupUseCase.self) { _ in
        CreateGroupUseCase(
            groupRepository: MockGroupRepository(),
            userRepository: MockUserRepository(),
            authRepository: MockAuthRepository()
        )
    }

    return CreateGroupView(resolver: container) { _ in
        print("Group created")
    }
}

// MARK: - Preview Mocks

private final class MockGroupRepository: GroupRepository, @unchecked Sendable {
    func createGroup(name: String, ownerId: String, ownerDisplayName: String, ownerPhotoURL: URL?) async throws -> SocialGroup {
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
