import SwiftUI

struct ForgotPasswordScreen: View {
    @Environment(\.dismiss) private var dismiss

    let initialEmail: String
    let themeColor: Color

    @State private var email: String = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    init(initialEmail: String, themeColor: Color) {
        self.initialEmail = initialEmail
        self.themeColor = themeColor
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(themeColor)

                    Text("Reset your password")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.customLabel)

                    Text("Enter the email associated with your account. We'll send a reset link. If you don't see it, check your Spam/Junk folder.")
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 20)

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
                .padding(.horizontal, 20)

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

                if let successMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(themeColor)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.top, 2)
                            Text(successMessage)
                                .foregroundColor(.customLabel)
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Button {
                    Task { await sendResetEmail() }
                } label: {
                    Text(isBusy ? "Sending..." : "Send Reset Email")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(themeColor)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .disabled(isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Back to Sign In")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(.bottom, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeColor)
                    }
                }
            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }

    private func sendResetEmail() async {
        errorMessage = nil
        successMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let validationError = AuthValidation.validateEmail(trimmedEmail) {
            errorMessage = validationError
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            try await FirebaseAuthClient.sendPasswordReset(email: trimmedEmail)
            await MainActor.run {
                successMessage = "Check your email for the reset link. If you don't see it, check Spam/Junk (it can take a few minutes). Follow the instructions to set a new password."
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ForgotPasswordScreen(
        initialEmail: "",
        themeColor: .customOrange
    )
}

