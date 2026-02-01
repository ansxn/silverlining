import SwiftUI

// MARK: - Storm Banner Component

struct StormBanner: View {
    let isActive: Bool
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        if isActive {
            HStack(spacing: 12) {
                Image(systemName: "cloud.bolt.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .symbolEffect(.pulse)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storm Mode Active")
                        .font(.stormBodyBold)
                        .foregroundColor(.white)
                    
                    Text("Community wellness checks in progress")
                        .font(.stormCaption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.stormActive, Color.stormBanner],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .onTapGesture {
                onTap?()
            }
        }
    }
}

// MARK: - Compact Storm Indicator

struct StormIndicator: View {
    let isActive: Bool
    
    var body: some View {
        if isActive {
            HStack(spacing: 6) {
                Image(systemName: "cloud.bolt.fill")
                    .font(.caption)
                Text("STORM")
                    .font(.stormFootnote)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.stormActive)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StormBanner(isActive: true)
        StormBanner(isActive: false)
        StormIndicator(isActive: true)
    }
    .padding()
    .background(Color.stormBackground)
}
