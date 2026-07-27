import Foundation

/// Saved mid-workout progress so End early can resume later the same day.
struct WorkoutSessionDraft: Codable, Equatable {
    var exerciseId: String
    var dayKey: String
    var currentSetIndex: Int
    var currentRep: Int
    /// Reps finished in fully completed sets at the moment of save (session-local).
    var completedRepsThisSession: Int
    var isWallSitPhase: Bool
    var currentWallSitSet: Int
    var wallSitSecondsRemaining: Int
    var wasActivelyCountingReps: Bool
    var wasResting: Bool
    var restSecondsRemaining: Int
    var elapsedSeconds: Int
    var plannedTotalReps: Int
    var plannedSets: Int
    var plannedRepsPerSet: Int
    /// Continue starts at set 1 / rep 1 (from the top), not mid-set.
    var restartFromTop: Bool
    /// Early quit: remaining work + an extra owed set.
    var isEarlyQuitDebt: Bool
    /// True when `plannedTotalReps` includes the early-quit penalty set.
    var includesPenaltySet: Bool
    
    init(
        exerciseId: String,
        dayKey: String = WorkoutSessionDraft.dayKey(),
        currentSetIndex: Int,
        currentRep: Int,
        completedRepsThisSession: Int,
        isWallSitPhase: Bool,
        currentWallSitSet: Int,
        wallSitSecondsRemaining: Int,
        wasActivelyCountingReps: Bool,
        wasResting: Bool,
        restSecondsRemaining: Int,
        elapsedSeconds: Int,
        plannedTotalReps: Int,
        plannedSets: Int,
        plannedRepsPerSet: Int,
        restartFromTop: Bool = true,
        isEarlyQuitDebt: Bool = false,
        includesPenaltySet: Bool = false
    ) {
        self.exerciseId = exerciseId
        self.dayKey = dayKey
        self.currentSetIndex = currentSetIndex
        self.currentRep = currentRep
        self.completedRepsThisSession = completedRepsThisSession
        self.isWallSitPhase = isWallSitPhase
        self.currentWallSitSet = currentWallSitSet
        self.wallSitSecondsRemaining = wallSitSecondsRemaining
        self.wasActivelyCountingReps = wasActivelyCountingReps
        self.wasResting = wasResting
        self.restSecondsRemaining = restSecondsRemaining
        self.elapsedSeconds = elapsedSeconds
        self.plannedTotalReps = plannedTotalReps
        self.plannedSets = plannedSets
        self.plannedRepsPerSet = plannedRepsPerSet
        self.restartFromTop = restartFromTop
        self.isEarlyQuitDebt = isEarlyQuitDebt
        self.includesPenaltySet = includesPenaltySet
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try c.decode(String.self, forKey: .exerciseId)
        dayKey = try c.decode(String.self, forKey: .dayKey)
        currentSetIndex = try c.decode(Int.self, forKey: .currentSetIndex)
        currentRep = try c.decode(Int.self, forKey: .currentRep)
        completedRepsThisSession = try c.decode(Int.self, forKey: .completedRepsThisSession)
        isWallSitPhase = try c.decode(Bool.self, forKey: .isWallSitPhase)
        currentWallSitSet = try c.decode(Int.self, forKey: .currentWallSitSet)
        wallSitSecondsRemaining = try c.decode(Int.self, forKey: .wallSitSecondsRemaining)
        wasActivelyCountingReps = try c.decode(Bool.self, forKey: .wasActivelyCountingReps)
        wasResting = try c.decode(Bool.self, forKey: .wasResting)
        restSecondsRemaining = try c.decode(Int.self, forKey: .restSecondsRemaining)
        elapsedSeconds = try c.decode(Int.self, forKey: .elapsedSeconds)
        plannedTotalReps = try c.decode(Int.self, forKey: .plannedTotalReps)
        plannedSets = try c.decode(Int.self, forKey: .plannedSets)
        plannedRepsPerSet = try c.decode(Int.self, forKey: .plannedRepsPerSet)
        restartFromTop = try c.decodeIfPresent(Bool.self, forKey: .restartFromTop) ?? true
        isEarlyQuitDebt = try c.decodeIfPresent(Bool.self, forKey: .isEarlyQuitDebt) ?? false
        includesPenaltySet = try c.decodeIfPresent(Bool.self, forKey: .includesPenaltySet) ?? false
    }
    
    static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var isFromToday: Bool {
        dayKey == Self.dayKey()
    }
    
    func matches(exerciseId: String) -> Bool {
        self.exerciseId.lowercased() == exerciseId.lowercased()
    }
    
    /// Builds the "owe PushLimit" continue block: remaining reps + one full set, from the top.
    static func earlyQuitDebtDraft(
        exerciseId: String,
        remainingReps: Int,
        repsPerSet: Int,
        elapsedSeconds: Int
    ) -> WorkoutSessionDraft? {
        let perSet = max(1, repsPerSet)
        let leftover = max(0, remainingReps)
        guard leftover > 0 else { return nil }
        
        let penaltySet = perSet
        let owedTotal = leftover + penaltySet
        let owedSets = max(1, Int(ceil(Double(owedTotal) / Double(perSet))))
        
        return WorkoutSessionDraft(
            exerciseId: exerciseId,
            currentSetIndex: 0,
            currentRep: 1,
            completedRepsThisSession: 0,
            isWallSitPhase: false,
            currentWallSitSet: 0,
            wallSitSecondsRemaining: 30,
            wasActivelyCountingReps: false,
            wasResting: false,
            restSecondsRemaining: 0,
            elapsedSeconds: elapsedSeconds,
            plannedTotalReps: owedTotal,
            plannedSets: owedSets,
            plannedRepsPerSet: perSet,
            restartFromTop: true,
            isEarlyQuitDebt: true,
            includesPenaltySet: true
        )
    }
}
