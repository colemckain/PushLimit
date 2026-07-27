import Foundation

/// Records Terms/Privacy and fitness disclaimer acceptance for compliance.
enum LegalConsentStore {
    private static let termsAcceptedVersionKey = "legalTermsAcceptedVersion"
    private static let termsAcceptedAtKey = "legalTermsAcceptedAt"
    private static let fitnessDisclaimerAcceptedAtKey = "fitnessDisclaimerAcceptedAt"
    private static let legRunLocationDisclosureAcceptedAtKey = "legRunLocationDisclosureAcceptedAt"
    private static let legRunLocationDisclosureAcceptedVersionKey = "legRunLocationDisclosureAcceptedVersion"

    static var hasAcceptedTermsAndPrivacy: Bool {
        UserDefaults.standard.string(forKey: termsAcceptedVersionKey) == LegalCopy.policyVersion
    }

    static var hasAcceptedFitnessDisclaimer: Bool {
        UserDefaults.standard.object(forKey: fitnessDisclaimerAcceptedAtKey) != nil
    }

    static var hasAcceptedLegRunLocationDisclosure: Bool {
        UserDefaults.standard.string(forKey: legRunLocationDisclosureAcceptedVersionKey)
            == LegWorkoutSupport.locationDisclosureVersion
    }

    /// Terms + fitness disclaimer required before collecting profile PII.
    static var hasAcceptedRequiredLegalConsent: Bool {
        hasAcceptedTermsAndPrivacy && hasAcceptedFitnessDisclaimer
    }

    static var termsAcceptedAt: Date? {
        guard let interval = UserDefaults.standard.object(forKey: termsAcceptedAtKey) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    static func recordTermsAndPrivacyAcceptance() {
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(LegalCopy.policyVersion, forKey: termsAcceptedVersionKey)
        UserDefaults.standard.set(now, forKey: termsAcceptedAtKey)
    }

    static func recordFitnessDisclaimerAcceptance() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: fitnessDisclaimerAcceptedAtKey)
    }

    static func recordLegRunLocationDisclosureAcceptance() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: legRunLocationDisclosureAcceptedAtKey)
        UserDefaults.standard.set(
            LegWorkoutSupport.locationDisclosureVersion,
            forKey: legRunLocationDisclosureAcceptedVersionKey
        )
    }

    static func recordFullOnboardingConsent() {
        recordTermsAndPrivacyAcceptance()
        recordFitnessDisclaimerAcceptance()
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: termsAcceptedVersionKey)
        UserDefaults.standard.removeObject(forKey: termsAcceptedAtKey)
        UserDefaults.standard.removeObject(forKey: fitnessDisclaimerAcceptedAtKey)
        UserDefaults.standard.removeObject(forKey: legRunLocationDisclosureAcceptedAtKey)
        UserDefaults.standard.removeObject(forKey: legRunLocationDisclosureAcceptedVersionKey)
    }
}
