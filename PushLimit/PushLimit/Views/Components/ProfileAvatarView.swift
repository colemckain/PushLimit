import SwiftUI

struct ProfileAvatarView: View {
    let preset: ProfileAvatarPreset
    let userName: String
    let profileColor: Color
    var size: CGFloat = 100
    var showEditBadge: Bool = false
    var themeColor: Color = .customOrange

    private var innerSize: CGFloat { size * 0.88 }
    private var iconSize: CGFloat { size * 0.38 }
    private var initialFontSize: CGFloat { size * 0.38 }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [themeColor.opacity(0.55), themeColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(3, size * 0.035)
                    )
                    .frame(width: size, height: size)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [profileColor, profileColor.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: innerSize, height: innerSize)
                    .shadow(color: profileColor.opacity(0.35), radius: size * 0.1, x: 0, y: size * 0.05)

                avatarContent

                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: max(1.5, size * 0.018))
                    .frame(width: innerSize, height: innerSize)
            }

            if showEditBadge {
                ZStack {
                    Circle()
                        .fill(Color.customBackground)
                        .frame(width: size * 0.3, height: size * 0.3)
                    Circle()
                        .fill(themeColor)
                        .frame(width: size * 0.26, height: size * 0.26)
                    Image(systemName: "pencil")
                        .font(.system(size: size * 0.11, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: size * 0.04, y: size * 0.04)
            }
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if preset.usesFlameAsset {
            Image("flame")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize * 1.1, height: iconSize * 1.1)
        } else if let symbol = preset.symbolName {
            Image(systemName: symbol)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
        } else {
            Text(initialLetter)
                .font(.system(size: initialFontSize, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var initialLetter: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }
}

#Preview {
    HStack(spacing: 16) {
        ProfileAvatarView(preset: .initial, userName: "Cole", profileColor: .orange, showEditBadge: true)
        ProfileAvatarView(preset: .flame, userName: "Cole", profileColor: .orange)
        ProfileAvatarView(preset: .trophy, userName: "Cole", profileColor: .purple)
    }
    .padding()
}
