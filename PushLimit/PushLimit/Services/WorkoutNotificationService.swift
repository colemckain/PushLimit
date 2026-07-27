import Foundation
import UserNotifications
import SwiftUI

class WorkoutNotificationService: NSObject, ObservableObject {
    static let shared = WorkoutNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    // Notification identifiers
    private let morningNotificationId = "workout_morning_11am"
    private let afternoonNotificationId = "workout_afternoon_3pm"
    private let earlyQuitDebtNotificationPrefix = "early_quit_debt_"
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            DebugLog.log("❌ Error requesting notification authorization: \(error)")
            return false
        }
    }

    // MARK: - Scheduling (single path)

    /// Schedules the next personalized 11 AM and 3 PM notifications (one-off each, never repeating placeholders).
    func refreshScheduledNotifications(workoutViewModel: WorkoutViewModel) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }

            var idsToRemove = Set([self.morningNotificationId, self.afternoonNotificationId])
            for request in requests {
                let id = request.identifier
                if id.hasPrefix(self.morningNotificationId) || id.hasPrefix(self.afternoonNotificationId) {
                    idsToRemove.insert(id)
                }
            }
            self.center.removePendingNotificationRequests(withIdentifiers: Array(idsToRemove))

            let recommendation = workoutViewModel.getTodaysRecommendation()
            let progress = self.checkTodaysProgress(
                todaysRecommendation: recommendation,
                todaysWorkouts: workoutViewModel.getTodaysWorkouts()
            )
            let morning = PushLimitNotificationCopy.morningWorkout(
                recommendation: recommendation
            )
            let afternoon = PushLimitNotificationCopy.afternoonWorkout(
                recommendation: recommendation,
                completedCount: progress.completed.count,
                totalCount: recommendation?.exercises.count ?? 0,
                nextExercise: progress.remaining.first.map(shortExerciseName)
            )

            self.scheduleNextNotification(
                id: self.morningNotificationId,
                hour: 11,
                minute: 0,
                title: morning.title,
                body: morning.body
            )
            self.scheduleNextNotification(
                id: self.afternoonNotificationId,
                hour: 15,
                minute: 0,
                title: afternoon.title,
                body: afternoon.body
            )

            DebugLog.log("✅ Workout notifications refreshed")
        }
    }

    /// Backward-compatible alias used after workouts and on app launch.
    func updateTodayNotifications(workoutViewModel: WorkoutViewModel) {
        refreshScheduledNotifications(workoutViewModel: workoutViewModel)
    }

    /// Deprecated — kept so older call sites compile; delegates to refresh when a ViewModel is available.
    func scheduleDailyNotifications() {
        DebugLog.log("ℹ️ scheduleDailyNotifications is deprecated; notifications refresh via refreshScheduledNotifications")
    }

    private func scheduleNextNotification(id: String, hour: Int, minute: Int, title: String, body: String) {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        if let fireDate = calendar.date(from: components), fireDate <= now {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }
            components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = hour
            components.minute = minute
            components.second = 0
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                DebugLog.log("❌ Error scheduling \(id): \(error)")
            }
        }
    }
    
    // MARK: - Early quit debt reminder
    
    func earlyQuitDebtNotificationId(for exerciseId: String) -> String {
        "\(earlyQuitDebtNotificationPrefix)\(exerciseId.lowercased())"
    }
    
    /// Reminds the user to finish after quitting early (tone-aware local notification).
    func scheduleEarlyQuitDebtNotification(
        exerciseId: String,
        exerciseName: String,
        leftoverReps: Int,
        extraSetReps: Int,
        completedReps: Int = 0,
        delaySeconds: TimeInterval = 8
    ) {
        let id = earlyQuitDebtNotificationId(for: exerciseId)
        
        Task { @MainActor in
            let settings = await center.notificationSettings()
            var status = settings.authorizationStatus
            if status == .notDetermined {
                let granted = await requestAuthorization()
                status = granted ? .authorized : .denied
            }
            guard status == .authorized || status == .provisional else {
                DebugLog.log("⚠️ Early-quit notification skipped — notifications not authorized")
                return
            }
            
            self.center.removePendingNotificationRequests(withIdentifiers: [id])
            self.center.removeDeliveredNotifications(withIdentifiers: [id])
            
            // Persist current tone so copy matches the user’s coaching setting.
            FeedbackTone.persist(FeedbackTone.current)
            
            let copy = PushLimitNotificationCopy.earlyQuitIncomplete(
                exerciseName: exerciseName,
                completedReps: max(completedReps, 0)
            )
            
            let content = UNMutableNotificationContent()
            content.title = copy.title
            content.body = copy.body
            content.sound = .default
            content.badge = NSNumber(value: 1)
            content.userInfo = [
                "type": "early_quit_incomplete",
                "exerciseId": exerciseId,
                "leftoverReps": leftoverReps,
                "extraSetReps": extraSetReps,
                "feedbackTone": FeedbackTone.current.rawValue
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(3, delaySeconds),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            do {
                try await self.center.add(request)
                DebugLog.log("📬 Scheduled early-quit notification for \(exerciseId) (\(FeedbackTone.current.rawValue))")
            } catch {
                DebugLog.log("❌ Error scheduling early-quit notice: \(error)")
            }
        }
    }
    
    func clearEarlyQuitDebtNotification(for exerciseId: String) {
        let id = earlyQuitDebtNotificationId(for: exerciseId)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
    
    /// Dev / Test & Cheats — fires the early-quit reminder immediately for the current tone.
    func testEarlyQuitNotification(exerciseName: String = "Push-ups", completedReps: Int = 12) {
        Task { @MainActor in
            let settings = await center.notificationSettings()
            var status = settings.authorizationStatus
            if status == .notDetermined {
                let granted = await requestAuthorization()
                status = granted ? .authorized : .denied
            }
            guard status == .authorized || status == .provisional else {
                DebugLog.log("⚠️ Test early-quit notification skipped — not authorized")
                return
            }
            
            let copy = PushLimitNotificationCopy.earlyQuitIncomplete(
                exerciseName: exerciseName,
                completedReps: completedReps
            )
            let content = UNMutableNotificationContent()
            content.title = copy.title
            content.body = copy.body
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "test_early_quit_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
                DebugLog.log("✅ Test early-quit notification sent (\(FeedbackTone.current.rawValue))")
            } catch {
                DebugLog.log("❌ Error testing early-quit notification: \(error)")
            }
        }
    }
    
    // MARK: - Generate Morning Notification Content
    /// Lock-screen safe copy — delegates to `PushLimitNotificationCopy`.
    func generateMorningNotificationContent(todaysRecommendation: WorkoutPlan.DailyRecommendation?) -> (title: String, body: String) {
        PushLimitNotificationCopy.morningWorkout(recommendation: todaysRecommendation)
    }

    // MARK: - Generate Afternoon Notification Content
    func generateAfternoonNotificationContent(
        todaysRecommendation: WorkoutPlan.DailyRecommendation?,
        completedExercises: [String],
        remainingExercises: [String]
    ) -> (title: String, body: String) {
        PushLimitNotificationCopy.afternoonWorkout(
            recommendation: todaysRecommendation,
            completedCount: completedExercises.count,
            totalCount: todaysRecommendation?.exercises.count ?? 0,
            nextExercise: remainingExercises.first.map(shortExerciseName)
        )
    }

    private func shortExerciseName(_ exercise: String) -> String {
        exercise
            .replacingOccurrences(of: "Leg Workout", with: "Legs")
    }

    // MARK: - Check Today's Progress (Helper method for WorkoutViewModel)
    func checkTodaysProgress(
        todaysRecommendation: WorkoutPlan.DailyRecommendation?,
        todaysWorkouts: [Workout]
    ) -> (completed: [String], remaining: [String]) {
        
        guard let recommendation = todaysRecommendation else {
            return (completed: [], remaining: [])
        }
        
        var completedExercises: [String] = []
        var remainingExercises: [String] = []
        
        for exercise in recommendation.exercises {
            let exerciseLower = exercise.exercise.lowercased()
            
            let isCompleted: Bool
            if CoreWorkoutSupport.isCorePlanExercise(exercise.exercise) {
                isCompleted = CoreWorkoutSupport.isDayComplete(workouts: todaysWorkouts)
            } else {
                isCompleted = todaysWorkouts.contains { workout in
                    guard workout.isFullSessionCompletion else { return false }
                    let workoutExercise = workout.exercise.lowercased()
                    return workoutExercise.contains(exerciseLower) ||
                           exerciseLower.contains(workoutExercise) ||
                           (exerciseLower.contains("push") && workoutExercise.contains("push")) ||
                           ((exerciseLower.contains("squat") || exerciseLower.contains("leg")) && (workoutExercise.contains("squat") || workoutExercise.contains("leg")))
                }
            }
            
            if isCompleted {
                completedExercises.append(exercise.exercise)
            } else {
                remainingExercises.append(exercise.exercise)
            }
        }
        
        return (completed: completedExercises, remaining: remainingExercises)
    }
    
    // MARK: - Remove All Notifications
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        SleepNotificationService.shared.removeSleepNotifications()
        DebugLog.log("🗑️ All workout and sleep notifications removed")
    }
    
    // MARK: - Test Notifications
    func testMorningNotification(workoutViewModel: WorkoutViewModel) {
        let todaysRecommendation = workoutViewModel.getTodaysRecommendation()
        
        let content = generateMorningNotificationContent(
            todaysRecommendation: todaysRecommendation
        )
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = .default
        notificationContent.badge = NSNumber(value: 1)
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_morning_\(UUID().uuidString)", content: notificationContent, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                DebugLog.log("❌ Error testing morning notification: \(error)")
            } else {
                DebugLog.log("✅ Test morning notification sent")
            }
        }
    }
    
    func testAfternoonNotification(workoutViewModel: WorkoutViewModel) {
        let todaysRecommendation = workoutViewModel.getTodaysRecommendation()
        let todaysWorkouts = workoutViewModel.getTodaysWorkouts()
        
        let progress = checkTodaysProgress(
            todaysRecommendation: todaysRecommendation,
            todaysWorkouts: todaysWorkouts
        )
        
        let content = generateAfternoonNotificationContent(
            todaysRecommendation: todaysRecommendation,
            completedExercises: progress.completed,
            remainingExercises: progress.remaining
        )
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = .default
        notificationContent.badge = NSNumber(value: 1)
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_afternoon_\(UUID().uuidString)", content: notificationContent, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                DebugLog.log("❌ Error testing afternoon notification: \(error)")
            } else {
                DebugLog.log("✅ Test afternoon notification sent")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension WorkoutNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - could navigate to workout screen
        completionHandler()
    }
}

