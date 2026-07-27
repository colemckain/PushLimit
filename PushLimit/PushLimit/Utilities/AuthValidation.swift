import Foundation

enum AuthValidation {
    static let minimumPasswordLength = 8

    static func validateEmail(_ raw: String) -> String? {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty {
            return "Please enter your email."
        }
        // Practical RFC 5322–inspired check (not exhaustive).
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        guard email.range(of: pattern, options: .regularExpression) != nil else {
            return "Please enter a valid email address."
        }
        return nil
    }

    static func validatePassword(_ password: String, isSignUp: Bool) -> String? {
        if password.isEmpty {
            return "Please enter your password."
        }
        guard isSignUp else { return nil }

        if password.count < minimumPasswordLength {
            return "Password must be at least \(minimumPasswordLength) characters."
        }
        if password.rangeOfCharacter(from: .letters) == nil {
            return "Password must include at least one letter."
        }
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            return "Password must include at least one number."
        }
        return nil
    }

    static func validateSignIn(email: String, password: String) -> String? {
        if let emailError = validateEmail(email) { return emailError }
        return validatePassword(password, isSignUp: false)
    }

    static func validateSignUp(email: String, password: String) -> String? {
        if let emailError = validateEmail(email) { return emailError }
        return validatePassword(password, isSignUp: true)
    }
}
