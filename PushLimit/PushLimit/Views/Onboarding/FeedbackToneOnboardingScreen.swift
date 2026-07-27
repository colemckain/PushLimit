import SwiftUI

struct FeedbackToneOnboardingScreen: View {
    @Binding var selectedTone: FeedbackTone
    let themeColor: Color
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                VStack(spacing: 10) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(themeColor)

                    Text("How should we talk to you?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)

                    Text("This shapes reminders, completion messages, and coaching copy. Change it anytime in Profile.")
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    ForEach(FeedbackTone.allCases) { tone in
                        FeedbackToneOptionCard(
                            tone: tone,
                            isSelected: selectedTone == tone,
                            themeColor: themeColor
                        ) {
                            selectedTone = tone
                        }
                    }
                }
                .padding(.horizontal, 20)

                previewCard
                    .padding(.horizontal, 20)
            }
            .onboardingScrollBottomInset()
        }
        .background(Color.customBackground)
        .onboardingForwardAction(step: 5, action: onContinue)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
                .textCase(.uppercase)
                .tracking(0.4)

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedTone.previewNotificationTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.customLabel)
                Text(selectedTone.previewNotificationBody)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FeedbackToneOptionCard: View {
    let tone: FeedbackTone
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeColor.opacity(0.18) : Color.primary.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Image(systemName: tone.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? themeColor : .customSecondaryLabel)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(tone.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(tone.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? themeColor : .customSecondaryLabel.opacity(0.5))
            }
            .padding(16)
            .background(isSelected ? themeColor.opacity(0.08) : Color.customSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? themeColor.opacity(0.45) : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FeedbackToneOnboardingScreen(
        selectedTone: .constant(.supportive),
        themeColor: .orange,
        onContinue: {}
    )
}
