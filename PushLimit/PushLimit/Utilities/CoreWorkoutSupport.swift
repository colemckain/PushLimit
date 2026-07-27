import Foundation

/// Five-move core circuit that replaces standalone sit-ups.
enum CoreWorkoutSupport {
    static let catalogExerciseId = "situps"
    static let planExerciseName = "Core Workout"
    static let goalDisplayName = "Core"
    static let moveCount = 5
    
    /// Default day when assessment points at the middle band (10 each).
    static let baseDailyTotal = 50
    static let baseRepsPerMove = 10
    
    struct Move: Identifiable, Equatable {
        let id: String
        let name: String
        let description: String
        let icon: String
    }
    
    static let moves: [Move] = [
        Move(
            id: "core-crunches",
            name: "Crunches",
            description: "Knees bent, feet flat. Lift shoulders using your abs — short range, controlled.",
            icon: "figure.core.training"
        ),
        Move(
            id: "core-bicycles",
            name: "Bicycle Crunches",
            description: "Opposite elbow to knee. Count each side as one, stay smooth.",
            icon: "arrow.triangle.2.circlepath"
        ),
        Move(
            id: "core-leg-raises",
            name: "Leg Raises",
            description: "On your back, raise legs (or bent knees) until hips engage, then lower with control.",
            icon: "arrow.up.and.down"
        ),
        Move(
            id: "core-russian-twists",
            name: "Russian Twists",
            description: "Seated, lean back slightly. Tap side to side — each tap counts as one.",
            icon: "arrow.left.and.right"
        ),
        Move(
            id: "core-mountain-climbers",
            name: "Mountain Climbers",
            description: "High plank. Drive knees in alternately — each drive counts as one.",
            icon: "figure.run"
        )
    ]
    
    static func exercise(for move: Move) -> Exercise {
        Exercise(
            id: move.id,
            name: move.name,
            description: move.description,
            muscleGroups: ["Abs", "Core", "Obliques"]
        )
    }
    
    static func isCoreCatalogId(_ id: String) -> Bool {
        id.lowercased() == catalogExerciseId || id.lowercased() == "core"
    }
    
    static func isCoreMoveId(_ id: String) -> Bool {
        let lower = id.lowercased()
        return lower.hasPrefix("core-") || moves.contains { $0.id == lower }
    }
    
    static func isCorePlanExercise(_ name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("core") ||
            (lower.contains("sit") && !lower.contains("wall"))
    }
    
    static func isCoreWorkoutLog(_ exerciseId: String) -> Bool {
        let lower = exerciseId.lowercased()
        return isCoreMoveId(lower) ||
            lower == catalogExerciseId ||
            lower == "situps" ||
            lower == "sit-ups" ||
            (lower.contains("sit") && !lower.contains("wall"))
    }
    
    static func isCoreProgressLabel(_ label: String) -> Bool {
        let lower = label.lowercased()
        return lower.contains("core") ||
            isCoreMoveId(lower) ||
            (lower.contains("sit") && !lower.contains("wall"))
    }
    
    static func coreLogsMatch(planName: String, workoutLog: String) -> Bool {
        isCorePlanExercise(planName) && isCoreWorkoutLog(workoutLog)
    }
    
    /// Day total from sit-up / crunch assessment (or activity estimate).
    static func dailyTotal(maxSitups: Int?, activityLevel: UserProfile.ActivityLevel? = nil) -> Int {
        let maxReps: Int = {
            if let maxSitups, maxSitups > 0 { return maxSitups }
            switch activityLevel {
            case .beginner: return 8
            case .intermediate: return 15
            case .advanced: return 25
            case .none: return 15
            }
        }()
        
        switch maxReps {
        case ..<10: return 30
        case 10..<25: return baseDailyTotal
        case 25..<40: return 75
        default: return 100
        }
    }
    
    /// Soft scale for goal / age multipliers while keeping totals divisible by 5.
    static func scaleDailyTotal(_ base: Int, multiplier: Double) -> Int {
        let scaled = Int((Double(base) * max(0.8, multiplier)).rounded())
        let snapped = max(moveCount * 6, (scaled / moveCount) * moveCount)
        return snapped
    }
    
    static func repsPerMove(dailyTotal: Int) -> Int {
        max(6, dailyTotal / moveCount)
    }
    
    static func normalizedDailyTotal(from preferredDaily: Int) -> (dailyTotal: Int, repsPerMove: Int) {
        let perMove = repsPerMove(dailyTotal: preferredDaily)
        return (perMove * moveCount, perMove)
    }
    
    static func weeklyGoal(dailyTotal: Int, workoutDays: Int) -> Int {
        max(moveCount * 6, dailyTotal * max(1, workoutDays))
    }
    
    static func move(byId id: String) -> Move? {
        moves.first { $0.id == id.lowercased() }
    }
    
    /// User-facing label for logged workouts / history rows.
    static func displayName(forExerciseId id: String) -> String {
        if let move = move(byId: id) { return move.name }
        let lower = id.lowercased()
        if isCoreCatalogId(lower) || lower == "sit-ups" || lower == "situps" {
            return planExerciseName
        }
        return id.replacingOccurrences(of: "-", with: " ").capitalized
    }
    
    static func repsCompletedToday(in workouts: [Workout], moveId: String) -> Int {
        workouts
            .filter { $0.exercise.lowercased() == moveId.lowercased() }
            .reduce(0) { $0 + $1.reps }
    }
    
    static func totalCoreRepsToday(in workouts: [Workout]) -> Int {
        workouts
            .filter { isCoreWorkoutLog($0.exercise) }
            .reduce(0) { $0 + $1.reps }
    }
    
    static func isMoveComplete(workouts: [Workout], moveId: String, targetReps: Int = 0) -> Bool {
        _ = targetReps
        return workouts.contains {
            $0.exercise.lowercased() == moveId.lowercased() && $0.isFullSessionCompletion
        }
    }
    
    static func isDayComplete(workouts: [Workout], repsPerMove: Int = 0, dailyTotal: Int = 0) -> Bool {
        _ = repsPerMove
        _ = dailyTotal
        return moves.allSatisfy { isMoveComplete(workouts: workouts, moveId: $0.id) }
    }
    
    static func circuitNotes(repsPerMove: Int) -> String {
        let names = moves.map(\.name).joined(separator: " · ")
        return "\(moveCount) moves · \(repsPerMove) each: \(names)"
    }
}
