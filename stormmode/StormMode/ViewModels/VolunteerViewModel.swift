import SwiftUI
import Combine

// MARK: - Volunteer View Model

class VolunteerViewModel: ObservableObject {
    @Published var openRequests: [TransportRequest] = []
    @Published var myAssignedRequests: [TransportRequest] = []
    @Published var isLoading: Bool = false
    
    private let dataService = MockDataService.shared
    private let missionService = MockMissionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var volunteerId: String {
        dataService.currentUser.id
    }
    
    var volunteerName: String {
        dataService.currentUser.firstName
    }
    
    var isStormMode: Bool {
        dataService.stormState.isStormMode
    }
    
    var openRequestsCount: Int {
        openRequests.count
    }
    
    var assignedCount: Int {
        myAssignedRequests.filter { $0.status == .assigned || $0.status == .inProgress }.count
    }
    
    var completedCount: Int {
        myAssignedRequests.filter { $0.status == .completed }.count
    }
    
    init() {
        setupBindings()
        loadData()
    }
    
    private func setupBindings() {
        dataService.$requests
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        openRequests = missionService.openMissions
        myAssignedRequests = dataService.requestsForVolunteer(volunteerId)
    }
    
    // MARK: - Mission Actions
    
    func acceptRequest(_ requestId: String) {
        missionService.acceptMission(id: requestId, by: volunteerId)
        loadData()
    }
    
    func startTrip(_ requestId: String) {
        if let index = dataService.requests.firstIndex(where: { $0.id == requestId }) {
            dataService.requests[index].status = .inProgress
        }
        loadData()
    }
    
    func completeTrip(_ requestId: String) {
        missionService.completeMission(id: requestId)
        loadData()
    }
    
    func cancelAssignment(_ requestId: String) {
        dataService.cancelRequest(id: requestId)
        loadData()
    }
    
    func failMission(_ requestId: String, reason: String) {
        missionService.failMission(id: requestId, reason: reason)
        loadData()
    }
    
    // MARK: - Helpers
    
    func patientName(for patientId: String) -> String {
        // For privacy, only show first name and initial
        if let patient = dataService.patient(for: patientId) {
            return patient.firstName + " " + (patient.fullName.components(separatedBy: " ").last?.prefix(1).uppercased() ?? "") + "."
        }
        return "Patient"
    }
}

