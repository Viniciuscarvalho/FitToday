//
//  ManageGroupView.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import SwiftUI

// MARK: - ManageGroupView

struct ManageGroupView: View {
    let group: SocialGroup
    let members: [GroupMember]
    let currentUserId: String?
    let onRemoveMember: (String) -> Void
    let onDeleteGroup: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var memberToRemove: GroupMember?
    @State private var showDeleteGroupConfirmation = false
    @State private var showDeleteGroupFinalConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Members Section
                Section {
                    ForEach(members) { member in
                        ManageMemberRowView(
                            member: member,
                            isCurrentUser: member.id == currentUserId
                        )
                    }
                    .onDelete(perform: handleDeleteMember)
                } header: {
                    Text("Membros (\(members.count))")
                } footer: {
                    Text("Deslize para a esquerda para remover um membro.")
                        .font(.caption)
                }

                // Delete Group Section
                Section {
                    Button(role: .destructive) {
                        showDeleteGroupConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Excluir Grupo", systemImage: "trash")
                                .font(.headline)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Esta ação é irreversível. Todos os membros serão removidos do grupo.")
                        .font(.caption)
                }
            }
            .navigationTitle("Gerenciar Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
            // Remove Member Confirmation
            .confirmationDialog(
                "Remover Membro",
                isPresented: Binding(
                    get: { memberToRemove != nil },
                    set: { if !$0 { memberToRemove = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let member = memberToRemove {
                    Button("Remover \(member.displayName)", role: .destructive) {
                        onRemoveMember(member.id)
                        memberToRemove = nil
                    }
                    Button("Cancelar", role: .cancel) {
                        memberToRemove = nil
                    }
                }
            } message: {
                if let member = memberToRemove {
                    Text("Remover \(member.displayName) do grupo? Esta pessoa não poderá mais ver os desafios ou placares.")
                }
            }
            // Delete Group First Confirmation
            .confirmationDialog(
                "Excluir Grupo",
                isPresented: $showDeleteGroupConfirmation,
                titleVisibility: .visible
            ) {
                Button("Continuar", role: .destructive) {
                    showDeleteGroupFinalConfirmation = true
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Tem certeza que deseja excluir o grupo \"\(group.name)\"?")
            }
            // Delete Group Final Confirmation (two-step for safety)
            .alert("Confirmar Exclusão", isPresented: $showDeleteGroupFinalConfirmation) {
                Button("Excluir Grupo", role: .destructive) {
                    onDeleteGroup()
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta ação é IRREVERSÍVEL. Todos os dados do grupo serão perdidos permanentemente.")
            }
        }
    }

    // MARK: - Actions

    private func handleDeleteMember(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let member = members[index]

        // Don't allow removing self (admin)
        guard member.id != currentUserId else { return }

        // Don't allow removing other admins
        guard member.role != .admin else { return }

        memberToRemove = member
    }
}

// MARK: - ManageMemberRowView

private struct ManageMemberRowView: View {
    let member: GroupMember
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar or initials
            if let photoURL = member.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialsView
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                initialsView
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName)
                        .font(.body)

                    if isCurrentUser {
                        Text("(você)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if member.role == .admin {
                        Text("Admin")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FitTodayColor.brandPrimary)
                            .clipShape(Capsule())
                    }
                }

                Text("Entrou em \(member.joinedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .deleteDisabled(isCurrentUser || member.role == .admin)
    }

    private var initials: String {
        let components = member.displayName.split(separator: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(FitTodayColor.brandPrimary.opacity(0.2))

            Text(initials)
                .font(.headline)
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Preview

#Preview {
    let sampleMembers = [
        GroupMember(id: "1", displayName: "João Silva", photoURL: nil, joinedAt: Date(), role: .admin, isActive: true),
        GroupMember(id: "2", displayName: "Maria Santos", photoURL: nil, joinedAt: Date().addingTimeInterval(-86400), role: .member, isActive: true),
        GroupMember(id: "3", displayName: "Pedro Oliveira", photoURL: nil, joinedAt: Date().addingTimeInterval(-172800), role: .member, isActive: true)
    ]

    let sampleGroup = SocialGroup(
        id: "test",
        name: "Galera da Academia",
        createdAt: Date(),
        createdBy: "1",
        memberCount: 3,
        isActive: true
    )

    return ManageGroupView(
        group: sampleGroup,
        members: sampleMembers,
        currentUserId: "1",
        onRemoveMember: { userId in print("Remove: \(userId)") },
        onDeleteGroup: { print("Delete group") }
    )
}
