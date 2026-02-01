import Foundation
import SwiftUI

// MARK: - User Model

struct User: Identifiable, Codable {
    let id: String
    var role: UserRole
    var fullName: String
    var phone: String
    var email: String?
    var createdAt: Date
    var isVulnerable: Bool
    var contactPreference: ContactPreference
    var address: String?
    var emergencyContact: String?
    
    // Computed properties
    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable {
    case patient = "patient"
    case volunteer = "volunteer"
    case clinicStaff = "clinic_staff"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .patient: return "Patient"
        case .volunteer: return "Volunteer Driver"
        case .clinicStaff: return "Clinic Staff"
        case .admin: return "Admin"
        }
    }
    
    var icon: String {
        switch self {
        case .patient: return "person.fill"
        case .volunteer: return "car.fill"
        case .clinicStaff: return "stethoscope"
        case .admin: return "gearshape.fill"
        }
    }
}

// MARK: - Contact Preference

enum ContactPreference: String, Codable, CaseIterable {
    case sms = "sms"
    case app = "app"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .sms: return "SMS"
        case .app: return "App Only"
        case .both: return "Both"
        }
    }
}

// MARK: - Volunteer Availability

enum VolunteerAvailability: String, Codable, CaseIterable {
    case available = "available"
    case unavailable = "unavailable"
    case onMission = "on_mission"
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .unavailable: return "Unavailable"
        case .onMission: return "On a Mission"
        }
    }
    
    var color: Color {
        switch self {
        case .available: return .statusOk
        case .unavailable: return .textLight
        case .onMission: return .stormActive
        }
    }
    
    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .unavailable: return "moon.fill"
        case .onMission: return "car.fill"
        }
    }
}

// MARK: - Volunteer Tier (Trusted Responder Network)

enum VolunteerTier: String, Codable, CaseIterable {
    case generalHelper = "general_helper"
    case trustedResponder = "trusted_responder"
    
    var displayName: String {
        switch self {
        case .generalHelper: return "General Helper"
        case .trustedResponder: return "Trusted Responder"
        }
    }
    
    var badge: String {
        switch self {
        case .generalHelper: return "🤝"
        case .trustedResponder: return "⭐️"
        }
    }
    
    var color: Color {
        switch self {
        case .generalHelper: return .cardBlue
        case .trustedResponder: return .cardYellow
        }
    }
    
    var description: String {
        switch self {
        case .generalHelper: return "Can accept standard transport and delivery missions"
        case .trustedResponder: return "Verified for welfare checks and sensitive missions"
        }
    }
}

// MARK: - Volunteer Model

struct Volunteer: Identifiable, Codable {
    let id: String
    var userId: String
    var fullName: String
    var phone: String
    var zone: String                           // e.g., "North", "Downtown", "East Side"
    var tier: VolunteerTier
    var availability: VolunteerAvailability
    var completedMissions: Int
    var acceptedMissions: Int
    var preferredDriverId: String?             // Patient's preferred driver
    
    // Computed reliability score (0.0 - 1.0)
    var reliabilityScore: Double {
        guard acceptedMissions > 0 else { return 1.0 }
        return min(Double(completedMissions) / Double(acceptedMissions), 1.0)
    }
    
    var reliabilityPercent: Int {
        Int(reliabilityScore * 100)
    }
    
    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
    
    // Check if volunteer can accept a mission based on tier
    func canAccept(missionType: TransportType) -> Bool {
        switch missionType {
        case .stormCheckIn:
            // Welfare checks require trusted tier
            return tier == .trustedResponder
        default:
            return true
        }
    }
}

// MARK: - Sample Volunteers

extension Volunteer {
    static let sampleVolunteers: [Volunteer] = [
        Volunteer(
            id: "vol-001",
            userId: "volunteer-001",
            fullName: "John Wilson",
            phone: "+1234567892",
            zone: "Downtown",
            tier: .trustedResponder,
            availability: .available,
            completedMissions: 47,
            acceptedMissions: 50
        ),
        Volunteer(
            id: "vol-002",
            userId: "volunteer-002",
            fullName: "Sarah Miller",
            phone: "+1234567894",
            zone: "North Side",
            tier: .generalHelper,
            availability: .available,
            completedMissions: 12,
            acceptedMissions: 14
        ),
        Volunteer(
            id: "vol-003",
            userId: "volunteer-003",
            fullName: "Mike Chen",
            phone: "+1234567895",
            zone: "East Side",
            tier: .trustedResponder,
            availability: .available,
            completedMissions: 89,
            acceptedMissions: 92
        ),
        Volunteer(
            id: "vol-004",
            userId: "volunteer-004",
            fullName: "Emily Davis",
            phone: "+1234567896",
            zone: "Downtown",
            tier: .generalHelper,
            availability: .unavailable,
            completedMissions: 5,
            acceptedMissions: 6
        ),
        Volunteer(
            id: "vol-005",
            userId: "volunteer-005",
            fullName: "Carlos Rodriguez",
            phone: "+1234567897",
            zone: "South Side",
            tier: .trustedResponder,
            availability: .available,
            completedMissions: 156,
            acceptedMissions: 160
        )
    ]
}

// MARK: - Sample Users Extension

extension User {
    static let samplePatient = User(
        id: "patient-001",
        role: .patient,
        fullName: "Mary Thompson",
        phone: "+1234567890",
        email: "mary@example.com",
        createdAt: Date(),
        isVulnerable: true,
        contactPreference: .sms,
        address: "123 Pine Street, Clearwater Ridge",
        emergencyContact: "+1234567891"
    )
    
    static let sampleVolunteer = User(
        id: "volunteer-001",
        role: .volunteer,
        fullName: "John Wilson",
        phone: "+1234567892",
        email: nil,
        createdAt: Date(),
        isVulnerable: false,
        contactPreference: .app,
        address: "456 Oak Road"
    )
    
    static let sampleStaff = User(
        id: "staff-001",
        role: .clinicStaff,
        fullName: "Nurse Sarah Chen",
        phone: "+1234567893",
        email: "sarah@clinic.com",
        createdAt: Date(),
        isVulnerable: false,
        contactPreference: .both
    )
}
