import Foundation
import SwiftUI

// MARK: - Mock Data Service
// Provides sample data for demo purposes

class MockDataService: ObservableObject {
    static let shared = MockDataService()
    
    // MARK: - Published Data
    @Published var currentUser: User
    @Published var users: [User]
    @Published var volunteers: [Volunteer]
    @Published var referrals: [Referral]
    @Published var requests: [TransportRequest]
    @Published var tasks: [StormTask]
    @Published var checkIns: [CheckIn]
    @Published var stormState: StormState
    
    // Demo mode for role switching
    @Published var demoRole: UserRole = .clinicStaff
    
    // Track patient → preferred driver relationships
    @Published var patientPreferredDrivers: [String: String] = [
        "patient-001": "vol-001"  // Mary Thompson prefers John Wilson
    ]
    
    private init() {
        // Initialize with sample data
        self.users = Self.generateUsers()
        self.volunteers = Volunteer.sampleVolunteers
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
        
        let autopilot = AutopilotService.shared
        
        // Log Storm Mode activation
        autopilot.logAction(
            .stormModeActivated,
            description: "Storm Mode activated - Winter Storm Warning in effect",
            priority: .warning
        )
        
        // Generate check-in tasks for vulnerable patients
        let vulnerablePatients = users.filter { $0.isVulnerable && $0.role == .patient }
        
        // Log bulk check-in creation
        if !vulnerablePatients.isEmpty {
            autopilot.logAction(
                .checkInCreated,
                description: "Auto-created Storm Check-Ins for \(vulnerablePatients.count) high-risk patients",
                priority: .info
            )
        }
        
        // 📱 SEND REAL SMS via Twilio to patients who prefer SMS
        let smsPatients = vulnerablePatients.filter { 
            $0.contactPreference == .sms || $0.contactPreference == .both 
        }
        
        if !smsPatients.isEmpty {
            Task {
                await sendStormCheckInSMS(to: smsPatients)
            }
        }
        
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
            
            // Create essential supply delivery request for vulnerable patients
            // (every other vulnerable patient gets a supply delivery for demo)
            if vulnerablePatients.firstIndex(where: { $0.id == patient.id })?.isMultiple(of: 2) == true {
                let supplyRequest = TransportRequest(
                    id: UUID().uuidString,
                    type: .essentialSupplyDropoff,
                    patientId: patient.id,
                    createdBy: "AUTOPILOT",
                    pickupLocation: "Community Resource Center",
                    dropoffLocation: patient.address ?? "Patient Address",
                    pickupZone: "Downtown",
                    dropoffZone: TransportRequest.inferZone(from: patient.address ?? "Downtown"),
                    timeWindowStart: Date().addingTimeInterval(3600),
                    timeWindowEnd: Date().addingTimeInterval(14400),
                    mobilityNeeds: nil,
                    status: .open,
                    assignedVolunteerId: nil,
                    linkedReferralId: nil,
                    createdAt: Date(),
                    notes: "Auto-created: Storm supply delivery for \(patient.firstName)",
                    visibility: .publicVolunteers,
                    needsClinicFollowUp: false,
                    failReason: nil,
                    completedAt: nil
                )
                requests.append(supplyRequest)
                
                autopilot.logAction(
                    .missionCreated,
                    description: "Auto-created supply delivery for \(patient.fullName)",
                    missionId: supplyRequest.id,
                    priority: .info
                )
            }
        }
        
        // Flag upcoming appointments as storm_at_risk
        let lookaheadDate = Calendar.current.date(byAdding: .day, value: stormState.rules.daysLookahead, to: Date()) ?? Date()
        var rescheduledCount = 0
        
        for i in 0..<referrals.count {
            if let appointmentDate = referrals[i].appointmentDateTime,
               appointmentDate <= lookaheadDate,
               appointmentDate > Date(),
               referrals[i].stormSensitive {
                referrals[i].status = .stormAtRisk
                rescheduledCount += 1
                
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
        
        if rescheduledCount > 0 {
            autopilot.logAction(
                .rescheduleMission,
                description: "Flagged \(rescheduledCount) storm-sensitive appointments for reschedule",
                priority: .warning
            )
        }
        
        // Create volunteer missions for storm check-ins
        MockMissionService.shared.createStormCheckInMissions()
        
        // AUTO-ASSIGN: Try to assign all open requests to best volunteers
        autoAssignOpenStormMissions()
    }
    
    // MARK: - Storm Auto-Assignment
    
    private func autoAssignOpenStormMissions() {
        let smartMatch = SmartMatchService.shared
        let autopilot = AutopilotService.shared
        
        // Lower threshold during storm mode - be more aggressive with matching
        let openRequests = requests.filter { $0.status == .open }
        var assignedCount = 0
        
        for request in openRequests {
            let result = smartMatch.findBestMatch(for: request)
            
            // During storm mode, lower threshold to 60% (vs 85% normally)
            if let volunteer = result.bestMatch, result.matchScore >= 60 {
                if let _ = smartMatch.autoAssign(request: request) {
                    assignedCount += 1
                    autopilot.logAction(
                        .missionAssigned,
                        description: "Storm auto-assigned: \(request.type.shortName) to \(volunteer.fullName) (\(result.matchScore)%)",
                        missionId: request.id,
                        volunteerId: volunteer.id,
                        priority: .success
                    )
                }
            }
        }
        
        if assignedCount > 0 {
            autopilot.logAction(
                .missionAssigned,
                description: "Storm Mode: Auto-assigned \(assignedCount) missions to available volunteers",
                priority: .success
            )
        }
    }
    
    func deactivateStormMode() {
        stormState.isStormMode = false
        stormState.deactivatedAt = Date()
        
        AutopilotService.shared.logAction(
            .stormModeDeactivated,
            description: "Storm Mode deactivated - returning to normal operations",
            priority: .info
        )
    }
    
    // MARK: - Send SMS Check-Ins via Twilio
    
    @MainActor
    private func sendStormCheckInSMS(to patients: [User]) async {
        let autopilot = AutopilotService.shared
        
        // Log that SMS blast is starting
        autopilot.logAction(
            .smsBroadcast,
            description: "📱 Sending SMS check-ins to \(patients.count) patients...",
            priority: .info
        )
        
        var sentCount = 0
        var failedCount = 0
        
        for patient in patients {
            let result = await TwilioService.shared.sendStormCheckIn(
                patientName: patient.firstName,
                patientPhone: patient.phone
            )
            
            if result.success {
                sentCount += 1
                print("✅ SMS sent to \(patient.fullName)")
            } else {
                failedCount += 1
                print("❌ SMS failed for \(patient.fullName): \(result.error ?? "Unknown")")
            }
            
            // Small delay between sends
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        // Log completion
        if sentCount > 0 {
            autopilot.logAction(
                .smsBroadcast,
                description: "✅ SMS Check-Ins: \(sentCount) sent successfully" + (failedCount > 0 ? ", \(failedCount) failed" : ""),
                priority: .success
            )
        } else if failedCount > 0 {
            autopilot.logAction(
                .smsBroadcast,
                description: "❌ SMS Check-Ins failed: Check Twilio configuration",
                priority: .critical
            )
        }
    }
    
    // MARK: - Simulate Check-In Response
    
    func simulateCheckInResponse(checkInId: String, status: CheckInStatus) {
        if let index = checkIns.firstIndex(where: { $0.id == checkInId }) {
            checkIns[index].status = status
            checkIns[index].receivedAt = Date()
            
            // Sync check-in to Firebase
            let updatedCheckIn = checkIns[index]
            Task { try? await FirebaseService.shared.saveCheckIn(updatedCheckIn) }
            
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
                
                // Sync urgent task to Firebase
                Task { try? await FirebaseService.shared.saveTask(urgentTask) }
            }
        }
    }
    
    // MARK: - Referral Actions
    
    func createReferral(_ referral: Referral) {
        var newReferral = referral
        newReferral.lastStatusUpdateAt = Date()
        referrals.append(newReferral)
        
        // Sync to Firebase
        Task { try? await FirebaseService.shared.saveReferral(newReferral) }
    }
    
    func updateReferralStatus(id: String, status: ReferralStatus) {
        if let index = referrals.firstIndex(where: { $0.id == id }) {
            referrals[index].status = status
            referrals[index].lastStatusUpdateAt = Date()
            
            // Sync to Firebase
            let updatedReferral = referrals[index]
            Task { try? await FirebaseService.shared.saveReferral(updatedReferral) }
            
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
                
                // Sync new task to Firebase
                Task { try? await FirebaseService.shared.saveTask(task) }
            }
        }
    }
    
    // MARK: - Transport Request Actions
    
    func createRequest(_ request: TransportRequest) {
        requests.append(request)
        
        // Sync to Firebase
        Task { try? await FirebaseService.shared.saveTransportRequest(request) }
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
            
            // Sync to Firebase
            let updatedRequest = requests[index]
            Task { try? await FirebaseService.shared.saveTransportRequest(updatedRequest) }
        }
    }
    
    func cancelRequest(id: String) {
        if let index = requests.firstIndex(where: { $0.id == id }) {
            requests[index].status = .open
            requests[index].assignedVolunteerId = nil
            requests[index].visibility = .publicVolunteers // Reset visibility so it reappears
        }
    }
    
    
    // MARK: - Task Actions
    
    func completeTask(id: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = .done
            tasks[index].completedAt = Date()
            
            // Sync to Firebase
            let updatedTask = tasks[index]
            Task { try? await FirebaseService.shared.saveTask(updatedTask) }
        }
    }
    
    // MARK: - Volunteer Management
    
    var currentVolunteer: Volunteer? {
        volunteers.first { $0.userId == currentUser.id }
    }
    
    func getVolunteer(id: String) -> Volunteer? {
        volunteers.first { $0.id == id || $0.userId == id }
    }
    
    func toggleVolunteerAvailability(volunteerId: String) {
        guard let index = volunteers.firstIndex(where: { $0.id == volunteerId || $0.userId == volunteerId }) else { return }
        
        // Don't toggle if on a mission
        if volunteers[index].availability == .onMission { return }
        
        volunteers[index].availability = volunteers[index].availability == .available ? .unavailable : .available
    }
    
    func setVolunteerOnMission(volunteerId: String, onMission: Bool) {
        guard let index = volunteers.firstIndex(where: { $0.id == volunteerId || $0.userId == volunteerId }) else { return }
        
        if onMission {
            volunteers[index].availability = .onMission
        } else {
            volunteers[index].availability = .available
        }
    }
    
    // Smart match volunteers for a mission - sorted by availability, then reliability, then zone match
    func smartMatchedVolunteers(for request: TransportRequest? = nil, zone: String? = nil) -> [Volunteer] {
        var matched = volunteers
        
        // Filter by tier if mission requires trusted responder
        if let request = request {
            matched = matched.filter { $0.canAccept(missionType: request.type) }
        }
        
        // Sort by: availability (available first) → reliability → zone match
        return matched.sorted { v1, v2 in
            // 1. Available volunteers first
            if v1.availability == .available && v2.availability != .available { return true }
            if v2.availability == .available && v1.availability != .available { return false }
            
            // 2. On mission comes before unavailable
            if v1.availability == .onMission && v2.availability == .unavailable { return true }
            if v2.availability == .onMission && v1.availability == .unavailable { return false }
            
            // 3. Higher reliability first
            if v1.reliabilityScore != v2.reliabilityScore {
                return v1.reliabilityScore > v2.reliabilityScore
            }
            
            // 4. Zone match (if provided)
            if let targetZone = zone {
                if v1.zone == targetZone && v2.zone != targetZone { return true }
                if v2.zone == targetZone && v1.zone != targetZone { return false }
            }
            
            return v1.completedMissions > v2.completedMissions
        }
    }
    
    // Get available volunteers only
    var availableVolunteers: [Volunteer] {
        volunteers.filter { $0.availability == .available }
    }
    
    // MARK: - Patient-Driver Preferences
    
    func setPreferredDriver(patientId: String, driverId: String) {
        patientPreferredDrivers[patientId] = driverId
    }
    
    func getPreferredDriver(forPatient patientId: String) -> Volunteer? {
        guard let driverId = patientPreferredDrivers[patientId] else { return nil }
        return getVolunteer(id: driverId)
    }
    
    func patientsWhoPrefer(driverId: String) -> [User] {
        let patientIds = patientPreferredDrivers.filter { $0.value == driverId }.keys
        return users.filter { patientIds.contains($0.id) && $0.role == .patient }
    }
    
    var patientsPreferringCurrentVolunteer: [User] {
        guard let volunteer = currentVolunteer else { return [] }
        return patientsWhoPrefer(driverId: volunteer.id)
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
                phone: "+14168305958",  // Demo: YOUR phone number for testing
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
                pickupZone: "Downtown",
                dropoffZone: "East End",
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
                pickupZone: "North Side",
                dropoffZone: "Downtown",
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
