import SwiftUI

// MARK: - Storm Check-In View
// Simple "I'm OK / I need help" prompt for patients during Storm Mode
// Reassurance during uncertainty - the system checks on them

struct StormCheckInView: View {
    @ObservedObject var dataService = MockDataService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResponse: CheckInResponse? = nil
    @State private var helpDetails: String = ""
    @State private var showConfirmation = false
    @State private var isSubmitting = false
    
    enum CheckInResponse {
        case imOkay
        case needHelp
    }
    
    var body: some View {
        ZStack {
            // Storm-themed background
            stormBackground
            
            VStack(spacing: 0) {
                // Header
                stormHeader
                
                Spacer()
                
                // Main content
                if showConfirmation {
                    confirmationView
                } else if selectedResponse == .needHelp {
                    helpDetailsView
                } else {
                    mainPromptView
                }
                
                Spacer()
                
                // Footer
                footerInfo
            }
        }
    }
    
    // MARK: - Storm Background
    
    private var stormBackground: some View {
        ZStack {
            // Dark gradient for storm feel
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle cloud pattern overlay
            VStack {
                HStack {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.03))
                        .offset(x: -20, y: 20)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.white.opacity(0.02))
                        .offset(x: 30, y: -40)
                }
            }
        }
    }
    
    // MARK: - Storm Header
    
    private var stormHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Storm mode indicator
                HStack(spacing: 6) {
                    Image(systemName: "cloud.bolt.fill")
                        .font(.caption)
                    Text("STORM MODE ACTIVE")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.stormActive)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.stormActive.opacity(0.2))
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Main title
            VStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.cardMint)
                
                Text("Storm Check-In")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("We're checking in to make sure you're safe")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Main Prompt View
    
    private var mainPromptView: some View {
        VStack(spacing: 24) {
            Text("How are you doing?")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            // I'm Okay button
            Button(action: { selectResponse(.imOkay) }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.statusOk.opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.statusOk)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I'm Okay")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Everything is fine, no help needed")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.statusOk.opacity(0.3), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            // I Need Help button
            Button(action: { selectResponse(.needHelp) }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.statusWarning.opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.statusWarning)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I Need Help")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("I need assistance or have concerns")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.statusWarning.opacity(0.3), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Help Details View
    
    private var helpDetailsView: some View {
        VStack(spacing: 24) {
            Text("What do you need?")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            // Quick options
            VStack(spacing: 12) {
                HelpOptionButton(
                    icon: "cross.vial.fill",
                    title: "Medication",
                    subtitle: "Need medication pickup or refill",
                    color: .cardMint,
                    action: { submitHelpRequest("Medication assistance needed") }
                )
                
                HelpOptionButton(
                    icon: "car.fill",
                    title: "Transportation",
                    subtitle: "Need a ride somewhere",
                    color: .cardBlue,
                    action: { submitHelpRequest("Transportation assistance needed") }
                )
                
                HelpOptionButton(
                    icon: "bag.fill",
                    title: "Supplies",
                    subtitle: "Need food, water, or essentials",
                    color: .cardYellow,
                    action: { submitHelpRequest("Supplies assistance needed") }
                )
                
                HelpOptionButton(
                    icon: "phone.fill",
                    title: "Someone to Talk To",
                    subtitle: "Feeling anxious or need support",
                    color: .cardLavender,
                    action: { submitHelpRequest("Emotional support needed") }
                )
                
                HelpOptionButton(
                    icon: "exclamationmark.triangle.fill",
                    title: "Emergency",
                    subtitle: "Urgent medical or safety issue",
                    color: .statusUrgent,
                    action: { submitHelpRequest("EMERGENCY: Urgent assistance needed") }
                )
            }
            
            // Back button
            Button(action: { selectedResponse = nil }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                    Text("Go Back")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Confirmation View
    
    private var confirmationView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.statusOk.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.statusOk)
            }
            .scaleEffect(showConfirmation ? 1.0 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showConfirmation)
            
            Text(selectedResponse == .imOkay ? "Great to hear!" : "Help is on the way!")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Text(selectedResponse == .imOkay ?
                 "Thank you for checking in. We're glad you're safe." :
                 "Someone from the clinic will reach out to you shortly.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardMint)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Footer Info
    
    private var footerInfo: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                Text("No response in 2 hours triggers a follow-up check")
                    .font(.system(size: 12))
            }
            .foregroundColor(.white.opacity(0.4))
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Actions
    
    private func selectResponse(_ response: CheckInResponse) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedResponse = response
            
            if response == .imOkay {
                submitOkayResponse()
            }
        }
    }
    
    private func submitOkayResponse() {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Record the check-in
            dataService.recordCheckIn(
                patientId: "patient_001", // Would be current user
                response: .ok,
                notes: nil
            )
            
            isSubmitting = false
            withAnimation {
                showConfirmation = true
            }
        }
    }
    
    private func submitHelpRequest(_ details: String) {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Record the check-in with need
            dataService.recordCheckIn(
                patientId: "patient_001",
                response: .needHelp,
                notes: details
            )
            
            isSubmitting = false
            withAnimation {
                showConfirmation = true
            }
        }
    }
}

// MARK: - Help Option Button

struct HelpOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    StormCheckInView()
}
