import SwiftUI
import FirebaseCore

// MARK: - App Delegate for Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase initialized successfully!")
        
        // Start real-time listeners
        FirebaseService.shared.startRealTimeListeners()
        
        return true
    }
}

// MARK: - Main App

@main
struct StormModeApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .task {
                    // Load data from Firebase on app start
                    await FirebaseService.shared.loadAllDataFromFirebase()
                }
        }
    }
}
