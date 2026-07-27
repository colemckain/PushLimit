import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var userName: String = "User"
    @Published var profileColor: Color = .customOrange
    @Published var profileAvatarPreset: ProfileAvatarPreset = .initial
    @Published var themeColor: Color = .customOrange  // App theme color (replaces orange highlights)
    @Published var feedbackTone: FeedbackTone = .disciplined
    @Published var levelInfo: LevelInfo = LevelInfo(
        level: 1,
        title: "Rookie",
        progress: 0.0,
        xpInCurrentLevel: 0,
        xpToNextLevel: 100
    )
    @Published var weeklyGoals: WeeklyGoals = WeeklyGoals()
    @Published var weeklyProgress: WeeklyProgress = WeeklyProgress()
    
    // MARK: - New Profile & Plan Properties
    @Published var userProfile: UserProfile = UserProfile()
    @Published var fitnessAssessment: FitnessAssessment?
    @Published var currentWorkoutPlan: WorkoutPlan?
    
    // MARK: - Level Up Achievement
    @Published var showLevelUpAchievement = false
    @Published var levelUpInfo: (newLevel: Int, newTitle: String, oldLevel: Int, oldTitle: String)?
    
    // MARK: - UserDefaults Keys (theme only — sensitive data uses Keychain via SecureUserDataStore)
    private let workoutsKey = "savedWorkouts"
    private let userNameKey = "userName"
    private let profileColorKey = "profileColor"
    private let profileAvatarPresetKey = "profileAvatarPreset"
    private let levelInfoKey = "levelInfo"
    private let weeklyGoalsKey = "weeklyGoals"
    private let weeklyProgressKey = "weeklyProgress"
    private let userProfileKey = "userProfile"
    private let fitnessAssessmentKey = "fitnessAssessment"
    private let currentWorkoutPlanKey = "currentWorkoutPlan"
    private let themeColorKey = "themeColor"
    private let feedbackToneKey = FeedbackTone.userDefaultsKey
    private let sessionDraftsKey = "workoutSessionDrafts"

    /// In-progress sessions that can be continued later today (keyed by exercise id).
    @Published private(set) var sessionDrafts: [String: WorkoutSessionDraft] = [:]

    private static let secureDataKeys = [
        "savedWorkouts",
        "userName",
        "levelInfo",
        "weeklyGoals",
        "weeklyProgress",
        "userProfile",
        "fitnessAssessment",
        "currentWorkoutPlan"
    ]
    
    // Available theme colors (bright highlighter colors)
    static let availableThemeColors: [Color] = [
        Color(red: 1.0, green: 0.4, blue: 0.0),      // Bright Orange
        Color(red: 1.0, green: 0.0, blue: 0.3),      // Bright Red/Pink
        Color(red: 1.0, green: 0.2, blue: 0.8),      // Bright Magenta
        Color(red: 0.6, green: 0.0, blue: 1.0),      // Bright Purple
        Color(red: 0.2, green: 0.4, blue: 1.0),      // Bright Blue
        Color(red: 0.0, green: 0.8, blue: 1.0),      // Bright Cyan
        Color(red: 0.0, green: 0.9, blue: 0.4),      // Bright Green
        Color(red: 0.8, green: 1.0, blue: 0.0),      // Bright Yellow/Green
        Color(red: 1.0, green: 0.8, blue: 0.0),     // Bright Yellow
    ]
    
    // Available profile colors
    static let availableProfileColors: [Color] = [
        .customOrange,
        .blue,
        .green,
        .purple,
        .pink,
        .red,
        .indigo,
        .teal,
        .mint,
        .brown
    ]
    
    init() {
        loadData()
        checkAndResetWeeklyProgress()
        // Debug: Print loaded userName
        DebugLog.log("🔍 WorkoutViewModel init - Loaded userName: '\(userName)'")
    }
    
    // MARK: - Data Persistence

    private func migrateSensitiveDataFromUserDefaultsIfNeeded() {
        for key in Self.secureDataKeys {
            guard SecureUserDataStore.data(forKey: key) == nil else { continue }
            if let data = UserDefaults.standard.data(forKey: key) {
                try? SecureUserDataStore.set(data, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
                DebugLog.log("🔐 Migrated \(key) from UserDefaults to Keychain")
            } else if key == userNameKey, let name = UserDefaults.standard.string(forKey: key) {
                try? SecureUserDataStore.setString(name, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
                DebugLog.log("🔐 Migrated userName from UserDefaults to Keychain")
            }
        }
    }

    private func secureSet(_ data: Data, forKey key: String) {
        do {
            try SecureUserDataStore.set(data, forKey: key)
        } catch {
            DebugLog.log("❌ Keychain save failed for \(key): \(error)")
        }
    }

    private func secureData(forKey key: String) -> Data? {
        SecureUserDataStore.data(forKey: key)
    }

    private func saveData() {
        do {
            // Save workouts
            let workoutsData = try JSONEncoder().encode(workouts)
            secureSet(workoutsData, forKey: workoutsKey)
            
            // Save user name - always save if not empty
            // Save it regardless of whether it's "User" or a real name, so we can track state
            do {
                try SecureUserDataStore.setString(userName, forKey: userNameKey)
            } catch {
                DebugLog.log("❌ Keychain save failed for userName: \(error)")
            }
            if !userName.isEmpty && userName != "User" {
                DebugLog.log("💾 Saving user name: '\(userName)' to key: '\(userNameKey)'")
            } else if userName == "User" {
                DebugLog.log("💾 Saving default userName: 'User' to key: '\(userNameKey)'")
            } else {
                DebugLog.log("⚠️ Saving empty userName to key: '\(userNameKey)'")
            }
            
            // Save profile color (non-sensitive preference)
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(profileColor), requiringSecureCoding: false) {
                UserDefaults.standard.set(colorData, forKey: profileColorKey)
            }

            UserDefaults.standard.set(profileAvatarPreset.rawValue, forKey: profileAvatarPresetKey)

            FeedbackTone.persist(feedbackTone)
            
            // Save theme color (non-sensitive preference)
            if let themeColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(themeColor), requiringSecureCoding: false) {
                UserDefaults.standard.set(themeColorData, forKey: themeColorKey)
            }
            
            // Save level info
            let levelInfoData = try JSONEncoder().encode(levelInfo)
            secureSet(levelInfoData, forKey: levelInfoKey)
            
            // Save weekly goals
            let weeklyGoalsData = try JSONEncoder().encode(weeklyGoals)
            secureSet(weeklyGoalsData, forKey: weeklyGoalsKey)
            
            // Save weekly progress
            let weeklyProgressData = try JSONEncoder().encode(weeklyProgress)
            secureSet(weeklyProgressData, forKey: weeklyProgressKey)
            
            // Save user profile
            let userProfileData = try JSONEncoder().encode(userProfile)
            secureSet(userProfileData, forKey: userProfileKey)
            
            // Save fitness assessment (remove key when cleared so reset does not resurrect old data)
            if let assessment = fitnessAssessment {
                let assessmentData = try JSONEncoder().encode(assessment)
                secureSet(assessmentData, forKey: fitnessAssessmentKey)
            } else {
                SecureUserDataStore.remove(forKey: fitnessAssessmentKey)
            }
            
            // Save current workout plan
            if let plan = currentWorkoutPlan {
                let planData = try JSONEncoder().encode(plan)
                secureSet(planData, forKey: currentWorkoutPlanKey)
            } else {
                SecureUserDataStore.remove(forKey: currentWorkoutPlanKey)
            }
            
            UserDefaults.standard.synchronize()
            DebugLog.log("💾 Data saved successfully")
            
            NotificationCenter.default.post(name: .workoutUserDataDidSave, object: self)
        } catch {
            DebugLog.log("❌ Error saving data: \(error)")
        }
    }
    
    private func loadData() {
        migrateSensitiveDataFromUserDefaultsIfNeeded()

        do {
            // Load workouts
            if let workoutsData = secureData(forKey: workoutsKey) {
                workouts = try JSONDecoder().decode([Workout].self, from: workoutsData)
                DebugLog.log("📱 Loaded \(workouts.count) workouts")
            }
            
            // Load user name
            DebugLog.log("🔍 Checking Keychain for userNameKey: '\(userNameKey)'")
            
            if let savedUserName = SecureUserDataStore.string(forKey: userNameKey) {
                if !savedUserName.isEmpty {
                    userName = savedUserName
                    DebugLog.log("✅ Loaded user name from Keychain: '\(userName)'")
                } else {
                    DebugLog.log("⚠️ Found userNameKey but value is empty string, keeping default: '\(userName)'")
                }
            } else {
                DebugLog.log("⚠️ No saved user name found in Keychain for key '\(userNameKey)', keeping default: '\(userName)'")
            }
            
            // Load profile color
            if let colorData = UserDefaults.standard.data(forKey: profileColorKey),
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                profileColor = Color(uiColor: uiColor)
                DebugLog.log("📱 Loaded profile color")
            }

            if let avatarRaw = UserDefaults.standard.string(forKey: profileAvatarPresetKey),
               let preset = ProfileAvatarPreset(rawValue: avatarRaw) {
                profileAvatarPreset = preset
            }
            
            // Load theme color
            if let themeColorData = UserDefaults.standard.data(forKey: themeColorKey),
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: themeColorData) {
                themeColor = Color(uiColor: uiColor)
                DebugLog.log("📱 Loaded theme color")
            }

            if let toneRaw = UserDefaults.standard.string(forKey: feedbackToneKey),
               let tone = FeedbackTone(rawValue: toneRaw) {
                feedbackTone = tone
            }
            
            // Load level info
            if let levelInfoData = secureData(forKey: levelInfoKey) {
                levelInfo = try JSONDecoder().decode(LevelInfo.self, from: levelInfoData)
                DebugLog.log("📱 Loaded level info: Level \(levelInfo.level) - \(levelInfo.title)")
            }
            
            // Load weekly goals
            if let weeklyGoalsData = secureData(forKey: weeklyGoalsKey) {
                weeklyGoals = try JSONDecoder().decode(WeeklyGoals.self, from: weeklyGoalsData)
                DebugLog.log("📱 Loaded weekly goals: P:\(weeklyGoals.pushups) S:\(weeklyGoals.situps) Sq:\(weeklyGoals.squats)")
            }
            
            // Load weekly progress
            if let weeklyProgressData = secureData(forKey: weeklyProgressKey) {
                weeklyProgress = try JSONDecoder().decode(WeeklyProgress.self, from: weeklyProgressData)
                DebugLog.log("📱 Loaded weekly progress: P:\(weeklyProgress.pushupsCompleted) S:\(weeklyProgress.situpsCompleted) Sq:\(weeklyProgress.squatsCompleted)")
            }
            
            // Load user profile
            if let userProfileData = secureData(forKey: userProfileKey) {
                userProfile = try JSONDecoder().decode(UserProfile.self, from: userProfileData)
                DebugLog.log("📱 Loaded user profile: Age \(userProfile.age ?? 0), Goal: \(userProfile.fitnessGoal.rawValue)")
            }
            
            // Load fitness assessment
            if let assessmentData = secureData(forKey: fitnessAssessmentKey) {
                fitnessAssessment = try JSONDecoder().decode(FitnessAssessment.self, from: assessmentData)
                DebugLog.log("📱 Loaded fitness assessment: Level \(fitnessAssessment?.fitnessLevel.rawValue ?? "N/A")")
            }
            
            // Load current workout plan
            if let planData = secureData(forKey: currentWorkoutPlanKey) {
                do {
                    var plan = try JSONDecoder().decode(WorkoutPlan.self, from: planData)
                    if plan.migrateSitUpsToCoreWorkoutIfNeeded() {
                        currentWorkoutPlan = plan
                        saveData()
                        DebugLog.log("🔄 Migrated Sit-ups plan rows to Core Workout")
                    } else {
                        currentWorkoutPlan = plan
                    }
                    DebugLog.log("📱 Loaded workout plan: \(currentWorkoutPlan?.name ?? "N/A")")
                } catch {
                    DebugLog.log("⚠️ Failed to decode workout plan (likely missing new properties): \(error)")
                    DebugLog.log("🔄 Will attempt to regenerate plan after load...")
                }
            }
            
            DebugLog.log("📱 Data loaded successfully")
        } catch {
            DebugLog.log("❌ Error loading data: \(error)")
        }
        
        // MARK: - Auto-Migration: Regenerate plan if it's missing but user has completed onboarding
        if currentWorkoutPlan == nil && userProfile.hasCompletedOnboarding {
            DebugLog.log("🔄 Detected missing workout plan for completed onboarding - regenerating...")
            regeneratePlanFromProfile()
        }
        
        // Clear any legacy mid-workout resume drafts — sessions must be finished in one sitting.
        clearAllSessionDrafts()
    }
    
    // MARK: - Session drafts (legacy cleared; no mid-workout resume)
    
    func sessionDraft(for exerciseId: String) -> WorkoutSessionDraft? { nil }
    
    func hasResumableSession(for exerciseId: String) -> Bool { false }
    
    func ensureResumeDraftIfNeeded(for exerciseId: String, plannedSets: Int, plannedRepsPerSet: Int, plannedTotalReps: Int) {
        // Intentional no-op: early quit does not create a Continue draft.
    }
    
    func saveSessionDraft(_ draft: WorkoutSessionDraft) {
        // Intentional no-op — workouts must be completed in one sitting.
    }
    
    func clearSessionDraft(for exerciseId: String) {
        WorkoutNotificationService.shared.clearEarlyQuitDebtNotification(for: exerciseId)
    }
    
    func clearAllSessionDrafts() {
        sessionDrafts = [:]
        UserDefaults.standard.removeObject(forKey: sessionDraftsKey)
    }
    
    private func loadSessionDrafts() {
        // Discard persisted resume drafts from earlier app versions.
        clearAllSessionDrafts()
    }
    
    /// Reps logged today for a catalog / move id (`pushups`, `squats`, `core-crunches`, …).
    func repsLoggedToday(forExerciseId exerciseId: String) -> Int {
        let id = exerciseId.lowercased()
        return getTodaysWorkouts()
            .filter { workoutMatchesExerciseId($0, exerciseId: id) }
            .reduce(0) { $0 + $1.reps }
    }
    
    private func workoutMatchesExerciseId(_ workout: Workout, exerciseId id: String) -> Bool {
        let logged = workout.exercise.lowercased()
        if CoreWorkoutSupport.isCoreMoveId(id) {
            return logged == id
        }
        if CoreWorkoutSupport.isCoreCatalogId(id) {
            return CoreWorkoutSupport.isCoreWorkoutLog(logged)
        }
        if id.contains("push") {
            return logged.contains("push")
        }
        if id.contains("squat") || id == LegWorkoutSupport.strengthExerciseId {
            return LegWorkoutSupport.isLegWorkoutLog(logged) && logged != LegWorkoutSupport.runExerciseId
        }
        return logged == id || logged.contains(id) || id.contains(logged)
    }
    
    /// True when the user finished a full uninterrupted session for this exercise today.
    func hasFullSessionCompletionToday(forExerciseId exerciseId: String) -> Bool {
        getTodaysWorkouts().contains {
            workoutMatchesExerciseId($0, exerciseId: exerciseId.lowercased()) && $0.isFullSessionCompletion
        }
    }
    
    func plannedTotalReps(forExerciseId exerciseId: String) -> Int? {
        guard let todaysPlan = getTodaysRecommendation() else { return nil }
        let id = exerciseId.lowercased()
        let match = todaysPlan.exercises.first { planEx in
            let planName = planEx.exercise.lowercased()
            if CoreWorkoutSupport.isCoreMoveId(id) {
                return CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)
            }
            if CoreWorkoutSupport.isCoreCatalogId(id) {
                return CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)
            }
            if id.contains("push") { return planName.contains("push") }
            if id.contains("squat") || id.contains("leg") {
                return planName.contains("squat") || planName.contains("leg")
            }
            return planName.contains(id) || id.contains(planName)
        }
        if CoreWorkoutSupport.isCoreMoveId(id), let match {
            return CoreWorkoutSupport.repsPerMove(dailyTotal: match.totalReps)
        }
        return match?.totalReps
    }
    
    // MARK: - Plan Regeneration Helper
    private func regeneratePlanFromProfile() {
        // Only regenerate if we have the necessary data
        guard userProfile.hasCompletedOnboarding else {
            DebugLog.log("⚠️ Cannot regenerate plan - onboarding not completed")
            return
        }
        
        let newPlan = WorkoutPlanGenerator.generateWorkoutPlan(
            profile: userProfile,
            assessment: fitnessAssessment
        )
        
        currentWorkoutPlan = newPlan
        weeklyGoals = newPlan.weeklyGoals
        saveData()
        DebugLog.log("✅ Successfully regenerated workout plan: \(newPlan.name)")
    }
    
    // MARK: - Public Data Management
    func saveUserData() {
        saveData()
    }
    
    func updateProfileColor(_ color: Color) {
        profileColor = color
        saveData()
        DebugLog.log("🎨 Updated profile color")
    }

    func updateProfileAvatar(preset: ProfileAvatarPreset, color: Color) {
        profileAvatarPreset = preset
        profileColor = color
        saveData()
        DebugLog.log("🎨 Updated profile avatar: \(preset.rawValue)")
    }
    
    func updateThemeColor(_ color: Color) {
        themeColor = color
        saveData()
        DebugLog.log("🎨 Updated theme color")
    }

    func updateFeedbackTone(_ tone: FeedbackTone) {
        feedbackTone = tone
        FeedbackTone.persist(tone)
        saveData()
        updateWorkoutNotifications()
        DebugLog.log("💬 Updated feedback tone: \(tone.rawValue)")
    }

    // MARK: - Testing / Cheat Actions

    func devAddLevel() {
        let xpNeeded = max(1, levelInfo.xpToNextLevel - levelInfo.xpInCurrentLevel)
        addXP(xpNeeded)
    }

    func devSetCurrentStreak(days: Int) {
        let target = max(0, days)
        let calendar = Calendar.current

        workouts.removeAll { calendar.isDateInToday($0.timestamp) || isWorkoutInRecentWindow($0.timestamp, days: target + 7, calendar: calendar) }

        guard target > 0 else {
            saveData()
            updateWorkoutNotifications()
            DebugLog.log("🧪 Dev set streak to 0")
            return
        }

        let templateExercise = currentWorkoutPlan?.dailyRecommendations.first(where: { !$0.restDay })?.exercises.first?.exercise
            ?? "Push-ups"

        for offset in 0..<target {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let workout = Workout(
                exercise: templateExercise,
                reps: 10,
                timestamp: date,
                timeSpent: 120
            )
            workouts.insert(workout, at: 0)
        }

        saveData()
        updateWorkoutNotifications()
        DebugLog.log("🧪 Dev set streak to \(target)")
    }

    func devShiftWeeklyProgress(days: Int) {
        let calendar = Calendar.current
        weeklyProgress.weekStartDate = calendar.date(byAdding: .day, value: days, to: weeklyProgress.weekStartDate) ?? weeklyProgress.weekStartDate
        saveData()
        DebugLog.log("🧪 Dev shifted weekly progress by \(days) days")
    }

    func devSetPlanWeek(_ week: Int) {
        guard var plan = currentWorkoutPlan else { return }
        plan.currentWeek = max(1, min(6, week))
        plan.lastProgressionCheckDate = Date()
        saveWorkoutPlan(plan)
        DebugLog.log("🧪 Dev set plan week to \(plan.currentWeek)")
    }

    func devCycleFeedbackTone() {
        let nextTone: FeedbackTone = feedbackTone == .supportive ? .disciplined : .supportive
        updateFeedbackTone(nextTone)
    }

    private func isWorkoutInRecentWindow(_ date: Date, days: Int, calendar: Calendar) -> Bool {
        guard let start = calendar.date(byAdding: .day, value: -max(0, days), to: Date()) else { return false }
        return date >= start
    }
    
    func clearAllData() {
        workouts = []
        userName = "User"
        profileColor = .customOrange
        profileAvatarPreset = .initial
        themeColor = .customOrange
        feedbackTone = .disciplined
        levelInfo = LevelInfo(
            level: 1,
            title: "Rookie",
            progress: 0.0,
            xpInCurrentLevel: 0,
            xpToNextLevel: 100
        )
        weeklyGoals = WeeklyGoals()
        weeklyProgress = WeeklyProgress()
        userProfile = UserProfile()
        fitnessAssessment = nil
        currentWorkoutPlan = nil
        showLevelUpAchievement = false
        levelUpInfo = nil
        
        // Clear from Keychain + preferences
        SecureUserDataStore.removeAll(forKeys: Self.secureDataKeys)
        UserDefaults.standard.removeObject(forKey: profileColorKey)
        UserDefaults.standard.removeObject(forKey: profileAvatarPresetKey)
        UserDefaults.standard.removeObject(forKey: themeColorKey)
        UserDefaults.standard.removeObject(forKey: feedbackToneKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.onboardingDraft)
        UserDefaults.standard.removeObject(forKey: "onboardingDraftV1")
        UserDefaults.standard.removeObject(forKey: "savedAppSelection")
        LegalConsentStore.clearAll()
        UserDefaults.standard.synchronize()
        
        DebugLog.log("🗑️ All data cleared")
    }
    
    // MARK: - Goal Management
    func updateWeeklyGoals(pushups: Int, situps: Int, squats: Int) {
        weeklyGoals.pushups = pushups
        weeklyGoals.situps = situps
        weeklyGoals.squats = squats
        saveData()
        DebugLog.log("🎯 Updated weekly goals: P:\(pushups) S:\(situps) Sq:\(squats)")
    }
    
    // MARK: - Weekly Progress Management
    private func checkAndResetWeeklyProgress() {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Monday)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // If the stored week start date is different from current week start, reset progress
        if !calendar.isDate(weeklyProgress.weekStartDate, inSameDayAs: weekStart) {
            weeklyProgress = WeeklyProgress(weekStartDate: weekStart)
            saveData()
            DebugLog.log("🔄 Weekly progress reset for new week starting \(weekStart)")
        }
    }
    
    func updateWeeklyProgress(for exercise: String, reps: Int) {
        checkAndResetWeeklyProgress()
        
        let exerciseLower = exercise.lowercased()
        if exerciseLower.contains("push") {
            weeklyProgress.pushupsCompleted += reps
        } else if CoreWorkoutSupport.isCoreProgressLabel(exercise) {
            weeklyProgress.situpsCompleted += reps
        } else if exerciseLower.contains("squat") || exerciseLower.contains("leg") {
            weeklyProgress.squatsCompleted += reps
        }
        
        saveData()
        DebugLog.log("📊 Updated weekly progress: \(exercise) +\(reps) reps")
    }
    
    func updateWallSitTime(seconds: Int) {
        checkAndResetWeeklyProgress()
        weeklyProgress.wallSitTimeCompleted += seconds
        saveData()
        DebugLog.log("📊 Updated wall sit time: +\(seconds) seconds (Total: \(weeklyProgress.wallSitTimeCompleted)s)")
    }

    func completeLegRun(timeSpent: Int, distanceMeters: Double, creditedSquatReps: Int) {
        let workout = Workout(
            exercise: LegWorkoutSupport.runExerciseId,
            reps: creditedSquatReps,
            timeSpent: timeSpent,
            distanceMeters: distanceMeters
        )
        workouts.insert(workout, at: 0)
        updateWeeklyProgress(for: "Legs", reps: creditedSquatReps)
        updateWallSitTime(seconds: 60)
        addXP(WorkoutRewards.xp(forRepGoal: creditedSquatReps))
        saveData()
        updateWorkoutNotifications()
        DebugLog.log("🏃 Completed leg run: \(LegWorkoutSupport.formatDistance(distanceMeters)) in \(timeSpent)s")
    }
    
    // MARK: - Goal Progress Calculation
    func getGoalProgress() -> [GoalProgress] {
        checkAndResetWeeklyProgress()
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = Date()
        // Find the start of the week (Monday)
        let _ = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        // Find the end of the week (Sunday, 23:59:59)
        let weekEnd: Date = {
            if let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
                return calendar.date(byAdding: .day, value: 6, to: start)?.addingTimeInterval(86399) ?? today
            } else {
                return today
            }
        }()
        // Calculate days left in the week (including today)
        let daysLeft = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: weekEnd)).day ?? 0
        let daysLeftInWeek = max(1, daysLeft + 1) // Include today
        
        return [
            GoalProgress(
                workoutType: "Push-ups",
                weeklyGoal: weeklyGoals.pushups,
                completed: weeklyProgress.pushupsCompleted,
                daysLeftInWeek: daysLeftInWeek
            ),
            GoalProgress(
                workoutType: CoreWorkoutSupport.goalDisplayName,
                weeklyGoal: weeklyGoals.situps,
                completed: weeklyProgress.situpsCompleted,
                daysLeftInWeek: daysLeftInWeek
            ),
            GoalProgress(
                workoutType: "Squats",
                weeklyGoal: weeklyGoals.squats,
                completed: weeklyProgress.squatsCompleted,
                daysLeftInWeek: daysLeftInWeek
            ),
            GoalProgress(
                workoutType: "Wall Sits",
                weeklyGoal: weeklyGoals.wallSitTimeSeconds,
                completed: weeklyProgress.wallSitTimeCompleted,
                daysLeftInWeek: daysLeftInWeek
            )
        ]
    }
    
    // MARK: - Algorithm-Based Goal Progress (New)
    func getAlgorithmGoalProgress() -> [GoalProgress] {
        checkAndResetWeeklyProgress()
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = Date()
        // Find the start of the week (Monday)
        let _ = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        // Find the end of the week (Sunday, 23:59:59)
        let weekEnd: Date = {
            if let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
                return calendar.date(byAdding: .day, value: 6, to: start)?.addingTimeInterval(86399) ?? today
            } else {
                return today
            }
        }()
        // Calculate days left in the week (including today)
        let daysLeft = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: weekEnd)).day ?? 0
        let daysLeftInWeek = max(1, daysLeft + 1) // Include today
        
        // Use algorithm-generated goals from workout plan if available
        if let plan = currentWorkoutPlan {
            return [
                GoalProgress(
                    workoutType: "Push-ups",
                    weeklyGoal: plan.weeklyGoals.pushups,
                    completed: weeklyProgress.pushupsCompleted,
                    daysLeftInWeek: daysLeftInWeek
                ),
                GoalProgress(
                    workoutType: CoreWorkoutSupport.goalDisplayName,
                    weeklyGoal: plan.weeklyGoals.situps,
                    completed: weeklyProgress.situpsCompleted,
                    daysLeftInWeek: daysLeftInWeek
                ),
                GoalProgress(
                    workoutType: "Squats",
                    weeklyGoal: plan.weeklyGoals.squats,
                    completed: weeklyProgress.squatsCompleted,
                    daysLeftInWeek: daysLeftInWeek
                ),
                GoalProgress(
                    workoutType: "Wall Sits",
                    weeklyGoal: plan.weeklyGoals.wallSitTimeSeconds,
                    completed: weeklyProgress.wallSitTimeCompleted,
                    daysLeftInWeek: daysLeftInWeek
                )
            ]
        } else {
            // Fallback to old manual goals if no plan exists
            return getGoalProgress()
        }
    }
    
    // MARK: - Workout Management
    func getRecentWorkouts(_ count: Int) -> [Workout] {
        return Array(workouts.prefix(count))
    }
    
    func getCurrentStreak() -> Int {
        // Simple streak calculation - in a real app, this would be more sophisticated
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        while true {
            let workoutsOnDate = workouts.filter { workout in
                calendar.isDate(workout.timestamp, inSameDayAs: currentDate)
            }
            
            if workoutsOnDate.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    func getTodaysWorkouts() -> [Workout] {
        let calendar = Calendar.current
        let today = Date()
        return workouts.filter { workout in
            calendar.isDate(workout.timestamp, inSameDayAs: today)
        }
    }
    
    /// True if today's work for this exercise was finished as a full uninterrupted session.
    func hasCompletedExerciseToday(exerciseId: String) -> Bool {
        if CoreWorkoutSupport.isCoreCatalogId(exerciseId) {
            return isCoreWorkoutCompletedToday()
        }
        return hasFullSessionCompletionToday(forExerciseId: exerciseId)
    }
    
    /// Core day is complete when every circuit move was finished in a full session today.
    func isCoreWorkoutCompletedToday() -> Bool {
        CoreWorkoutSupport.moves.allSatisfy { hasFullSessionCompletionToday(forExerciseId: $0.id) }
    }

    /// Today's logged workout that matches a plan row label (e.g. `"Push-ups"`).
    /// Prefers a full-session completion when one exists.
    func getTodaysWorkout(matchingPlanExercise planExerciseName: String) -> Workout? {
        let matches: (Workout) -> Bool = { workout in
            let exerciseLower = planExerciseName.lowercased()
            let workoutExercise = workout.exercise.lowercased()
            if CoreWorkoutSupport.isCorePlanExercise(planExerciseName) {
                return CoreWorkoutSupport.isCoreWorkoutLog(workout.exercise)
            }
            return workoutExercise.contains(exerciseLower) ||
                exerciseLower.contains(workoutExercise) ||
                (exerciseLower.contains("push") && workoutExercise.contains("push")) ||
                LegWorkoutSupport.legLogsMatch(planName: planExerciseName, workoutLog: workout.exercise)
        }
        
        let todays = getTodaysWorkouts().filter(matches)
        return todays.first(where: { $0.isFullSessionCompletion }) ?? todays.first
    }
    
    /// Matches a plan row label (e.g. `"Push-ups"`) to today's completed list from `getTodaysCompletedExercises()`.
    func isPlanExerciseCompletedToday(planExerciseName: String) -> Bool {
        todaysPlanExerciseStatus(for: planExerciseName) == .done
    }
    
    /// Home / plan-row status for a day's exercise recommendation.
    enum TodaysPlanExerciseStatus: Equatable {
        case notStarted
        /// Partial early quit — still needs a full session to count as Done.
        case almostDone
        case done
    }
    
    func catalogExerciseId(forPlanExerciseName planExerciseName: String) -> String? {
        let lower = planExerciseName.lowercased()
        if CoreWorkoutSupport.isCorePlanExercise(planExerciseName) {
            return CoreWorkoutSupport.catalogExerciseId
        }
        if lower.contains("push") { return "pushups" }
        if lower.contains("squat") || lower.contains("leg") {
            return LegWorkoutSupport.strengthExerciseId
        }
        return nil
    }
    
    /// Reps logged today toward a plan row (push / core / legs).
    func repsLoggedToday(forPlanExerciseName planExerciseName: String) -> Int {
        if let id = catalogExerciseId(forPlanExerciseName: planExerciseName) {
            return repsLoggedToday(forExerciseId: id)
        }
        let lower = planExerciseName.lowercased()
        return getTodaysWorkouts()
            .filter {
                let e = $0.exercise.lowercased()
                return e.contains(lower) || lower.contains(e)
            }
            .reduce(0) { $0 + $1.reps }
    }
    
    func todaysPlanExerciseStatus(for planExerciseName: String) -> TodaysPlanExerciseStatus {
        if CoreWorkoutSupport.isCorePlanExercise(planExerciseName) {
            if isCoreWorkoutCompletedToday() { return .done }
            let logged = CoreWorkoutSupport.totalCoreRepsToday(in: getTodaysWorkouts())
            if logged > 0 { return .almostDone }
            return .notStarted
        }
        
        if let id = catalogExerciseId(forPlanExerciseName: planExerciseName) {
            if hasFullSessionCompletionToday(forExerciseId: id) { return .done }
            if repsLoggedToday(forExerciseId: id) > 0 { return .almostDone }
            return .notStarted
        }
        
        if let workout = getTodaysWorkout(matchingPlanExercise: planExerciseName) {
            return workout.isFullSessionCompletion ? .done : .almostDone
        }
        return .notStarted
    }
    
    // MARK: - Notification Helper Methods
    func getTodaysCompletedExercises() -> [String] {
        guard let todaysRecommendation = getTodaysRecommendation() else { return [] }
        
        return todaysRecommendation.exercises
            .filter { todaysPlanExerciseStatus(for: $0.exercise) == .done }
            .map(\.exercise)
    }
    
    func getTodaysRemainingExercises() -> [String] {
        guard let todaysRecommendation = getTodaysRecommendation() else { return [] }
        let completedExercises = getTodaysCompletedExercises()
        
        return todaysRecommendation.exercises.map { $0.exercise }.filter { exercise in
            !completedExercises.contains(exercise)
        }
    }
    
    func updateWorkoutNotifications() {
        WorkoutNotificationService.shared.refreshScheduledNotifications(workoutViewModel: self)
        SleepNotificationService.shared.refreshScheduledNotifications(
            schedule: userProfile.sleepSchedule,
            streak: getCurrentStreak()
        )
    }
    
    func getTotalWorkoutTimeToday() -> Int {
        let todaysWorkouts = getTodaysWorkouts()
        // Assuming each rep takes about 2 seconds
        return todaysWorkouts.reduce(0) { total, workout in
            total + (workout.reps * 2)
        }
    }
    
    func formatWorkoutTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min\(minutes != 1 ? "s" : "")"
    }
    
    // MARK: - XP and Level Management
    func addXP(_ xp: Int) {
        DebugLog.log("🎯 Adding \(xp) XP to user")
        DebugLog.log("🎯 Before: Level \(levelInfo.level), \(levelInfo.xpInCurrentLevel)/\(levelInfo.xpToNextLevel) XP")
        
        levelInfo.xpInCurrentLevel += xp
        
        // Check if level up
        if levelInfo.xpInCurrentLevel >= levelInfo.xpToNextLevel {
            levelUp()
        }
        
        // Update progress
        levelInfo.progress = Double(levelInfo.xpInCurrentLevel) / Double(levelInfo.xpToNextLevel)
        
        // Save data after XP changes
        saveData()
        
        DebugLog.log("🎯 After: Level \(levelInfo.level), \(levelInfo.xpInCurrentLevel)/\(levelInfo.xpToNextLevel) XP, Progress: \(levelInfo.progress)")
    }
    
    private func levelUp() {
        let oldLevel = levelInfo.level
        let oldTitle = levelInfo.title
        
        DebugLog.log("🎉 LEVEL UP! Level \(oldLevel) → Level \(oldLevel + 1)")
        levelInfo.level += 1
        levelInfo.xpInCurrentLevel -= levelInfo.xpToNextLevel
        
        // Get XP requirement for next level
        levelInfo.xpToNextLevel = getXPForLevel(levelInfo.level)
        
        // Update title based on level
        levelInfo.title = getTitleForLevel(levelInfo.level)
        
        // Trigger level up achievement
        levelUpInfo = (newLevel: levelInfo.level, newTitle: levelInfo.title, oldLevel: oldLevel, oldTitle: oldTitle)
        showLevelUpAchievement = true
        
        DebugLog.log("🎉 New title: \(levelInfo.title)")
    }
    
    private func getXPForLevel(_ level: Int) -> Int {
        // XP requirements for each level - progressive difficulty
        switch level {
        case 1:
            return 100  // Rookie → Warrior
        case 2:
            return 200  // Warrior → Beast
        case 3:
            return 350  // Beast → Titan
        case 4:
            return 500  // Titan → Legend
        case 5:
            return 700  // Legend → Champion
        case 6:
            return 1000 // Champion → Elite
        case 7:
            return 1400 // Elite → Master
        case 8:
            return 1900 // Master → Grandmaster
        case 9:
            return 2500 // Grandmaster → Ultimate
        case 10:
            return 3200 // Ultimate → Immortal
        default:
            return 4000 // Beyond level 10
        }
    }
    
    private func getTitleForLevel(_ level: Int) -> String {
        switch level {
        case 1:
            return "Rookie"
        case 2:
            return "Warrior"
        case 3:
            return "Beast"
        case 4:
            return "Titan"
        case 5:
            return "Legend"
        case 6:
            return "Champion"
        case 7:
            return "Elite"
        case 8:
            return "Master"
        case 9:
            return "Grandmaster"
        case 10:
            return "Ultimate"
        default:
            return "Immortal"
        }
    }
    
    // MARK: - Testing Functions (for debugging)
    func testXPSystem() {
        DebugLog.log("🧪 Testing XP System...")
        DebugLog.log("🧪 Current state: Level \(levelInfo.level), \(levelInfo.xpInCurrentLevel)/\(levelInfo.xpToNextLevel) XP")
        
        // Test adding XP
        addXP(25)
        
        DebugLog.log("🧪 After adding 25 XP: Level \(levelInfo.level), \(levelInfo.xpInCurrentLevel)/\(levelInfo.xpToNextLevel) XP")
        DebugLog.log("🧪 Progress: \(levelInfo.progress)")
        DebugLog.log("🧪 Title: \(levelInfo.title)")
    }
    
    // MARK: - Week End Date for Display
    var currentWeekEndDate: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = Date()
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
            // End of week is Sunday, 23:59:59
            return calendar.date(byAdding: .day, value: 6, to: weekStart)?.addingTimeInterval(86399) ?? today
        } else {
            return today
        }
    }
    
    // MARK: - User Profile Management
    func updateUserProfile(_ profile: UserProfile) {
        self.userProfile = profile
        saveData()
        updateWorkoutNotifications()
        DebugLog.log("👤 Updated user profile")
    }
    
    func completeOnboarding(profile: UserProfile, assessment: FitnessAssessment?, plan: WorkoutPlan?) {
        self.userProfile = profile
        self.userProfile.hasCompletedOnboarding = true
        self.userProfile.onboardingCompletedDate = Date()
        self.fitnessAssessment = assessment
        self.currentWorkoutPlan = plan
        
        // Ensure userName is preserved (it should already be set in handlePersonalInfo)
        // Verify the userName is still set and save it explicitly
        DebugLog.log("🔍 completeOnboarding - Current userName: '\(userName)'")
        
        // Double-check Keychain has the name saved
        if let savedName = SecureUserDataStore.string(forKey: userNameKey), !savedName.isEmpty, savedName != "User" {
            userName = savedName
            DebugLog.log("✅ Found saved userName in Keychain: '\(savedName)'")
        } else {
            DebugLog.log("⚠️ No valid userName found in Keychain during completeOnboarding")
        }
        
        saveData()
        DebugLog.log("✅ Onboarding completed! Final user name: '\(userName)'")
    }
    
    func saveFitnessAssessment(_ assessment: FitnessAssessment) {
        self.fitnessAssessment = assessment
        saveData()
        DebugLog.log("📊 Saved fitness assessment: \(assessment.fitnessLevel.rawValue)")
    }
    
    func saveWorkoutPlan(_ plan: WorkoutPlan) {
        self.currentWorkoutPlan = plan
        // Also update weekly goals from the plan
        self.weeklyGoals = plan.weeklyGoals
        saveData()
        DebugLog.log("📋 Saved workout plan: \(plan.name)")
    }
    
    // Get today's workout recommendation
    func getTodaysRecommendation() -> WorkoutPlan.DailyRecommendation? {
        // Check for progression before returning today's recommendation
        checkAndApplyProgression()
        return currentWorkoutPlan?.getTodaysRecommendation()
    }
    
    // MARK: - Automatic Progression System
    
    /// Check if it's time to progress to the next week and apply changes
    func checkAndApplyProgression() {
        guard let plan = currentWorkoutPlan else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if a week has passed since last progression check
        let daysSinceLastCheck = calendar.dateComponents([.day], from: plan.lastProgressionCheckDate, to: today).day ?? 0
        
        // Only check progression once per week (at least 7 days)
        guard daysSinceLastCheck >= 7 else {
            DebugLog.log("⏰ Progression check: Only \(daysSinceLastCheck) days since last check, waiting...")
            return
        }
        
        DebugLog.log("📊 Running weekly progression check...")
        
        // Calculate weekly completion rate
        let completionRate = calculateWeeklyCompletionRate()
        DebugLog.log("📈 Weekly completion rate: \(Int(completionRate * 100))%")
        
        // Determine progression action based on performance
        let (shouldProgress, goalMultiplier) = determineProgressionAction(completionRate: completionRate, currentWeek: plan.currentWeek)
        
        if shouldProgress {
            // Progress to next week
            let newWeek = plan.currentWeek + 1
            DebugLog.log("🎯 Progressing to Week \(newWeek) with goal multiplier \(goalMultiplier)")
            
            let updatedPlan = WorkoutPlanGenerator.regeneratePlanWithProgression(
                currentPlan: plan,
                profile: userProfile,
                assessment: fitnessAssessment,
                newWeek: newWeek,
                weeklyGoalMultiplier: goalMultiplier
            )
            
            saveWorkoutPlan(updatedPlan)
            
            // Show progression message
            if goalMultiplier > 1.0 {
                DebugLog.log("🎉 Great work! Increasing goals by \(Int((goalMultiplier - 1.0) * 100))% and moving to \(updatedPlan.progressionPhase)")
            } else {
                DebugLog.log("✅ Moving to \(updatedPlan.progressionPhase)")
            }
        } else if goalMultiplier < 1.0 {
            // Reduce difficulty (maintain same week but lower goals)
            DebugLog.log("🔧 Adjusting goals to \(Int(goalMultiplier * 100))% for better sustainability")
            
            let updatedPlan = WorkoutPlanGenerator.regeneratePlanWithProgression(
                currentPlan: plan,
                profile: userProfile,
                assessment: fitnessAssessment,
                newWeek: plan.currentWeek,
                weeklyGoalMultiplier: goalMultiplier
            )
            
            saveWorkoutPlan(updatedPlan)
        } else {
            // Just update the check date, no progression yet
            DebugLog.log("⏳ Maintaining current week and goals")
            var updatedPlan = plan
            updatedPlan.lastProgressionCheckDate = today
            saveWorkoutPlan(updatedPlan)
        }
    }
    
    /// Calculate weekly completion rate (0.0 to 1.0)
    private func calculateWeeklyCompletionRate() -> Double {
        guard let plan = currentWorkoutPlan else { return 0.0 }
        
        // Calculate total goals
        let totalGoal = plan.weeklyGoals.pushups + plan.weeklyGoals.situps + plan.weeklyGoals.squats
        
        // Calculate total completed
        let totalCompleted = weeklyProgress.pushupsCompleted + weeklyProgress.situpsCompleted + weeklyProgress.squatsCompleted
        
        guard totalGoal > 0 else { return 0.0 }
        
        return min(Double(totalCompleted) / Double(totalGoal), 1.0)
    }
    
    /// Determine whether to progress and what multiplier to apply to goals
    /// Returns: (shouldProgressToNextWeek, goalMultiplier)
    private func determineProgressionAction(completionRate: Double, currentWeek: Int) -> (Bool, Double) {
        
        // If at max week (6+), don't progress further but can still adjust goals
        if currentWeek >= 6 {
            if completionRate >= 0.9 {
                return (false, 1.1)  // Don't progress week, but increase goals 10%
            } else if completionRate >= 0.7 {
                return (false, 1.0)  // Maintain
            } else {
                return (false, 0.9)  // Reduce goals 10%
            }
        }
        
        // Normal progression logic
        if completionRate >= 0.9 {
            // Excellent performance (90%+): Progress and increase goals 5-10%
            return (true, 1.05)
        } else if completionRate >= 0.7 {
            // Good performance (70-89%): Progress but maintain goals
            return (true, 1.0)
        } else if completionRate >= 0.5 {
            // Moderate performance (50-69%): Don't progress yet, maintain goals
            return (false, 1.0)
        } else {
            // Low performance (<50%): Don't progress, reduce goals 10%
            return (false, 0.9)
        }
    }
    
    // Check if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        return userProfile.hasCompletedOnboarding
    }
    
    /// Applies profile and activity data loaded from the cloud (Firestore) after sign-in. Persists via `saveData()`.
    func applyRemoteOnboardingSnapshot(
        userName: String,
        userProfile: UserProfile,
        fitnessAssessment: FitnessAssessment?,
        currentWorkoutPlan: WorkoutPlan?,
        workouts: [Workout],
        levelInfo: LevelInfo?,
        weeklyGoalsOverride: WeeklyGoals?,
        weeklyProgress: WeeklyProgress?
    ) {
        self.userName = userName
        self.userProfile = userProfile
        self.fitnessAssessment = fitnessAssessment
        self.currentWorkoutPlan = currentWorkoutPlan
        
        self.workouts = workouts
        if let levelInfo {
            self.levelInfo = levelInfo
        }
        if let weeklyProgress {
            self.weeklyProgress = weeklyProgress
        }
        if let weeklyGoalsOverride {
            self.weeklyGoals = weeklyGoalsOverride
        } else if let plan = currentWorkoutPlan {
            self.weeklyGoals = plan.weeklyGoals
        }
        
        if let plan = currentWorkoutPlan {
            saveData()
        } else if userProfile.hasCompletedOnboarding {
            forceRegeneratePlan()
        } else {
            saveData()
        }
        DebugLog.log("☁️ Applied remote onboarding snapshot from cloud (workouts: \(workouts.count))")
    }
    
    // MARK: - Debug: Force Regenerate Plan (Temporary)
    func forceRegeneratePlan() {
        regeneratePlanFromProfile()
        DebugLog.log("🔄 Force regenerated workout plan with updated algorithm")
    }
}

extension Notification.Name {
    /// Posted after local user data is persisted (UserDefaults). Used to sync to Firestore when signed in.
    static let workoutUserDataDidSave = Notification.Name("com.pushlimit.workoutUserDataDidSave")
    /// Posted after permanent reset (local + cloud wipe). App should return to onboarding.
    static let userDidResetAllData = Notification.Name("com.pushlimit.userDidResetAllData")
    /// Posted after sign-out. Local workout data is kept on device.
    static let userDidLogout = Notification.Name("com.pushlimit.userDidLogout")
} 