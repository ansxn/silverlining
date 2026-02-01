import SwiftUI

// MARK: - Landing Page View
// Premium onboarding experience with role selection

struct LandingPageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedRole: UserRole?
    @State private var animateIn = false
    @State private var showRoleCards = false
    
    var body: some View {
        ZStack {
            // Animated background
            LandingBackground()
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and branding
                VStack(spacing: 16) {
                    // App icon with glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.stormActive.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, Color.stormBackground],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.cardMint.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            // Silver lining through clouds
                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.cardMint, Color.cardBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)
                    
                    // App name
                    VStack(spacing: 8) {
                        Text("Silver Lining")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Every storm has one")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.cardMint)
                            .italic()
                        
                        Text("Community care when you need it most")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                }
                .padding(.bottom, 50)
                
                Spacer()
                
                // Role selection cards
                VStack(spacing: 16) {
                    Text("Continue as")
                        .font(.stormCaptionBold)
                        .foregroundColor(.textLight)
                        .opacity(showRoleCards ? 1 : 0)
                    
                    VStack(spacing: 12) {
                        RoleLoginCard(
                            role: .patient,
                            title: "Patient",
                            subtitle: "View appointments & request rides",
                            icon: "person.fill",
                            color: .cardBlue,
                            delay: 0.0,
                            isVisible: showRoleCards
                        ) {
                            selectRole(.patient)
                        }
                        
                        RoleLoginCard(
                            role: .volunteer,
                            title: "Volunteer",
                            subtitle: "Accept missions & help neighbors",
                            icon: "car.fill",
                            color: .cardMint,
                            delay: 0.1,
                            isVisible: showRoleCards
                        ) {
                            selectRole(.volunteer)
                        }
                        
                        RoleLoginCard(
                            role: .clinicStaff,
                            title: "Care Coordinator",
                            subtitle: "Dashboard, Storm Mode & automation",
                            icon: "stethoscope",
                            color: .cardLavender,
                            delay: 0.2,
                            isVisible: showRoleCards
                        ) {
                            selectRole(.clinicStaff)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                
                // Footer
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cardCoral.opacity(0.7))
                        Text("Volunteers ready to help")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textLight)
                    }
                    
                    Text("Silver Lining Health")
                        .font(.system(size: 10))
                        .foregroundColor(.textLight.opacity(0.6))
                }
                .opacity(showRoleCards ? 1 : 0)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateIn = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
                showRoleCards = true
            }
        }
    }
    
    private func selectRole(_ role: UserRole) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        selectedRole = role
        authViewModel.switchRole(to: role)
        authViewModel.isOnboarded = true
    }
}

// MARK: - Landing Background

struct LandingBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "E8F4F8"),
                    Color(hex: "F0F7FA"),
                    Color(hex: "F8FBFC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating orbs
            GeometryReader { geo in
                // Large pastel orb - top right
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cardLavender.opacity(0.4), Color.cardLavender.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width * 0.5, y: -50)
                    .offset(y: animate ? 20 : -20)
                
                // Medium mint orb - left
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cardMint.opacity(0.3), Color.cardMint.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: -80, y: geo.size.height * 0.4)
                    .offset(x: animate ? 10 : -10)
                
                // Small blue orb - bottom right
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cardBlue.opacity(0.25), Color.cardBlue.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .offset(x: geo.size.width * 0.7, y: geo.size.height * 0.7)
                    .offset(y: animate ? -15 : 15)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Role Login Card

struct RoleLoginCard: View {
    let role: UserRole
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let delay: Double
    let isVisible: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(color.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: color.opacity(0.15), radius: 15, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: isVisible)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    LandingPageView()
        .environmentObject(AuthViewModel())
}
