import SwiftUI
import UIKit

struct HomeScreen: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Binding var selectedTab: Int
    @State private var motivationalQuote: String = ""
    @State private var contentRevealed = false
    @State private var startWorkoutHapticTick = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let motivationalQuotes = [
        "Keep it going!",
        "You're stronger than you think!",
        "Every rep counts!",
        "Progress, not perfection!",
        "You've got this!",
        "Stay consistent!",
        "Push your limits!",
        "One workout at a time!",
        "You're building something great!",
        "Trust the process!"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                headerSection
                    .appearStaggered(index: 0, revealed: contentRevealed, reduceMotion: reduceMotion)

                if let plan = workoutViewModel.currentWorkoutPlan {
                    progressionSection(plan)
                        .appearStaggered(index: 1, revealed: contentRevealed, reduceMotion: reduceMotion)
                }

                if let schedule = workoutViewModel.userProfile.sleepSchedule {
                    sleepHabitSection(schedule)
                        .appearStaggered(index: 2, revealed: contentRevealed, reduceMotion: reduceMotion)
                } else if workoutViewModel.hasCompletedOnboarding {
                    sleepHabitPromptSection
                        .appearStaggered(index: 2, revealed: contentRevealed, reduceMotion: reduceMotion)
                }

                if let recommendation = workoutViewModel.getTodaysRecommendation() {
                    todayPlanSection(recommendation)
                        .appearStaggered(index: 3, revealed: contentRevealed, reduceMotion: reduceMotion)
                }

                AppPrimaryButton(
                    title: "Start Workout",
                    accentColor: workoutViewModel.themeColor
                ) {
                    startWorkoutHapticTick &+= 1
                    selectedTab = 1
                }
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.75), trigger: startWorkoutHapticTick)
                .appearStaggered(index: 4, revealed: contentRevealed, reduceMotion: reduceMotion)

                statsSection
                    .appearStaggered(index: 5, revealed: contentRevealed, reduceMotion: reduceMotion)
                weeklyGoalsSection
                    .appearStaggered(index: 6, revealed: contentRevealed, reduceMotion: reduceMotion)
                recentActivitySection
                    .appearStaggered(index: 7, revealed: contentRevealed, reduceMotion: reduceMotion)
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, isIPad ? 18 : 12)
            .padding(.bottom, 24)
        }
        .background(Color.customBackground)
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            selectMotivationalQuote()
            guard !contentRevealed else { return }
            if reduceMotion {
                contentRevealed = true
            } else {
                // Next runloop so the initial offset/opacity paints before animating in.
                DispatchQueue.main.async {
                    contentRevealed = true
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        AppGroupedSection {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    AppIconBadge(
                        systemName: greetingIcon,
                        color: workoutViewModel.themeColor,
                        size: 44
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(homeTimeGreeting)
                            .font(.system(size: AppTypography.caption, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Text(workoutViewModel.userName)
                            .font(.system(size: AppTypography.screenTitle, weight: .bold))
                            .foregroundColor(.customLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(todayDateLabel)
                            .font(.system(size: AppTypography.caption, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }

                    Spacer(minLength: 4)

                    if workoutStreakCount > 0 {
                        VStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(workoutViewModel.themeColor)
                            Text("\(workoutStreakCount)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.customLabel)
                                .monospacedDigit()
                            Text("days")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.customSecondaryLabel)
                        }
                        .frame(minWidth: 44)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(workoutViewModel.themeColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(workoutViewModel.themeColor.opacity(0.85))
                        .frame(width: 3)
                        .padding(.vertical, 1)

                    Text(motivationalQuote)
                        .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppSpacing.groupInner)
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.haze.fill"
        case 17..<22: return "moon.stars.fill"
        default: return "sparkles"
        }
    }

    private var todayDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Sleep habit

    private var sleepHabitPromptSection: some View {
        let accent = workoutViewModel.themeColor

        return AppGroupedSection {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(PushLimitVoiceCopy.sleepSetupTitle())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(PushLimitVoiceCopy.sleepSetupSubtitle())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }

                Spacer(minLength: 0)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = 3
                } label: {
                    Text("Set up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func sleepHabitSection(_ schedule: SleepSchedule) -> some View {
        let badge = schedule.statusBadge()
        let accent = workoutViewModel.themeColor

        return AppGroupedSection {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)

                    Text(schedule.habitHeadline())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customLabel)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(badge.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(badge.isPositive ? accent : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((badge.isPositive ? accent : Color.orange).opacity(0.12))
                        .clipShape(Capsule())
                }

                Text("\(schedule.formattedBedtime) → \(schedule.formattedWakeTime) · \(schedule.formattedDuration)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.customLabel)
                    .monospacedDigit()

                Text(schedule.habitMessageBrief())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Progression

    private func progressionSection(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            AppSectionHeader(title: "Training phase", accentColor: workoutViewModel.themeColor)

            AppGroupedSection {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        AppIconBadge(
                            systemName: phaseIcon(for: plan.currentWeek),
                            color: workoutViewModel.themeColor
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Week \(plan.currentWeek)")
                                .font(.system(size: AppTypography.body, weight: .semibold))
                                .foregroundColor(.customLabel)
                            Text(plan.progressionPhase)
                                .font(.system(size: AppTypography.caption, weight: .medium))
                                .foregroundColor(workoutViewModel.themeColor)
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(plan.targetSets)")
                                .font(.system(size: AppTypography.metricLarge, weight: .bold, design: .rounded))
                                .foregroundColor(.customLabel)
                                .monospacedDigit()
                            Text("sets / workout")
                                .font(.system(size: AppTypography.captionSmall, weight: .medium))
                                .foregroundColor(.customSecondaryLabel)
                        }
                    }

                    if plan.weeksUntilNextProgression > 0 {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Next progression")
                                    .font(.system(size: AppTypography.caption, weight: .medium))
                                    .foregroundColor(.customSecondaryLabel)
                                Spacer()
                                Text("\(plan.weeksUntilNextProgression) wk")
                                    .font(.system(size: AppTypography.caption, weight: .semibold))
                                    .foregroundColor(workoutViewModel.themeColor)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.customLabel.opacity(0.08))
                                        .frame(height: 5)
                                    Capsule()
                                        .fill(workoutViewModel.themeColor)
                                        .frame(
                                            width: progressWidth(for: plan, totalWidth: geometry.size.width),
                                            height: 5
                                        )
                                        .animation(
                                            reduceMotion ? .none : .easeOut(duration: 0.35),
                                            value: phaseProgressFraction(for: plan)
                                        )
                                }
                            }
                            .frame(height: 5)
                        }
                    } else {
                        Text("Maximum progression reached")
                            .font(.system(size: AppTypography.caption, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .padding(AppSpacing.groupInner)
            }
        }
    }

    // MARK: - Today's plan

    private func todayPlanSection(_ recommendation: WorkoutPlan.DailyRecommendation) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            AppSectionHeader(title: "Today", accentColor: workoutViewModel.themeColor)

            AppGroupedSection {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        AppIconBadge(
                            systemName: recommendation.restDay ? "bed.double.fill" : "calendar",
                            color: workoutViewModel.themeColor
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(recommendation.dayName)
                                .font(.system(size: AppTypography.body, weight: .semibold))
                                .foregroundColor(.customLabel)
                            if !recommendation.restDay && !recommendation.exercises.isEmpty {
                                Text("~\(recommendation.estimatedDuration) min")
                                    .font(.system(size: AppTypography.caption, weight: .medium))
                                    .foregroundColor(.customSecondaryLabel)
                            }
                        }
                        Spacer()
                    }
                    .padding(AppSpacing.groupInner)

                    if recommendation.restDay || recommendation.exercises.isEmpty {
                        Text("Rest day — no workouts scheduled.")
                            .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                            .padding(.horizontal, AppSpacing.groupInner)
                            .padding(.bottom, AppSpacing.groupInner)
                    } else {
                        AppGroupedDivider(leadingInset: AppSpacing.rowIconInset)
                        ForEach(Array(recommendation.exercises.enumerated()), id: \.element.id) { index, exercise in
                            todayPlanRow(exercise)
                            if index < recommendation.exercises.count - 1 {
                                AppGroupedDivider(leadingInset: AppSpacing.rowIconInset)
                            }
                        }
                    }
                }
            }
        }
    }

    private func todayPlanRow(_ exercise: WorkoutPlan.ExerciseRecommendation) -> some View {
        let status = workoutViewModel.todaysPlanExerciseStatus(for: exercise.exercise)
        let logged = workoutViewModel.repsLoggedToday(forPlanExerciseName: exercise.exercise)
        
        return HStack(spacing: 12) {
            AppIconBadge(
                systemName: exerciseIcon(exercise.exercise),
                color: status == .done ? .green : workoutViewModel.themeColor
            )

            Text(exercise.exercise)
                .font(.system(size: AppTypography.body, weight: .medium))
                .foregroundColor(.customLabel)
                .lineLimit(1)

            Spacer(minLength: 8)

            switch status {
            case .done:
                VStack(alignment: .trailing, spacing: 3) {
                    Text(exercise.formattedSetsAndReps)
                        .font(.system(size: AppTypography.caption, weight: .semibold))
                        .foregroundColor(workoutViewModel.themeColor)
                    if let completed = workoutViewModel.getTodaysWorkout(matchingPlanExercise: exercise.exercise) {
                        Text(todayCompletedDetail(exercise: exercise, workout: completed))
                            .font(.system(size: AppTypography.captionSmall, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    } else if logged > 0 {
                        Text("\(logged) reps")
                            .font(.system(size: AppTypography.captionSmall, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }
                    Text("Done")
                        .font(.system(size: AppTypography.captionSmall, weight: .bold))
                        .foregroundColor(.green)
                }
            case .almostDone:
                VStack(alignment: .trailing, spacing: 3) {
                    Text(exercise.formattedSetsAndReps)
                        .font(.system(size: AppTypography.caption, weight: .semibold))
                        .foregroundColor(workoutViewModel.themeColor)
                    Text(logged > 0 ? "\(logged)/\(exercise.totalReps) reps" : "In progress")
                        .font(.system(size: AppTypography.captionSmall, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                    Text("Incomplete")
                        .font(.system(size: AppTypography.captionSmall, weight: .bold))
                        .foregroundColor(workoutViewModel.themeColor)
                }
            case .notStarted:
                VStack(alignment: .trailing, spacing: 2) {
                    Text(exercise.formattedSetsAndReps)
                        .font(.system(size: AppTypography.caption, weight: .semibold))
                        .foregroundColor(workoutViewModel.themeColor)
                    Text(exercise.restDescription)
                        .font(.system(size: AppTypography.captionSmall, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }
            }
        }
        .frame(minHeight: 52, alignment: .center)
        .padding(.horizontal, AppSpacing.groupInner)
        .padding(.vertical, AppSpacing.rowVertical)
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            AppSectionHeader(title: "Stats", accentColor: workoutViewModel.themeColor)

            AppGroupedSection {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        HomeStatCell(
                            icon: "clock.fill",
                            iconColor: workoutViewModel.themeColor,
                            label: "Workout time",
                            value: workoutViewModel.formatWorkoutTime(workoutViewModel.getTotalWorkoutTimeToday())
                        )
                        statVerticalDivider
                        HomeStatCell(
                            icon: "figure.strengthtraining.traditional",
                            iconColor: workoutViewModel.themeColor,
                            label: "Workouts",
                            value: "\(workoutViewModel.getTodaysWorkouts().count)",
                            valueAccent: workoutViewModel.themeColor
                        )
                    }
                    AppGroupedDivider()
                    HStack(spacing: 0) {
                        HomeStatCell(
                            icon: "star.fill",
                            iconColor: workoutViewModel.themeColor,
                            label: "XP",
                            value: "\(workoutViewModel.levelInfo.xpInCurrentLevel)"
                        )
                        statVerticalDivider
                        HomeStatCell(
                            icon: "trophy.fill",
                            iconColor: workoutViewModel.themeColor,
                            label: "Level",
                            value: "\(workoutViewModel.levelInfo.level)",
                            valueAccent: workoutViewModel.themeColor
                        )
                    }
                }
            }
        }
    }

    private var statVerticalDivider: some View {
        Rectangle()
            .fill(Color.customLabel.opacity(0.08))
            .frame(width: 1)
            .padding(.vertical, 6)
    }

    // MARK: - Weekly goals

    private var weeklyGoalsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            AppSectionHeader(
                title: "Weekly goals",
                trailingTitle: "Profile",
                trailingAction: { selectedTab = 3 },
                accentColor: workoutViewModel.themeColor
            )

            let allGoalProgress = workoutViewModel.getAlgorithmGoalProgress()
            let goalProgress = allGoalProgress.filter { $0.workoutType != "Wall Sits" }

            if allGoalProgress.isEmpty {
                AppGroupedSection {
                    Text("Complete onboarding to set personalized goals.")
                        .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.groupInner)
                }
            } else if !goalProgress.isEmpty {
                AppGroupedSection {
                    VStack(spacing: 0) {
                        ForEach(Array(goalProgress.enumerated()), id: \.element.workoutType) { index, progress in
                            CompactGoalProgressRow(
                                goalProgress: progress,
                                themeColor: workoutViewModel.themeColor,
                                compact: true
                            )
                            .padding(.horizontal, AppSpacing.groupInner)
                            .padding(.vertical, AppSpacing.rowVertical)

                            if index < goalProgress.count - 1 {
                                AppGroupedDivider(leadingInset: AppSpacing.rowIconInset)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            AppSectionHeader(
                title: "Recent workouts",
                trailingTitle: workoutViewModel.workouts.isEmpty ? nil : "Progress",
                trailingAction: workoutViewModel.workouts.isEmpty ? nil : { selectedTab = 2 },
                accentColor: workoutViewModel.themeColor
            )

            if workoutViewModel.workouts.isEmpty {
                AppGroupedSection {
                    VStack(spacing: 8) {
                        AppIconBadge(
                            systemName: "figure.strengthtraining.traditional",
                            color: workoutViewModel.themeColor,
                            size: 44
                        )
                        Text("No workouts yet")
                            .font(.system(size: AppTypography.body, weight: .semibold))
                            .foregroundColor(.customLabel)
                        Text("Your history will show up here.")
                            .font(.system(size: AppTypography.caption, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(workoutViewModel.getRecentWorkouts(3)) { workout in
                            HomeRecentWorkoutChip(workout: workout, themeColor: workoutViewModel.themeColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var homeTimeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var workoutStreakCount: Int {
        workoutViewModel.getCurrentStreak()
    }

    private func phaseProgressFraction(for plan: WorkoutPlan) -> CGFloat {
        switch plan.currentWeek {
        case 1...2: return CGFloat(plan.currentWeek) / 2.0
        case 3...4: return CGFloat(plan.currentWeek - 2) / 2.0
        default: return 1
        }
    }

    private func selectMotivationalQuote() {
        motivationalQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]
    }

    private func phaseIcon(for week: Int) -> String {
        switch week {
        case 1...2: return "figure.walk"
        case 3...4: return "figure.run"
        default: return "bolt.fill"
        }
    }

    private func progressWidth(for plan: WorkoutPlan, totalWidth: CGFloat) -> CGFloat {
        let phaseDuration: Int
        let currentWeekInPhase: Int
        switch plan.currentWeek {
        case 1...2:
            phaseDuration = 2
            currentWeekInPhase = plan.currentWeek
        case 3...4:
            phaseDuration = 2
            currentWeekInPhase = plan.currentWeek - 2
        default:
            return totalWidth
        }
        return totalWidth * CGFloat(currentWeekInPhase) / CGFloat(phaseDuration)
    }

    private func todayCompletedDetail(exercise: WorkoutPlan.ExerciseRecommendation, workout: Workout) -> String {
        if workout.isRunWorkout, let distance = workout.distanceMeters {
            let distanceLine = LegWorkoutSupport.formatDistance(distance)
            let timeLine = formatSessionTime(workout.timeSpent)
            return "\(distanceLine) · \(timeLine)"
        }
        let repsLine = "\(workout.reps) reps"
        let timeLine = formatSessionTime(workout.timeSpent)
        if workout.timeSpent > 0 {
            return "\(repsLine) · \(timeLine)"
        }
        return repsLine
    }

    private func formatSessionTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0, secs > 0 { return "\(mins)m \(secs)s" }
        if mins > 0 { return "\(mins) min" }
        return "\(secs)s"
    }

    private func exerciseIcon(_ exercise: String) -> String {
        if exercise.lowercased().contains("push") { return "figure.strengthtraining.traditional" }
        if CoreWorkoutSupport.isCorePlanExercise(exercise) || CoreWorkoutSupport.isCoreMoveId(exercise) || exercise.lowercased() == "core" {
            return "figure.core.training"
        }
        if exercise.lowercased().contains("squat") { return "figure.flexibility" }
        return "figure.walk"
    }
}

// MARK: - Home stat cell

private struct HomeStatCell: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var valueAccent: Color? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: AppTypography.captionSmall, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(value)
                    .font(.system(size: AppTypography.bodyMedium, weight: .semibold, design: .rounded))
                    .foregroundColor(valueAccent ?? .customLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

// MARK: - Recent workout chip

private struct HomeRecentWorkoutChip: View {
    let workout: Workout
    let themeColor: Color

    var body: some View {
        HStack(spacing: 10) {
            AppIconBadge(
                systemName: exerciseIcon(workout.exercise),
                color: themeColor,
                size: 32
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(CoreWorkoutSupport.isCoreWorkoutLog(workout.exercise)
                     ? CoreWorkoutSupport.displayName(forExerciseId: workout.exercise)
                     : workout.exercise.capitalized)
                    .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                    .foregroundColor(.customLabel)
                    .lineLimit(1)
                Text("\(workout.reps) reps")
                    .font(.system(size: AppTypography.caption, weight: .medium))
                    .foregroundColor(themeColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 168, alignment: .leading)
        .background {
            AppGroupedSurface()
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
    }

    private func exerciseIcon(_ exercise: String) -> String {
        if exercise.lowercased().contains("push") { return "figure.strengthtraining.traditional" }
        if CoreWorkoutSupport.isCorePlanExercise(exercise) || CoreWorkoutSupport.isCoreMoveId(exercise) || exercise.lowercased() == "core" {
            return "figure.core.training"
        }
        if exercise.lowercased().contains("squat") || exercise.lowercased().contains("leg") { return "figure.flexibility" }
        return "figure.walk"
    }
}

// MARK: - Compact Goal Progress Row

struct CompactGoalProgressRow: View {
    let goalProgress: GoalProgress
    let themeColor: Color
    var compact: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(
                systemName: exerciseIcon(goalProgress.workoutType),
                color: themeColor
            )

            Text(goalProgress.workoutType.capitalized)
                .font(.system(size: compact ? AppTypography.bodyMedium : AppTypography.body, weight: .medium))
                .foregroundColor(.customLabel)
                .lineLimit(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatProgress(completed: goalProgress.completed, goal: goalProgress.weeklyGoal))
                    .font(.system(size: AppTypography.caption, weight: .semibold))
                    .foregroundColor(.customLabel)
                    .monospacedDigit()
                Text("\(calculateDisplayPercentage(goalProgress))%")
                    .font(.system(size: AppTypography.captionSmall, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.customLabel.opacity(0.08))
                    Capsule()
                        .fill(themeColor)
                        .frame(width: max(0, geo.size.width * goalProgress.progressPercentage))
                }
            }
            .frame(width: compact ? 52 : 60, height: 5)
        }
        .frame(minHeight: 52, alignment: .center)
    }

    private func calculateDisplayPercentage(_ goalProgress: GoalProgress) -> Int {
        let rounded = Int(round(goalProgress.progressPercentage * 100))
        if goalProgress.completed > 0 && rounded == 0 { return 1 }
        return rounded
    }

    private func exerciseIcon(_ exercise: String) -> String {
        if exercise.lowercased().contains("push") { return "figure.strengthtraining.traditional" }
        if CoreWorkoutSupport.isCorePlanExercise(exercise) ||
            CoreWorkoutSupport.isCoreMoveId(exercise) ||
            exercise.lowercased() == "core" {
            return "figure.core.training"
        }
        if exercise.lowercased().contains("squat") || exercise.lowercased().contains("leg") {
            return "figure.flexibility"
        }
        if exercise.lowercased().contains("wall") { return "figure.flexibility" }
        return "figure.walk"
    }

    private func formatProgress(completed: Int, goal: Int) -> String {
        if goalProgress.workoutType == "Wall Sits" {
            return "\(formatTime(completed))/\(formatTime(goal))"
        }
        return "\(completed)/\(goal)"
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        let remaining = seconds % 60
        if remaining == 0 { return "\(minutes)m" }
        return "\(minutes)m \(remaining)s"
    }
}

// MARK: - Legacy components (used elsewhere)

struct WorkoutCard: View {
    let workout: Workout
    let themeColor: Color

    var body: some View {
        HomeRecentWorkoutChip(workout: workout, themeColor: themeColor)
    }
}

struct CompactStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.customLabel)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.customSecondaryBackground)
        .cornerRadius(12)
    }
}

#Preview {
    HomeScreen(workoutViewModel: WorkoutViewModel(), selectedTab: .constant(0))
}
