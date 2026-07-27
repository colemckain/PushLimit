import SwiftUI

struct LevelUpAchievementView: View {
    let newLevel: Int
    let newTitle: String
    let oldLevel: Int
    let oldTitle: String
    let themeColor: Color
    let onDismiss: () -> Void
    
    private let quote: String
    
    @State private var backdropOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.72
    @State private var cardOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.6
    @State private var showHeadline = false
    @State private var showLevelTransition = false
    @State private var showTitleBadge = false
    @State private var showQuote = false
    @State private var showUnlock = false
    @State private var showButton = false
    @State private var heroPulse: CGFloat = 1
    @State private var confettiActive = false
    @State private var successHaptic = false
    
    init(
        newLevel: Int,
        newTitle: String,
        oldLevel: Int,
        oldTitle: String,
        themeColor: Color,
        onDismiss: @escaping () -> Void
    ) {
        self.newLevel = newLevel
        self.newTitle = newTitle
        self.oldLevel = oldLevel
        self.oldTitle = oldTitle
        self.themeColor = themeColor
        self.onDismiss = onDismiss
        self.quote = LevelUpCelebrationCopy.motivationalQuote(forLevel: newLevel)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .opacity(backdropOpacity)
                .onTapGesture { dismissWithAnimation() }
            
            RadialGradient(
                colors: [
                    themeColor.opacity(0.45),
                    themeColor.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .scaleEffect(glowScale)
            .opacity(backdropOpacity * 0.9)
            .allowsHitTesting(false)
            
            if confettiActive {
                LevelUpConfettiView(themeColor: themeColor)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            celebrationCard
                .padding(.horizontal, 28)
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
        }
        .sensoryFeedback(.success, trigger: successHaptic)
        .onAppear {
            startCelebrationSequence()
        }
    }
    
    private var celebrationCard: some View {
        VStack(spacing: 20) {
            heroBadge
            
            if showHeadline {
                headlineRow
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
            
            if showLevelTransition {
                levelTransitionRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showTitleBadge {
                titleBadge
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            
            if showQuote {
                quoteBlock
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
            
            if showUnlock, newLevel == 3 {
                levelThreeUnlockCard
                    .transition(.opacity.combined(with: .offset(y: 6)))
            }
            
            if showButton {
                keepPushingButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            themeColor.opacity(0.55),
                            themeColor.opacity(0.15),
                            Color.white.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: themeColor.opacity(0.35), radius: 28, x: 0, y: 12)
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.customSecondaryBackground,
                        Color.customSecondaryBackground.opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    private var heroBadge: some View {
        ZStack {
            Circle()
                .fill(themeColor.opacity(0.2))
                .frame(width: 118, height: 118)
                .scaleEffect(heroPulse)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [themeColor, themeColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 92)
                .shadow(color: themeColor.opacity(0.5), radius: 16, x: 0, y: 6)
            
            Image(systemName: "star.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.bounce, value: showHeadline)
        }
    }
    
    private var headlineRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeColor)
            Text("LEVEL UP!")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeColor, themeColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeColor)
        }
    }
    
    private var levelTransitionRow: some View {
        HStack(spacing: 14) {
            levelChip(level: oldLevel, label: oldTitle, subdued: true)
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeColor, themeColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            levelChip(level: newLevel, label: newTitle, subdued: false)
        }
    }
    
    private func levelChip(level: Int, label: String, subdued: Bool) -> some View {
        VStack(spacing: 4) {
            Text("Lv. \(level)")
                .font(.system(size: subdued ? 18 : 26, weight: .bold, design: .rounded))
                .foregroundColor(subdued ? .customSecondaryLabel : themeColor)
            Text(label)
                .font(.system(size: subdued ? 11 : 13, weight: .semibold))
                .foregroundColor(subdued ? .customSecondaryLabel : .customLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: 72)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(subdued ? Color.customBackground.opacity(0.5) : themeColor.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(subdued ? Color.gray.opacity(0.15) : themeColor.opacity(0.35), lineWidth: 1)
        )
    }
    
    private var titleBadge: some View {
        Text(newTitle.uppercased())
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .tracking(3)
            .foregroundColor(.customSecondaryLabel)
    }
    
    private var quoteBlock: some View {
        Text("\"\(quote)\"")
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .italic()
            .foregroundColor(.customLabel)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 8)
    }
    
    private var levelThreeUnlockCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColor)
                Text(LevelUpCelebrationCopy.levelThreeUnlockHeadline)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(themeColor)
            }
            Text(LevelUpCelebrationCopy.levelThreeUnlockDetail)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(themeColor.opacity(0.28), lineWidth: 1)
        )
    }
    
    private var keepPushingButton: some View {
        Button(action: dismissWithAnimation) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Keep pushing")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [themeColor, themeColor.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .shadow(color: themeColor.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func startCelebrationSequence() {
        confettiActive = true
        
        withAnimation(.easeOut(duration: 0.25)) {
            backdropOpacity = 1
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            cardScale = 1
            cardOpacity = 1
            glowScale = 1
        }
        
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            heroPulse = 1.12
        }
        
        revealStep(delay: 0.15) { showHeadline = true }
        revealStep(delay: 0.32) {
            showLevelTransition = true
            successHaptic.toggle()
        }
        revealStep(delay: 0.48) { showTitleBadge = true }
        revealStep(delay: 0.58) { showQuote = true }
        if newLevel == 3 {
            revealStep(delay: 0.72) { showUnlock = true }
            revealStep(delay: 0.86) { showButton = true }
        } else {
            revealStep(delay: 0.72) { showButton = true }
        }
    }
    
    private func revealStep(delay: TimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                action()
            }
        }
    }
    
    private func dismissWithAnimation() {
        confettiActive = false
        withAnimation(.easeIn(duration: 0.22)) {
            backdropOpacity = 0
            cardScale = 0.88
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}

// MARK: - Confetti

private struct LevelUpConfettiView: View {
    let themeColor: Color
    
    private let pieceCount = 48
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<pieceCount {
                    drawPiece(index: index, time: t, in: &context, size: size)
                }
            }
        }
    }
    
    private func drawPiece(index: Int, time: TimeInterval, in context: inout GraphicsContext, size: CGSize) {
        let seed = Double(index) * 1.618
        let xNorm = (sin(seed * 3.1) + 1) / 2
        let startY = -20 - (seed * 40).truncatingRemainder(dividingBy: 120)
        let speed = 90 + (seed * 70).truncatingRemainder(dividingBy: 80)
        let sway = sin(time * 2.2 + seed) * 28
        let x = xNorm * size.width + sway
        let y = (startY + time * speed).truncatingRemainder(dividingBy: size.height + 160) - 40
        
        let colors: [Color] = [
            themeColor,
            themeColor.opacity(0.85),
            .yellow,
            .white,
            Color.green.opacity(0.9),
            Color.orange.opacity(0.9)
        ]
        let color = colors[index % colors.count]
        
        var piece = context
        piece.translateBy(x: x, y: y)
        piece.rotate(by: .degrees(time * 120 + seed * 40))
        
        let w = CGFloat(5 + (index % 4))
        let h = CGFloat(8 + (index % 5))
        let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
        piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color))
    }
}

// MARK: - Button style (alias of shared pressable)

typealias ScaleButtonStyle = PressableButtonStyle

#Preview {
    LevelUpAchievementView(
        newLevel: 3,
        newTitle: "Beast",
        oldLevel: 2,
        oldTitle: "Warrior",
        themeColor: .customOrange,
        onDismiss: {}
    )
}
