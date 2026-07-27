import Foundation

struct AppConstants {
    
    // MARK: - App Information
    static let appName = "PushLimit"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.pushlimit.com"
        static let timeoutInterval: TimeInterval = 30.0
        static let maxRetries = 3
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let isFirstLaunch = "isFirstLaunch"
        static let userToken = "userToken"
        static let userId = "userId"
        static let pushNotificationsEnabled = "pushNotificationsEnabled"
        /// Mid-onboarding draft (v2 = shorter flow + reordered auth). Cleared on sign-out / reset.
        static let onboardingDraft = "onboardingDraftV2"
    }
    
    // MARK: - Notification Names
    struct NotificationNames {
        static let userDidLogin = "userDidLogin"
        static let userDidLogout = "userDidLogout"
        static let pushNotificationReceived = "pushNotificationReceived"
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 8.0
        static let buttonHeight: CGFloat = 44.0
        static let standardPadding: CGFloat = 16.0
        static let smallPadding: CGFloat = 8.0
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let short: TimeInterval = 0.2
        static let medium: TimeInterval = 0.3
        static let long: TimeInterval = 0.5
    }
} 