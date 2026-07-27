import SwiftUI

struct LegRunLocationConsentOnboardingScreen: View {
    let themeColor: Color
    let onContinue: () -> Void

    @State private var acceptedLocationDisclosure = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                VStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(themeColor)

                    Text("Leg runs & location")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)

                    Text("On leg days you can swap squats for an outdoor run. If you choose run, we use GPS to track your workout.")
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Location use")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customLabel)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeColor)
                            .padding(.top, 2)

                        Text(LegWorkoutSupport.locationDisclosureMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("Location is only used during an active leg run. Tracking continues if you lock the phone or switch apps; it stops when you pause or finish. You can skip runs and still complete leg day with squats and wall sits.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)

                LegRunLocationConsentCheckboxRow(
                    isOn: $acceptedLocationDisclosure,
                    themeColor: themeColor
                ) {
                    Text(LegWorkoutSupport.locationConsentCheckboxMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.customLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .onboardingScrollBottomInset()
            }
        }
        .background(Color.customBackground)
        .onboardingForwardAction(step: 6, gatesForward: true, enabled: acceptedLocationDisclosure) {
            LegalConsentStore.recordLegRunLocationDisclosureAcceptance()
            onContinue()
        }
    }
}

struct LegRunLocationConsentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let themeColor: Color
    let onAccepted: () -> Void

    @State private var acceptedLocationDisclosure = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(themeColor)

                        Text("Location for leg runs")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)

                        Text(LegWorkoutSupport.locationDisclosureMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    LegRunLocationConsentCheckboxRow(
                        isOn: $acceptedLocationDisclosure,
                        themeColor: themeColor
                    ) {
                        Text(LegWorkoutSupport.locationConsentCheckboxMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Leg run location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.customSecondaryLabel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Accept") {
                        LegalConsentStore.recordLegRunLocationDisclosureAcceptance()
                        dismiss()
                        onAccepted()
                    }
                    .foregroundColor(themeColor)
                    .disabled(!acceptedLocationDisclosure)
                }
            }
        }
    }
}

private struct LegRunLocationConsentCheckboxRow<Label: View>: View {
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
    LegRunLocationConsentOnboardingScreen(themeColor: .orange, onContinue: {})
        .environmentObject(OnboardingNavigationBridge())
}
