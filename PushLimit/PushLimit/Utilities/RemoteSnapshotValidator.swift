import Foundation

/// Validates Firestore `users/{uid}` payloads before decoding into local models.
/// Limits mirror `firestore.rules` so tampered or oversized cloud docs cannot crash the app.
enum RemoteSnapshotValidator {
    static let maxUserNameLength = 100
    static let maxUserProfileJsonLength = 51_200
    static let maxFitnessAssessmentJsonLength = 20_480
    static let maxWorkoutPlanJsonLength = 102_400
    static let maxWorkoutsJsonLength = 512_000
    static let maxLevelInfoJsonLength = 10_240
    static let maxWeeklyGoalsJsonLength = 10_240
    static let maxWeeklyProgressJsonLength = 10_240
    static let minSchemaVersion = 1
    static let maxSchemaVersion = 10

    private static let allowedKeys: Set<String> = [
        "userName",
        "userProfileJson",
        "fitnessAssessmentJson",
        "workoutPlanJson",
        "workoutsJson",
        "levelInfoJson",
        "weeklyGoalsJson",
        "weeklyProgressJson",
        "schemaVersion",
        "updatedAt"
    ]

    enum ValidationError: LocalizedError {
        case unexpectedFields(Set<String>)
        case missingRequiredField(String)
        case invalidFieldType(String)
        case fieldTooLarge(String, max: Int)
        case invalidSchemaVersion(Int)

        var errorDescription: String? {
            switch self {
            case .unexpectedFields(let keys):
                return "Cloud backup contains unexpected fields: \(keys.sorted().joined(separator: ", "))."
            case .missingRequiredField(let field):
                return "Cloud backup is missing required field: \(field)."
            case .invalidFieldType(let field):
                return "Cloud backup field has an invalid type: \(field)."
            case .fieldTooLarge(let field, let max):
                return "Cloud backup field \(field) exceeds the \(max)-character limit."
            case .invalidSchemaVersion(let version):
                return "Cloud backup schema version \(version) is not supported."
            }
        }
    }

    static func validate(_ data: [String: Any]) throws {
        let unexpected = Set(data.keys).subtracting(allowedKeys)
        if !unexpected.isEmpty {
            throw ValidationError.unexpectedFields(unexpected)
        }

        try requireString(data["userName"], field: "userName", maxLength: maxUserNameLength)
        try requireString(data["userProfileJson"], field: "userProfileJson", maxLength: maxUserProfileJsonLength)
        try optionalString(data["fitnessAssessmentJson"], field: "fitnessAssessmentJson", maxLength: maxFitnessAssessmentJsonLength)
        try optionalString(data["workoutPlanJson"], field: "workoutPlanJson", maxLength: maxWorkoutPlanJsonLength)
        try requireString(data["workoutsJson"], field: "workoutsJson", maxLength: maxWorkoutsJsonLength)
        try requireString(data["levelInfoJson"], field: "levelInfoJson", maxLength: maxLevelInfoJsonLength)
        try requireString(data["weeklyGoalsJson"], field: "weeklyGoalsJson", maxLength: maxWeeklyGoalsJsonLength)
        try requireString(data["weeklyProgressJson"], field: "weeklyProgressJson", maxLength: maxWeeklyProgressJsonLength)

        guard let schemaVersion = data["schemaVersion"] else {
            throw ValidationError.missingRequiredField("schemaVersion")
        }
        let version: Int
        if let intVersion = schemaVersion as? Int {
            version = intVersion
        } else if let numberVersion = schemaVersion as? NSNumber {
            version = numberVersion.intValue
        } else {
            throw ValidationError.invalidFieldType("schemaVersion")
        }
        guard version >= minSchemaVersion, version <= maxSchemaVersion else {
            throw ValidationError.invalidSchemaVersion(version)
        }
    }

    private static func requireString(_ value: Any?, field: String, maxLength: Int) throws {
        guard let string = value as? String else {
            throw ValidationError.missingRequiredField(field)
        }
        guard string.count <= maxLength else {
            throw ValidationError.fieldTooLarge(field, max: maxLength)
        }
    }

    private static func optionalString(_ value: Any?, field: String, maxLength: Int) throws {
        guard let value else { return }
        guard let string = value as? String else {
            throw ValidationError.invalidFieldType(field)
        }
        guard string.count <= maxLength else {
            throw ValidationError.fieldTooLarge(field, max: maxLength)
        }
    }
}
