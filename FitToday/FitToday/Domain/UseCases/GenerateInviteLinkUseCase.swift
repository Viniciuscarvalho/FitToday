//
//  GenerateInviteLinkUseCase.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - GenerateInviteLinkUseCase

struct GenerateInviteLinkUseCase: Sendable {
    // MARK: - Execute

    /// Generates an invite link for the given group ID.
    /// Returns both URL scheme format (for direct app open) and Universal Link format (for sharing).
    func execute(groupId: String) -> InviteLinks {
        let urlScheme = URL(string: "fittoday://group/invite/\(groupId)")!
        let universalLink = URL(string: "https://fittoday.app/group/invite/\(groupId)")!

        return InviteLinks(
            urlScheme: urlScheme,
            universalLink: universalLink
        )
    }
}

// MARK: - InviteLinks

struct InviteLinks: Sendable {
    /// Direct app URL scheme: fittoday://group/invite/{groupId}
    let urlScheme: URL

    /// Universal Link (HTTPS) for sharing: https://fittoday.app/group/invite/{groupId}
    let universalLink: URL

    /// Returns the universal link as the default sharing URL
    var shareURL: URL {
        universalLink
    }
}
