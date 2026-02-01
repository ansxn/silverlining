import Foundation

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
