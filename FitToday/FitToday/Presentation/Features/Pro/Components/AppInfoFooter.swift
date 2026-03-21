//
//  AppInfoFooter.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Footer com informações do app (versão + links legais)
// Componente extraído para manter a view principal < 100 linhas
struct AppInfoFooter: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Text("FitToday v\(appVersion)")
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)

            HStack(spacing: FitTodaySpacing.md) {
                Link("Termos", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("•")
                Link("Privacidade", destination: URL(string: "https://fittoday.app/privacy")!)
            }
            .font(.system(.caption))
            .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .padding(.top, FitTodaySpacing.lg)
    }
}
