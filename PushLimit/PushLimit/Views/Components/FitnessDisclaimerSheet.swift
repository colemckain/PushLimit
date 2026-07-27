import SwiftUI

/// Shown before a user's first workout (or if they have not yet accepted the fitness disclaimer).
struct FitnessDisclaimerSheet: View {
    let themeColor: Color
    let onAccept: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("Health & safety", systemImage: "heart.text.square.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(themeColor)

                    Text(LegalCopy.fitnessDisclaimerSummary)
                        .font(.system(size: 15))
                        .foregroundColor(.customLabel)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("By continuing, you confirm you understand these risks and accept responsibility for your own health and safety during workouts.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onAccept) {
                        Text("I Understand — Start Workout")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color.customBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    FitnessDisclaimerSheet(themeColor: .orange, onAccept: {})
}
