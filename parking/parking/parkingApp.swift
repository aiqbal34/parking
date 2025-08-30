import SwiftUI
import FirebaseCore

@main
struct ParkingApp: App {
    @StateObject private var firebaseService = FirebaseService()
    
    init() {
        FirebaseApp.configure()
        
        // Note: App Check is disabled for development to avoid simulator warnings
        // For production, you can enable it by uncommenting the code below:
        /*
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #else
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        */
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseService.isAuthenticated {
                    ContentView()
                        .environmentObject(firebaseService)
                        .onAppear {
                            print("🔍 User is authenticated, showing ContentView")
                        }
                } else {
                    AuthenticationView()
                        .environmentObject(firebaseService)
                        .onAppear {
                            print("🔍 User is not authenticated, showing AuthenticationView")
                        }
                }
            }
        }
    }
}
