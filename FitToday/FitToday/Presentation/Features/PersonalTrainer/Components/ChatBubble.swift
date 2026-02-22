//
//  ChatBubble.swift
//  FitToday
//
//  Chat message bubble component for trainer-student communication.
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(isFromCurrentUser ? .white : FitTodayColor.textPrimary)
                    .padding(.horizontal, FitTodaySpacing.md)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? FitTodayColor.brandPrimary : FitTodayColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}
