import SwiftUI

// MARK: - Guided scroll (onboarding)

enum OnboardingAutoScroll {
    static let scrollAnimation: Animation = .easeInOut(duration: 0.45)
}

extension View {
    /// Scrolls to `id` inside a `ScrollViewReader` proxy.
    func onboardingScrollTo(
        _ id: String,
        proxy: ScrollViewProxy,
        reduceMotion: Bool,
        anchor: UnitPoint = .top
    ) {
        if reduceMotion {
            proxy.scrollTo(id, anchor: anchor)
        } else {
            withAnimation(OnboardingAutoScroll.scrollAnimation) {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }
}

// MARK: - Active step (TabView keeps adjacent pages alive — only the visible step may own the bottom bar)

private struct OnboardingActiveStepKey: EnvironmentKey {
    static let defaultValue: Int = -1
}

extension EnvironmentValues {
    var onboardingActiveStep: Int {
        get { self[OnboardingActiveStepKey.self] }
        set { self[OnboardingActiveStepKey.self] = newValue }
    }
}

// MARK: - Shared Continue button

struct OnboardingContinueButton: View {
    let title: String
    let themeColor: Color
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isEnabled ? themeColor : themeColor.opacity(0.4))
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 20)
    }
}

// MARK: - Pinned bottom-bar forward control (mirrors back chevron on the left)

@MainActor
final class OnboardingNavigationBridge: ObservableObject {
    @Published private(set) var forwardEnabled = false
    /// When true, the container's Back button should call `performBack()` instead of leaving the step.
    @Published private(set) var consumesBack = false

    private var forwardHandler: (() -> Void)?
    private var backHandler: (() -> Void)?

    func setForward(enabled: Bool, action: @escaping () -> Void) {
        forwardEnabled = enabled
        forwardHandler = action
    }

    func setBackHandler(_ action: (() -> Void)?) {
        backHandler = action
        consumesBack = action != nil
    }

    func performForward() {
        forwardHandler?()
    }

    /// Returns true if the active step handled Back (stay on this onboarding step).
    @discardableResult
    func performBack() -> Bool {
        guard let backHandler else { return false }
        backHandler()
        return true
    }

    func clearBackHandler() {
        backHandler = nil
        consumesBack = false
    }
}

struct OnboardingBottomForwardButton: View {
    let enabled: Bool
    let themeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(enabled ? themeColor : themeColor.opacity(0.35))
                .frame(width: 44, height: 44)
                .background(themeColor.opacity(enabled ? 0.1 : 0.05))
                .clipShape(Circle())
        }
        .disabled(!enabled)
        .accessibilityLabel("Continue")
    }
}

private struct OnboardingForwardActionModifier: ViewModifier {
    @EnvironmentObject private var bridge: OnboardingNavigationBridge
    @Environment(\.onboardingActiveStep) private var activeStep
    let step: Int
    /// When true, `enabled` gates the bottom chevron (Terms & safety only).
    let gatesForward: Bool
    let enabled: Bool
    let action: () -> Void

    private func syncBridgeIfActive() {
        guard activeStep == step else { return }
        bridge.setForward(enabled: gatesForward ? enabled : true, action: action)
    }

    func body(content: Content) -> some View {
        content
            .onAppear { syncBridgeIfActive() }
            .onChange(of: activeStep) { _, _ in syncBridgeIfActive() }
            .onChange(of: enabled) { _, _ in syncBridgeIfActive() }
    }
}

extension View {
    /// Registers the pinned bottom-right continue action for a specific onboarding step.
    func onboardingForwardAction(
        step: Int,
        gatesForward: Bool = false,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            OnboardingForwardActionModifier(
                step: step,
                gatesForward: gatesForward,
                enabled: enabled,
                action: action
            )
        )
    }

    /// Extra scroll padding so content is not hidden behind the pinned bottom bar.
    func onboardingScrollBottomInset() -> some View {
        padding(.bottom, 20)
    }
}
