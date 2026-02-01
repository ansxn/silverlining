import SwiftUI
import Combine

// MARK: - Auth View Model
// Handles role switching for demo purposes

class AuthViewModel: ObservableObject {
    @Published var currentRole: UserRole = .clinicStaff
    @Published var isAuthenticated: Bool = true // Always true for demo
    @Published var isOnboarded: Bool = false // Show landing page first
    
    private let dataService = MockDataService.shared
    
    var currentUser: User {
        dataService.currentUser
    }
    
    var userName: String {
        dataService.currentUser.firstName
    }
    
    var userFullName: String {
        dataService.currentUser.fullName
    }
    
    // MARK: - Role Switching
    
    func switchRole(to role: UserRole) {
        currentRole = role
        dataService.switchRole(to: role)
    }
    
    // MARK: - Demo Actions
    
    func seedDemoData() {
        dataService.seedDemoData()
    }
}
