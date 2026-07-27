import Foundation

struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let muscleGroups: [String]
} 