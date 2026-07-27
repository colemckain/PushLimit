import Foundation

class WorkoutPlanGenerator {
    
    // MARK: - Generate Personalized Weekly Goals
    static func generateWeeklyGoals(
        profile: UserProfile,
        assessment: FitnessAssessment?
    ) -> WeeklyGoals {
        
        // Base multiplier from fitness level (if assessment was done)
        let levelMultiplier: Double = {
            if let assessment = assessment, !assessment.skippedAssessment {
                return assessment.fitnessLevel.multiplier
            } else {
                // If no assessment, use activity level
                return profile.activityLevel.multiplier
            }
        }()
        
        // Goal-based multiplier
        let goalMultiplier = profile.fitnessGoal.multiplier
        
        // Age-based multiplier
        let ageMultiplier = profile.ageMultiplier
        
        // Calculate total multiplier
        let totalMultiplier = levelMultiplier * goalMultiplier * ageMultiplier
        
        // Calculate wall sit time goal
        // Wall sits: 2 sets × 30 seconds = 60 seconds per leg workout
        let workoutDaysCount = profile.effectiveWorkoutDays.count
        let wallSitTimeGoal = 60 * workoutDaysCount  // 60 seconds per workout day
        
        // Use assessment data if available
        if let assessment = assessment, !assessment.skippedAssessment {
            let coreDaily = CoreWorkoutSupport.scaleDailyTotal(
                CoreWorkoutSupport.dailyTotal(maxSitups: assessment.maxSitups, activityLevel: profile.activityLevel),
                multiplier: goalMultiplier * ageMultiplier
            )
            return WeeklyGoals(
                pushups: calculateGoalFromMax(assessment.maxPushups, multiplier: totalMultiplier),
                situps: CoreWorkoutSupport.weeklyGoal(dailyTotal: coreDaily, workoutDays: workoutDaysCount),
                squats: calculateGoalFromMax(assessment.maxSquats, multiplier: totalMultiplier),
                wallSitTimeSeconds: wallSitTimeGoal
            )
        } else {
            // No assessment - use scaled base targets
            let baseTarget = 70  // Conservative base for beginners
            let target = Int(Double(baseTarget) * totalMultiplier)
            let coreDaily = CoreWorkoutSupport.scaleDailyTotal(
                CoreWorkoutSupport.dailyTotal(maxSitups: nil, activityLevel: profile.activityLevel),
                multiplier: goalMultiplier * ageMultiplier
            )
            return WeeklyGoals(
                pushups: target,
                situps: CoreWorkoutSupport.weeklyGoal(dailyTotal: coreDaily, workoutDays: workoutDaysCount),
                squats: target,
                wallSitTimeSeconds: wallSitTimeGoal
            )
        }
    }
    
    // MARK: - Calculate Weekly Goal from Max Performance
    private static func calculateGoalFromMax(_ maxReps: Int, multiplier: Double) -> Int {
        // More realistic approach: Weekly goal = max reps × 3-4 × multiplier
        // This assumes 3-4 sets per workout, spread across the week
        let baseGoal = maxReps * 2  // Easier ramp: reduce weekly volume
        let adjustedGoal = Int(Double(baseGoal) * multiplier)
        
        // Round to nearest 5 and ensure minimum of 20
        return max(20, (adjustedGoal / 5) * 5)
    }
    
    // MARK: - Generate Complete Workout Plan
    static func generateWorkoutPlan(
        profile: UserProfile,
        assessment: FitnessAssessment?
    ) -> WorkoutPlan {
        
        // Generate weekly goals
        let weeklyGoals = generateWeeklyGoals(profile: profile, assessment: assessment)
        
        // Generate daily recommendations
        let dailyRecommendations = generateDailyRecommendations(
            profile: profile,
            weeklyGoals: weeklyGoals,
            assessment: assessment
        )
        
        // Determine fitness level
        let fitnessLevel: FitnessAssessment.FitnessLevel = {
            if let assessment = assessment, !assessment.skippedAssessment {
                return assessment.fitnessLevel
            } else {
                switch profile.activityLevel {
                case .beginner: return .beginner
                case .intermediate: return .intermediate
                case .advanced: return .advanced
                }
            }
        }()
        
        // Create plan name and description
        let planName = generatePlanName(fitnessLevel: fitnessLevel, goal: profile.fitnessGoal)
        let planDescription = generatePlanDescription(fitnessLevel: fitnessLevel, goal: profile.fitnessGoal)
        
        return WorkoutPlan(
            name: planName,
            description: planDescription,
            durationWeeks: 4,
            weeklyGoals: weeklyGoals,
            dailyRecommendations: dailyRecommendations,
            fitnessLevel: fitnessLevel
        )
    }
    
    // MARK: - Generate Daily Recommendations
    private static func generateDailyRecommendations(
        profile: UserProfile,
        weeklyGoals: WeeklyGoals,
        assessment: FitnessAssessment?
    ) -> [WorkoutPlan.DailyRecommendation] {
        
        var recommendations: [WorkoutPlan.DailyRecommendation] = []
        
        // Determine workout days based on activity level
        let workoutDays = profile.effectiveWorkoutDays
        
        // Distribute weekly goals across workout days
        let daysCount = workoutDays.count
        let pushupsPerDay = weeklyGoals.pushups / daysCount
        let situpsPerDay = weeklyGoals.situps / daysCount
        let squatsPerDay = weeklyGoals.squats / daysCount
        
        // Create recommendations for each day of the week (1-7)
        for day in 1...7 {
            if workoutDays.contains(day) {
                // Workout day - create exercises
                let pushSets = calculateOptimalSets(
                    totalReps: pushupsPerDay,
                    maxReps: assessment?.maxPushups ?? estimateMaxReps(for: profile)
                )
                let pushRepsPerSet = calculateRepsPerSet(
                    totalReps: pushupsPerDay,
                    maxReps: assessment?.maxPushups ?? estimateMaxReps(for: profile)
                )
                let pushTotalReps = pushSets * pushRepsPerSet
                
                let squatSets = calculateOptimalSets(
                    totalReps: squatsPerDay,
                    maxReps: assessment?.maxSquats ?? estimateMaxReps(for: profile)
                )
                let squatRepsPerSet = calculateRepsPerSet(
                    totalReps: squatsPerDay,
                    maxReps: assessment?.maxSquats ?? estimateMaxReps(for: profile)
                )
                let squatTotalReps = squatSets * squatRepsPerSet
                let coreRecommendation = makeCoreRecommendation(preferredDailyTotal: situpsPerDay)
                
                let exercises: [WorkoutPlan.ExerciseRecommendation] = [
                    WorkoutPlan.ExerciseRecommendation(
                        exercise: "Push-ups",
                        sets: pushSets,
                        repsPerSet: pushRepsPerSet,
                        totalReps: pushTotalReps,
                        restBetweenSets: 60,
                        notes: "Focus on proper form with chest to floor"
                    ),
                    coreRecommendation,
                    WorkoutPlan.ExerciseRecommendation(
                        exercise: "Leg Workout",
                        sets: squatSets,
                        repsPerSet: squatRepsPerSet,
                        totalReps: squatTotalReps,
                        restBetweenSets: 45,
                        notes: "Squats: Squat to parallel or below. Wall Sits: 2 sets × 30 seconds."
                    )
                ]
                
                recommendations.append(WorkoutPlan.DailyRecommendation(
                    dayOfWeek: day,
                    exercises: exercises,
                    restDay: false
                ))
            } else {
                // Rest day
                recommendations.append(WorkoutPlan.DailyRecommendation(
                    dayOfWeek: day,
                    exercises: [],
                    restDay: true
                ))
            }
        }
        
        return recommendations
    }
    
    /// Core day = 5 moves × equal reps (e.g. 50 total → 10 each).
    private static func makeCoreRecommendation(preferredDailyTotal: Int) -> WorkoutPlan.ExerciseRecommendation {
        let normalized = CoreWorkoutSupport.normalizedDailyTotal(from: preferredDailyTotal)
        return WorkoutPlan.ExerciseRecommendation(
            exercise: CoreWorkoutSupport.planExerciseName,
            sets: CoreWorkoutSupport.moveCount,
            repsPerSet: normalized.repsPerMove,
            totalReps: normalized.dailyTotal,
            restBetweenSets: 45,
            notes: CoreWorkoutSupport.circuitNotes(repsPerMove: normalized.repsPerMove)
        )
    }
    
    // MARK: - Calculate Optimal Sets (Progressive)
    private static func calculateOptimalSets(totalReps: Int, maxReps: Int, currentWeek: Int = 1) -> Int {
        // Progressive sets based on week
        switch currentWeek {
        case 1...2:
            return 4  // Week 1-2: 4 sets (foundation)
        case 3...4:
            return 3  // Week 3-4: 3 sets (building)
        default:
            return 2  // Week 5+: 2 sets (power)
        }
    }
    
    // MARK: - Calculate Reps Per Set
    private static func calculateRepsPerSet(totalReps: Int, maxReps: Int, currentWeek: Int = 1) -> Int {
        let sets = calculateOptimalSets(totalReps: totalReps, maxReps: maxReps, currentWeek: currentWeek)
        let rawRepsPerSet = Double(totalReps) / Double(max(1, sets))

        // Always keep reps in consistent increments.
        // Rounding UP avoids awkward values like 13/17 and keeps progression predictable.
        let multiple = 5
        let roundedUp = Int(ceil(rawRepsPerSet / Double(multiple))) * multiple
        return max(5, roundedUp)
    }
    
    // MARK: - Estimate Max Reps (if no assessment)
    private static func estimateMaxReps(for profile: UserProfile) -> Int {
        switch profile.activityLevel {
        case .beginner: return 8
        case .intermediate: return 15
        case .advanced: return 25
        }
    }
    
    // MARK: - Generate Plan Name
    private static func generatePlanName(fitnessLevel: FitnessAssessment.FitnessLevel, goal: UserProfile.FitnessGoal) -> String {
        let levelPrefix: String = {
            switch fitnessLevel {
            case .beginner: return "Starter"
            case .intermediate: return "Builder"
            case .advanced: return "Athlete"
            case .elite: return "Elite"
            }
        }()
        
        let goalSuffix: String = {
            switch goal {
            case .loseWeight: return "Fat Burn"
            case .buildMuscle: return "Muscle Build"
            case .increaseFitness: return "Endurance"
            case .maintainHealth: return "Wellness"
            case .toneBody: return "Tone & Define"
            }
        }()
        
        return "\(levelPrefix) \(goalSuffix) Plan"
    }
    
    // MARK: - Generate Plan Description
    private static func generatePlanDescription(fitnessLevel: FitnessAssessment.FitnessLevel, goal: UserProfile.FitnessGoal) -> String {
        let levelDescription: String = {
            switch fitnessLevel {
            case .beginner:
                return "for beginners"
            case .intermediate:
                return "for intermediate fitness"
            case .advanced:
                return "for advanced athletes"
            case .elite:
                return "for elite performers"
            }
        }()
        
        let goalDescription: String = {
            switch goal {
            case .loseWeight:
                return "focused on fat burning"
            case .buildMuscle:
                return "focused on muscle building"
            case .increaseFitness:
                return "focused on endurance"
            case .maintainHealth:
                return "focused on health maintenance"
            case .toneBody:
                return "focused on toning"
            }
        }()
        
        return "4-week plan \(levelDescription) \(goalDescription)."
    }
    
    // MARK: - Generate Motivational Message
    static func generateMotivationalMessage(for assessment: FitnessAssessment) -> String {
        if assessment.skippedAssessment {
            return "We'll start with beginner goals and adjust as you progress!"
        }
        
        let performance = assessment.averageReps
        
        if performance < 10 {
            return "Great start! Your fitness journey begins now."
        } else if performance < 20 {
            return "Solid foundation! Let's build on it."
        } else if performance < 30 {
            return "Impressive! Time to level up."
        } else {
            return "Elite performance! Ready for the challenge?"
        }
    }
    
    // MARK: - Regenerate Plan with Progression
    static func regeneratePlanWithProgression(
        currentPlan: WorkoutPlan,
        profile: UserProfile,
        assessment: FitnessAssessment?,
        newWeek: Int,
        weeklyGoalMultiplier: Double = 1.0  // 1.0 = maintain, 1.1 = increase 10%
    ) -> WorkoutPlan {
        
        // Apply multiplier to weekly goals if performance warrants it
        var adjustedGoals = currentPlan.weeklyGoals
        if weeklyGoalMultiplier != 1.0 {
            // Recalculate wall sit time based on current workout days
            let workoutDaysCount = profile.effectiveWorkoutDays.count
            let wallSitTimeGoal = 60 * workoutDaysCount
            
            adjustedGoals = WeeklyGoals(
                pushups: Int(Double(currentPlan.weeklyGoals.pushups) * weeklyGoalMultiplier),
                situps: Int(Double(currentPlan.weeklyGoals.situps) * weeklyGoalMultiplier),
                squats: Int(Double(currentPlan.weeklyGoals.squats) * weeklyGoalMultiplier),
                wallSitTimeSeconds: wallSitTimeGoal
            )
        } else {
            // Recalculate wall sit time even if multiplier is 1.0 (in case workout days changed)
            let workoutDaysCount = profile.effectiveWorkoutDays.count
            adjustedGoals.wallSitTimeSeconds = 60 * workoutDaysCount
        }
        
        // Generate new daily recommendations with updated week number
        let dailyRecommendations = generateDailyRecommendationsForWeek(
            profile: profile,
            weeklyGoals: adjustedGoals,
            assessment: assessment,
            currentWeek: newWeek
        )
        
        // Create updated plan
        var updatedPlan = currentPlan
        updatedPlan.currentWeek = newWeek
        updatedPlan.weeklyGoals = adjustedGoals
        updatedPlan.dailyRecommendations = dailyRecommendations
        updatedPlan.lastProgressionCheckDate = Date()
        
        return updatedPlan
    }
    
    // MARK: - Generate Daily Recommendations for Specific Week
    private static func generateDailyRecommendationsForWeek(
        profile: UserProfile,
        weeklyGoals: WeeklyGoals,
        assessment: FitnessAssessment?,
        currentWeek: Int
    ) -> [WorkoutPlan.DailyRecommendation] {
        
        var recommendations: [WorkoutPlan.DailyRecommendation] = []
        
        // Determine workout days based on activity level
        let workoutDays = profile.effectiveWorkoutDays
        
        // Distribute weekly goals across workout days
        let daysCount = workoutDays.count
        let pushupsPerDay = weeklyGoals.pushups / daysCount
        let situpsPerDay = weeklyGoals.situps / daysCount
        let squatsPerDay = weeklyGoals.squats / daysCount
        
        // Create recommendations for each day of the week (1-7)
        for day in 1...7 {
            if workoutDays.contains(day) {
                // Workout day - create exercises with current week's set count
                let pushSets = calculateOptimalSets(
                    totalReps: pushupsPerDay,
                    maxReps: assessment?.maxPushups ?? estimateMaxReps(for: profile),
                    currentWeek: currentWeek
                )
                let pushRepsPerSet = calculateRepsPerSet(
                    totalReps: pushupsPerDay,
                    maxReps: assessment?.maxPushups ?? estimateMaxReps(for: profile),
                    currentWeek: currentWeek
                )
                let pushTotalReps = pushSets * pushRepsPerSet
                
                let squatSets = calculateOptimalSets(
                    totalReps: squatsPerDay,
                    maxReps: assessment?.maxSquats ?? estimateMaxReps(for: profile),
                    currentWeek: currentWeek
                )
                let squatRepsPerSet = calculateRepsPerSet(
                    totalReps: squatsPerDay,
                    maxReps: assessment?.maxSquats ?? estimateMaxReps(for: profile),
                    currentWeek: currentWeek
                )
                let squatTotalReps = squatSets * squatRepsPerSet
                let coreRecommendation = makeCoreRecommendation(preferredDailyTotal: situpsPerDay)
                
                let exercises: [WorkoutPlan.ExerciseRecommendation] = [
                    WorkoutPlan.ExerciseRecommendation(
                        exercise: "Push-ups",
                        sets: pushSets,
                        repsPerSet: pushRepsPerSet,
                        totalReps: pushTotalReps,
                        restBetweenSets: 60,
                        notes: "Focus on proper form with chest to floor"
                    ),
                    coreRecommendation,
                    WorkoutPlan.ExerciseRecommendation(
                        exercise: "Leg Workout",
                        sets: squatSets,
                        repsPerSet: squatRepsPerSet,
                        totalReps: squatTotalReps,
                        restBetweenSets: 45,
                        notes: "Squats: Squat to parallel or below. Wall Sits: 2 sets × 30 seconds."
                    )
                ]
                
                recommendations.append(WorkoutPlan.DailyRecommendation(
                    dayOfWeek: day,
                    exercises: exercises,
                    restDay: false
                ))
            } else {
                // Rest day
                recommendations.append(WorkoutPlan.DailyRecommendation(
                    dayOfWeek: day,
                    exercises: [],
                    restDay: true
                ))
            }
        }
        
        return recommendations
    }
}

