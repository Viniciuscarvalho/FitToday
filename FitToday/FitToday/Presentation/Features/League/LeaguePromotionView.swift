//
//  LeaguePromotionView.swift
//  FitToday
//

import SwiftUI

/// Full-screen promotion celebration with confetti-like particle animation.
struct LeaguePromotionView: View {
    let tier: LeagueTier
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var particles: [(color: Color, size: CGFloat, offset: CGSize, opacity: Double)] = []

    var body: some View {
        ZStack {
            FitTodayColor.background.ignoresSafeArea()

            ForEach(particles.indices, id: \.self) { i in
                Circle()
                    .fill(particles[i].color)
                    .frame(width: particles[i].size, height: particles[i].size)
                    .offset(particles[i].offset)
                    .opacity(particles[i].opacity)
            }

            VStack(spacing: FitTodaySpacing.lg) {
                Spacer()
                LeagueTierBadge(tier: tier, size: .large)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                Text("league.promoted.title".localized)
                    .font(FitTodayFont.ui(size: 28, weight: .bold))
                    .foregroundStyle(FitTodayColor.success)
                    .opacity(showContent ? 1 : 0)
                Text(tier.displayName)
                    .font(FitTodayFont.ui(size: 20, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .opacity(showContent ? 1 : 0)
                Spacer()
                Button("league.promoted.dismiss".localized) { onDismiss() }
                    .fitSecondaryStyle()
                    .padding(.horizontal, FitTodaySpacing.xl)
                    .opacity(showContent ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            guard !reduceMotion else { showContent = true; return }
            generateParticles()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showContent = true }
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }

    private func generateParticles() {
        let colors: [Color] = [.green, .yellow, .orange, .mint, .cyan]
        particles = (0..<20).map { _ in
            (color: colors.randomElement() ?? .green,
             size: CGFloat.random(in: 6...14),
             offset: CGSize(width: .random(in: -180...180), height: .random(in: -300...300)),
             opacity: Double.random(in: 0.4...0.9))
        }
    }
}
