import Foundation

struct FitnessAssessment: Codable {
    var maxPushups: Int
    var maxSitups: Int
    var maxSquats: Int
    var assessmentDate: Date
    var fitnessLevel: FitnessLevel
    var skippedAssessment: Bool
    
    // MARK: - Fitness Level Enum
    enum FitnessLevel: String, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case elite = "Elite"
        
        var icon: String {
            switch self {
            case .beginner: return "leaf.fill"
            case .intermediate: return "flame.fill"
            case .advanced: return "bolt.fill"
            case .elite: return "crown.fill"
            }
        }
        
        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            case .elite: return "purple"
            }
        }
        
        var title: String {
            switch self {
            case .beginner: return "Starting Strong"
            case .intermediate: return "Building Power"
            case .advanced: return "Impressive Form"
            case .elite: return "Beast Mode"
            }
        }
        
        var message: String {
            switch self {
            case .beginner:
                return "Your journey begins now!"
            case .intermediate:
                return "Solid foundation! Let's build on it."
            case .advanced:
                return "Great shape! Time to push limits."
            case .elite:
                return "Outstanding! Keep dominating!"
            }
        }
        
        var multiplier: Double {
            switch self {
            case .beginner: return 1.0
            case .intermediate: return 1.5
            case .advanced: return 2.0
            case .elite: return 2.0
            }
        }
    }
    
    // MARK: - Initializer with Assessment
    init(maxPushups: Int, maxSitups: Int, maxSquats: Int, skipped: Bool = false) {
        self.maxPushups = maxPushups
        self.maxSitups = maxSitups
        self.maxSquats = maxSquats
        self.assessmentDate = Date()
        self.skippedAssessment = skipped
        
        // Calculate fitness level based on performance
        if skipped {
            // If assessment was skipped, default to beginner
            self.fitnessLevel = .beginner
        } else {
            self.fitnessLevel = Self.calculateFitnessLevel(
                pushups: maxPushups,
                situps: maxSitups,
                squats: maxSquats
            )
        }
    }
    
    // MARK: - Calculate Fitness Level
    static func calculateFitnessLevel(pushups: Int, situps: Int, squats: Int) -> FitnessLevel {
        // Calculate average performance across all exercises
        let avgMax = (pushups + situps + squats) / 3
        
        // Determine fitness level based on average
        if avgMax < 10 {
            return .beginner
        } else if avgMax < 25 {
            return .intermediate
        } else if avgMax < 40 {
            return .advanced
        } else {
            return .elite
        }
    }
    
    // MARK: - Individual Exercise Levels
    func levelForExercise(_ exercise: String) -> FitnessLevel {
        let reps: Int
        
        if exercise.lowercased().contains("push") {
            reps = maxPushups
        } else if exercise.lowercased().contains("sit") {
            reps = maxSitups
        } else if exercise.lowercased().contains("squat") {
            reps = maxSquats
        } else {
            return .beginner
        }
        
        if reps < 10 {
            return .beginner
        } else if reps < 25 {
            return .intermediate
        } else if reps < 40 {
            return .advanced
        } else {
            return .elite
        }
    }
    
    // MARK: - Performance Metrics
    var totalReps: Int {
        return maxPushups + maxSitups + maxSquats
    }
    
    var averageReps: Int {
        return totalReps / 3
    }
    
    var strongestExercise: String {
        let max = Swift.max(maxPushups, maxSitups, maxSquats)
        if max == maxPushups {
            return "Push-ups"
        } else if max == maxSitups {
            return "Core"
        } else {
            return "Squats"
        }
    }
    
    var weakestExercise: String {
        let min = Swift.min(maxPushups, maxSitups, maxSquats)
        if min == maxPushups {
            return "Push-ups"
        } else if min == maxSitups {
            return "Core"
        } else {
            return "Squats"
        }
    }
    
    // MARK: - Assessment Summary
    var summary: String {
        if skippedAssessment {
            return "Assessment skipped - starting with beginner goals"
        }
        
        return "\(fitnessLevel.rawValue) level. Strongest: \(strongestExercise) (\(maxForExercise(strongestExercise))). Focus: \(weakestExercise) (\(maxForExercise(weakestExercise)))."
    }
    
    private func maxForExercise(_ exercise: String) -> Int {
        if exercise == "Push-ups" { return maxPushups }
        if exercise == "Sit-ups" || exercise == "Core" { return maxSitups }
        return maxSquats
    }
}

