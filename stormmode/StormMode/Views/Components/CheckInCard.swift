import SwiftUI

// MARK: - Check-In Card Component

struct CheckInCard: View {
    let checkIn: CheckIn
    var patientName: String
    var onSimulateOk: (() -> Void)? = nil
    var onSimulateNeedHelp: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(checkIn.status.emoji)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(patientName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: checkIn.channel.icon)
                            .font(.caption2)
                        Text("via \(checkIn.channel.displayName)")
                            .font(.stormCaption)
                    }
                    .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                CheckInStatusBadge(status: checkIn.status)
            }
            
            // Response time
            if let minutes = checkIn.responseTimeMinutes {
                Text("Responded in \(minutes) min")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
            }
            
            // Simulation buttons (for demo)
            if checkIn.status == .pending {
                HStack(spacing: 12) {
                    Button(action: { onSimulateOk?() }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Simulate OK")
                        }
                        .font(.stormCaptionBold)
                        .foregroundColor(.statusOk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.statusOk.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: { onSimulateNeedHelp?() }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Simulate Help")
                        }
                        .font(.stormCaptionBold)
                        .foregroundColor(.statusUrgent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.statusUrgent.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(checkIn.status == .needHelp ? Color.statusUrgent.opacity(0.15) : Color.stormBackground.opacity(0.95))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(checkIn.status == .needHelp ? Color.statusUrgent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Check-In Status Badge

struct CheckInStatusBadge: View {
    let status: CheckInStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayName)
                .font(.stormFootnote)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color)
        .cornerRadius(10)
    }
}

// MARK: - Check-In Summary

struct CheckInSummary: View {
    let total: Int
    let responded: Int
    let needHelp: Int
    let noReply: Int
    
    var responseRate: Double {
        guard total > 0 else { return 0 }
        return Double(responded) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Storm Check-Ins")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(responded)/\(total)")
                    .font(.stormCaptionBold)
                    .foregroundColor(.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    // OK responses
                    Rectangle()
                        .fill(Color.statusOk)
                        .frame(width: geo.size.width * (Double(responded - needHelp) / Double(max(total, 1))))
                    
                    // Need help
                    Rectangle()
                        .fill(Color.statusUrgent)
                        .frame(width: geo.size.width * (Double(needHelp) / Double(max(total, 1))))
                    
                    // No reply
                    Rectangle()
                        .fill(Color.textLight)
                        .frame(width: geo.size.width * (Double(noReply) / Double(max(total, 1))))
                    
                    // Pending
                    Rectangle()
                        .fill(Color.textLight.opacity(0.3))
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .statusOk, label: "OK")
                LegendItem(color: .statusUrgent, label: "Need Help")
                LegendItem(color: .textLight, label: "No Reply")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardCoral.opacity(0.85))
                .shadow(color: Color.cardCoral.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.stormFootnote)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CheckInSummary(total: 10, responded: 6, needHelp: 1, noReply: 2)
        
        CheckInCard(
            checkIn: CheckIn(
                id: "1",
                patientId: "p1",
                stormSessionId: "storm-001",
                status: .pending,
                channel: .sms,
                receivedAt: nil,
                sentAt: Date(),
                responseMessage: nil
            ),
            patientName: "Mary Thompson"
        )
        
        CheckInCard(
            checkIn: CheckIn(
                id: "2",
                patientId: "p2",
                stormSessionId: "storm-001",
                status: .needHelp,
                channel: .sms,
                receivedAt: Date(),
                sentAt: Date().addingTimeInterval(-300),
                responseMessage: "2"
            ),
            patientName: "Robert Chen"
        )
    }
    .padding()
    .background(Color.stormBackground)
}
