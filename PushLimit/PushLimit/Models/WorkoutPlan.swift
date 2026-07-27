import Foundation

struct WorkoutPlan: Codable {
    var id: String
    var name: String
    var description: String
    var durationWeeks: Int
    var weeklyGoals: WeeklyGoals
    var dailyRecommendations: [DailyRecommendation]
    var fitnessLevel: FitnessAssessment.FitnessLevel
    var createdDate: Date
    var currentWeek: Int
    var lastProgressionCheckDate: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        durationWeeks: Int,
        weeklyGoals: WeeklyGoals,
        dailyRecommendations: [DailyRecommendation],
        fitnessLevel: FitnessAssessment.FitnessLevel,
        createdDate: Date = Date(),
        currentWeek: Int = 1,
        lastProgressionCheckDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.durationWeeks = durationWeeks
        self.weeklyGoals = weeklyGoals
        self.dailyRecommendations = dailyRecommendations
        self.fitnessLevel = fitnessLevel
        self.createdDate = createdDate
        self.currentWeek = currentWeek
        self.lastProgressionCheckDate = lastProgressionCheckDate
    }
    
    // MARK: - Daily Recommendation
    struct DailyRecommendation: Codable, Identifiable {
        var id: String
        var dayOfWeek: Int  // 1-7 (Monday-Sunday)
        var exercises: [ExerciseRecommendation]
        var restDay: Bool
        
        init(
            id: String = UUID().uuidString,
            dayOfWeek: Int,
            exercises: [ExerciseRecommendation] = [],
            restDay: Bool = false
        ) {
            self.id = id
            self.dayOfWeek = dayOfWeek
            self.exercises = exercises
            self.restDay = restDay
        }
        
        var dayName: String {
            let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            return days[dayOfWeek - 1]
        }
        
        var dayShortName: String {
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return days[dayOfWeek - 1]
        }
        
        var totalReps: Int {
            exercises.reduce(0) { $0 + $1.totalReps }
        }
        
        /// Whole minutes, **ceil** of sum of per-exercise session models (rep pace timers + 60s set rests + leg wall-sit block).
        /// Matches `WorkoutDurationEstimate` / `WorkoutSessionScreen` behavior, not plan `restBetweenSets` (session uses 60s).
        var estimatedDuration: Int {
            guard !exercises.isEmpty else { return 0 }
            let totalSeconds = exercises.reduce(0) { $0 + $1.sessionEstimatedTotalSeconds }
            return WorkoutDurationEstimate.minutesRoundedUp(totalSeconds: totalSeconds)
        }
    }
    
    // MARK: - Exercise Recommendation
    struct ExerciseRecommendation: Codable, Identifiable {
        var id: String
        var exercise: String
        var sets: Int
        var repsPerSet: Int
        var totalReps: Int
        var restBetweenSets: Int  // seconds
        var notes: String?
        
        init(
            id: String = UUID().uuidString,
            exercise: String,
            sets: Int,
            repsPerSet: Int,
            totalReps: Int,
            restBetweenSets: Int,
            notes: String? = nil
        ) {
            self.id = id
            self.exercise = exercise
            self.sets = sets
            self.repsPerSet = repsPerSet
            self.totalReps = totalReps
            self.restBetweenSets = restBetweenSets
            self.notes = notes
        }
        
        var formattedSetsAndReps: String {
            return "\(sets) × \(repsPerSet)"
        }
        
        var restDescription: String {
            if restBetweenSets < 60 {
                return "\(restBetweenSets)s rest"
            } else {
                let minutes = restBetweenSets / 60
                return "\(minutes)m rest"
            }
        }
    }
    
    /// Renames legacy "Sit-ups" plan rows into the 5-move Core Workout circuit.
    mutating func migrateSitUpsToCoreWorkoutIfNeeded() -> Bool {
        var didChange = false
        for dayIndex in dailyRecommendations.indices {
            for exerciseIndex in dailyRecommendations[dayIndex].exercises.indices {
                let current = dailyRecommendations[dayIndex].exercises[exerciseIndex]
                let lower = current.exercise.lowercased()
                let isLegacySitUps = lower.contains("sit") && !lower.contains("wall") &&
                    current.exercise != CoreWorkoutSupport.planExerciseName
                guard isLegacySitUps else { continue }
                
                let normalized = CoreWorkoutSupport.normalizedDailyTotal(from: max(current.totalReps, CoreWorkoutSupport.baseDailyTotal))
                dailyRecommendations[dayIndex].exercises[exerciseIndex] = ExerciseRecommendation(
                    id: current.id,
                    exercise: CoreWorkoutSupport.planExerciseName,
                    sets: CoreWorkoutSupport.moveCount,
                    repsPerSet: normalized.repsPerMove,
                    totalReps: normalized.dailyTotal,
                    restBetweenSets: 45,
                    notes: CoreWorkoutSupport.circuitNotes(repsPerMove: normalized.repsPerMove)
                )
                didChange = true
            }
        }
        return didChange
    }
    
    // MARK: - Helper Methods
    
    // Get today's recommendation
    func getTodaysRecommendation() -> DailyRecommendation? {
        let calendar = Calendar.current
        let today = Date()
        var dayOfWeek = calendar.component(.weekday, from: today)
        
        // Convert Sunday (1) to 7, and shift Monday (2) to 1
        dayOfWeek = dayOfWeek == 1 ? 7 : dayOfWeek - 1
        
        return dailyRecommendations.first { $0.dayOfWeek == dayOfWeek }
    }
    
    // Get recommendation for specific day
    func getRecommendation(for dayOfWeek: Int) -> DailyRecommendation? {
        return dailyRecommendations.first { $0.dayOfWeek == dayOfWeek }
    }
    
    // Check if today is a workout day
    var isTodayWorkoutDay: Bool {
        if let todaysRec = getTodaysRecommendation() {
            return !todaysRec.restDay
        }
        return false
    }
    
    // Get number of workout days per week
    var workoutDaysPerWeek: Int {
        return dailyRecommendations.filter { !$0.restDay }.count
    }
    
    // Get total weekly reps
    var totalWeeklyReps: Int {
        return dailyRecommendations.reduce(0) { $0 + $1.totalReps }
    }
    
    // Estimated weekly workout time in minutes
    var estimatedWeeklyDuration: Int {
        return dailyRecommendations.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    // MARK: - Progression System
    
    // Determine target sets based on current week
    var targetSets: Int {
        switch currentWeek {
        case 1...2:
            return 4  // Week 1-2: 4 sets (easiest, most distributed)
        case 3...4:
            return 3  // Week 3-4: 3 sets (moderate)
        default:
            return 2  // Week 5+: 2 sets (hardest, most reps per set)
        }
    }
    
    // Current progression phase description
    var progressionPhase: String {
        switch currentWeek {
        case 1...2:
            return "Foundation Phase (4 sets)"
        case 3...4:
            return "Building Phase (3 sets)"
        default:
            return "Power Phase (2 sets)"
        }
    }
    
    // Weeks until next progression
    var weeksUntilNextProgression: Int {
        if currentWeek < 2 {
            return 2 - currentWeek
        } else if currentWeek < 4 {
            return 4 - currentWeek
        } else {
            return 0 // Already at max progression
        }
    }
}

// MARK: - Sample Plans (for reference/testing)

extension WorkoutPlan {
    static var sampleBeginnerPlan: WorkoutPlan {
        WorkoutPlan(
            name: "Beginner Starter",
            description: "Perfect for those just starting their fitness journey",
            durationWeeks: 4,
            weeklyGoals: WeeklyGoals(pushups: 70, situps: 70, squats: 70),
            dailyRecommendations: [],
            fitnessLevel: .beginner
        )
    }
    
    static var sampleIntermediatePlan: WorkoutPlan {
        WorkoutPlan(
            name: "Intermediate Builder",
            description: "Take your fitness to the next level",
            durationWeeks: 4,
            weeklyGoals: WeeklyGoals(pushups: 150, situps: 150, squats: 150),
            dailyRecommendations: [],
            fitnessLevel: .intermediate
        )
    }
    
    static var sampleAdvancedPlan: WorkoutPlan {
        WorkoutPlan(
            name: "Advanced Athlete",
            description: "For serious fitness enthusiasts",
            durationWeeks: 4,
            weeklyGoals: WeeklyGoals(pushups: 250, situps: 250, squats: 250),
            dailyRecommendations: [],
            fitnessLevel: .advanced
        )
    }
}

