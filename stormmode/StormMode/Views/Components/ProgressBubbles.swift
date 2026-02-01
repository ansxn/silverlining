import SwiftUI

// MARK: - Progress Bubbles Component
// Inspired by the UI reference - circular bubble grid

struct ProgressBubbles: View {
    let progress: Double // 0.0 to 1.0
    let totalBubbles: Int = 20
    let columns: Int = 5
    
    private var filledCount: Int {
        Int(Double(totalBubbles) * min(max(progress, 0), 1))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            let rows = totalBubbles / columns
            
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        Circle()
                            .fill(index < filledCount ? Color.cardMint : Color.cardMint.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }
}

// MARK: - Progress Ring Component

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Large Progress Display

struct ProgressDisplay: View {
    let percentage: Int
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(percentage)")
                    .font(.stormStatLarge)
                    .foregroundColor(.textPrimary)
                
                Text("%")
                    .font(.stormTitle2)
                    .foregroundColor(.textPrimary)
            }
            
            Text(subtitle)
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title row with icon
            HStack(alignment: .center, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: true, vertical: false)
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            Spacer()
            
            // Large value at bottom
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.15))
        )
    }

}

// MARK: - Dashboard Metric Card

struct MetricCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.stormTitle2)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Text(title)
                    .font(.stormCaptionBold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.stormFootnote)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(minHeight: 120)
            .background(color.opacity(0.2))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ProgressBubbles(progress: 0.65)
            
            HStack {
                ProgressDisplay(percentage: 89, subtitle: "Of the weekly plan completed")
                Spacer()
                ProgressRing(progress: 0.89, color: .statusOk)
            }
            .stormCard()
            
            HStack(spacing: 12) {
                StatCard(title: "Referrals", value: "12", icon: "doc.text.fill", color: .cardBlue)
                StatCard(title: "Completed", value: "8", icon: "checkmark.circle.fill", color: .statusOk)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(title: "Overdue Referrals", count: 3, icon: "exclamationmark.circle.fill", color: .statusUrgent)
                MetricCard(title: "Open Tasks", count: 5, icon: "checklist", color: .cardBlue)
            }
        }
        .padding()
    }
    .background(Color.stormBackground)
}
