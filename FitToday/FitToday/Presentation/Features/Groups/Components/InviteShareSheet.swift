//
//  InviteShareSheet.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI

// MARK: - InviteShareSheet

struct InviteShareSheet: View {
    let groupName: String
    let inviteLinks: InviteLinks

    var body: some View {
        ShareLink(
            item: inviteLinks.shareURL,
            subject: Text("Convite para FitToday"),
            message: Text(shareMessage)
        ) {
            Label("Compartilhar Convite", systemImage: "square.and.arrow.up")
        }
    }

    private var shareMessage: String {
        "Entre no meu grupo '\(groupName)' no FitToday e vamos treinar juntos! 💪"
    }
}

#Preview {
    let links = InviteLinks(
        urlScheme: URL(string: "fittoday://group/invite/test")!,
        universalLink: URL(string: "https://fittoday.app/group/invite/test")!
    )

    return List {
        InviteShareSheet(groupName: "Galera da Academia", inviteLinks: links)
    }
}
