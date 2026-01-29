//
//  CelebrationOverlay.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import SwiftUI

// MARK: - CelebrationType

/// Types of celebration moments in the app.
enum CelebrationType {
    case checkInComplete
    case rankUp(newRank: Int)
    case topThree
}

// MARK: - CelebrationOverlay

/// Animated overlay for celebration moments with confetti and messaging.
struct CelebrationOverlay: View {
    let type: CelebrationType
    @State private var isAnimating = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Confetti
            ConfettiView(isAnimating: $isAnimating)

            // Content
            VStack(spacing: FitTodaySpacing.lg) {
                Image(systemName: iconName)
                    .font(.system(size: 72))
                    .foregroundStyle(iconColor)
                    .scaleEffect(showContent ? 1 : 0.5)

                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showContent = true
            }
        }
    }

    private var iconName: String {
        switch type {
        case .checkInComplete: return "checkmark.circle.fill"
        case .rankUp: return "arrow.up.circle.fill"
        case .topThree: return "trophy.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .checkInComplete: return .green
        case .rankUp: return .blue
        case .topThree: return .yellow
        }
    }

    private var title: String {
        switch type {
        case .checkInComplete: return "Check-in Feito!"
        case .rankUp(let rank): return "Você subiu para #\(rank)!"
        case .topThree: return "Top 3!"
        }
    }

    private var subtitle: String {
        switch type {
        case .checkInComplete: return "Seu treino foi registrado"
        case .rankUp: return "Continue assim!"
        case .topThree: return "Você está entre os melhores!"
        }
    }
}

// MARK: - ConfettiView

/// Animated confetti particles falling from the top.
struct ConfettiView: View {
    @Binding var isAnimating: Bool

    private let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        size: geo.size,
                        isAnimating: isAnimating,
                        delay: Double(index) * 0.02
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - ConfettiPiece

/// A single animated confetti particle.
struct ConfettiPiece: View {
    let color: Color
    let size: CGSize
    let isAnimating: Bool
    let delay: Double

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    @State private var scale: Double = 1

    private let pieceWidth: CGFloat = 10
    private let pieceHeight: CGFloat = 6

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: pieceWidth, height: pieceHeight)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .position(position)
            .opacity(opacity)
            .onAppear {
                // Random starting position at top
                position = CGPoint(
                    x: CGFloat.random(in: pieceWidth...size.width - pieceWidth),
                    y: -20
                )
                rotation = Double.random(in: 0...360)

                animate()
            }
    }

    private func animate() {
        guard isAnimating else { return }

        let targetX = position.x + CGFloat.random(in: -100...100)
        let targetY = size.height + 50

        withAnimation(
            .easeOut(duration: Double.random(in: 2.5...3.5))
            .delay(delay)
        ) {
            position = CGPoint(x: targetX, y: targetY)
            rotation += Double.random(in: 360...1080)
            opacity = 0
        }
    }
}
