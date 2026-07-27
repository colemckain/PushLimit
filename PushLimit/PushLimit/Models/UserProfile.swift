import Foundation

struct UserProfile: Codable {
    static let weekdayShortNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var age: Int?
    var gender: Gender
    var fitnessGoal: FitnessGoal
    var activityLevel: ActivityLevel
    /// User-selected workout weekdays (1 = Monday … 7 = Sunday). Nil uses activity-level defaults.
    var preferredWorkoutDays: [Int]?
    var sleepSchedule: SleepSchedule?
    var hasCompletedOnboarding: Bool
    var onboardingCompletedDate: Date?
    
    init(
        age: Int? = nil,
        gender: Gender = .preferNotToSay,
        fitnessGoal: FitnessGoal = .maintainHealth,
        activityLevel: ActivityLevel = .beginner,
        preferredWorkoutDays: [Int]? = nil,
        sleepSchedule: SleepSchedule? = nil,
        hasCompletedOnboarding: Bool = false,
        onboardingCompletedDate: Date? = nil
    ) {
        self.age = age
        self.gender = gender
        self.fitnessGoal = fitnessGoal
        self.activityLevel = activityLevel
        self.preferredWorkoutDays = preferredWorkoutDays
        self.sleepSchedule = sleepSchedule
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.onboardingCompletedDate = onboardingCompletedDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        gender = try container.decode(Gender.self, forKey: .gender)
        fitnessGoal = try container.decode(FitnessGoal.self, forKey: .fitnessGoal)
        activityLevel = try container.decode(ActivityLevel.self, forKey: .activityLevel)
        preferredWorkoutDays = try container.decodeIfPresent([Int].self, forKey: .preferredWorkoutDays)
        sleepSchedule = try container.decodeIfPresent(SleepSchedule.self, forKey: .sleepSchedule)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        onboardingCompletedDate = try container.decodeIfPresent(Date.self, forKey: .onboardingCompletedDate)
    }

    /// Resolved workout days for plan generation — validates count against the current activity level.
    var effectiveWorkoutDays: [Int] {
        let expectedCount = activityLevel.workoutDays.count
        if let preferred = preferredWorkoutDays,
           preferred.count == expectedCount,
           Set(preferred).count == expectedCount {
            return preferred.sorted()
        }
        return activityLevel.workoutDays
    }

    var workoutDaysSummary: String {
        Self.formattedWorkoutDays(effectiveWorkoutDays)
    }

    static func formattedWorkoutDays(_ days: [Int]) -> String {
        days.sorted().map { weekdayShortNames[$0 - 1] }.joined(separator: " · ")
    }

    static func defaultWorkoutDays(for level: ActivityLevel) -> [Int] {
        level.workoutDays
    }

    mutating func syncWorkoutDaysForActivityLevel() {
        let expectedCount = activityLevel.workoutDays.count
        if preferredWorkoutDays?.count != expectedCount {
            preferredWorkoutDays = activityLevel.workoutDays
        }
    }
    
    // MARK: - Gender Enum
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case nonBinary = "Non-binary"
        case preferNotToSay = "Prefer not to say"
        
        var icon: String {
            switch self {
            case .male: return "person.fill"
            case .female: return "person.fill"
            case .nonBinary: return "person.fill"
            case .preferNotToSay: return "person.fill"
            }
        }
    }
    
    // MARK: - Fitness Goal Enum
    enum FitnessGoal: String, Codable, CaseIterable {
        case loseWeight = "Lose Weight"
        case buildMuscle = "Build Muscle"
        case increaseFitness = "Increase Fitness"
        case maintainHealth = "Maintain Health"
        case toneBody = "Tone & Strengthen"
        
        var icon: String {
            switch self {
            case .loseWeight: return "figure.run"
            case .buildMuscle: return "figure.strengthtraining.traditional"
            case .increaseFitness: return "heart.fill"
            case .maintainHealth: return "heart.circle.fill"
            case .toneBody: return "bolt.fill"
            }
        }
        
        var description: String {
            switch self {
            case .loseWeight:
                return "High-volume workouts to burn calories"
            case .buildMuscle:
                return "Progressive training to build strength"
            case .increaseFitness:
                return "Cardiovascular health and endurance"
            case .maintainHealth:
                return "Stay active and maintain fitness"
            case .toneBody:
                return "Define muscles and improve composition"
            }
        }
        
        var multiplier: Double {
            switch self {
            case .loseWeight: return 1.3
            case .buildMuscle: return 1.2
            case .increaseFitness: return 1.4
            case .maintainHealth: return 1.0
            case .toneBody: return 1.2
            }
        }
    }
    
    // MARK: - Activity Level Enum
    enum ActivityLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .beginner: return "1.circle.fill"
            case .intermediate: return "2.circle.fill"
            case .advanced: return "3.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .beginner:
                return "Just starting my fitness journey"
            case .intermediate:
                return "Exercise occasionally (1-3 times/week)"
            case .advanced:
                return "Work out regularly (4+ times/week)"
            }
        }
        
        var multiplier: Double {
            switch self {
            case .beginner: return 1.0
            case .intermediate: return 1.5
            case .advanced: return 2.0
            }
        }
        
        var workoutDays: [Int] {
            switch self {
            case .beginner: return [1, 3, 5] // Mon, Wed, Fri
            case .intermediate: return [1, 2, 4, 5] // Mon, Tue, Thu, Fri
            case .advanced: return [1, 2, 3, 4, 5] // Mon-Fri
            }
        }
    }
    
    // MARK: - Age-based Multiplier
    var ageMultiplier: Double {
        guard let age = age else { return 1.0 }
        
        if age < 18 {
            return 0.9 // Youth - slightly lower volume
        } else if age < 30 {
            return 1.0 // Prime years
        } else if age < 40 {
            return 0.95
        } else if age < 50 {
            return 0.9
        } else if age < 60 {
            return 0.85
        } else {
            return 0.8 // 60+ - recovery focus
        }
    }
    
    // MARK: - Computed Properties
    var isComplete: Bool {
        return hasCompletedOnboarding
    }
}

