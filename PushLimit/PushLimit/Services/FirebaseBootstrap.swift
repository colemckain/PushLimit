import Foundation

#if canImport(FirebaseAppCheck)
import FirebaseAppCheck
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAppCheck) && canImport(FirebaseCore)
/// Production App Check provider — App Attest on iOS 14+, DeviceCheck fallback.
private final class PushLimitAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        }
        return DeviceCheckProvider(app: app)
    }
}
#endif

/// Configures Firebase App Check (when available) before `FirebaseApp.configure()`.
/// Must run once, before any other Firebase API usage.
enum FirebaseBootstrap {
    private static var didConfigure = false
    private static let lock = NSLock()

    static func configureIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didConfigure else { return }

        #if canImport(FirebaseAppCheck)
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(PushLimitAppCheckProviderFactory())
        #endif
        #endif

        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif

        didConfigure = true
    }
}
