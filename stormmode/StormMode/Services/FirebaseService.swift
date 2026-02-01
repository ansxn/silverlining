import Foundation
import FirebaseCore
import FirebaseFirestore

// MARK: - Firebase Service
// Handles all Firestore database operations

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    
    // Collection references
    private var usersCollection: CollectionReference { db.collection("users") }
    private var referralsCollection: CollectionReference { db.collection("referrals") }
    private var transportRequestsCollection: CollectionReference { db.collection("transport_requests") }
    private var checkInsCollection: CollectionReference { db.collection("check_ins") }
    private var tasksCollection: CollectionReference { db.collection("tasks") }
    
    @Published var isConnected = false
    @Published var lastSyncTime: Date?
    
    private init() {
        // Test connection on init
        testConnection()
    }
    
    // MARK: - Connection Test
    
    func testConnection() {
        db.collection("_connection_test").document("ping").setData([
            "timestamp": FieldValue.serverTimestamp(),
            "source": "ios_app"
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase connection failed: \(error.localizedDescription)")
                    self?.isConnected = false
                } else {
                    print("✅ Firebase connected successfully!")
                    self?.isConnected = true
                    self?.lastSyncTime = Date()
                }
            }
        }
    }
    
    // MARK: - Users
    
    func saveUser(_ user: User) async throws {
        let data = try encodeToFirestore(user)
        try await usersCollection.document(user.id).setData(data)
        print("✅ Saved user: \(user.fullName)")
    }
    
    func fetchUsers() async throws -> [User] {
        let snapshot = try await usersCollection.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(User.self, document: doc)
        }
    }
    
    func fetchUser(id: String) async throws -> User? {
        let doc = try await usersCollection.document(id).getDocument()
        guard doc.exists else { return nil }
        return try decodeFromFirestore(User.self, document: doc)
    }
    
    // MARK: - Referrals
    
    func saveReferral(_ referral: Referral) async throws {
        let data = try encodeToFirestore(referral)
        try await referralsCollection.document(referral.id).setData(data)
        print("✅ Saved referral: \(referral.id)")
    }
    
    func fetchReferrals() async throws -> [Referral] {
        let snapshot = try await referralsCollection.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(Referral.self, document: doc)
        }
    }
    
    func fetchReferrals(forPatient patientId: String) async throws -> [Referral] {
        let snapshot = try await referralsCollection
            .whereField("patientId", isEqualTo: patientId)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(Referral.self, document: doc)
        }
    }
    
    // MARK: - Transport Requests
    
    func saveTransportRequest(_ request: TransportRequest) async throws {
        let data = try encodeToFirestore(request)
        try await transportRequestsCollection.document(request.id).setData(data)
        print("✅ Saved transport request: \(request.id)")
    }
    
    func fetchTransportRequests() async throws -> [TransportRequest] {
        let snapshot = try await transportRequestsCollection.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(TransportRequest.self, document: doc)
        }
    }
    
    func fetchOpenTransportRequests() async throws -> [TransportRequest] {
        let snapshot = try await transportRequestsCollection
            .whereField("status", isEqualTo: "open")
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(TransportRequest.self, document: doc)
        }
    }
    
    // MARK: - Check-Ins
    
    func saveCheckIn(_ checkIn: CheckIn) async throws {
        let data = try encodeToFirestore(checkIn)
        try await checkInsCollection.document(checkIn.id).setData(data)
        print("✅ Saved check-in: \(checkIn.id)")
    }
    
    func fetchCheckIns(forPatient patientId: String) async throws -> [CheckIn] {
        let snapshot = try await checkInsCollection
            .whereField("patientId", isEqualTo: patientId)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(CheckIn.self, document: doc)
        }
    }
    
    // MARK: - Tasks
    
    func saveTask(_ task: StormTask) async throws {
        let data = try encodeToFirestore(task)
        try await tasksCollection.document(task.id).setData(data)
        print("✅ Saved task: \(task.id)")
    }
    
    func fetchTasks() async throws -> [StormTask] {
        let snapshot = try await tasksCollection.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? decodeFromFirestore(StormTask.self, document: doc)
        }
    }
    
    // MARK: - Batch Sync (Sync all demo data to Firebase)
    
    func syncDemoDataToFirebase(
        users: [User],
        referrals: [Referral],
        requests: [TransportRequest],
        checkIns: [CheckIn],
        tasks: [StormTask]
    ) async {
        print("🔄 Starting Firebase sync...")
        
        // Sync users
        for user in users {
            try? await saveUser(user)
        }
        
        // Sync referrals
        for referral in referrals {
            try? await saveReferral(referral)
        }
        
        // Sync transport requests
        for request in requests {
            try? await saveTransportRequest(request)
        }
        
        // Sync check-ins
        for checkIn in checkIns {
            try? await saveCheckIn(checkIn)
        }
        
        // Sync tasks
        for task in tasks {
            try? await saveTask(task)
        }
        
        DispatchQueue.main.async {
            self.lastSyncTime = Date()
        }
        
        print("✅ Firebase sync complete!")
    }
    
    // MARK: - Encoding/Decoding Helpers
    
    private func encodeToFirestore<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return json
    }
    
    private func decodeFromFirestore<T: Decodable>(_ type: T.Type, document: DocumentSnapshot) throws -> T {
        guard var data = document.data() else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data in document"])
        }
        
        // Add document ID to data
        data["id"] = document.documentID
        
        // Convert Firestore Timestamps to ISO8601 strings
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                data[key] = ISO8601DateFormatter().string(from: timestamp.dateValue())
            }
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: jsonData)
    }
}
