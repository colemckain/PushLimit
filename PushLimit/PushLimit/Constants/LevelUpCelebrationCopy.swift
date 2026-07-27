import Foundation

/// Motivational copy for the level-up celebration overlay.
enum LevelUpCelebrationCopy {
    static func title(for level: Int) -> String {
        switch level {
        case 1: return "Rookie"
        case 2: return "Warrior"
        case 3: return "Beast"
        case 4: return "Titan"
        case 5: return "Legend"
        case 6: return "Champion"
        case 7: return "Elite"
        case 8: return "Master"
        case 9: return "Grandmaster"
        case 10: return "Ultimate"
        default: return "Immortal"
        }
    }
    
    static func motivationalQuote(forLevel level: Int) -> String {
        let pool = quotesForLevel(level)
        return pool.randomElement() ?? universalQuotes.randomElement()!
    }
    
    static var levelThreeUnlockHeadline: String {
        "New power unlocked"
    }
    
    static var levelThreeUnlockDetail: String {
        "You earned it — customize your accent color in Settings."
    }
    
    private static var universalQuotes: [String] {
        [
            "Every rep built this. Keep going.",
            "Limits are suggestions. You just proved it.",
            "Consistency beats talent. You're proving both.",
            "The hard days are why today happened.",
            "You didn't level up by accident — you earned it."
        ]
    }
    
    private static func quotesForLevel(_ level: Int) -> [String] {
        switch level {
        case 2:
            return [
                "You showed up. That's how warriors are made.",
                "Warriors aren't born — they're built rep by rep.",
                "Your future self is thanking you right now."
            ] + universalQuotes
        case 3:
            return [
                "Comfort zone? Left it a few workouts ago.",
                "Beast mode isn't a switch — it's a habit you kept.",
                "Stronger than yesterday. That's the whole game."
            ] + universalQuotes
        case 4:
            return [
                "Heavy reps. Heavy discipline. That's titan energy.",
                "Titans don't wait for motivation — they train.",
                "You bent the limit. Now break the next one."
            ] + universalQuotes
        case 5:
            return [
                "Legends aren't born — they're built rep by rep.",
                "This level is proof: you keep your promises to yourself.",
                "Legend status: earned, not given."
            ] + universalQuotes
        case 6:
            return [
                "Champions don't wait for motivation. They train.",
                "Winning today started on your hardest days.",
                "Champion mindset: show up again tomorrow."
            ] + universalQuotes
        case 7:
            return [
                "Elite isn't a gift. It's what you do when no one's watching.",
                "Average stops here. You didn't.",
                "Elite is a habit — and you're living it."
            ] + universalQuotes
        case 8:
            return [
                "Mastery isn't the peak — it's the habit you kept.",
                "Masters are made in the reps no one claps for.",
                "Precision. Patience. Power. That's mastery."
            ] + universalQuotes
        case 9:
            return [
                "You've outgrown 'good enough.' Stay hungry.",
                "Grandmaster energy: calm, focused, unstoppable.",
                "The top isn't the end — it's the new starting line."
            ] + universalQuotes
        case 10:
            return [
                "Most people stop here. You didn't.",
                "Ultimate isn't a label — it's your standard now.",
                "You redefined your ceiling. Raise it again."
            ] + universalQuotes
        default:
            return [
                "Immortal consistency. Keep writing your story.",
                "Beyond the map. You're the benchmark now.",
                "They'll ask how you did it. You'll know: one rep at a time."
            ] + universalQuotes
        }
    }
}
