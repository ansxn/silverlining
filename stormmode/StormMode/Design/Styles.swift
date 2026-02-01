import SwiftUI

// MARK: - Card Styles

struct StormCardStyle: ViewModifier {
    var backgroundColor: Color = .stormBackground
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor.opacity(0.95))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
    }
}

struct GlassCardStyle: ViewModifier {
    var tint: Color = .stormBackground
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tint.opacity(0.3))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
    }
}

struct ColoredCardStyle: ViewModifier {
    var color: Color
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.stormBodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDisabled ? Color.textLight : 
                    (configuration.isPressed ? Color.stormActive.opacity(0.8) : Color.stormActive))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.stormBodyBold)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.stormBackground.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.textLight.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StormModeButtonStyle: ButtonStyle {
    var isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.stormBodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? Color.stormActive : Color.stormActive.opacity(0.9))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func stormCard(color: Color = .stormBackground, cornerRadius: CGFloat = 24) -> some View {
        modifier(StormCardStyle(backgroundColor: color, cornerRadius: cornerRadius))
    }
    
    func glassCard(tint: Color = .stormBackground, cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCardStyle(tint: tint, cornerRadius: cornerRadius))
    }
    
    func coloredCard(_ color: Color, cornerRadius: CGFloat = 24) -> some View {
        modifier(ColoredCardStyle(color: color, cornerRadius: cornerRadius))
    }
}

// MARK: - Status Pill Modifier

struct StatusPillStyle: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.stormCaptionBold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

extension View {
    func statusPill(color: Color) -> some View {
        modifier(StatusPillStyle(color: color))
    }
}

// MARK: - Shadow Styles

extension View {
    func softShadow() -> some View {
        self.shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
    
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

