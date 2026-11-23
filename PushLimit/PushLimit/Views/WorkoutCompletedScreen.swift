import SwiftUI

struct WorkoutCompletedScreen: View {
    let exercise: Exercise
    let totalReps: Int
    let timeSpent: Int
    let xpEarned: Int
    let wallSitTime: Int?
    let runDistanceMeters: Double?
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Binding var selectedTab: Int
    let onWorkoutCompleted: () -> Void
    let themeColor: Color
    /// True when the session ended early (progress saved, not a full sitting).
    let wasEarlyEnd: Bool

    private let headline: String
    private let quote: String

    @State private var showHero = false
    @State private var showQuote = false
    @State private var showStats = false
    @State private var showExtras = false
    @State private var showActions = false
    @State private var displayedXP = 0
    @State private var completionHapticTick = 0

    init(
        exercise: Exercise,
        totalReps: Int,
        timeSpent: Int,
        xpEarned: Int,
        wallSitTime: Int?,
        runDistanceMeters: Double? = nil,
        workoutViewModel: WorkoutViewModel,
        selectedTab: Binding<Int>,
        onWorkoutCompleted: @escaping () -> Void,
        themeColor: Color,
        wasEarlyEnd: Bool = false
    ) {
        self.exercise = exercise
        self.totalReps = totalReps
        self.timeSpent = timeSpent
        self.xpEarned = xpEarned
        self.wallSitTime = wallSitTime
        self.runDistanceMeters = runDistanceMeters
        self._workoutViewModel = ObservedObject(wrappedValue: workoutViewModel)
        self._selectedTab = selectedTab
        self.onWorkoutCompleted = onWorkoutCompleted
        self.themeColor = themeColor
        self.wasEarlyEnd = wasEarlyEnd
        self.headline = PushLimitVoiceCopy.workoutCompletionHeadline()
        self.quote = PushLimitVoiceCopy.workoutCompletionQuote()
    }

    private var isLegWorkout: Bool {
        exercise.id.lowercased().contains("squat") || exercise.id.lowercased().contains("leg")
    }

    private var isRunWorkout: Bool {
        exercise.id.lowercased() == LegWorkoutSupport.runExerciseId
    }

    var body: some View {
        GeometryReader { geo in
            ViewThatFits(in: .vertical) {
                lockedContent(.regular)
                lockedContent(.compact)
                lockedContent(.tight)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background {
            ZStack {
                Color.customBackground
                RadialGradient(
                    colors: [themeColor.opacity(0.14), Color.clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 340
                )
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: completionHapticTick)
        .onAppear { startRevealSequence() }
    }

    /// Fixed summary. `ViewThatFits` picks the largest spacing that stays inside the sheet,
    /// so the screen never scrolls.
    private func lockedContent(_ metrics: CompletionMetrics) -> some View {
        VStack(spacing: 0) {
            heroSection(metrics)
            flexibleGap(metrics)
            statsPreviewCard(metrics)
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 8)
                .accessibilityHidden(!showStats)
            flexibleGap(metrics)
            extrasSection(metrics)
                .opacity(showExtras ? 1 : 0)
                .offset(y: showExtras ? 0 : 8)
                .accessibilityHidden(!showExtras)
            flexibleGap(metrics)
            actionButtons(metrics)
                .opacity(showActions ? 1 : 0)
                .offset(y: showActions ? 0 : 6)
                .allowsHitTesting(showActions)
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, metrics.topPadding)
        .padding(.bottom, metrics.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Grows a little on taller phones, but never enough to push the buttons off screen.
    private func flexibleGap(_ metrics: CompletionMetrics) -> some View {
        Spacer(minLength: metrics.sectionGap)
            .frame(maxHeight: metrics.maxSectionGap)
    }

    // MARK: - Hero

    private func heroSection(_ metrics: CompletionMetrics) -> some View {
        VStack(spacing: metrics.heroSpacing) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.12))
                    .frame(width: metrics.heroOuter, height: metrics.heroOuter)
                    .scaleEffect(showHero ? 1 : 0.6)
                    .opacity(showHero ? 1 : 0)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeColor, themeColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: metrics.heroInner, height: metrics.heroInner)
                    .shadow(color: themeColor.opacity(0.35), radius: metrics.isCompact ? 8 : 12, x: 0, y: 6)
                    .scaleEffect(showHero ? 1 : 0.5)
                    .opacity(showHero ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: metrics.checkSize, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showHero ? 1 : 0.3)
                    .opacity(showHero ? 1 : 0)
            }

            VStack(spacing: metrics.titleSpacing) {
                Text(headline)
                    .font(.system(size: metrics.headlineSize, weight: .bold))
                    .foregroundColor(.customLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(exercise.name)
                    .font(.system(size: metrics.exerciseSize, weight: .semibold))
                    .foregroundColor(themeColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .opacity(showHero ? 1 : 0)
            .offset(y: showHero ? 0 : 8)

            Text(quote)
                .font(.system(size: metrics.quoteSize, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.center)
                .lineSpacing(metrics.isCompact ? 1 : 2)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 4)
                .opacity(showQuote ? 1 : 0)
                .offset(y: showQuote ? 0 : 6)
        }
    }

    // MARK: - Stats

    private func statsPreviewCard(_ metrics: CompletionMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.cardSpacing) {
            Text("Today's session")
                .font(.system(size: metrics.headerSize, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
                .textCase(.uppercase)
                .tracking(0.5)

            statGrid(sessionStats, metrics: metrics)
        }
        .padding(metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppGroupedSurface() }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }

    private func statGrid(_ stats: [CompletionStat], metrics: CompletionMetrics) -> some View {
        let rowIndexes = Array(stride(from: 0, to: stats.count, by: 2))
        return VStack(spacing: metrics.gridSpacing) {
            ForEach(rowIndexes, id: \.self) { start in
                HStack(spacing: metrics.gridSpacing) {
                    completionStatTile(stats[start], metrics: metrics)
                    if start + 1 < stats.count {
                        completionStatTile(stats[start + 1], metrics: metrics)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var sessionStats: [CompletionStat] {
        let streak = CompletionStat(
            icon: "flame.fill",
            label: "Streak",
            value: "\(workoutViewModel.getCurrentStreak())d"
        )
        let xp = CompletionStat(
            icon: "star.fill",
            label: "XP earned",
            value: "+\(displayedXP)",
            accent: true
        )
        let time = CompletionStat(icon: "clock.fill", label: "Time", value: formatTime(timeSpent))

        if isRunWorkout, let runDistanceMeters {
            return [
                CompletionStat(
                    icon: "location.fill",
                    label: "Distance",
                    value: LegWorkoutSupport.formatDistance(runDistanceMeters)
                ),
                time,
                CompletionStat(
                    icon: "speedometer",
                    label: "Pace",
                    value: LegWorkoutSupport.formatPace(
                        distanceMeters: runDistanceMeters,
                        elapsedSeconds: timeSpent
                    )
                ),
                xp,
                streak,
                CompletionStat(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Level",
                    value: "Lv. \(workoutViewModel.levelInfo.level)"
                )
            ]
        }

        if isLegWorkout, let wallSitTime {
            return [
                CompletionStat(
                    icon: "figure.strengthtraining.traditional",
                    label: "Squats",
                    value: "\(totalReps)"
                ),
                CompletionStat(icon: "timer", label: "Wall sits", value: formatWallSitTime(wallSitTime)),
                time,
                xp,
                streak,
                CompletionStat(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Level",
                    value: "Lv. \(workoutViewModel.levelInfo.level)"
                )
            ]
        }

        return [
            CompletionStat(icon: "repeat", label: "Total reps", value: "\(totalReps)"),
            time,
            xp,
            streak
        ]
    }

    private func completionStatTile(_ stat: CompletionStat, metrics: CompletionMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.tileSpacing) {
            HStack(spacing: 4) {
                Image(systemName: stat.icon)
                    .font(.system(size: metrics.statLabelSize, weight: .semibold))
                    .foregroundColor(stat.accent ? themeColor : .customSecondaryLabel)
                Text(stat.label)
                    .font(.system(size: metrics.statLabelSize, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
            }
            Text(stat.value)
                .font(.system(size: metrics.statValueSize, weight: .bold, design: .rounded))
                .foregroundColor(stat.accent ? themeColor : .customLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, metrics.tileHorizontalPadding)
        .padding(.vertical, metrics.tileVerticalPadding)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Extras

    private func extrasSection(_ metrics: CompletionMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.extrasSpacing) {
            if let goal = weeklyGoalForExercise {
                weeklyGoalPreview(goal: goal, metrics: metrics)
            }
            levelProgressPreview(metrics)
        }
        .padding(metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppGroupedSurface() }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }

    private func weeklyGoalPreview(goal: GoalProgress, metrics: CompletionMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.barSpacing) {
            HStack(spacing: 8) {
                Text("This week · \(goal.workoutType)")
                    .font(.system(size: metrics.bodySize, weight: .semibold))
                    .foregroundColor(.customLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.system(size: metrics.bodySize, weight: .bold))
                    .foregroundColor(goal.isGoalAchieved ? .green : themeColor)
            }

            progressBar(fraction: min(1, goal.progressPercentage), achieved: goal.isGoalAchieved, metrics: metrics)

            Text(weeklyGoalCaption(goal))
                .font(.system(size: metrics.captionSize, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private func levelProgressPreview(_ metrics: CompletionMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.barSpacing) {
            HStack(spacing: 8) {
                Text(workoutViewModel.levelInfo.title)
                    .font(.system(size: metrics.bodySize, weight: .semibold))
                    .foregroundColor(.customLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 8)
                Text("\(workoutViewModel.levelInfo.xpInCurrentLevel) / \(workoutViewModel.levelInfo.xpToNextLevel) XP")
                    .font(.system(size: metrics.captionSize, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            progressBar(fraction: workoutViewModel.levelInfo.progress, achieved: false, metrics: metrics)
        }
    }

    private func progressBar(fraction: Double, achieved: Bool, metrics: CompletionMetrics) -> some View {
        GeometryReader { geo in
            let width = max(8, geo.size.width * CGFloat(min(1, max(0, fraction))))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.customLabel.opacity(0.08))
                Capsule()
                    .fill(barFill(achieved: achieved))
                    .frame(width: width)
            }
        }
        .frame(height: metrics.barHeight)
    }

    private func barFill(achieved: Bool) -> LinearGradient {
        if achieved {
            return LinearGradient(colors: [.green, .green], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(
            colors: [themeColor, themeColor.opacity(0.65)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Actions

    private func actionButtons(_ metrics: CompletionMetrics) -> some View {
        VStack(spacing: metrics.buttonSpacing) {
            Button(action: dismissToWorkout) {
                Text("Done")
                    .font(.system(size: metrics.doneFontSize, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, metrics.doneVerticalPadding)
                    .background(themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.pressable)

            Button(action: dismissToProgress) {
                Text("View progress")
                    .font(.system(size: metrics.secondaryFontSize, weight: .semibold))
                    .foregroundColor(themeColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, metrics.secondaryVerticalPadding)
            }
            .buttonStyle(.pressableSubtle)
        }
    }

    // MARK: - Helpers

    private var weeklyGoalForExercise: GoalProgress? {
        let goals = workoutViewModel.getAlgorithmGoalProgress()
        let id = exercise.id.lowercased()
        if id.contains("push") { return goals.first { $0.workoutType == "Push-ups" } }
        if CoreWorkoutSupport.isCoreMoveId(id) || id.contains("sit") || id.contains("core") {
            return goals.first { $0.workoutType == CoreWorkoutSupport.goalDisplayName }
        }
        if id.contains("squat") || id.contains("leg") { return goals.first { $0.workoutType == "Squats" } }
        return nil
    }

    private func weeklyGoalCaption(_ goal: GoalProgress) -> String {
        PushLimitVoiceCopy.weeklyGoalCaption(
            goalAchieved: goal.isGoalAchieved,
            remaining: goal.remaining
        )
    }

    private func startRevealSequence() {
        // Full-session celebration haptic; early-end warning already fired from the session screen.
        if !wasEarlyEnd {
            completionHapticTick &+= 1
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            showHero = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.45)) { showQuote = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.45)) { showStats = true }
            animateXPCounter()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeOut(duration: 0.4)) { showExtras = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.easeOut(duration: 0.4)) { showActions = true }
        }
    }

    private func animateXPCounter() {
        guard xpEarned > 0 else {
            displayedXP = 0
            return
        }
        let steps = min(xpEarned, 12)
        let increment = max(1, xpEarned / steps)
        var current = 0
        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.05) {
                current = min(xpEarned, current + increment)
                displayedXP = step == steps - 1 ? xpEarned : current
            }
        }
    }

    private func dismissToWorkout() {
        onWorkoutCompleted()
        selectedTab = 1
    }

    private func dismissToProgress() {
        onWorkoutCompleted()
        selectedTab = 2
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatWallSitTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 { return "\(mins)m" }
        return "\(mins)m \(secs)s"
    }
}

private struct CompletionStat: Identifiable {
    let icon: String
    let label: String
    let value: String
    var accent: Bool = false

    var id: String { label }
}

/// Spacing and type for the locked completion sheet.
/// Regular is used when it fits; compact and tight are the shorter-phone fallbacks.
private struct CompletionMetrics {
    let isCompact: Bool
    let heroOuter: CGFloat
    let heroInner: CGFloat
    let checkSize: CGFloat
    let headlineSize: CGFloat
    let exerciseSize: CGFloat
    let quoteSize: CGFloat
    let heroSpacing: CGFloat
    let titleSpacing: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let sectionGap: CGFloat
    let maxSectionGap: CGFloat
    let cardPadding: CGFloat
    let cardSpacing: CGFloat
    let gridSpacing: CGFloat
    let tileSpacing: CGFloat
    let tileHorizontalPadding: CGFloat
    let tileVerticalPadding: CGFloat
    let statValueSize: CGFloat
    let statLabelSize: CGFloat
    let headerSize: CGFloat
    let bodySize: CGFloat
    let captionSize: CGFloat
    let extrasSpacing: CGFloat
    let barSpacing: CGFloat
    let barHeight: CGFloat
    let doneFontSize: CGFloat
    let doneVerticalPadding: CGFloat
    let secondaryFontSize: CGFloat
    let secondaryVerticalPadding: CGFloat
    let buttonSpacing: CGFloat

    static let regular = CompletionMetrics(
        isCompact: false,
        heroOuter: 60,
        heroInner: 48,
        checkSize: 24,
        headlineSize: 28,
        exerciseSize: 14,
        quoteSize: 15,
        heroSpacing: 8,
        titleSpacing: 4,
        topPadding: 8,
        bottomPadding: 10,
        sectionGap: 10,
        maxSectionGap: 28,
        cardPadding: 12,
        cardSpacing: 8,
        gridSpacing: 8,
        tileSpacing: 3,
        tileHorizontalPadding: 10,
        tileVerticalPadding: 8,
        statValueSize: 20,
        statLabelSize: 11,
        headerSize: 12,
        bodySize: 13,
        captionSize: 12,
        extrasSpacing: 10,
        barSpacing: 6,
        barHeight: 6,
        doneFontSize: 17,
        doneVerticalPadding: 13,
        secondaryFontSize: 15,
        secondaryVerticalPadding: 8,
        buttonSpacing: 6
    )

    static let compact = CompletionMetrics(
        isCompact: true,
        heroOuter: 46,
        heroInner: 36,
        checkSize: 18,
        headlineSize: 24,
        exerciseSize: 13,
        quoteSize: 13,
        heroSpacing: 6,
        titleSpacing: 2,
        topPadding: 4,
        bottomPadding: 6,
        sectionGap: 6,
        maxSectionGap: 16,
        cardPadding: 8,
        cardSpacing: 6,
        gridSpacing: 6,
        tileSpacing: 2,
        tileHorizontalPadding: 8,
        tileVerticalPadding: 6,
        statValueSize: 17,
        statLabelSize: 10,
        headerSize: 11,
        bodySize: 12,
        captionSize: 11,
        extrasSpacing: 8,
        barSpacing: 4,
        barHeight: 5,
        doneFontSize: 16,
        doneVerticalPadding: 12,
        secondaryFontSize: 14,
        secondaryVerticalPadding: 6,
        buttonSpacing: 2
    )

    static let tight = CompletionMetrics(
        isCompact: true,
        heroOuter: 36,
        heroInner: 28,
        checkSize: 14,
        headlineSize: 22,
        exerciseSize: 12,
        quoteSize: 12,
        heroSpacing: 4,
        titleSpacing: 1,
        topPadding: 2,
        bottomPadding: 2,
        sectionGap: 4,
        maxSectionGap: 8,
        cardPadding: 6,
        cardSpacing: 4,
        gridSpacing: 4,
        tileSpacing: 1,
        tileHorizontalPadding: 6,
        tileVerticalPadding: 4,
        statValueSize: 15,
        statLabelSize: 9,
        headerSize: 10,
        bodySize: 11,
        captionSize: 10,
        extrasSpacing: 6,
        barSpacing: 3,
        barHeight: 4,
        doneFontSize: 16,
        doneVerticalPadding: 10,
        secondaryFontSize: 13,
        secondaryVerticalPadding: 4,
        buttonSpacing: 0
    )
}

#Preview {
    WorkoutCompletedScreen(
        exercise: Exercise(
            id: "pushups",
            name: "Push-Ups",
            description: "Test",
            muscleGroups: ["Chest"]
        ),
        totalReps: 30,
        timeSpent: 195,
        xpEarned: 30,
        wallSitTime: nil,
        workoutViewModel: WorkoutViewModel(),
        selectedTab: .constant(0),
        onWorkoutCompleted: {},
        themeColor: .customOrange
    )
}
