import Foundation

struct Workout: Identifiable, Codable {
    let id: String
    let exercise: String
    let reps: Int
    let timestamp: Date
    let timeSpent: Int // in seconds
    let distanceMeters: Double?
    /// True only when the user finished the full session (sets + rests) in one sitting.
    let isFullSessionCompletion: Bool

    init(
        id: String = UUID().uuidString,
        exercise: String,
        reps: Int,
        timestamp: Date = Date(),
        timeSpent: Int,
        distanceMeters: Double? = nil,
        isFullSessionCompletion: Bool = true
    ) {
        self.id = id
        self.exercise = exercise
        self.reps = reps
        self.timestamp = timestamp
        self.timeSpent = timeSpent
        self.distanceMeters = distanceMeters
        self.isFullSessionCompletion = isFullSessionCompletion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        exercise = try container.decode(String.self, forKey: .exercise)
        reps = try container.decode(Int.self, forKey: .reps)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        timeSpent = try container.decode(Int.self, forKey: .timeSpent)
        distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters)
        isFullSessionCompletion = try container.decodeIfPresent(Bool.self, forKey: .isFullSessionCompletion) ?? true
    }

    var isRunWorkout: Bool {
        exercise.lowercased() == LegWorkoutSupport.runExerciseId
    }
}

struct LevelInfo: Codable {
    var level: Int
    var title: String
    var progress: Double
    var xpInCurrentLevel: Int
    var xpToNextLevel: Int
}

struct WorkoutStats {
    let totalWorkouts: Int
    let currentStreak: Int
    let totalWorkoutTime: Int // in seconds
}

// MARK: - Goal Tracking Models

struct WeeklyGoals: Codable {
    var pushups: Int
    var situps: Int
    var squats: Int
    var wallSitTimeSeconds: Int  // Total wall sit time goal in seconds
    
    init(pushups: Int = 100, situps: Int = 100, squats: Int = 100, wallSitTimeSeconds: Int = 0) {
        self.pushups = pushups
        self.situps = situps
        self.squats = squats
        self.wallSitTimeSeconds = wallSitTimeSeconds
    }
}

struct WeeklyProgress: Codable {
    var pushupsCompleted: Int
    var situpsCompleted: Int
    var squatsCompleted: Int
    var wallSitTimeCompleted: Int  // Total wall sit time completed in seconds
    var weekStartDate: Date
    
    init(pushupsCompleted: Int = 0, situpsCompleted: Int = 0, squatsCompleted: Int = 0, wallSitTimeCompleted: Int = 0, weekStartDate: Date = Date()) {
        self.pushupsCompleted = pushupsCompleted
        self.situpsCompleted = situpsCompleted
        self.squatsCompleted = squatsCompleted
        self.wallSitTimeCompleted = wallSitTimeCompleted
        self.weekStartDate = weekStartDate
    }
}

struct GoalProgress {
    let workoutType: String
    let weeklyGoal: Int
    let completed: Int
    let remaining: Int
    let dailyTarget: Int
    let progressPercentage: Double
    let isGoalAchieved: Bool
    let motivationalMessage: String
    
    init(workoutType: String, weeklyGoal: Int, completed: Int, daysLeftInWeek: Int) {
        self.workoutType = workoutType
        self.weeklyGoal = weeklyGoal
        self.completed = completed
        self.remaining = max(0, weeklyGoal - completed)
        if daysLeftInWeek <= 1 {
            self.dailyTarget = self.remaining
        } else {
            self.dailyTarget = Int(ceil(Double(self.remaining) / Double(daysLeftInWeek)))
        }
        self.progressPercentage = weeklyGoal > 0 ? min(1.0, Double(completed) / Double(weeklyGoal)) : 0.0
        self.isGoalAchieved = completed >= weeklyGoal
        
        // Motivational messages based on progress
        if isGoalAchieved {
            self.motivationalMessage = "🎉 Goal achieved! You're crushing it!"
        } else if progressPercentage >= 0.8 {
            self.motivationalMessage = "🔥 Almost there! Keep pushing!"
        } else if progressPercentage >= 0.6 {
            self.motivationalMessage = "💪 Great progress! You've got this!"
        } else if progressPercentage >= 0.4 {
            self.motivationalMessage = "🚀 Halfway there! Stay consistent!"
        } else if progressPercentage >= 0.2 {
            self.motivationalMessage = "⭐ Good start! Keep it up!"
        } else {
            self.motivationalMessage = "💪 Let's get started! Every rep counts!"
        }
    }
} 