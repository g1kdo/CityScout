import SwiftUI
import Firebase
import FacebookCore
import FBSDKCoreKit
import FirebaseFirestore
import FirebaseAppCheck
import FirebaseAppCheckInterop
import GoogleMaps
import GooglePlaces

// Define your AppCheckDebugProviderFactory
#if targetEnvironment(simulator)
class AppCheckDebugProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        let debugProvider = AppCheckDebugProvider(app: app)
        print("AppCheck Debug Token: \(debugProvider?.localDebugToken())")
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
        let settings = FirestoreSettings()
        // Set the cache size to 200 MB
        settings.cacheSizeBytes = Int64(truncating: NSNumber(value: 200 * 1024 * 1024))
        Firestore.firestore().settings = settings

        // Initialize Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        print("Facebook SDK initialized")
    
        GMSServices.provideAPIKey(Secrets.googleMapsAPIKey)
        
        GMSPlacesClient.provideAPIKey(Secrets.googleMapsAPIKey)

        return true
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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}
