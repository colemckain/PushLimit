import SwiftUI

// MARK: - Spacing & layout (Apple-style rhythm)

enum AppSpacing {
    static let screenHorizontal: CGFloat = 16
    static let sectionGap: CGFloat = 18
    static let sectionHeaderGap: CGFloat = 8
    static let groupInner: CGFloat = 12
    static let rowVertical: CGFloat = 11
    static let groupRadius: CGFloat = 12
    static let iconBadgeSize: CGFloat = 36
    /// Leading inset for dividers aligned with text after an icon badge row.
    static var rowIconInset: CGFloat { groupInner + iconBadgeSize + 10 }
}

// MARK: - Typography (Home + shared screens)

enum AppTypography {
    static let screenTitle: CGFloat = 26
    static let sectionTitle: CGFloat = 17
    static let body: CGFloat = 17
    static let bodyMedium: CGFloat = 16
    static let caption: CGFloat = 14
    static let captionSmall: CGFloat = 13
    static let metric: CGFloat = 22
    static let metricLarge: CGFloat = 24
}

// MARK: - Icon badge (tinted circle + symbol)

struct AppIconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = AppSpacing.iconBadgeSize

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.30), color.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundColor(color)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Section header

struct AppSectionHeader: View {
    let title: String
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil
    let accentColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: AppTypography.sectionTitle, weight: .semibold))
                .foregroundColor(.customLabel)

            Spacer(minLength: 8)

            if let trailingTitle, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailingTitle)
                        .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Grouped inset container (Settings-style)

struct AppGroupedSurface: View {
    var cornerRadius: CGFloat = AppSpacing.groupRadius

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5)
            }
    }
}

struct AppGroupedSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background {
            AppGroupedSurface()
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }
}

struct AppGroupedDivider: View {
    var leadingInset: CGFloat = 16

    var body: some View {
        Divider()
            .padding(.leading, leadingInset)
            .opacity(0.35)
    }
}

// MARK: - Screen section (header + grouped card)

struct AppScreenSection<Content: View>: View {
    let title: String
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            AppSectionHeader(
                title: title,
                trailingTitle: trailingTitle,
                trailingAction: trailingAction,
                accentColor: accentColor
            )
            AppGroupedSection(content: content)
        }
    }
}

// MARK: - Profile / large inset section container

extension View {
    /// Outer profile-style section card (replaces solid grey + customShadow).
    func appSectionContainer(strokeColor: Color? = nil) -> some View {
        padding(AppSpacing.groupInner + 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { AppGroupedSurface() }
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
            .overlay {
                if let strokeColor {
                    RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous)
                        .strokeBorder(strokeColor, lineWidth: 1)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    /// Nested inset panel inside a section (e.g. sync status block).
    func appInsetPanel() -> some View {
        padding(AppSpacing.groupInner + 2)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
    }
}

// MARK: - Pressable button style

/// Shared press feedback for primary CTAs, cards, and nav items.
struct PressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97
    var pressedOpacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static var pressableSubtle: PressableButtonStyle {
        PressableButtonStyle(pressedScale: 0.985, pressedOpacity: 0.94)
    }
}

// MARK: - Appear stagger

extension View {
    /// Fade + rise entrance for stacked sections (Home / Workout).
    func appearStaggered(
        index: Int,
        revealed: Bool,
        reduceMotion: Bool
    ) -> some View {
        self
            .opacity(revealed || reduceMotion ? 1 : 0)
            .offset(y: revealed || reduceMotion ? 0 : 14)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(response: 0.48, dampingFraction: 0.86).delay(0.055 * Double(index)),
                value: revealed
            )
    }
}

// MARK: - Primary button

struct AppPrimaryButton: View {
    let title: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.pressable)
    }
}
