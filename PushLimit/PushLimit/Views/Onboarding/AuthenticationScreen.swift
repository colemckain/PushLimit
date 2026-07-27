import SwiftUI

// Firebase is optional at compile-time so the app can still build even if the
// Firebase SDK isn't present yet. Once Firebase is added to the project,
// this screen will automatically use it.
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
import FirebaseAuth
import FirebaseCore
#endif

struct AuthenticationScreen: View {
    @Binding var isAuthenticated: Bool
    let themeColor: Color
    let onContinue: () -> Void
    /// When set (e.g. onboarding), show a full-width secondary action alongside sign-in.
    let onContinueWithoutAccount: (() -> Void)?
    let headline: String
    let subtitle: String
    let headerSystemImage: String
    let secondaryCtaTitle: String

    init(
        isAuthenticated: Binding<Bool>,
        themeColor: Color,
        onContinue: @escaping () -> Void,
        onContinueWithoutAccount: (() -> Void)? = nil,
        headline: String = "Sign in to PushLimit",
        subtitle: String = "Optional: sign in to back up your plan and use it on your other devices.",
        headerSystemImage: String = "lock.shield.fill",
        secondaryCtaTitle: String = "Continue without account"
    ) {
        _isAuthenticated = isAuthenticated
        self.themeColor = themeColor
        self.onContinue = onContinue
        self.onContinueWithoutAccount = onContinueWithoutAccount
        self.headline = headline
        self.subtitle = subtitle
        self.headerSystemImage = headerSystemImage
        self.secondaryCtaTitle = secondaryCtaTitle
    }

    @State private var authMode: AuthMode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""

    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var showingForgotPassword = false

    enum AuthMode: Hashable {
        case signIn
        case signUp
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                VStack(spacing: 12) {
                    Image(systemName: headerSystemImage)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(themeColor)

                    Text(headline)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Picker("", selection: $authMode) {
                    Text("Sign In").tag(AuthMode.signIn)
                    Text("Sign Up").tag(AuthMode.signUp)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: authMode) { _, _ in
                    errorMessage = nil
                    infoMessage = nil
                }

                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.customLabel)

                        TextField("you@example.com", text: $email)
                            .font(.system(size: 18))
                            .foregroundColor(.customLabel)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(16)
                            .background(Color.customSecondaryBackground)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.customLabel)

                        SecureField("Your password", text: $password)
                            .font(.system(size: 18))
                            .foregroundColor(.customLabel)
                            .textContentType(authMode == .signUp ? .newPassword : .password)
                            .padding(16)
                            .background(Color.customSecondaryBackground)
                            .cornerRadius(12)

                        if authMode == .signUp {
                            Text("At least \(AuthValidation.minimumPasswordLength) characters with a letter and a number.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.customSecondaryLabel)
                        }
                    }
                }
                .padding(.horizontal, 20)

                if let infoMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundColor(themeColor)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.top, 2)

                            Text(infoMessage)
                                .foregroundColor(.customLabel)
                                .font(.system(size: 13))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if let errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.top, 2)

                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 13))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 14) {
                    if authMode == .signIn {
                        Button {
                            Task { await handleSignIn() }
                        } label: {
                            Text(isBusy ? "Signing In..." : "Sign In")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(themeColor)
                        .cornerRadius(12)
                        .disabled(isBusy || email.isEmpty || password.isEmpty)
                    } else {
                        Button {
                            Task { await handleSignUp() }
                        } label: {
                            Text(isBusy ? "Creating Account..." : "Sign Up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(themeColor)
                        .cornerRadius(12)
                        .disabled(isBusy || email.isEmpty || password.isEmpty)
                    }

                    if let onContinueWithoutAccount {
                        Button {
                            errorMessage = nil
                            isAuthenticated = false
                            onContinueWithoutAccount()
                        } label: {
                            Text(secondaryCtaTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.customSecondaryBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeColor.opacity(0.45), lineWidth: 2)
                                )
                        }
                        .disabled(isBusy)
                    }

                    Button {
                        showingForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeColor)
                    }
                    .disabled(isBusy)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
        }
        .background(Color.customBackground)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordScreen(
                initialEmail: email,
                themeColor: themeColor
            )
        }
    }

    private func validateInputs(isSignUp: Bool) -> String? {
        if isSignUp {
            return AuthValidation.validateSignUp(email: email, password: password)
        }
        return AuthValidation.validateSignIn(email: email, password: password)
    }

    private func handleSignIn() async {
        errorMessage = nil
        infoMessage = nil

        if let validationError = validateInputs(isSignUp: false) {
            errorMessage = validationError
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            try await FirebaseAuthClient.signIn(email: email, password: password)
            await MainActor.run {
                isAuthenticated = true
                onContinue()
            }
        } catch {
            await MainActor.run {
                isAuthenticated = false
                #if canImport(FirebaseAuth)
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.secondFactorRequired.rawValue {
                    errorMessage = "This account has two-factor authentication enabled in Firebase, but PushLimit does not support SMS 2FA on the free plan."
                    return
                }
                #endif
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleSignUp() async {
        errorMessage = nil
        infoMessage = nil

        if let validationError = validateInputs(isSignUp: true) {
            errorMessage = validationError
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            try await FirebaseAuthClient.signUp(email: trimmedEmail, password: password)
            try await FirebaseAuthClient.sendEmailVerification()
            await MainActor.run {
                isAuthenticated = true
                infoMessage = "We sent a verification link to \(trimmedEmail). Verify your email to enable cloud backup. You can continue using the app on this device."
                onContinue()
            }
        } catch {
            await MainActor.run {
                isAuthenticated = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // Password reset is handled in `ForgotPasswordScreen` (separate page).
}

enum FirebaseAuthClientError: LocalizedError {
    case firebaseUnavailable
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .firebaseUnavailable:
            return "FirebaseAuth is not available in this build. Make sure Firebase is added to the project."
        case .notSignedIn:
            return "You must be signed in to perform this action."
        }
    }
}

struct FirebaseAuthClient {
    private static func ensureFirebaseReady() {
        FirebaseBootstrap.configureIfNeeded()
    }

    static func signIn(email: String, password: String) async throws {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        ensureFirebaseReady()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
#else
        throw FirebaseAuthClientError.firebaseUnavailable
#endif
    }

    static func signUp(email: String, password: String) async throws {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        ensureFirebaseReady()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
#else
        throw FirebaseAuthClientError.firebaseUnavailable
#endif
    }

    static func sendPasswordReset(email: String) async throws {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        ensureFirebaseReady()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
#else
        throw FirebaseAuthClientError.firebaseUnavailable
#endif
    }

    static func sendEmailVerification() async throws {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        ensureFirebaseReady()
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthClientError.notSignedIn
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.sendEmailVerification { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
#else
        throw FirebaseAuthClientError.firebaseUnavailable
#endif
    }

    static func reloadCurrentUserEmailVerified() async throws -> Bool {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        ensureFirebaseReady()
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthClientError.notSignedIn
        }
        try await user.reload()
        return Auth.auth().currentUser?.isEmailVerified ?? false
#else
        throw FirebaseAuthClientError.firebaseUnavailable
#endif
    }
}

#Preview {
    AuthenticationScreen(
        isAuthenticated: .constant(false),
        themeColor: .customOrange,
        onContinue: {}
    )
}

