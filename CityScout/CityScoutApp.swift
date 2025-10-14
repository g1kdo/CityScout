import SwiftUI
import Firebase
import FacebookCore
import FBSDKCoreKit
import FirebaseFirestore
import FirebaseAppCheck
import FirebaseAppCheckInterop
import GoogleMaps
import GooglePlaces
import FirebaseMessaging
import FirebaseAuth

// Define your AppCheckDebugProviderFactory
#if targetEnvironment(simulator)
class AppCheckDebugProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        let debugProvider = AppCheckDebugProvider(app: app)
        print("AppCheck Debug Token: \(String(describing: debugProvider?.localDebugToken()))")
        return debugProvider
    }
}
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        #if targetEnvironment(simulator)
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        // Configure Firebase
        FirebaseApp.configure()
        print("Firebase configured")
        
        // Configure Firestore cache
        let settings = FirestoreSettings()
        settings.cacheSizeBytes = Int64(truncating: NSNumber(value: 200 * 1024 * 1024))
        Firestore.firestore().settings = settings
        
        // Initialize Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        print("Facebook SDK initialized")
        
        // Provide API keys for Google Maps and Google Places
        GMSServices.provideAPIKey(Secrets.googleMapsAPIKey)
        GMSPlacesClient.provideAPIKey(Secrets.googleMapsAPIKey)
        
        // Register for push notifications
        PushNotificationManager.shared.registerForPushNotifications()
        
        return true
    }
    
    // Add a method to receive the APNS token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Let Facebook SDK handle login callbacks
        let handledByFacebook = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[.sourceApplication] as? String,
            annotation: options[.annotation]
        )
        return handledByFacebook
    }
}

@main
struct CityScoutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authVM = AuthenticationViewModel()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var messageVM = MessageViewModel()
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(homeVM)
                .environmentObject(messageVM)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Only proceed if a user is currently logged in
                    guard Auth.auth().currentUser != nil else { return }

                    switch newPhase {
                    case .active:
                        // App came to the foreground
                        Task {
                            await authVM.setStatus(isOnline: true)
                        }
                    case .inactive, .background:
                        // App is going away (background/multitasking view)
                        Task {
                            await authVM.setStatus(isOnline: false)
                        }
                    @unknown default:
                        break
                    }
                }
    }
}
