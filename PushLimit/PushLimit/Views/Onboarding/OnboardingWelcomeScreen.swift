import SwiftUI

struct OnboardingWelcomeScreen: View {
    let themeColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showGlow = false
    @State private var showFlame = false
    @State private var showHeadline = false
    @State private var showSubcopy = false
    @State private var showHighlights = false
    @State private var flamePulse = false

    private let highlights: [(icon: String, title: String, subtitle: String)] = [
        ("timer", "10–15 min", "Sessions that fit your day"),
        ("flame.fill", "Streaks & XP", "Level up as you show up"),
        ("calendar.badge.clock", "~1 minute", "To your first real plan")
    ]

    var body: some View {
        ZStack {
            welcomeBackground

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                heroSection
                    .padding(.bottom, 28)

                copySection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)

                highlightsSection
                    .padding(.horizontal, 20)

                Spacer(minLength: 16)
            }
        }
        .onAppear(perform: startReveal)
    }

    // MARK: - Background

    private var welcomeBackground: some View {
        ZStack {
            Color.customBackground
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeColor.opacity(0.22), themeColor.opacity(0.04), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 380, height: 380)
                .offset(y: -80)
                .scaleEffect(showGlow ? 1 : 0.7)
                .opacity(showGlow ? 1 : 0)

            Circle()
                .stroke(themeColor.opacity(0.12), lineWidth: 1)
                .frame(width: 260, height: 260)
                .offset(y: -60)
                .scaleEffect(showGlow ? 1 : 0.85)
                .opacity(showGlow ? 1 : 0)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(themeColor.opacity(0.14 - Double(ring) * 0.03), lineWidth: 2)
                    .frame(width: 120 + CGFloat(ring) * 34, height: 120 + CGFloat(ring) * 34)
                    .scaleEffect(showFlame ? 1 : 0.6)
                    .opacity(showFlame ? 1 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.72).delay(0.04 * Double(ring)),
                        value: showFlame
                    )
            }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeColor.opacity(0.28), themeColor.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 112, height: 112)
                    .shadow(color: themeColor.opacity(0.35), radius: 18, x: 0, y: 8)

                Image("flame")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .scaleEffect(flamePulse ? 1.04 : 0.96)
            }
            .scaleEffect(showFlame ? 1 : 0.4)
            .opacity(showFlame ? 1 : 0)
        }
        .frame(height: 200)
    }

    // MARK: - Copy

    private var copySection: some View {
        VStack(spacing: 14) {
            Text("Push your limits.")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.customLabel)
                .multilineTextAlignment(.center)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 14)

            Text("Short workouts built for real life — when you're busy, tired, or starting from zero.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showSubcopy ? 1 : 0)
                .offset(y: showSubcopy ? 0 : 10)

            Text("Let's build your first week.")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(themeColor.opacity(0.12))
                .clipShape(Capsule())
                .opacity(showSubcopy ? 1 : 0)
        }
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(highlights.enumerated()), id: \.offset) { index, item in
                OnboardingWelcomeHighlightRow(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                    themeColor: themeColor
                )
                .opacity(showHighlights ? 1 : 0)
                .offset(x: showHighlights ? 0 : -16)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82).delay(0.08 * Double(index)),
                    value: showHighlights
                )
            }
        }
    }

    // MARK: - Animation

    private func startReveal() {
        if reduceMotion {
            showGlow = true
            showFlame = true
            showHeadline = true
            showSubcopy = true
            showHighlights = true
            return
        }

        withAnimation(.easeOut(duration: 0.5)) { showGlow = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.08)) { showFlame = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.22)) { showHeadline = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.34)) { showSubcopy = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.46)) { showHighlights = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                flamePulse = true
            }
        }
    }
}

private struct OnboardingWelcomeHighlightRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let themeColor: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.customLabel)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(themeColor.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingWelcomeScreen(themeColor: .customOrange)
}
