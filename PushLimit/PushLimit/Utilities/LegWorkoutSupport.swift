import Foundation

enum LegWorkoutSupport {
    static let strengthExerciseId = "squats"
    static let runExerciseId = "leg-run"
    static let minimumRunDurationSeconds = 60
    /// Bump when the leg-run location disclosure changes materially so users re-acknowledge.
    static let locationDisclosureVersion = "2026-07-26"

    static let locationDisclosureMessage =
        "PushLimit uses your location during active leg runs to track distance and map your route. " +
        "Tracking continues in the background while your run is active — including when the screen is locked or you switch apps (for example, to change music). " +
        "Location updates stop when you pause or finish the run. We do not track your location when you are not on an active run."

    static let locationConsentCheckboxMessage =
        "I understand and agree that PushLimit may use my location during active leg runs — including in the background while the phone is locked or in another app — to track distance and map my route. Tracking stops when I pause or finish."

    static let runExercise = Exercise(
        id: runExerciseId,
        name: "Leg Run",
        description: "Outdoor run to complete today's leg workout. GPS tracks time, distance, and your route — including in the background until you pause or finish.",
        muscleGroups: ["Quads", "Glutes", "Hamstrings", "Cardio"]
    )

    static func isLegPlanExercise(_ name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("squat") || lower.contains("leg")
    }

    static func isLegWorkoutLog(_ exerciseId: String) -> Bool {
        let lower = exerciseId.lowercased()
        return lower.contains("squat") || lower.contains("leg") || lower == runExerciseId
    }

    static func legLogsMatch(planName: String, workoutLog: String) -> Bool {
        isLegPlanExercise(planName) && isLegWorkoutLog(workoutLog)
    }

    static func formatDistance(_ meters: Double) -> String {
        guard meters > 0 else { return "0.00 mi" }
        let miles = meters / 1609.344
        if miles < 0.1 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.2f mi", miles)
    }

    static func formatPace(distanceMeters: Double, elapsedSeconds: Int) -> String {
        guard distanceMeters > 10, elapsedSeconds > 0 else { return "--:--" }
        let miles = distanceMeters / 1609.344
        let minutesPerMile = Double(elapsedSeconds) / 60.0 / miles
        let mins = Int(minutesPerMile)
        let secs = Int((minutesPerMile - Double(mins)) * 60)
        return String(format: "%d:%02d /mi", mins, secs)
    }
}

enum WorkoutRewards {
    static func xp(forRepGoal repGoal: Int) -> Int {
        switch repGoal {
        case 5...10: return 10
        case 11...20: return 20
        case 21...30: return 30
        case 31...40: return 40
        case 41...50: return 50
        default: return 25
        }
    }
}
