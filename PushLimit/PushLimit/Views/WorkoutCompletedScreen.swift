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
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                if showStats { statsPreviewCard.transition(.opacity.combined(with: .offset(y: 12))) }
                if showExtras {
                    extrasSection.transition(.opacity.combined(with: .offset(y: 10)))
                }
                if showActions { actionButtons.transition(.opacity.combined(with: .offset(y: 8))) }
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, 28)
            .padding(.bottom, 36)
            .frame(maxWidth: .infinity)
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.12))
                    .frame(width: 88, height: 88)
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
                    .frame(width: 72, height: 72)
                    .shadow(color: themeColor.opacity(0.35), radius: 12, x: 0, y: 6)
                    .scaleEffect(showHero ? 1 : 0.5)
                    .opacity(showHero ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showHero ? 1 : 0.3)
                    .opacity(showHero ? 1 : 0)
            }

            VStack(spacing: 8) {
                Text(headline)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.customLabel)
                    .multilineTextAlignment(.center)

                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeColor)
            }
            .opacity(showHero ? 1 : 0)
            .offset(y: showHero ? 0 : 10)

            if showQuote {
                Text(quote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Stats

    private var statsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's session")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
                .textCase(.uppercase)
                .tracking(0.5)

            if isRunWorkout, let runDistanceMeters {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    completionStatTile(icon: "location.fill", label: "Distance", value: LegWorkoutSupport.formatDistance(runDistanceMeters))
                    completionStatTile(icon: "clock.fill", label: "Time", value: formatTime(timeSpent))
                    completionStatTile(
                        icon: "speedometer",
                        label: "Pace",
                        value: LegWorkoutSupport.formatPace(distanceMeters: runDistanceMeters, elapsedSeconds: timeSpent)
                    )
                    completionStatTile(icon: "star.fill", label: "XP earned", value: "+\(displayedXP)", accent: true)
                }
            } else if isLegWorkout, let wallSitTime {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    completionStatTile(icon: "figure.strengthtraining.traditional", label: "Squats", value: "\(totalReps)")
                    completionStatTile(icon: "timer", label: "Wall sits", value: formatWallSitTime(wallSitTime))
                    completionStatTile(icon: "clock.fill", label: "Time", value: formatTime(timeSpent))
                    completionStatTile(icon: "star.fill", label: "XP earned", value: "+\(displayedXP)", accent: true)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    completionStatTile(icon: "repeat", label: "Total reps", value: "\(totalReps)")
                    completionStatTile(icon: "clock.fill", label: "Time", value: formatTime(timeSpent))
                    completionStatTile(icon: "star.fill", label: "XP earned", value: "+\(displayedXP)", accent: true)
                    completionStatTile(icon: "flame.fill", label: "Streak", value: "\(workoutViewModel.getCurrentStreak())d")
                }
            }

            if isLegWorkout || isRunWorkout {
                HStack(spacing: 10) {
                    completionStatTile(
                        icon: "flame.fill",
                        label: "Streak",
                        value: "\(workoutViewModel.getCurrentStreak())d"
                    )
                    completionStatTile(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Level",
                        value: "Lv. \(workoutViewModel.levelInfo.level)"
                    )
                }
            }
        }
        .padding(AppSpacing.groupInner + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppGroupedSurface() }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }

    private func completionStatTile(
        icon: String,
        label: String,
        value: String,
        accent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accent ? themeColor : .customSecondaryLabel)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(accent ? themeColor : .customLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Extras

    @ViewBuilder
    private var extrasSection: some View {
        VStack(spacing: 12) {
            if let goal = weeklyGoalForExercise {
                weeklyGoalPreview(goal: goal)
            }
            levelProgressPreview
        }
    }

    private func weeklyGoalPreview(goal: GoalProgress) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("This week · \(goal.workoutType)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customLabel)
                Spacer(minLength: 8)
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(goal.isGoalAchieved ? .green : themeColor)
            }

            GeometryReader { geo in
                let width = max(8, geo.size.width * CGFloat(min(1, goal.progressPercentage)))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.customLabel.opacity(0.08))
                    Capsule()
                        .fill(goal.isGoalAchieved ? Color.green : themeColor)
                        .frame(width: width)
                }
            }
            .frame(height: 8)

            Text(weeklyGoalCaption(goal))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
        }
        .padding(AppSpacing.groupInner + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppGroupedSurface() }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }

    private var levelProgressPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workoutViewModel.levelInfo.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customLabel)
                Spacer()
                Text("\(workoutViewModel.levelInfo.xpInCurrentLevel) / \(workoutViewModel.levelInfo.xpToNextLevel) XP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }

            GeometryReader { geo in
                let width = max(8, geo.size.width * CGFloat(workoutViewModel.levelInfo.progress))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.customLabel.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [themeColor, themeColor.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width)
                }
            }
            .frame(height: 8)
        }
        .padding(AppSpacing.groupInner + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppGroupedSurface() }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: dismissToWorkout) {
                Text("Done")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.pressable)

            Button(action: dismissToProgress) {
                Text("View progress")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.pressableSubtle)
        }
        .padding(.top, 4)
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
