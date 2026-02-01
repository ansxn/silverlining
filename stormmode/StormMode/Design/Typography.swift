import SwiftUI

// MARK: - StormMode Typography
// Clean, friendly typeface hierarchy

extension Font {
    // MARK: - Display
    static let stormLargeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let stormTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let stormTitle2 = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let stormTitle3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // MARK: - Headlines
    static let stormHeadline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let stormSubheadline = Font.system(size: 16, weight: .medium, design: .rounded)
    
    // MARK: - Body
    static let stormBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let stormBodyBold = Font.system(size: 16, weight: .semibold, design: .rounded)
    
    // MARK: - Supporting
    static let stormCaption = Font.system(size: 14, weight: .regular, design: .rounded)
    static let stormCaptionBold = Font.system(size: 14, weight: .medium, design: .rounded)
    static let stormFootnote = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // MARK: - Stats/Numbers
    static let stormStatLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let stormStatMedium = Font.system(size: 36, weight: .bold, design: .rounded)
}

// MARK: - Text Style Modifiers
struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.stormTitle)
            .foregroundColor(.textPrimary)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.stormHeadline)
            .foregroundColor(.textPrimary)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.stormBody)
            .foregroundColor(.textSecondary)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.stormCaption)
            .foregroundColor(.textLight)
    }
}

// MARK: - View Extensions
extension View {
    func titleStyle() -> some View {
        modifier(TitleStyle())
    }
    
    func headlineStyle() -> some View {
        modifier(HeadlineStyle())
    }
    
    func bodyStyle() -> some View {
        modifier(BodyStyle())
    }
    
    func captionStyle() -> some View {
        modifier(CaptionStyle())
    }
}
