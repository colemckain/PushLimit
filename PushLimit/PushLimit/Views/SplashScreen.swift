import SwiftUI

// MARK: - Theme helper

private enum SplashTheme {
    static let colorKey = "themeColor"

    static var accent: Color {
        if let data = UserDefaults.standard.data(forKey: colorKey),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(uiColor: uiColor)
        }
        return .customOrange
    }
}

// MARK: - Ambient background

private struct SplashAmbientBackground: View {
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulse: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color.customBackground

                LinearGradient(
                    colors: [
                        accent.opacity(colorScheme == .dark ? 0.10 : 0.07),
                        Color.customBackground.opacity(0),
                        accent.opacity(colorScheme == .dark ? 0.06 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                radialGlow(
                    accent: accent,
                    size: max(w, h) * 0.92,
                    opacity: colorScheme == .dark ? 0.24 : 0.16
                )
                .position(x: w * 0.40, y: h * 0.28)
                .scaleEffect(glowScale(primary: true))
                .opacity(glowOpacity(base: colorScheme == .dark ? 0.88 : 1.0))

                radialGlow(
                    accent: accent,
                    size: max(w, h) * 0.62,
                    opacity: colorScheme == .dark ? 0.14 : 0.09
                )
                .position(x: w * 0.82, y: h * 0.68)
                .scaleEffect(glowScale(primary: false))
                .opacity(glowOpacity(base: colorScheme == .dark ? 0.72 : 0.92))

                radialGlow(
                    accent: accent,
                    size: min(w, h) * 0.55,
                    opacity: colorScheme == .dark ? 0.18 : 0.11
                )
                .position(x: w * 0.5, y: h * 0.42)
                .blur(radius: 8)

                LinearGradient(
                    colors: [
                        Color.customBackground.opacity(0),
                        Color.customBackground.opacity(colorScheme == .dark ? 0.50 : 0.30)
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0.35),
                    endPoint: .bottom
                )
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            pulse = 0
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }

    private func radialGlow(accent: Color, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        accent.opacity(opacity),
                        accent.opacity(opacity * 0.35),
                        accent.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.5
                )
            )
            .frame(width: size, height: size)
            .blur(radius: size * 0.07)
    }

    private func glowScale(primary: Bool) -> CGFloat {
        if reduceMotion { return primary ? 1.0 : 0.98 }
        let base: CGFloat = primary ? 0.95 : 1.0
        let amplitude: CGFloat = primary ? 0.08 : 0.06
        let phase = primary ? pulse : (1 - pulse)
        return base + amplitude * phase
    }

    private func glowOpacity(base: Double) -> Double {
        if reduceMotion { return base }
        return base * (0.90 + 0.18 * Double(pulse))
    }
}

// MARK: - Expanding pulse rings

private struct SplashPulseRings: View {
    let accent: Color
    let phase: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let offset = CGFloat(index) / 3.0
                let ringPhase = (phase + offset).truncatingRemainder(dividingBy: 1)
                Circle()
                    .stroke(accent.opacity(Double(1 - ringPhase) * 0.35), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(0.85 + ringPhase * 0.55)
                    .opacity(Double(1 - ringPhase))
            }
        }
    }
}

// MARK: - Floating embers

private struct SplashEmbers: View {
    let accent: Color
    let phase: CGFloat

    private struct Ember {
        let x: CGFloat
        let delay: CGFloat
        let size: CGFloat
    }

    private let embers: [Ember] = [
        Ember(x: -18, delay: 0.0, size: 5),
        Ember(x: -6, delay: 0.18, size: 4),
        Ember(x: 8, delay: 0.08, size: 6),
        Ember(x: 20, delay: 0.28, size: 4),
        Ember(x: -12, delay: 0.38, size: 3),
        Ember(x: 14, delay: 0.48, size: 5)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(embers.enumerated()), id: \.offset) { _, ember in
                let local = (phase + ember.delay).truncatingRemainder(dividingBy: 1)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent, accent.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: ember.size
                        )
                    )
                    .frame(width: ember.size, height: ember.size)
                    .blur(radius: 0.5)
                    .offset(x: ember.x, y: 28 - local * 52)
                    .opacity(Double(1 - local) * 0.85)
                    .scaleEffect(0.6 + (1 - local) * 0.5)
            }
        }
    }
}

// MARK: - Logo hero

private struct SplashLogoHero: View {
    let accent: Color
    let scale: CGFloat
    let floatOffset: CGFloat
    let ringScale: CGFloat
    let pulseScale: CGFloat
    let pulsePhase: CGFloat
    let showBurst: Bool

    var body: some View {
        ZStack {
            SplashPulseRings(accent: accent, phase: pulsePhase)

            Circle()
                .stroke(accent.opacity(0.14), lineWidth: 1)
                .frame(width: 148, height: 148)
                .scaleEffect(ringScale)

            Circle()
                .stroke(accent.opacity(0.08), lineWidth: 1)
                .frame(width: 172, height: 172)
                .scaleEffect(ringScale * 0.98)

            if showBurst {
                Circle()
                    .stroke(accent.opacity(0.5), lineWidth: 3)
                    .frame(width: 130, height: 130)
                    .scaleEffect(1.25)
                    .opacity(0)
                    .modifier(BurstRingModifier())
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.22), accent.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 112, height: 112)
                .blur(radius: 1)
                .overlay {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    Circle()
                        .strokeBorder(accent.opacity(0.22), lineWidth: 0.75)
                }
                .shadow(color: accent.opacity(0.28), radius: 22, y: 12)

            ZStack {
                SplashEmbers(accent: accent, phase: pulsePhase)
                Image("flame")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 58, height: 58)
                    .shadow(color: accent.opacity(0.35), radius: 8, y: 4)
            }
        }
        .scaleEffect(scale * pulseScale)
        .offset(y: floatOffset)
    }
}

private struct BurstRingModifier: ViewModifier {
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.55 : 1.0)
            .opacity(animate ? 0 : 0.7)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    animate = true
                }
            }
    }
}

// MARK: - Rep rhythm indicator

private struct SplashRepRhythm: View {
    let accent: Color
    let activeIndex: Int
    let repCount: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index <= activeIndex ? accent : Color.primary.opacity(0.10))
                        .frame(width: index == activeIndex ? 10 : 7, height: index == activeIndex ? 10 : 7)
                        .shadow(color: index == activeIndex ? accent.opacity(0.45) : .clear, radius: 6)
                        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: activeIndex)
                }
            }

            HStack(spacing: 4) {
                Text("REP")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.customSecondaryLabel)
                    .tracking(1.2)
                Text("\(repCount)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(accent)
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(accent.opacity(0.12), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Status ticker

private struct SplashStatusTicker: View {
    let accent: Color
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.customSecondaryLabel)
            .multilineTextAlignment(.center)
            .id(message)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 8)),
                removal: .opacity.combined(with: .offset(y: -8))
            ))
            .animation(.easeInOut(duration: 0.35), value: message)
    }
}

// MARK: - Splash

struct SplashScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var footerOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.88
    @State private var ringScale: CGFloat = 0.94
    @State private var floatPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var activeRepIndex: Int = -1
    @State private var repCount: Int = 0
    @State private var statusMessage: String = "Warming up"
    @State private var showBurst = false

    var onLoadingComplete: () -> Void

    private let minimumDisplayDuration: Double = 5.0

    private var accent: Color { SplashTheme.accent }

    private let statusMessages = [
        "Warming up",
        "Finding your fire",
        "Building momentum",
        "Ready to push"
    ]

    var body: some View {
        ZStack {
            SplashAmbientBackground(accent: accent)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 22) {
                    SplashLogoHero(
                        accent: accent,
                        scale: logoScale,
                        floatOffset: floatOffset,
                        ringScale: ringScale,
                        pulseScale: pulseScale,
                        pulsePhase: pulsePhase,
                        showBurst: showBurst
                    )
                    .opacity(logoOpacity)

                    VStack(spacing: 6) {
                        Text("PushLimit")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, accent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("limits exist — rise above")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                            .tracking(0.3)
                    }
                    .opacity(titleOpacity)
                }

                Spacer(minLength: 0)

                VStack(spacing: 16) {
                    SplashRepRhythm(
                        accent: accent,
                        activeIndex: activeRepIndex,
                        repCount: repCount
                    )

                    SplashStatusTicker(accent: accent, message: statusMessage)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(footerOpacity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var floatOffset: CGFloat {
        guard !reduceMotion else { return 0 }
        return -3 + 6 * floatPhase
    }

    private func startAnimations() {
        let entranceDelay: Double = reduceMotion ? 0 : 0.06
        let loadDuration = minimumDisplayDuration

        if reduceMotion {
            logoScale = 1.0
            ringScale = 1.0
            logoOpacity = 1
            titleOpacity = 1
            footerOpacity = 1
            activeRepIndex = 4
            repCount = 5
            statusMessage = statusMessages.last ?? "Ready to push"
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + entranceDelay) {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.78)) {
                    logoScale = 1.0
                    ringScale = 1.0
                    logoOpacity = 1
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + entranceDelay + 0.12) {
                withAnimation(.easeOut(duration: 0.45)) {
                    titleOpacity = 1
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + entranceDelay + 0.22) {
                withAnimation(.easeOut(duration: 0.4)) {
                    footerOpacity = 1
                }
            }

            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                floatPhase = 1
            }

            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                pulsePhase = 1
            }

            startRepRhythm(totalDuration: loadDuration, startDelay: entranceDelay + 0.35)
            startStatusRotation(startDelay: entranceDelay + 0.35, interval: loadDuration / Double(statusMessages.count))
            startHeartbeat(startDelay: entranceDelay + 0.35, duration: loadDuration)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + entranceDelay + (reduceMotion ? 0.1 : 0.28) + loadDuration - 0.35) {
            if !reduceMotion {
                showBurst = true
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    pulseScale = 1.08
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        pulseScale = 1.0
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + entranceDelay + (reduceMotion ? 0.1 : 0.28) + loadDuration) {
            onLoadingComplete()
        }
    }

    private func startRepRhythm(totalDuration: Double, startDelay: Double) {
        let repInterval = totalDuration / 5.0
        for index in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + repInterval * Double(index)) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
                    activeRepIndex = index
                    repCount = index + 1
                }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
                    pulseScale = 1.04
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        pulseScale = 1.0
                    }
                }
            }
        }
    }

    private func startStatusRotation(startDelay: Double, interval: Double) {
        for (index, message) in statusMessages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + interval * Double(index)) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    statusMessage = message
                }
            }
        }
    }

    private func startHeartbeat(startDelay: Double, duration: Double) {
        guard !reduceMotion else { return }
        let beatInterval = 0.55
        let beatCount = Int(duration / beatInterval)
        for i in 0..<beatCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + beatInterval * Double(i)) {
                withAnimation(.easeOut(duration: 0.18)) {
                    pulseScale = 1.03
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.easeIn(duration: 0.22)) {
                        pulseScale = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen(onLoadingComplete: {})
}
