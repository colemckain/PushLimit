import Foundation

// MARK: - Session-aligned duration (keep in sync with `WorkoutSessionScreen`)

/// Estimates automated timer duration (does **not** include warm-up, ready screens, or pauses — only rep pace timers, set rests, and wall-sit timers).
///
/// Uses the **same** rules as the live workout:
/// - Rep “pace” countdown: **1.33s** per rep if the exercise is push-focused, otherwise **1.67s** per rep.
/// - **60s** rest after each rep set except the last (before wall sits or finish).
/// - Leg workouts: **two 30s** wall sits plus **30s** rest between them.
enum WorkoutDurationEstimate {
    static let pushRepSecondsPerRep: Double = 1.33
    static let otherRepSecondsPerRep: Double = 1.67
    static let restBetweenRepSetsSeconds: Int = 60
    static let wallSitHoldSeconds: Int = 30
    static let wallSitSetCount: Int = 2
    static let restBetweenWallSitSetsSeconds: Int = 30

    /// Same table as `WorkoutSessionScreen.getSetBreakdown` for totals used by presets / fallbacks.
    private static let repTotalBreakdowns: [Int: [Int]] = [
        5: [1, 1, 1, 2],
        10: [4, 2, 1, 3],
        15: [2, 3, 4, 6],
        20: [3, 4, 5, 8],
        25: [6, 7, 4, 8],
        30: [5, 8, 7, 10],
        35: [6, 9, 8, 12],
        40: [7, 8, 9, 16],
        45: [8, 14, 10, 13],
        50: [12, 18, 8, 12]
    ]

    static func setBreakdown(for totalReps: Int) -> [Int] {
        repTotalBreakdowns[totalReps] ?? []
    }

    static func setCountForAdHocTotalReps(_ totalReps: Int) -> Int {
        let b = setBreakdown(for: totalReps)
        if !b.isEmpty { return b.count }
        return max(1, totalReps > 0 ? 1 : 1)
    }

    static func secondsPerRep(planExerciseLabel: String, fallbackExerciseId: String) -> Double {
        let s = (planExerciseLabel + " " + fallbackExerciseId).lowercased()
        return s.contains("push") ? pushRepSecondsPerRep : otherRepSecondsPerRep
    }

    static func includesLegWallSitBlock(planExerciseLabel: String, fallbackExerciseId: String) -> Bool {
        let s = (planExerciseLabel + " " + fallbackExerciseId).lowercased()
        return s.contains("squat") || s.contains("leg")
    }

    /// Two wall-sit holds + one rest between them (`WorkoutSessionScreen.completeWallSitSet`).
    private static func legWallSitBlockSeconds() -> Double {
        Double(wallSitHoldSeconds * wallSitSetCount + restBetweenWallSitSetsSeconds)
    }

    /// Rep pace timers for every rep + fixed 60s rests between rep sets (not after the last rep set).
    static func mainRepPhaseSeconds(
        totalReps: Int,
        setCount: Int,
        planExerciseLabel: String,
        fallbackExerciseId: String
    ) -> Double {
        let pace = secondsPerRep(planExerciseLabel: planExerciseLabel, fallbackExerciseId: fallbackExerciseId)
        let repTotal = Double(max(0, totalReps)) * pace
        let safeSets = max(1, setCount)
        let restTotal = Double(restBetweenRepSetsSeconds * max(0, safeSets - 1))
        return repTotal + restTotal
    }

    static func totalSessionSeconds(
        totalReps: Int,
        setCount: Int,
        planExerciseLabel: String,
        fallbackExerciseId: String
    ) -> Int {
        var t = mainRepPhaseSeconds(
            totalReps: totalReps,
            setCount: setCount,
            planExerciseLabel: planExerciseLabel,
            fallbackExerciseId: fallbackExerciseId
        )
        if includesLegWallSitBlock(planExerciseLabel: planExerciseLabel, fallbackExerciseId: fallbackExerciseId) {
            t += legWallSitBlockSeconds()
        }
        return Int(ceil(t))
    }

    static func totalSessionSeconds(planExercise: WorkoutPlan.ExerciseRecommendation) -> Int {
        totalSessionSeconds(
            totalReps: planExercise.totalReps,
            setCount: planExercise.sets,
            planExerciseLabel: planExercise.exercise,
            fallbackExerciseId: planExercise.exercise
        )
    }

    static func minutesRoundedUp(totalSeconds: Int) -> Int {
        max(1, Int(ceil(Double(max(0, totalSeconds)) / 60.0)))
    }

    static func tildeMinutesLabel(totalSeconds: Int) -> String {
        "~\(minutesRoundedUp(totalSeconds: totalSeconds)) min"
    }
}

extension WorkoutPlan.ExerciseRecommendation {
    /// Total seconds (rep timers + in-session rests + leg wall-sit block when applicable).
    var sessionEstimatedTotalSeconds: Int {
        WorkoutDurationEstimate.totalSessionSeconds(planExercise: self)
    }
}
