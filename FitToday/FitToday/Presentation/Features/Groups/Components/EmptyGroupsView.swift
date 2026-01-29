//
//  EmptyGroupsView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI

// MARK: - EmptyGroupsView

struct EmptyGroupsView: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Treine em Grupo")
                    .font(.title2.bold())

                Text("Crie um grupo com amigos e mantenha-se motivados juntos!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onCreateTapped) {
                Text("Criar Seu Primeiro Grupo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyGroupsView {
        print("Create group tapped")
    }
}
