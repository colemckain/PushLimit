import Foundation

enum ProfileAvatarPreset: String, CaseIterable, Codable, Identifiable {
    case initial
    case flame
    case strength
    case runner
    case bolt
    case trophy
    case star
    case heart
    case target
    case crown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .initial: return "Initials"
        case .flame: return "Flame"
        case .strength: return "Strength"
        case .runner: return "Runner"
        case .bolt: return "Energy"
        case .trophy: return "Champion"
        case .star: return "Star"
        case .heart: return "Heart"
        case .target: return "Focus"
        case .crown: return "Elite"
        }
    }

    var usesFlameAsset: Bool {
        self == .flame
    }

    var symbolName: String? {
        switch self {
        case .initial: return nil
        case .flame: return nil
        case .strength: return "figure.strengthtraining.traditional"
        case .runner: return "figure.run"
        case .bolt: return "bolt.fill"
        case .trophy: return "trophy.fill"
        case .star: return "star.fill"
        case .heart: return "heart.fill"
        case .target: return "scope"
        case .crown: return "crown.fill"
        }
    }
}
