//
//  GroupDashboardView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI
import Swinject

// MARK: - GroupDashboardView

struct GroupDashboardView: View {
    let group: SocialGroup
    let members: [GroupMember]
    let isAdmin: Bool
    let currentUserId: String?
    let resolver: Resolver
    let onInviteTapped: () -> Void
    let onLeaveTapped: () -> Void
    var onManageGroupTapped: (() -> Void)?

    @State private var showLeaveConfirmation = false

    var body: some View {
        List {
            // Group Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(.title2.bold())

                    Text("\(members.count) \(members.count == 1 ? "membro" : "membros")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            // Members Section
            Section("Membros") {
                ForEach(members) { member in
                    MemberRowView(member: member)
                }
            }

            // Leaderboards
            Section("Desafios da Semana") {
                LeaderboardView(
                    groupId: group.id,
                    currentUserId: currentUserId,
                    resolver: resolver
                )
                .frame(height: 400)
            }

            // Actions Section
            Section {
                Button {
                    onInviteTapped()
                } label: {
                    Label("Convidar Amigos", systemImage: "person.badge.plus")
                }

                if isAdmin {
                    Button {
                        onManageGroupTapped?()
                    } label: {
                        Label("Gerenciar Grupo", systemImage: "gearshape")
                    }
                }

                Button(role: .destructive) {
                    showLeaveConfirmation = true
                } label: {
                    Label("Sair do Grupo", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .confirmationDialog(
            "Sair do Grupo",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sair", role: .destructive) {
                onLeaveTapped()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tem certeza? Suas estatísticas serão removidas dos placares.")
        }
    }
}

// MARK: - MemberRowView

private struct MemberRowView: View {
    let member: GroupMember

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

                    if member.role == .admin {
                        Text("Admin")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                Text("Entrou em \(member.joinedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))

            Text(member.initials)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - GroupMember Extension

private extension GroupMember {
    var initials: String {
        let components = displayName.split(separator: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
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

    return NavigationStack {
        GroupDashboardView(
            group: sampleGroup,
            members: sampleMembers,
            isAdmin: true,
            currentUserId: "1",
            resolver: Container().synchronize(),
            onInviteTapped: { print("Invite tapped") },
            onLeaveTapped: { print("Leave tapped") },
            onManageGroupTapped: { print("Manage tapped") }
        )
        .navigationTitle("Grupos")
    }
}
