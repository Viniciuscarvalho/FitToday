//
//  HomeHeader.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//  Redesigned on 29/01/26 - Simplified greeting design
//

import SwiftUI

struct HomeHeader: View {
    let greeting: String
    let dateFormatted: String
    let isPro: Bool
    let goalBadgeText: String?
    var userName: String?
    var userPhotoURL: URL?
    var onNotificationTap: (() -> Void)?

    // Computed: first name only for display (nil when no user name)
    private var displayName: String? {
        guard let name = userName, !name.isEmpty else { return nil }
        return name.components(separatedBy: " ").first ?? name
    }

    // Greeting text with name and emoji
    private var greetingWithName: String {
        if let name = displayName {
            return "\(greeting), \(name)! 👋"
        }
        return "\(greeting)! 👋"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text(greetingWithName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("home.header.subtitle".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }
}
