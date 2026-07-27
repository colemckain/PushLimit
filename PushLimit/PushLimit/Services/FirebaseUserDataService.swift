import Foundation
import SwiftUI
import Combine

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Syncs profile, plan, completed workouts, and progress to Firestore for the signed-in user.
/// Requires Firebase Auth + Firestore in the project and Firestore security rules (see `FIRESTORE_SETUP.md`).
@MainActor
final class FirebaseUserDataService: ObservableObject {
    static let shared = FirebaseUserDataService()
    
    @Published private(set) var isSignedIn = false
    @Published private(set) var isEmailVerified = false
    @Published private(set) var email: String?
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncError: String?
    @Published private(set) var lastSyncMessage: String?
    @Published private(set) var lastSuccessfulSyncAt: Date?
    /// True when the last failed sync was a Firestore permission / rules issue (not network, etc.).
    @Published private(set) var lastSyncWasPermissionDenied = false
    
    /// Signed-in users only: show “permission / backup disabled” when rules block Firestore.
    var shouldShowBackupPermissionIssue: Bool {
        guard Self.isCloudSyncAvailable, isSignedIn else { return false }
        return lastSyncWasPermissionDenied
    }

    /// Signed in but email not verified — local app works; cloud backup is paused.
    var needsEmailVerification: Bool {
        isSignedIn && !isEmailVerified
    }
    
    /// `true` when Auth + Firestore SDKs are available in this build.
    static var isCloudSyncAvailable: Bool {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        return true
        #else
        return false
        #endif
    }
    
    weak var workoutViewModel: WorkoutViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var isApplyingRemotePayload = false
    /// Blocks cloud load/upload during permanent reset so stale remote data cannot return.
    private var isCloudSyncPaused = false
    
    private init() {
        #if canImport(FirebaseAuth)
        FirebaseBootstrap.configureIfNeeded()
        refreshAuthStateFromFirebase()
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.applyAuthUser(user)
            }
        }
        #endif
        
        NotificationCenter.default.publisher(for: .workoutUserDataDidSave)
            .compactMap { $0.object as? WorkoutViewModel }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vm in
                Task { await self?.syncLocalToCloudIfNeeded(from: vm) }
            }
            .store(in: &cancellables)
    }
    
    func attach(_ viewModel: WorkoutViewModel) {
        workoutViewModel = viewModel
        #if canImport(FirebaseAuth)
        // Refreshes sign-in state and loads from Firestore when a user is already signed in.
        refreshAuthStateFromFirebase()
        #endif
    }
    
    /// Call after fixing Firestore rules or to refresh cloud state (signed-in only).
    func retryCloudSync() async {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        await loadRemoteOrUploadLocal(uid: uid)
        #endif
    }
    
    #if canImport(FirebaseAuth)
    private func refreshAuthStateFromFirebase() {
        applyAuthUser(Auth.auth().currentUser)
    }
    
    private func applyAuthUser(_ user: User?) {
        isSignedIn = user != nil
        email = user?.email
        isEmailVerified = user?.isEmailVerified ?? false
        if user == nil {
            lastSyncError = nil
            lastSyncMessage = nil
            lastSuccessfulSyncAt = nil
            lastSyncWasPermissionDenied = false
            return
        }
        guard isEmailVerified else {
            lastSyncMessage = "Verify your email to enable cloud backup."
            lastSyncError = nil
            return
        }
        #if canImport(FirebaseFirestore)
        if let uid = user?.uid, !isCloudSyncPaused {
            Task { await loadRemoteOrUploadLocal(uid: uid) }
        }
        #endif
    }

    /// Sends a verification email to the signed-in user.
    func sendVerificationEmail() async {
        do {
            try await FirebaseAuthClient.sendEmailVerification()
            lastSyncMessage = "Verification email sent. Check your inbox and spam folder."
            lastSyncError = nil
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    /// Reloads the auth user and returns whether email is now verified.
    @discardableResult
    func refreshEmailVerificationStatus() async -> Bool {
        #if canImport(FirebaseAuth)
        do {
            let verified = try await FirebaseAuthClient.reloadCurrentUserEmailVerified()
            isEmailVerified = verified
            if verified {
                lastSyncMessage = "Email verified. Syncing your account…"
                lastSyncError = nil
                #if canImport(FirebaseFirestore)
                if let uid = Auth.auth().currentUser?.uid, !isCloudSyncPaused {
                    await loadRemoteOrUploadLocal(uid: uid)
                }
                #endif
            }
            return verified
        } catch {
            lastSyncError = error.localizedDescription
            return false
        }
        #else
        return false
        #endif
    }
    #endif
    
    /// Deletes cloud backup, wipes local storage, signs out, and returns to onboarding. Returns an error message if cloud delete failed.
    func resetAllDataPermanently() async -> String? {
        isCloudSyncPaused = true
        isApplyingRemotePayload = true
        lastSyncError = nil
        lastSyncMessage = nil
        lastSuccessfulSyncAt = nil
        lastSyncWasPermissionDenied = false
        
        var cloudError: String?
        
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        if let uid = Auth.auth().currentUser?.uid {
            do {
                try await Firestore.firestore().collection("users").document(uid).delete()
                DebugLog.log("☁️ Deleted Firestore user document for signed-in user")
            } catch {
                cloudError = error.localizedDescription
                lastSyncWasPermissionDenied = Self.isFirestorePermissionDenied(error)
                lastSyncError = cloudError
                DebugLog.log("☁️ Firestore delete failed:", error.localizedDescription)
            }
        }
        #endif
        
        workoutViewModel?.clearAllData()
        clearAllLocalPersistenceExtras()
        
        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
        } catch {
            if cloudError == nil {
                cloudError = error.localizedDescription
            }
            lastSyncError = error.localizedDescription
        }
        #endif
        
        isSignedIn = false
        isEmailVerified = false
        email = nil
        isApplyingRemotePayload = false
        isCloudSyncPaused = false
        
        NotificationCenter.default.post(name: .userDidResetAllData, object: nil)
        
        return cloudError
    }
    
    private func clearAllLocalPersistenceExtras() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.isFirstLaunch)
        defaults.removeObject(forKey: "onboardingDraftV1")
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.onboardingDraft)
        defaults.removeObject(forKey: "savedAppSelection")
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.isFirstLaunch)
        defaults.synchronize()
    }
    
    /// Push local onboarding-related data to `users/{uid}` when the user is signed in.
    func syncLocalToCloudIfNeeded(from viewModel: WorkoutViewModel) async {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard !isCloudSyncPaused,
              !isApplyingRemotePayload,
              let uid = Auth.auth().currentUser?.uid,
              Auth.auth().currentUser?.isEmailVerified == true,
              viewModel.hasCompletedOnboarding else { return }
        
        isSyncing = true
        lastSyncError = nil
        lastSyncWasPermissionDenied = false
        defer { isSyncing = false }
        
        do {
            try await uploadSnapshot(uid: uid, from: viewModel)
            lastSyncMessage = "Saved to account"
            lastSuccessfulSyncAt = Date()
        } catch {
            lastSyncWasPermissionDenied = Self.isFirestorePermissionDenied(error)
            lastSyncError = error.localizedDescription
            DebugLog.log("☁️ Firestore sync failed:", error.localizedDescription)
        }
        #endif
    }
    
    #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
    private func loadRemoteOrUploadLocal(uid: String) async {
        guard !isCloudSyncPaused, let vm = workoutViewModel else { return }
        #if canImport(FirebaseAuth)
        guard Auth.auth().currentUser?.isEmailVerified == true else {
            lastSyncMessage = "Verify your email to enable cloud backup."
            return
        }
        #endif
        
        isSyncing = true
        lastSyncError = nil
        lastSyncWasPermissionDenied = false
        defer { isSyncing = false }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard snapshot.exists, let data = snapshot.data() else {
                if vm.hasCompletedOnboarding {
                    try await uploadSnapshot(uid: uid, from: vm)
                    lastSyncMessage = "Backed up your profile"
                    lastSuccessfulSyncAt = Date()
                }
                return
            }

            do {
                try RemoteSnapshotValidator.validate(data)
            } catch {
                lastSyncError = error.localizedDescription
                lastSyncMessage = "Cloud backup could not be loaded safely. Your local data was kept."
                DebugLog.log("☁️ Remote snapshot validation failed:", error.localizedDescription)
                return
            }
            
            guard let profileJson = data["userProfileJson"] as? String,
                  let profileData = profileJson.data(using: .utf8) else {
                if vm.hasCompletedOnboarding {
                    try await uploadSnapshot(uid: uid, from: vm)
                    lastSyncMessage = "Backed up your profile"
                    lastSuccessfulSyncAt = Date()
                }
                return
            }
            
            let profile = try JSONDecoder().decode(UserProfile.self, from: profileData)
            let name = data["userName"] as? String ?? vm.userName
            
            let assessment: FitnessAssessment?
            if let aJson = data["fitnessAssessmentJson"] as? String, let aData = aJson.data(using: .utf8) {
                assessment = try? JSONDecoder().decode(FitnessAssessment.self, from: aData)
            } else {
                assessment = nil
            }
            
            let plan: WorkoutPlan?
            if let pJson = data["workoutPlanJson"] as? String, let pData = pJson.data(using: .utf8) {
                plan = try? JSONDecoder().decode(WorkoutPlan.self, from: pData)
            } else {
                plan = nil
            }
            
            let workouts: [Workout]
            if let wJson = data["workoutsJson"] as? String, let wData = wJson.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([Workout].self, from: wData) {
                workouts = decoded
            } else {
                workouts = []
            }
            
            let levelInfo: LevelInfo?
            if let j = data["levelInfoJson"] as? String, let d = j.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(LevelInfo.self, from: d) {
                levelInfo = decoded
            } else {
                levelInfo = nil
            }
            
            let weeklyGoalsRemote: WeeklyGoals?
            if let j = data["weeklyGoalsJson"] as? String, let d = j.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(WeeklyGoals.self, from: d) {
                weeklyGoalsRemote = decoded
            } else {
                weeklyGoalsRemote = nil
            }
            
            let weeklyProgressRemote: WeeklyProgress?
            if let j = data["weeklyProgressJson"] as? String, let d = j.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(WeeklyProgress.self, from: d) {
                weeklyProgressRemote = decoded
            } else {
                weeklyProgressRemote = nil
            }
            
            isApplyingRemotePayload = true
            vm.applyRemoteOnboardingSnapshot(
                userName: name,
                userProfile: profile,
                fitnessAssessment: assessment,
                currentWorkoutPlan: plan,
                workouts: workouts,
                levelInfo: levelInfo,
                weeklyGoalsOverride: weeklyGoalsRemote,
                weeklyProgress: weeklyProgressRemote
            )
            isApplyingRemotePayload = false
            lastSyncMessage = "Loaded from account"
            lastSuccessfulSyncAt = Date()
        } catch {
            lastSyncWasPermissionDenied = Self.isFirestorePermissionDenied(error)
            lastSyncError = error.localizedDescription
            DebugLog.log("☁️ Firestore load failed:", error.localizedDescription)
        }
    }
    
    private func uploadSnapshot(uid: String, from vm: WorkoutViewModel) async throws {
        let encoder = JSONEncoder()
        let profileJson = String(data: try encoder.encode(vm.userProfile), encoding: .utf8) ?? ""
        let workoutsJson = String(data: try encoder.encode(vm.workouts), encoding: .utf8) ?? "[]"
        let levelInfoJson = String(data: try encoder.encode(vm.levelInfo), encoding: .utf8) ?? ""
        let weeklyGoalsJson = String(data: try encoder.encode(vm.weeklyGoals), encoding: .utf8) ?? ""
        let weeklyProgressJson = String(data: try encoder.encode(vm.weeklyProgress), encoding: .utf8) ?? ""
        var fields: [String: Any] = [
            "userName": vm.userName,
            "userProfileJson": profileJson,
            "workoutsJson": workoutsJson,
            "levelInfoJson": levelInfoJson,
            "weeklyGoalsJson": weeklyGoalsJson,
            "weeklyProgressJson": weeklyProgressJson,
            "schemaVersion": 2,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let assessment = vm.fitnessAssessment {
            if let s = String(data: try encoder.encode(assessment), encoding: .utf8) {
                fields["fitnessAssessmentJson"] = s
            }
        }
        if let plan = vm.currentWorkoutPlan {
            if let s = String(data: try encoder.encode(plan), encoding: .utf8) {
                fields["workoutPlanJson"] = s
            }
        }
        try await Firestore.firestore().collection("users").document(uid).setData(fields, merge: true)
    }
    #endif
    
    func signOut() {
        lastSyncError = nil
        lastSyncMessage = nil
        lastSuccessfulSyncAt = nil
        lastSyncWasPermissionDenied = false
        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
        } catch {
            lastSyncError = error.localizedDescription
            return
        }
        #endif
        isSignedIn = false
        isEmailVerified = false
        email = nil
        lastSyncMessage = "Signed out. Your workouts stay on this device."
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    /// Detects Firestore “PERMISSION_DENIED” across NSError domains / localized strings.
    private static func isFirestorePermissionDenied(_ error: Error) -> Bool {
        let ns = error as NSError
        let domain = ns.domain
        if domain == "FIRFirestoreErrorDomain" || domain.contains("Firestore") {
            // PERMISSION_DENIED = 7 in Firebase Firestore public API
            if ns.code == 7 {
                return true
            }
        }
        let msg = error.localizedDescription.lowercased()
        if msg.contains("permission_denied") { return true }
        if msg.contains("permission denied") { return true }
        if msg.contains("missing or insufficient permissions") { return true }
        if msg.contains("insufficient permission") { return true }
        return false
    }
}
