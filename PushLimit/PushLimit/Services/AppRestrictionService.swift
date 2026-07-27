import Foundation
import SwiftUI

// MARK: - Family Controls Feature Flag
// This code is disabled when Family Controls capability is not available
// To enable: Add Family Controls capability and use manual signing

#if false // Set to true when Family Controls is enabled

import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
class AppRestrictionService: ObservableObject {
    static let shared = AppRestrictionService()
    
    @Published var isAuthorized = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var isRestrictionActive = false
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            await checkAuthorizationStatus()
        } catch {
            DebugLog.log("Failed to request authorization: \(error)")
        }
    }
    
    func checkAuthorizationStatus() async {
        let status = center.authorizationStatus
        await MainActor.run {
            isAuthorized = status == .approved
        }
    }
    
    // MARK: - App Selection
    
    func showAppPicker() -> Bool {
        guard isAuthorized else { return false }
        return true
    }
    
    // MARK: - Restriction Management
    
    func lockApps() {
        guard isAuthorized && !selectedApps.applicationTokens.isEmpty else { return }
        
        store.shield.applications = selectedApps.applicationTokens
        store.shield.applicationCategories = .specific(selectedApps.categoryTokens)
        
        isRestrictionActive = true
        DebugLog.log("Apps locked: \(selectedApps.applicationTokens.count) apps")
    }
    
    func unlockApps() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        
        isRestrictionActive = false
        DebugLog.log("Apps unlocked")
    }
    
    // MARK: - Workout Integration
    
    func startWorkoutRestriction() {
        lockApps()
    }
    
    func completeWorkoutRestriction() {
        unlockApps()
    }
    
    // MARK: - Persistence
    
    func saveSelection() {
        // Save the selection to UserDefaults for persistence
        if let data = try? JSONEncoder().encode(selectedApps) {
            UserDefaults.standard.set(data, forKey: "savedAppSelection")
        }
    }
    
    func loadSelection() {
        // Load the saved selection from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savedAppSelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
    }
}

#else

// MARK: - Stub Implementation (Family Controls Disabled)
@MainActor
class AppRestrictionService: ObservableObject {
    static let shared = AppRestrictionService()
    
    @Published var isAuthorized = false
    @Published var isRestrictionActive = false
    
    private init() {
        DebugLog.log("⚠️ AppRestrictionService: Family Controls is disabled")
    }
    
    func requestAuthorization() async {
        DebugLog.log("⚠️ Family Controls not available - feature disabled")
    }
    
    func checkAuthorizationStatus() async {
        isAuthorized = false
    }
    
    func showAppPicker() -> Bool {
        return false
    }
    
    func lockApps() {
        DebugLog.log("⚠️ Family Controls not available - cannot lock apps")
    }
    
    func unlockApps() {
        DebugLog.log("⚠️ Family Controls not available - cannot unlock apps")
    }
    
    func startWorkoutRestriction() {
        DebugLog.log("⚠️ Workout restriction feature requires Family Controls")
    }
    
    func completeWorkoutRestriction() {
        DebugLog.log("⚠️ Workout restriction feature requires Family Controls")
    }
    
    func saveSelection() {
        // No-op when disabled
    }
    
    func loadSelection() {
        // No-op when disabled
    }
}

#endif
