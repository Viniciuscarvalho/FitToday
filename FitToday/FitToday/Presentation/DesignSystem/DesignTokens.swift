//
//  DesignTokens.swift
//  FitToday
//
//  Design System inspirado no Gym App UI Kit (ui8.net)
//  Tema Dark Mode completo com cores vibrantes de fitness
//

import SwiftUI

// MARK: - Color System (Dark Theme - Gym App Style)

enum FitTodayColor {
    // Cores de marca - Verde/Lime neon típico de apps de fitness
    static let brandPrimary = Color(hex: "#A8FF00")  // Lime neon vibrante
    static let brandSecondary = Color(hex: "#FF6B35")  // Laranja energético
    static let brandAccent = Color(hex: "#7B61FF")  // Roxo para destaques
    
    // Backgrounds - Dark theme
    static let background = Color(hex: "#0A0A0A")  // Preto profundo
    static let backgroundElevated = Color(hex: "#141414")  // Elevação leve
    static let surface = Color(hex: "#1C1C1E")  // Cards e superfícies
    static let surfaceElevated = Color(hex: "#2C2C2E")  // Cards elevados
    
    // Texto
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#A1A1A1")  // Cinza claro
    static let textTertiary = Color(hex: "#6B6B6B")  // Cinza médio
    static let textInverse = Color(hex: "#0A0A0A")  // Para botões com fundo claro
    
    // Separadores e bordas
    static let outline = Color(hex: "#2D2D2D")
    static let outlineVariant = Color(hex: "#404040")
    
    // Status colors
    static let success = Color(hex: "#34C759")  // Verde Apple
    static let warning = Color(hex: "#FF9500")  // Laranja Apple
    static let error = Color(hex: "#FF3B30")  // Vermelho Apple
    static let info = Color(hex: "#5AC8FA")  // Azul claro
    
    // Gradientes
    static let gradientPrimary = LinearGradient(
        colors: [brandPrimary, Color(hex: "#8BDD00")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientSecondary = LinearGradient(
        colors: [brandSecondary, Color(hex: "#FF8C5A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientPro = LinearGradient(
        colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientBackground = LinearGradient(
        colors: [background, Color(hex: "#121212")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing System (8pt Grid)

enum FitTodaySpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Border Radius

enum FitTodayRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let pill: CGFloat = 999
}

// MARK: - Typography (SF Pro)

enum FitTodayTypography {
    static func largeTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(FitTodayColor.textPrimary)
    }
    
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(FitTodayColor.textPrimary)
    }
    
    static func title2(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(FitTodayColor.textPrimary)
    }
    
    static func heading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func subheading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(FitTodayColor.textSecondary)
    }
    
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17))
            .foregroundStyle(FitTodayColor.textPrimary)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(FitTodayColor.textTertiary)
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica sombra suave usada em cards principais (estilo dark mode).
    func fitCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    /// Sombra mais sutil para elementos menores.
    func fitSubtleShadow() -> some View {
        shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    /// Aplica borda sutil para cards em dark mode.
    func fitCardBorder() -> some View {
        overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline, lineWidth: 1)
        )
    }
    
    /// Glow effect para elementos de destaque.
    func fitGlowEffect(color: Color = FitTodayColor.brandPrimary) -> some View {
        shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 0)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
