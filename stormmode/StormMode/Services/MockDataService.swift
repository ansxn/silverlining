import Foundation
import SwiftUI

// MARK: - Mock Data Service
// Provides sample data for demo purposes

class MockDataService: ObservableObject {
    static let shared = MockDataService()
    
    // MARK: - Published Data
    @Published var currentUser: User
    @Published var users: [User]
    @Published var referrals: [Referral]
    @Published var requests: [TransportRequest]
    @Published var tasks: [StormTask]
    @Published var checkIns: [CheckIn]
    @Published var stormState: StormState
    
    // Demo mode for role switching
    @Published var demoRole: UserRole = .clinicStaff
    
    private init() {
        // Initialize with sample data
        self.users = Self.generateUsers()
        self.referrals = Self.generateReferrals()
        self.requests = Self.generateRequests()
        self.tasks = Self.generateTasks()
        self.checkIns = []
        self.stormState = .default
        self.currentUser = Self.generateUsers().first(where: { $0.role == .clinicStaff }) ?? User.sampleStaff
    }
    
    // MARK: - Role Switching for Demo
    
    func switchRole(to role: UserRole) {
        demoRole = role
        if let user = users.first(where: { $0.role == role }) {
            currentUser = user
        }
    }
    
    // MARK: - Storm Mode Actions
    
    func activateStormMode() {
        stormState.isStormMode = true
        stormState.activatedAt = Date()
        stormState.activatedBy = currentUser.id
        
        // Generate check-in tasks for vulnerable patients
        let vulnerablePatients = users.filter { $0.isVulnerable && $0.role == .patient }
        
        for patient in vulnerablePatients {
            // Create storm check-in task
            let task = StormTask(
                id: UUID().uuidString,
                type: .stormCheckIn,
                patientId: patient.id,
                linkedReferralId: nil,
                linkedRequestId: nil,
                status: .open,
                priority: .high,
                assignedTo: currentUser.id,
                createdAt: Date(),
                dueAt: Date().addingTimeInterval(3600), // 1 hour
                completedAt: nil,
                notes: "Storm check-in for \(patient.fullName)"
            )
            tasks.append(task)
            
            // Create pending check-in record
            let checkIn = CheckIn(
                id: UUID().uuidString,
                patientId: patient.id,
                stormSessionId: stormState.activatedAt?.ISO8601Format() ?? UUID().uuidString,
                status: .pending,
                channel: patient.contactPreference == .app ? .app : .sms,
                receivedAt: nil,
                sentAt: Date(),
                responseMessage: nil
            )
            checkIns.append(checkIn)
        }
        
        // Flag upcoming appointments as storm_at_risk
        let lookaheadDate = Calendar.current.date(byAdding: .day, value: stormState.rules.daysLookahead, to: Date()) ?? Date()
        
        for i in 0..<referrals.count {
            if let appointmentDate = referrals[i].appointmentDateTime,
               appointmentDate <= lookaheadDate,
               appointmentDate > Date(),
               referrals[i].stormSensitive {
                referrals[i].status = .stormAtRisk
                
                // Create reschedule task
                let rescheduleTask = StormTask(
                    id: UUID().uuidString,
                    type: .rescheduleReferral,
                    patientId: referrals[i].patientId,
                    linkedReferralId: referrals[i].id,
                    linkedRequestId: nil,
                    status: .open,
                    priority: referrals[i].priority,
                    assignedTo: currentUser.id,
                    createdAt: Date(),
                    dueAt: Date().addingTimeInterval(7200),
                    completedAt: nil,
                    notes: "Reschedule due to storm"
                )
                tasks.append(rescheduleTask)
            }
        }
    }
    
    func deactivateStormMode() {
        stormState.isStormMode = false
        stormState.deactivatedAt = Date()
    }
    
    // MARK: - Simulate Check-In Response
    
    func simulateCheckInResponse(checkInId: String, status: CheckInStatus) {
        if let index = checkIns.firstIndex(where: { $0.id == checkInId }) {
            checkIns[index].status = status
            checkIns[index].receivedAt = Date()
            
            // If needs help, create urgent call task
            if status == .needHelp {
                let checkIn = checkIns[index]
                let urgentTask = StormTask(
                    id: UUID().uuidString,
                    type: .callPatient,
                    patientId: checkIn.patientId,
                    linkedReferralId: nil,
                    linkedRequestId: nil,
                    status: .open,
                    priority: .high,
                    assignedTo: currentUser.id,
                    createdAt: Date(),
                    dueAt: Date().addingTimeInterval(900), // 15 minutes
                    completedAt: nil,
                    notes: "URGENT: Storm check-in - patient needs help"
                )
                tasks.append(urgentTask)
            }
        }
    }
    
    // MARK: - Referral Actions
    
    func createReferral(_ referral: Referral) {
        var newReferral = referral
        newReferral.lastStatusUpdateAt = Date()
        referrals.append(newReferral)
    }
    
    func updateReferralStatus(id: String, status: ReferralStatus) {
        if let index = referrals.firstIndex(where: { $0.id == id }) {
            referrals[index].status = status
            referrals[index].lastStatusUpdateAt = Date()
            
            // If missed, create reschedule task
            if status == .missed {
                let task = StormTask(
                    id: UUID().uuidString,
                    type: .rescheduleReferral,
                    patientId: referrals[index].patientId,
                    linkedReferralId: id,
                    linkedRequestId: nil,
                    status: .open,
                    priority: referrals[index].priority,
                    assignedTo: currentUser.id,
                    createdAt: Date(),
                    dueAt: Date().addingTimeInterval(86400),
                    completedAt: nil,
                    notes: "Patient missed appointment"
                )
                tasks.append(task)
            }
        }
    }
    
    // MARK: - Transport Request Actions
    
    func createRequest(_ request: TransportRequest) {
        requests.append(request)
    }
    
    func assignRequest(id: String, volunteerId: String) {
        if let index = requests.firstIndex(where: { $0.id == id }) {
            requests[index].status = .assigned
            requests[index].assignedVolunteerId = volunteerId
        }
    }
    
    func completeRequest(id: String) {
        if let index = requests.firstIndex(where: { $0.id == id }) {
            requests[index].status = .completed
        }
    }
    
    func cancelRequest(id: String) {
        if let index = requests.firstIndex(where: { $0.id == id }) {
            requests[index].status = .open
            requests[index].assignedVolunteerId = nil
        }
    }
    
    // MARK: - Task Actions
    
    func completeTask(id: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = .done
            tasks[index].completedAt = Date()
        }
    }
    
    // MARK: - Seed Demo Data
    
    func seedDemoData() {
        users = Self.generateUsers()
        referrals = Self.generateReferrals()
        requests = Self.generateRequests()
        tasks = Self.generateTasks()
        checkIns = []
        stormState = .default
    }
    
    // MARK: - Query Helpers
    
    func referralsForPatient(_ patientId: String) -> [Referral] {
        referrals.filter { $0.patientId == patientId }
    }
    
    func requestsForPatient(_ patientId: String) -> [TransportRequest] {
        requests.filter { $0.patientId == patientId }
    }
    
    func requestsForVolunteer(_ volunteerId: String) -> [TransportRequest] {
        requests.filter { $0.assignedVolunteerId == volunteerId }
    }
    
    func openRequests() -> [TransportRequest] {
        requests.filter { $0.status == .open }
    }
    
    func overdueReferrals() -> [Referral] {
        referrals.filter { $0.isOverdue }
    }
    
    func missedReferrals() -> [Referral] {
        referrals.filter { $0.status == .missed }
    }
    
    func openTasks() -> [StormTask] {
        tasks.filter { $0.status == .open }.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    func tasksForUser(_ userId: String) -> [StormTask] {
        tasks.filter { $0.assignedTo == userId && $0.status != .done }
    }
    
    func checkInsAwaitingResponse() -> [CheckIn] {
        checkIns.filter { $0.status == .pending || $0.status == .noReply }
    }
    
    func checkInsNeedingHelp() -> [CheckIn] {
        checkIns.filter { $0.status == .needHelp }
    }
    
    func patient(for id: String) -> User? {
        users.first { $0.id == id }
    }
}

// MARK: - Sample Data Generation

extension MockDataService {
    
    static func generateUsers() -> [User] {
        return [
            // Patients
            User(
                id: "patient-001",
                role: .patient,
                fullName: "Mary Thompson",
                phone: "+1867555001",
                email: "mary@example.com",
                createdAt: Date().addingTimeInterval(-86400 * 120),
                isVulnerable: true,
                contactPreference: .sms,
                address: "123 Pine Street",
                emergencyContact: "+1867555002"
            ),
            User(
                id: "patient-002",
                role: .patient,
                fullName: "Robert Chen",
                phone: "+1867555003",
                email: nil,
                createdAt: Date().addingTimeInterval(-86400 * 90),
                isVulnerable: true,
                contactPreference: .sms,
                address: "45 Birch Lane",
                emergencyContact: "+1867555004"
            ),
            User(
                id: "patient-003",
                role: .patient,
                fullName: "James Wilson",
                phone: "+1867555005",
                email: "james.w@example.com",
                createdAt: Date().addingTimeInterval(-86400 * 60),
                isVulnerable: false,
                contactPreference: .app,
                address: "789 Oak Drive"
            ),
            User(
                id: "patient-004",
                role: .patient,
                fullName: "Eleanor Davis",
                phone: "+1867555006",
                email: nil,
                createdAt: Date().addingTimeInterval(-86400 * 200),
                isVulnerable: true,
                contactPreference: .sms,
                address: "12 Maple Court",
                emergencyContact: "+1867555007"
            ),
            User(
                id: "patient-005",
                role: .patient,
                fullName: "Michael Brown",
                phone: "+1867555008",
                email: "m.brown@example.com",
                createdAt: Date().addingTimeInterval(-86400 * 30),
                isVulnerable: false,
                contactPreference: .both,
                address: "567 Cedar Road"
            ),
            
            // Volunteers
            User(
                id: "volunteer-001",
                role: .volunteer,
                fullName: "John Anderson",
                phone: "+1867555010",
                email: "john.a@example.com",
                createdAt: Date().addingTimeInterval(-86400 * 180),
                isVulnerable: false,
                contactPreference: .app,
                address: "234 Spruce Street"
            ),
            User(
                id: "volunteer-002",
                role: .volunteer,
                fullName: "Lisa Martin",
                phone: "+1867555011",
                email: nil,
                createdAt: Date().addingTimeInterval(-86400 * 150),
                isVulnerable: false,
                contactPreference: .sms,
                address: "890 Willow Way"
            ),
            
            // Clinic Staff
            User(
                id: "staff-001",
                role: .clinicStaff,
                fullName: "Nurse Sarah Chen",
                phone: "+1867555020",
                email: "sarah@clearwaterclinic.ca",
                createdAt: Date().addingTimeInterval(-86400 * 365),
                isVulnerable: false,
                contactPreference: .both,
                address: "Clearwater Ridge Nursing Station"
            ),
            User(
                id: "staff-002",
                role: .clinicStaff,
                fullName: "Coordinator Mike Johnson",
                phone: "+1867555021",
                email: "mike@clearwaterclinic.ca",
                createdAt: Date().addingTimeInterval(-86400 * 300),
                isVulnerable: false,
                contactPreference: .app
            ),
            
            // Admin
            User(
                id: "admin-001",
                role: .admin,
                fullName: "Dr. Patricia White",
                phone: "+1867555030",
                email: "admin@clearwaterclinic.ca",
                createdAt: Date().addingTimeInterval(-86400 * 400),
                isVulnerable: false,
                contactPreference: .both
            )
        ]
    }
    
    static func generateReferrals() -> [Referral] {
        let now = Date()
        
        return [
            // Active referrals
            Referral(
                id: "ref-001",
                patientId: "patient-001",
                createdBy: "staff-001",
                referralType: .cardiology,
                priority: .high,
                status: .scheduled,
                appointmentDateTime: now.addingTimeInterval(86400 * 3), // 3 days
                followUpDueAt: nil,
                notesClinicOnly: "Patient has history of heart issues",
                lastStatusUpdateAt: now.addingTimeInterval(-86400),
                stormSensitive: true,
                linkedTransportRequestId: "req-001",
                createdAt: now.addingTimeInterval(-86400 * 5)
            ),
            Referral(
                id: "ref-002",
                patientId: "patient-002",
                createdBy: "staff-001",
                referralType: .mentalHealth,
                priority: .medium,
                status: .reminded,
                appointmentDateTime: now.addingTimeInterval(86400 * 1), // Tomorrow
                followUpDueAt: nil,
                notesClinicOnly: "Follow-up from previous session",
                lastStatusUpdateAt: now.addingTimeInterval(-3600),
                stormSensitive: true,
                linkedTransportRequestId: nil,
                createdAt: now.addingTimeInterval(-86400 * 10)
            ),
            Referral(
                id: "ref-003",
                patientId: "patient-003",
                createdBy: "staff-002",
                referralType: .imaging,
                priority: .low,
                status: .created,
                appointmentDateTime: nil,
                followUpDueAt: now.addingTimeInterval(86400 * 7),
                notesClinicOnly: "Routine X-ray needed",
                lastStatusUpdateAt: now.addingTimeInterval(-86400 * 2),
                stormSensitive: false,
                linkedTransportRequestId: nil,
                createdAt: now.addingTimeInterval(-86400 * 2)
            ),
            
            // Missed referral
            Referral(
                id: "ref-004",
                patientId: "patient-004",
                createdBy: "staff-001",
                referralType: .physicalTherapy,
                priority: .medium,
                status: .missed,
                appointmentDateTime: now.addingTimeInterval(-86400 * 2), // 2 days ago
                followUpDueAt: now.addingTimeInterval(86400),
                notesClinicOnly: "Needs reschedule - patient was unreachable",
                lastStatusUpdateAt: now.addingTimeInterval(-86400 * 2),
                stormSensitive: true,
                linkedTransportRequestId: nil,
                createdAt: now.addingTimeInterval(-86400 * 14)
            ),
            
            // Completed referral
            Referral(
                id: "ref-005",
                patientId: "patient-005",
                createdBy: "staff-002",
                referralType: .labWork,
                priority: .low,
                status: .closed,
                appointmentDateTime: now.addingTimeInterval(-86400 * 5),
                followUpDueAt: nil,
                notesClinicOnly: "Results normal",
                lastStatusUpdateAt: now.addingTimeInterval(-86400 * 5),
                stormSensitive: false,
                linkedTransportRequestId: nil,
                createdAt: now.addingTimeInterval(-86400 * 20)
            ),
            
            // Upcoming for storm testing
            Referral(
                id: "ref-006",
                patientId: "patient-001",
                createdBy: "staff-001",
                referralType: .specialist,
                priority: .high,
                status: .scheduled,
                appointmentDateTime: now.addingTimeInterval(86400 * 5), // 5 days
                followUpDueAt: nil,
                notesClinicOnly: "Specialist consultation in city",
                lastStatusUpdateAt: now.addingTimeInterval(-86400),
                stormSensitive: true,
                linkedTransportRequestId: "req-003",
                createdAt: now.addingTimeInterval(-86400 * 3)
            )
        ]
    }
    
    static func generateRequests() -> [TransportRequest] {
        let now = Date()
        
        return [
            // Open ride request
            TransportRequest(
                id: "req-001",
                type: .rideToAppointment,
                patientId: "patient-001",
                createdBy: "staff-001",
                pickupLocation: "123 Pine Street",
                dropoffLocation: "Regional Hospital, 110km",
                timeWindowStart: now.addingTimeInterval(86400 * 3 + 28800), // 8am in 3 days
                timeWindowEnd: now.addingTimeInterval(86400 * 3 + 36000), // 10am
                mobilityNeeds: "Walker assistance needed",
                status: .open,
                assignedVolunteerId: nil,
                linkedReferralId: "ref-001",
                createdAt: now.addingTimeInterval(-86400),
                notes: "Patient prefers window seat"
            ),
            
            // Assigned request
            TransportRequest(
                id: "req-002",
                type: .pharmacyPickup,
                patientId: "patient-002",
                createdBy: "patient-002",
                pickupLocation: "Clearwater Pharmacy",
                dropoffLocation: "45 Birch Lane",
                timeWindowStart: now.addingTimeInterval(3600), // 1 hour from now
                timeWindowEnd: now.addingTimeInterval(10800), // 3 hours
                mobilityNeeds: nil,
                status: .assigned,
                assignedVolunteerId: "volunteer-001",
                linkedReferralId: nil,
                createdAt: now.addingTimeInterval(-7200),
                notes: "Prescription ready for pickup"
            ),
            
            // Another open request
            TransportRequest(
                id: "req-003",
                type: .rideToAppointment,
                patientId: "patient-004",
                createdBy: "staff-001",
                pickupLocation: "12 Maple Court",
                dropoffLocation: "Regional Hospital, 110km",
                timeWindowStart: now.addingTimeInterval(86400 * 5 + 25200), // 7am in 5 days
                timeWindowEnd: now.addingTimeInterval(86400 * 5 + 32400), // 9am
                mobilityNeeds: "Wheelchair",
                status: .open,
                assignedVolunteerId: nil,
                linkedReferralId: "ref-006",
                createdAt: now.addingTimeInterval(-43200),
                notes: nil
            ),
            
            // Completed
            TransportRequest(
                id: "req-004",
                type: .essentialSupplyDropoff,
                patientId: "patient-003",
                createdBy: "staff-002",
                pickupLocation: "Community Center",
                dropoffLocation: "789 Oak Drive",
                timeWindowStart: now.addingTimeInterval(-86400),
                timeWindowEnd: now.addingTimeInterval(-72000),
                mobilityNeeds: nil,
                status: .completed,
                assignedVolunteerId: "volunteer-002",
                linkedReferralId: nil,
                createdAt: now.addingTimeInterval(-86400 * 2),
                notes: "Heating supplies delivered"
            )
        ]
    }
    
    static func generateTasks() -> [StormTask] {
        let now = Date()
        
        return [
            StormTask(
                id: "task-001",
                type: .callPatient,
                patientId: "patient-004",
                linkedReferralId: "ref-004",
                linkedRequestId: nil,
                status: .open,
                priority: .high,
                assignedTo: "staff-001",
                createdAt: now.addingTimeInterval(-86400 * 2),
                dueAt: now.addingTimeInterval(3600),
                completedAt: nil,
                notes: "Follow up on missed appointment"
            ),
            StormTask(
                id: "task-002",
                type: .rescheduleReferral,
                patientId: "patient-004",
                linkedReferralId: "ref-004",
                linkedRequestId: nil,
                status: .open,
                priority: .medium,
                assignedTo: "staff-001",
                createdAt: now.addingTimeInterval(-86400),
                dueAt: now.addingTimeInterval(86400),
                completedAt: nil,
                notes: "Physical therapy reschedule needed"
            ),
            StormTask(
                id: "task-003",
                type: .arrangeRide,
                patientId: "patient-001",
                linkedReferralId: "ref-001",
                linkedRequestId: "req-001",
                status: .open,
                priority: .medium,
                assignedTo: "staff-002",
                createdAt: now.addingTimeInterval(-43200),
                dueAt: now.addingTimeInterval(86400 * 2),
                completedAt: nil,
                notes: "Confirm volunteer for cardiology appointment"
            ),
            StormTask(
                id: "task-004",
                type: .followUp,
                patientId: "patient-005",
                linkedReferralId: "ref-005",
                linkedRequestId: nil,
                status: .done,
                priority: .low,
                assignedTo: "staff-002",
                createdAt: now.addingTimeInterval(-86400 * 6),
                dueAt: now.addingTimeInterval(-86400 * 5),
                completedAt: now.addingTimeInterval(-86400 * 5),
                notes: "Lab results communicated to patient"
            )
        ]
    }
}
