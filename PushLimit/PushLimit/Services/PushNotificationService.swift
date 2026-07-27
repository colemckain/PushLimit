import Foundation
import UserNotifications
import UIKit

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var isRegistered = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        do {
            let granted = try await center.requestAuthorization(options: options)
            
            await MainActor.run {
                self.isRegistered = granted
                self.checkAuthorizationStatus()
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Register for Remote Notifications
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Unregister from Remote Notifications
    func unregisterFromRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
        
        DispatchQueue.main.async {
            self.isRegistered = false
        }
    }
    
    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isRegistered = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Local Notification
    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugLog.log("Error scheduling notification:", error)
            }
        }
    }
    
    // MARK: - Remove All Pending Notifications
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Remove All Delivered Notifications
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        // Post notification for other parts of the app to handle
        NotificationCenter.default.post(
            name: NSNotification.Name(AppConstants.NotificationNames.pushNotificationReceived),
            object: nil,
            userInfo: userInfo
        )
        
        completionHandler()
    }
}

// MARK: - App Delegate Extension
extension PushNotificationService {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        DebugLog.log("Device token registered (length: \(token.count))")
        
        // Send token to your server
        sendDeviceTokenToServer(token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DebugLog.log("Failed to register for remote notifications:", error)
    }
    
    private func sendDeviceTokenToServer(_ token: String) {
        // Implement your server communication here
        // This is where you would send the device token to your backend
        DebugLog.log("Sending device token to server (length: \(token.count))")
    }
} 