import SwiftUI

// MARK: - Referral Detail View

struct ReferralDetailView: View {
    let referral: Referral
    @StateObject private var viewModel = PatientViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmAttended = false
    @State private var showRequestReschedule = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    progressRingCard
                    appointmentCard
                    StatusTimeline(currentStatus: referral.status)
                    actionButtons
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("Referral Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Confirm Attendance", isPresented: $showConfirmAttended) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") {
                    viewModel.confirmAttendance(referralId: referral.id)
                    dismiss()
                }
            } message: {
                Text("Please confirm that you attended your \(referral.referralType.displayName) appointment.")
            }
            .alert("Request Reschedule", isPresented: $showRequestReschedule) {
                Button("Cancel", role: .cancel) {}
                Button("Request") {
                    viewModel.requestReschedule(referralId: referral.id)
                    dismiss()
                }
            } message: {
                Text("The clinic will contact you to reschedule your appointment.")
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        let typeColor = referral.referralType.color
        let typeIcon = referral.referralType.icon
        let typeName = referral.referralType.displayName
        
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: typeIcon)
                    .font(.largeTitle)
                    .foregroundColor(typeColor)
            }
            
            Text(typeName)
                .font(.stormTitle2)
                .foregroundColor(.textPrimary)
            
            StatusPill(status: referral.status)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(typeColor.opacity(0.2))
        .cornerRadius(24)
    }
    
    // MARK: - Progress Ring Card
    
    private var progressRingCard: some View {
        let progressValue = referral.status.progressValue
        let statusColor = referral.status.color
        let statusText = referral.status.isTerminal ? "Complete" : "In Progress"
        
        return VStack(spacing: 16) {
            Text("Referral Progress")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            ProgressRing(
                progress: progressValue,
                color: statusColor,
                size: 120
            )
            
            Text(statusText)
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
    
    // MARK: - Appointment Card
    
    @ViewBuilder
    private var appointmentCard: some View {
        if let date = referral.appointmentDateTime {
            AppointmentCardContent(date: date, daysUntil: referral.daysUntilAppointment)
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        let showActions = !referral.status.isTerminal && referral.appointmentDateTime != nil
        
        if showActions {
            VStack(spacing: 12) {
                Button(action: { showConfirmAttended = true }) {
                    Text("Confirm I Attended")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: { showRequestReschedule = true }) {
                    Text("Request Reschedule")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Appointment Card Content

struct AppointmentCardContent: View {
    let date: Date
    let daysUntil: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appointment")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.cardBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.stormBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(formattedTime)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                daysBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .cardShadow()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private var daysBadge: some View {
        if let days = daysUntil, days >= 0 {
            let badgeText = days == 0 ? "Today" : "\(days) days"
            let badgeColor: Color = days <= 1 ? .statusWarning : .cardBlue
            
            Text(badgeText)
                .font(.stormCaptionBold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(badgeColor)
                .cornerRadius(12)
        }
    }
}

// MARK: - Status Timeline

struct StatusTimeline: View {
    let currentStatus: ReferralStatus
    
    private let statuses: [ReferralStatus] = [
        .created, .scheduled, .reminded, .attended, .closed
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Status Timeline")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
                .padding(.bottom, 16)
            
            ForEach(Array(statuses.enumerated()), id: \.element) { index, status in
                TimelineRow(
                    status: status,
                    isReached: isReached(status),
                    isCurrent: isCurrent(status),
                    showConnector: index < statuses.count - 1,
                    nextReached: index < statuses.count - 1 ? isReached(statuses[index + 1]) : false
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .cardShadow()
    }
    
    private func isReached(_ status: ReferralStatus) -> Bool {
        status.progressValue <= currentStatus.progressValue
    }
    
    private func isCurrent(_ status: ReferralStatus) -> Bool {
        status == currentStatus
    }
}

// MARK: - Timeline Row

struct TimelineRow: View {
    let status: ReferralStatus
    let isReached: Bool
    let isCurrent: Bool
    let showConnector: Bool
    let nextReached: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                circleIndicator
                
                if showConnector {
                    connectorLine
                }
            }
            
            statusText
            
            Spacer()
        }
    }
    
    private var circleIndicator: some View {
        let fillColor: Color = isReached ? status.color : Color.textLight.opacity(0.3)
        let iconName = isReached ? status.icon : "circle"
        let iconColor: Color = isReached ? .white : .textLight
        
        return ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 32, height: 32)
            
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
        }
    }
    
    private var connectorLine: some View {
        let lineColor: Color = nextReached ? .statusOk : Color.textLight.opacity(0.3)
        
        return Rectangle()
            .fill(lineColor)
            .frame(width: 2, height: 40)
    }
    
    private var statusText: some View {
        let textColor: Color = isReached ? .textPrimary : .textLight
        
        return VStack(alignment: .leading, spacing: 2) {
            Text(status.displayName)
                .font(.stormBodyBold)
                .foregroundColor(textColor)
            
            if isCurrent {
                Text("Current")
                    .font(.stormCaption)
                    .foregroundColor(.statusOk)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    ReferralDetailView(
        referral: Referral(
            id: "1",
            patientId: "p1",
            createdBy: "s1",
            referralType: .cardiology,
            priority: .high,
            status: .scheduled,
            appointmentDateTime: Date().addingTimeInterval(86400 * 3),
            followUpDueAt: nil,
            notesClinicOnly: nil,
            lastStatusUpdateAt: Date(),
            stormSensitive: true,
            linkedTransportRequestId: nil,
            createdAt: Date()
        )
    )
}
