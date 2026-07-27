import SwiftUI

struct LegalConsentOnboardingScreen: View {
    let themeColor: Color
    let onContinue: () -> Void

    @State private var acceptedTermsAndPrivacy = false
    @State private var acceptedFitnessDisclaimer = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    private var canContinue: Bool {
        acceptedTermsAndPrivacy && acceptedFitnessDisclaimer
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 12)

                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 52))
                        .foregroundColor(themeColor)

                    Text("Terms & safety")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)

                    Text("Please review and accept before we collect your profile information.")
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Health & fitness notice")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customLabel)

                    Text(LegalCopy.fitnessDisclaimerSummary)
                        .font(.system(size: 14))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 20)

                VStack(spacing: 14) {
                    LegalConsentCheckboxRow(
                        isOn: $acceptedTermsAndPrivacy,
                        themeColor: themeColor
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I agree to the Terms of Service and Privacy Policy.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.customLabel)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 12) {
                                Button("Terms of Service") { showTerms = true }
                                Button("Privacy Policy") { showPrivacy = true }
                            }
                            .font(.system(size: 14, weight: .semibold))
                        }
                    }

                    LegalConsentCheckboxRow(
                        isOn: $acceptedFitnessDisclaimer,
                        themeColor: themeColor
                    ) {
                        Text("I understand PushLimit is not medical advice, I should consult a physician before exercising, and I will stop if I feel pain or discomfort.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 20)
                .onboardingScrollBottomInset()
            }
        }
        .background(Color.customBackground)
        .onboardingForwardAction(step: 1, gatesForward: true, enabled: canContinue) {
            LegalConsentStore.recordFullOnboardingConsent()
            onContinue()
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsOfServiceScreen()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTerms = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                PrivacyPolicyScreen()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showPrivacy = false }
                        }
                    }
            }
        }
    }
}

private struct LegalConsentCheckboxRow<Label: View>: View {
    @Binding var isOn: Bool
    let themeColor: Color
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(isOn ? themeColor : .customSecondaryLabel)

                label()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LegalConsentOnboardingScreen(themeColor: .orange, onContinue: {})
        .environmentObject(OnboardingNavigationBridge())
}
