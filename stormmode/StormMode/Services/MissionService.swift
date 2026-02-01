import Foundation
import SwiftUI

// MARK: - Mission Service Protocol (Firebase-ready abstraction)
// Swap MockMissionService with FirestoreMissionService later

protocol MissionServiceProtocol: ObservableObject {
    var openMissions: [TransportRequest] { get }
    var myMissions: [TransportRequest] { get }
    var completedTodayCount: Int { get }
    var stormCheckInsCompleted: Int { get }
    
    func acceptMission(id: String, by volunteerId: String)
    func completeMission(id: String)
    func failMission(id: String, reason: String)
    func createStormCheckInMissions()
}

// MARK: - Mock Mission Service (Local implementation)

class MockMissionService: ObservableObject, MissionServiceProtocol {
    static let shared = MockMissionService()
    
    @Published private var dataService = MockDataService.shared
    
    private init() {}
    
    // MARK: - Computed Properties
    
    var openMissions: [TransportRequest] {
        dataService.requests.filter { 
            $0.status == .open && $0.visibility == .publicVolunteers 
        }.sorted { $0.timeWindowStart < $1.timeWindowStart }
    }
    
    var myMissions: [TransportRequest] {
        let volunteerId = dataService.currentUser.id
        return dataService.requests.filter { 
            $0.assignedVolunteerId == volunteerId && 
            ($0.status == .assigned || $0.status == .inProgress)
        }
    }
    
    var completedTodayCount: Int {
        let calendar = Calendar.current
        return dataService.requests.filter { request in
            guard let completedAt = request.completedAt else { return false }
            return request.status == .completed && calendar.isDateInToday(completedAt)
        }.count
    }
    
    var stormCheckInsCompleted: Int {
        dataService.requests.filter { 
            $0.type == .stormCheckIn && $0.status == .completed 
        }.count
    }
    
    // MARK: - Mission Actions
    
    func acceptMission(id: String, by volunteerId: String) {
        guard let index = dataService.requests.firstIndex(where: { $0.id == id }) else { return }
        
        dataService.requests[index].status = .assigned
        dataService.requests[index].assignedVolunteerId = volunteerId
        dataService.requests[index].visibility = .assignedOnly
        
        print("✅ [Mission] Accepted: \(id) by \(volunteerId)")
    }
    
    func completeMission(id: String) {
        guard let index = dataService.requests.firstIndex(where: { $0.id == id }) else { return }
        
        dataService.requests[index].status = .completed
        dataService.requests[index].completedAt = Date()
        
        print("✅ [Mission] Completed: \(id)")
    }
    
    func failMission(id: String, reason: String) {
        guard let index = dataService.requests.firstIndex(where: { $0.id == id }) else { return }
        
        dataService.requests[index].status = .failed
        dataService.requests[index].failReason = reason
        dataService.requests[index].needsClinicFollowUp = true
        
        // Create follow-up task for clinic staff
        createClinicFollowUpTask(for: dataService.requests[index])
        
        print("⚠️ [Mission] Failed: \(id) - \(reason)")
    }
    
    // MARK: - Storm Mode Integration
    
    func createStormCheckInMissions() {
        // Only create if no storm checkins exist
        let existingStormMissions = dataService.requests.filter { $0.type == .stormCheckIn && $0.status == .open }
        if !existingStormMissions.isEmpty {
            print("ℹ️ [Mission] Storm check-in missions already exist")
            return
        }
        
        // Get vulnerable patients
        let vulnerablePatients = dataService.users.filter { $0.isVulnerable && $0.role == .patient }
        let patientsToCheck = Array(vulnerablePatients.prefix(min(5, vulnerablePatients.count)))
        
        for patient in patientsToCheck {
            let mission = TransportRequest(
                id: UUID().uuidString,
                type: .stormCheckIn,
                patientId: patient.id,
                createdBy: dataService.currentUser.id,
                pickupLocation: patient.address ?? "Address on file",
                dropoffLocation: patient.address ?? "Same location",
                timeWindowStart: Date(),
                timeWindowEnd: Date().addingTimeInterval(86400), // 24 hours
                mobilityNeeds: nil,
                status: .open,
                assignedVolunteerId: nil,
                linkedReferralId: nil,
                createdAt: Date(),
                notes: "🌀 Storm safety check for \(patient.firstName)",
                visibility: .publicVolunteers,
                needsClinicFollowUp: false,
                failReason: nil,
                completedAt: nil
            )
            
            dataService.requests.append(mission)
        }
        
        print("🌀 [Mission] Created \(patientsToCheck.count) storm check-in missions")
    }
    
    // MARK: - Private Helpers
    
    private func createClinicFollowUpTask(for mission: TransportRequest) {
        let task = StormTask(
            id: UUID().uuidString,
            type: .followUp,
            patientId: mission.patientId,
            linkedReferralId: nil,
            linkedRequestId: mission.id,
            status: .open,
            priority: .high,
            assignedTo: "", // Unassigned - any staff can pick up
            createdAt: Date(),
            dueAt: Date().addingTimeInterval(3600), // 1 hour
            completedAt: nil,
            notes: "⚠️ Volunteer mission failed: \(mission.failReason ?? "Unknown reason")"
        )
        
        dataService.tasks.append(task)
        print("📋 [Mission] Created follow-up task for failed mission")
    }
}

// MARK: - Community Impact Stats

struct CommunityImpactStats {
    let openMissions: Int
    let completedToday: Int
    let stormCheckInsCompleted: Int
    let totalVolunteersActive: Int
    
    static var current: CommunityImpactStats {
        let service = MockMissionService.shared
        let dataService = MockDataService.shared
        
        let activeVolunteers = Set(
            dataService.requests
                .filter { $0.status == .assigned || $0.status == .inProgress }
                .compactMap { $0.assignedVolunteerId }
        ).count
        
        return CommunityImpactStats(
            openMissions: service.openMissions.count,
            completedToday: service.completedTodayCount,
            stormCheckInsCompleted: service.stormCheckInsCompleted,
            totalVolunteersActive: activeVolunteers
        )
    }
}
