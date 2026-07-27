import SwiftUI

struct ProfileFolderRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel.opacity(0.85))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

/// In-scroll title aligned with profile detail content (matches card inset, not screen edge).
struct ProfileDetailHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.customLabel)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .padding(.bottom, 4)
    }
}

extension View {
    func profileDetailNavigation() -> some View {
        navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
}
