import SwiftUI
import Combine

// MARK: - Patient View Model

class PatientViewModel: ObservableObject {
    @Published var myReferrals: [Referral] = []
    @Published var myRequests: [TransportRequest] = []
    @Published var isLoading: Bool = false
    
    private let dataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var isStormMode: Bool {
        dataService.stormState.isStormMode
    }
    
    var patientId: String {
        dataService.currentUser.id
    }
    
    var patientName: String {
        dataService.currentUser.firstName
    }
    
    var hasActiveReferrals: Bool {
        !myReferrals.filter { !$0.status.isTerminal }.isEmpty
    }
    
    var activeReferralsCount: Int {
        myReferrals.filter { !$0.status.isTerminal }.count
    }
    
    var completedReferralsCount: Int {
        myReferrals.filter { $0.status.isTerminal }.count
    }
    
    var pendingRequestsCount: Int {
        myRequests.filter { $0.status == .open || $0.status == .assigned }.count
    }
    
    // Progress calculation
    var overallProgress: Double {
        guard !myReferrals.isEmpty else { return 0 }
        let completed = myReferrals.filter { $0.status == .closed || $0.status == .attended }.count
        return Double(completed) / Double(myReferrals.count)
    }
    
    init() {
        setupBindings()
        loadData()
    }
    
    private func setupBindings() {
        // Listen for data changes
        dataService.$referrals
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
        
        dataService.$requests
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        myReferrals = dataService.referralsForPatient(patientId)
        myRequests = dataService.requestsForPatient(patientId)
    }
    
    // MARK: - Actions
    
    func confirmAttendance(referralId: String) {
        dataService.updateReferralStatus(id: referralId, status: .attended)
        loadData()
    }
    
    func requestReschedule(referralId: String) {
        dataService.updateReferralStatus(id: referralId, status: .needsReschedule)
        loadData()
    }
    
    func createTransportRequest(type: TransportType, pickup: String, dropoff: String, date: Date, notes: String?) {
        let request = TransportRequest(
            id: UUID().uuidString,
            type: type,
            patientId: patientId,
            createdBy: patientId,
            pickupLocation: pickup,
            dropoffLocation: dropoff,
            timeWindowStart: date,
            timeWindowEnd: date.addingTimeInterval(7200), // 2 hour window
            mobilityNeeds: nil,
            status: .open,
            assignedVolunteerId: nil,
            linkedReferralId: nil,
            createdAt: Date(),
            notes: notes
        )
        dataService.createRequest(request)
        loadData()
    }
}
