import Foundation

/// How PushLimit speaks to the user — supportive encouragement or direct discipline mode.
enum FeedbackTone: String, Codable, CaseIterable, Identifiable {
    case supportive
    case disciplined

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supportive: return "Supportive"
        case .disciplined: return "Discipline mode"
        }
    }

    var subtitle: String {
        switch self {
        case .supportive:
            return "Warm, helpful reminders that meet you where you are"
        case .disciplined:
            return "Direct reality checks — no gym excuses, just action"
        }
    }

    var icon: String {
        switch self {
        case .supportive: return "heart.fill"
        case .disciplined: return "bolt.fill"
        }
    }

    var previewNotificationTitle: String {
        switch self {
        case .supportive: return "Good job so far"
        case .disciplined: return "Not so fast"
        }
    }

    var previewNotificationBody: String {
        switch self {
        case .supportive:
            return "Nice work on the reps you finished. Circle back when you can and complete the full workout — you’ve got this."
        case .disciplined:
            return "Nice try cutting the session short. You still owe me a full workout — come back when you’ve got the time. Don’t forget."
        }
    }

    var previewCompletionHeadline: String {
        switch self {
        case .supportive: return "You showed up."
        case .disciplined: return "Excuses didn't win."
        }
    }

    var previewCompletionQuote: String {
        switch self {
        case .supportive:
            return "Small session, real progress. Be proud of showing up for yourself."
        case .disciplined:
            return "Too far to drive. Too long to train. You still got it done."
        }
    }

    static let userDefaultsKey = "feedbackTone"

    static var current: FeedbackTone {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let tone = FeedbackTone(rawValue: raw) else {
            return .disciplined
        }
        return tone
    }

    static func persist(_ tone: FeedbackTone) {
        UserDefaults.standard.set(tone.rawValue, forKey: userDefaultsKey)
    }
}
