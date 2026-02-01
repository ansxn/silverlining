import SwiftUI

// MARK: - Content View (Root Navigation)

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var dataService = MockDataService.shared
    @State private var showRoleSwitcher = false
    @State private var showDemoActions = false
    
    var body: some View {
        Group {
            if !authViewModel.isOnboarded {
                // Show landing page first
                LandingPageView()
            } else {
                // Main app content
                ZStack(alignment: .bottom) {
                    // Main Content based on role
                    Group {
                        switch authViewModel.currentRole {
                        case .patient:
                            PatientHomeView()
                        case .volunteer:
                            VolunteerHomeView()
                        case .clinicStaff:
                            StaffDashboardView()
                        case .admin:
                            StaffDashboardView() // Admin uses same view for MVP
                        }
                    }
                    
                    // Bottom Navigation Bar
                    BottomNavBar(
                        currentRole: authViewModel.currentRole,
                        isStormMode: dataService.stormState.isStormMode,
                        onRoleTap: { showRoleSwitcher = true },
                        onDemoTap: { showDemoActions = true }
                    )
                }
                .sheet(isPresented: $showRoleSwitcher) {
                    RoleSwitcherView(
                        currentRole: authViewModel.currentRole,
                        onSelect: { role in
                            authViewModel.switchRole(to: role)
                            showRoleSwitcher = false
                        }
                    )
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showDemoActions) {
                    DemoActionsView(
                        onSeedData: {
                            authViewModel.seedDemoData()
                            showDemoActions = false
                        }
                    )
                    .presentationDetents([.height(300)])
                }
            }
        }
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavBar: View {
    let currentRole: UserRole
    let isStormMode: Bool
    var onRoleTap: () -> Void
    var onDemoTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Home (Role indicator)
            NavBarItem(
                icon: currentRole.icon,
                label: currentRole.displayName,
                isActive: true,
                action: onRoleTap
            )
            
            // Demo controls
            NavBarItem(
                icon: "slider.horizontal.3",
                label: "Demo",
                isActive: false,
                action: onDemoTap
            )
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(isStormMode ? Color.stormActive : Color.textPrimary)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 60)
        .padding(.bottom, 20)
    }
}

struct NavBarItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white.opacity(isActive ? 1 : 0.6))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Role Switcher View

struct RoleSwitcherView: View {
    let currentRole: UserRole
    var onSelect: (UserRole) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Switch Demo Role")
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
                .padding(.top, 20)
            
            Text("Select a role to see different app experiences")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
            
            VStack(spacing: 12) {
                ForEach([UserRole.patient, .volunteer, .clinicStaff], id: \.self) { role in
                    RoleOptionButton(
                        role: role,
                        isSelected: currentRole == role,
                        action: { onSelect(role) }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.stormBackground)
    }
}

struct RoleOptionButton: View {
    let role: UserRole
    let isSelected: Bool
    var action: () -> Void
    
    var roleColor: Color {
        switch role {
        case .patient: return .cardBlue
        case .volunteer: return .cardMint
        case .clinicStaff: return .cardLavender
        case .admin: return .cardSage
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(roleColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: role.icon)
                        .font(.title2)
                        .foregroundColor(roleColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.displayName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
                    Text(roleDescription(for: role))
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.statusOk)
                }
            }
            .padding(16)
            .background(isSelected ? roleColor.opacity(0.2) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? roleColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func roleDescription(for role: UserRole) -> String {
        switch role {
        case .patient: return "View referrals, request rides"
        case .volunteer: return "Accept and complete rides"
        case .clinicStaff: return "Dashboard, tasks, Storm Mode"
        case .admin: return "System administration"
        }
    }
}

// MARK: - Demo Actions View

struct DemoActionsView: View {
    var onSeedData: () -> Void
    @ObservedObject var dataService = MockDataService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Demo Controls")
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
                .padding(.top, 20)
            
            VStack(spacing: 12) {
                Button(action: onSeedData) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset Demo Data")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                HStack {
                    Text("Storm Mode:")
                        .font(.stormBody)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text(dataService.stormState.isStormMode ? "Active" : "Inactive")
                        .font(.stormBodyBold)
                        .foregroundColor(dataService.stormState.isStormMode ? .stormActive : .textLight)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.stormBackground)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
