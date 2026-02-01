import SwiftUI
import Combine

// MARK: - Clinic Staff View Model

class ClinicStaffViewModel: ObservableObject {
    @Published var allReferrals: [Referral] = []
    @Published var allRequests: [TransportRequest] = []
    @Published var allTasks: [StormTask] = []
    @Published var checkIns: [CheckIn] = []
    @Published var stormState: StormState = .default
    @Published var isLoading: Bool = false
    
    private let dataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var staffId: String {
        dataService.currentUser.id
    }
    
    var staffName: String {
        dataService.currentUser.firstName
    }
    
    // MARK: - Dashboard Metrics
    
    var isStormMode: Bool {
        stormState.isStormMode
    }
    
    var overdueReferrals: [Referral] {
        allReferrals.filter { $0.isOverdue }
    }
    
    var missedReferrals: [Referral] {
        allReferrals.filter { $0.status == .missed }
    }
    
    var stormAtRiskReferrals: [Referral] {
        allReferrals.filter { $0.status == .stormAtRisk }
    }
    
    var unassignedRequests: [TransportRequest] {
        allRequests.filter { $0.status == .open }
    }
    
    var openTasks: [StormTask] {
        allTasks.filter { $0.status == .open }.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    var urgentTasks: [StormTask] {
        openTasks.filter { $0.priority == .high }
    }
    
    var pendingCheckIns: [CheckIn] {
        checkIns.filter { $0.status == .pending }
    }
    
    var needHelpCheckIns: [CheckIn] {
        checkIns.filter { $0.status == .needHelp }
    }
    
    var noReplyCheckIns: [CheckIn] {
        checkIns.filter { $0.status == .noReply }
    }
    
    // Overall stats
    var totalActiveReferrals: Int {
        allReferrals.filter { !$0.status.isTerminal }.count
    }
    
    var referralClosureRate: Double {
        guard !allReferrals.isEmpty else { return 0 }
        let closed = allReferrals.filter { $0.status == .closed || $0.status == .attended }.count
        return Double(closed) / Double(allReferrals.count)
    }
    
    var checkInResponseRate: Double {
        guard !checkIns.isEmpty else { return 0 }
        let responded = checkIns.filter { $0.status == .ok || $0.status == .needHelp }.count
        return Double(responded) / Double(checkIns.count)
    }
    
    init() {
        setupBindings()
        loadData()
    }
    
    private func setupBindings() {
        dataService.$referrals
            .sink { [weak self] referrals in
                self?.allReferrals = referrals
            }
            .store(in: &cancellables)
        
        dataService.$requests
            .sink { [weak self] requests in
                self?.allRequests = requests
            }
            .store(in: &cancellables)
        
        dataService.$tasks
            .sink { [weak self] tasks in
                self?.allTasks = tasks
            }
            .store(in: &cancellables)
        
        dataService.$checkIns
            .sink { [weak self] checkIns in
                self?.checkIns = checkIns
            }
            .store(in: &cancellables)
        
        dataService.$stormState
            .sink { [weak self] state in
                self?.stormState = state
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        allReferrals = dataService.referrals
        allRequests = dataService.requests
        allTasks = dataService.tasks
        checkIns = dataService.checkIns
        stormState = dataService.stormState
    }
    
    // MARK: - Storm Mode Actions
    
    func toggleStormMode() {
        if stormState.isStormMode {
            dataService.deactivateStormMode()
        } else {
            dataService.activateStormMode()
        }
        loadData()
    }
    
    // MARK: - Referral Actions
    
    func createReferral(patientId: String, type: ReferralType, priority: Priority, notes: String?, stormSensitive: Bool) {
        let referral = Referral(
            id: UUID().uuidString,
            patientId: patientId,
            createdBy: staffId,
            referralType: type,
            priority: priority,
            status: .created,
            appointmentDateTime: nil,
            followUpDueAt: Date().addingTimeInterval(86400 * 7),
            notesClinicOnly: notes,
            lastStatusUpdateAt: Date(),
            stormSensitive: stormSensitive,
            linkedTransportRequestId: nil,
            createdAt: Date()
        )
        dataService.createReferral(referral)
        loadData()
    }
    
    func updateReferralStatus(id: String, status: ReferralStatus) {
        dataService.updateReferralStatus(id: id, status: status)
        loadData()
    }
    
    func scheduleReferral(id: String, date: Date) {
        if let index = dataService.referrals.firstIndex(where: { $0.id == id }) {
            dataService.referrals[index].appointmentDateTime = date
            dataService.referrals[index].status = .scheduled
            dataService.referrals[index].lastStatusUpdateAt = Date()
        }
        loadData()
    }
    
    // MARK: - Task Actions
    
    func completeTask(_ taskId: String) {
        dataService.completeTask(id: taskId)
        loadData()
    }
    
    // MARK: - Check-In Simulation
    
    func simulateCheckInResponse(checkInId: String, status: CheckInStatus) {
        dataService.simulateCheckInResponse(checkInId: checkInId, status: status)
        loadData()
    }
    
    // MARK: - Helpers
    
    func patientName(for patientId: String) -> String {
        dataService.patient(for: patientId)?.fullName ?? "Unknown Patient"
    }
    
    func patients() -> [User] {
        dataService.users.filter { $0.role == .patient }
    }
}
