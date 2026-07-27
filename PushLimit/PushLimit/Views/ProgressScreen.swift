import SwiftUI

struct ProgressScreen: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                weeklyProgressSection
                weeklyGoalsProgressSection
                lifetimeStatsSection
                trainingJourneySection
                recentActivitySection
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, isIPad ? 18 : 12)
            .padding(.bottom, 24)
        }
        .background(Color.customBackground)
        .ignoresSafeArea(.container, edges: .top)
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                }
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }

    // MARK: - Weekly Progress

    private var weeklyProgressSection: some View {
        AppScreenSection(title: "Weekly Progress", accentColor: workoutViewModel.themeColor) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    AppIconBadge(systemName: "flame.fill", color: workoutViewModel.themeColor, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Streak")
                            .font(.system(size: AppTypography.captionSmall, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                        Text("\(workoutViewModel.getCurrentStreak()) Days")
                            .font(.system(size: AppTypography.body + 2, weight: .bold, design: .rounded))
                            .foregroundColor(workoutViewModel.themeColor)
                    }
                    Spacer(minLength: 0)
                }

                AppGroupedDivider()

                HStack(spacing: 8) {
                    ForEach(getCurrentWeekDates(), id: \.self) { date in
                        CompactDayContainer(
                            date: date,
                            hasWorkout: hasWorkoutOnDate(date),
                            isToday: isToday(date),
                            themeColor: workoutViewModel.themeColor
                        )
                    }
                }
            }
            .padding(AppSpacing.groupInner)
        }
    }

    // MARK: - Weekly Goals

    private var weeklyGoalsProgressSection: some View {
        AppScreenSection(title: "Weekly Goals Progress", accentColor: workoutViewModel.themeColor) {
            let goalProgress = workoutViewModel.getAlgorithmGoalProgress()

            if goalProgress.isEmpty {
                VStack(spacing: 8) {
                    AppIconBadge(systemName: "checkmark.circle", color: workoutViewModel.themeColor, size: 40)
                    Text("Complete onboarding to get your personalized goals!")
                        .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, AppSpacing.groupInner)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(goalProgress.enumerated()), id: \.element.workoutType) { index, progress in
                        CompactGoalProgressRow(
                            goalProgress: progress,
                            themeColor: workoutViewModel.themeColor
                        )
                        .padding(.vertical, 10)

                        if index < goalProgress.count - 1 {
                            AppGroupedDivider(leadingInset: AppSpacing.rowIconInset)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.groupInner)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Lifetime Stats

    private var lifetimeStatsSection: some View {
        AppScreenSection(title: "Lifetime Stats", accentColor: workoutViewModel.themeColor) {
            if workoutViewModel.workouts.isEmpty {
                VStack(spacing: 10) {
                    AppIconBadge(systemName: "chart.bar.fill", color: workoutViewModel.themeColor, size: 40)
                    Text("No stats yet")
                        .font(.system(size: AppTypography.body, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text("Complete your first workout to start tracking your progress!")
                        .font(.system(size: AppTypography.caption, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, AppSpacing.groupInner)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        CompactLifetimeStatCard(
                            icon: "figure.strengthtraining.traditional",
                            label: "Push-ups",
                            value: "\(getTotalPushups())",
                            color: workoutViewModel.themeColor
                        )
                        CompactLifetimeStatCard(
                            icon: "figure.core.training",
                            label: "Core",
                            value: "\(getTotalCoreReps())",
                            color: workoutViewModel.themeColor
                        )
                    }
                    HStack(spacing: 10) {
                        CompactLifetimeStatCard(
                            icon: "figure.flexibility",
                            label: "Squats",
                            value: "\(getTotalSquats())",
                            color: workoutViewModel.themeColor
                        )
                        CompactLifetimeStatCard(
                            icon: "flame.fill",
                            label: "Best Streak",
                            value: "\(getLongestStreak())",
                            color: workoutViewModel.themeColor
                        )
                    }
                }
                .padding(AppSpacing.groupInner)
            }
        }
    }

    // MARK: - Training Journey

    @ViewBuilder
    private var trainingJourneySection: some View {
        if let plan = workoutViewModel.currentWorkoutPlan {
            trainingJourneySection(plan)
        } else {
            AppScreenSection(title: "Training Journey", accentColor: workoutViewModel.themeColor) {
                VStack(spacing: 10) {
                    AppIconBadge(systemName: "map.fill", color: workoutViewModel.themeColor, size: 40)
                    Text("Your roadmap isn't ready yet")
                        .font(.system(size: AppTypography.body, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text("Complete onboarding to unlock your personalized training phases and weekly progression plan.")
                        .font(.system(size: AppTypography.caption, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, AppSpacing.groupInner)
            }
        }
    }

    private func trainingJourneySection(_ plan: WorkoutPlan) -> some View {
        AppScreenSection(title: "Training Journey", accentColor: workoutViewModel.themeColor) {
            VStack(alignment: .leading, spacing: 16) {
                Text(trainingJourneyIntro)
                    .font(.system(size: AppTypography.caption, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)

                currentPhaseCard(plan)

                AppGroupedDivider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your progression path")
                        .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                        .foregroundColor(.customLabel)

                    ForEach(TrainingPhase.allCases) { phase in
                        TrainingPhaseRoadmapRow(
                            phase: phase,
                            status: phaseStatus(phase, plan: plan),
                            accentColor: workoutViewModel.themeColor
                        )
                    }
                }

                AppGroupedDivider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("What's ahead", systemImage: "calendar.badge.clock")
                        .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                        .foregroundColor(.customLabel)

                    Text(upcomingProgressionMessage(for: plan))
                        .font(.system(size: AppTypography.caption, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AppGroupedDivider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("How you advance", systemImage: "arrow.up.forward.circle")
                        .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                        .foregroundColor(.customLabel)

                    Text("Every week, PushLimit reviews how close you came to your weekly rep goals. Hit 70% or more to move forward — 90%+ can raise your targets. Stay under 50% and we'll dial goals back so you can build momentum sustainably.")
                        .font(.system(size: AppTypography.caption, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if plan.currentWeek >= 5 {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                        Text("You're in the long-term Power Phase — goals keep adapting as you train.")
                            .font(.system(size: AppTypography.captionSmall, weight: .medium))
                            .foregroundColor(workoutViewModel.themeColor)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(workoutViewModel.themeColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(AppSpacing.groupInner)
        }
    }

    private func currentPhaseCard(_ plan: WorkoutPlan) -> some View {
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

            Text(currentPhaseDescription(for: plan))
                .font(.system(size: AppTypography.caption, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            if plan.weeksUntilNextProgression > 0 {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Next phase")
                            .font(.system(size: AppTypography.caption, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                        Spacer()
                        Text("\(plan.weeksUntilNextProgression) wk left")
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
                                    width: phaseProgressWidth(for: plan, totalWidth: geometry.size.width),
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
            } else if plan.currentWeek < 5 {
                Text("Final week of this phase")
                    .font(.system(size: AppTypography.caption, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
            } else {
                Text("Maximum set progression reached")
                    .font(.system(size: AppTypography.caption, weight: .semibold))
                    .foregroundColor(.green)
            }

            HStack(spacing: 10) {
                TrainingJourneyStatPill(
                    label: "Weekly push-ups",
                    value: "\(plan.weeklyGoals.pushups)",
                    color: workoutViewModel.themeColor
                )
                TrainingJourneyStatPill(
                    label: "Workout days",
                    value: "\(plan.workoutDaysPerWeek)/wk",
                    color: workoutViewModel.themeColor
                )
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var trainingJourneyIntro: String {
        "PushLimit builds you up in three phases over the coming weeks — more reps per set as sets decrease, with weekly goals that grow as you prove consistency."
    }

    private func currentPhaseDescription(for plan: WorkoutPlan) -> String {
        switch plan.currentWeek {
        case 1...2:
            return "Foundation spreads your reps across 4 manageable sets so you lock in form, build habit, and recover between efforts."
        case 3...4:
            return "Building consolidates volume into 3 sets with higher reps each round — you're earning more intensity while staying in control."
        default:
            return "Power pushes you with 2 high-rep sets per exercise. This is where strength and endurance peak, and weekly targets keep climbing with you."
        }
    }

    private func upcomingProgressionMessage(for plan: WorkoutPlan) -> String {
        switch plan.currentWeek {
        case 1:
            return "Finish this foundation week, then Week 2 keeps the same 4-set structure while your weekly rep targets may rise if you're hitting goals. After that, you'll enter the Building Phase with 3 sets per exercise."
        case 2:
            return "Next up: the Building Phase (Weeks 3–4). Sets drop to 3 while reps per set increase — a step up in challenge without changing how often you train."
        case 3:
            return "You're mid-build. Week 4 stays at 3 sets, then the Power Phase begins — just 2 sets per exercise with the highest reps yet."
        case 4:
            return "One more week in Building. After that, Power Phase kicks in at Week 5 with 2 intense sets and goals that scale based on your weekly completion rate."
        default:
            return "You've unlocked the Power Phase. Each week, your rep goals adjust up or down based on how much of your weekly target you complete — keeping training challenging but achievable."
        }
    }

    private func phaseStatus(_ phase: TrainingPhase, plan: WorkoutPlan) -> TrainingPhaseStatus {
        let current = phaseIndex(for: plan.currentWeek)
        if phase.rawValue < current { return .completed }
        if phase.rawValue == current { return .current }
        return .upcoming
    }

    private func phaseIndex(for week: Int) -> Int {
        switch week {
        case 1...2: return 0
        case 3...4: return 1
        default: return 2
        }
    }

    private func phaseIcon(for week: Int) -> String {
        switch week {
        case 1...2: return "figure.walk"
        case 3...4: return "figure.run"
        default: return "bolt.fill"
        }
    }

    private func phaseProgressFraction(for plan: WorkoutPlan) -> CGFloat {
        switch plan.currentWeek {
        case 1...2: return CGFloat(plan.currentWeek) / 2.0
        case 3...4: return CGFloat(plan.currentWeek - 2) / 2.0
        default: return 1
        }
    }

    private func phaseProgressWidth(for plan: WorkoutPlan, totalWidth: CGFloat) -> CGFloat {
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

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        AppScreenSection(title: "Recent Activity", accentColor: workoutViewModel.themeColor) {
            if workoutViewModel.workouts.isEmpty {
                VStack(spacing: 10) {
                    AppIconBadge(systemName: "figure.strengthtraining.traditional", color: workoutViewModel.themeColor, size: 40)
                    Text("No recent workouts")
                        .font(.system(size: AppTypography.body, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text("Start your first workout to see your activity here!")
                        .font(.system(size: AppTypography.caption, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, AppSpacing.groupInner)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(workoutViewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                        CompactActivityItem(
                            workout: workout,
                            themeColor: workoutViewModel.themeColor,
                            onDelete: {
                                workoutToDelete = workout
                                showingDeleteAlert = true
                            }
                        )
                        .padding(.horizontal, AppSpacing.groupInner)

                        if index < workoutViewModel.workouts.count - 1 {
                            AppGroupedDivider(leadingInset: AppSpacing.groupInner + 20)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Helpers

    private func getCurrentWeekDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.weekday, from: today) - 1
        let startOfWeek = calendar.date(byAdding: .day, value: -currentDay, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func hasWorkoutOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return workoutViewModel.workouts.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func getTotalPushups() -> Int {
        workoutViewModel.workouts
            .filter { $0.exercise.lowercased() == "push-ups" || $0.exercise.lowercased() == "pushups" }
            .reduce(0) { $0 + $1.reps }
    }

    private func getTotalCoreReps() -> Int {
        workoutViewModel.workouts
            .filter { CoreWorkoutSupport.isCoreWorkoutLog($0.exercise) }
            .reduce(0) { $0 + $1.reps }
    }

    private func getTotalSquats() -> Int {
        workoutViewModel.workouts
            .filter {
                let e = $0.exercise.lowercased()
                return e.contains("squat") || e.contains("leg")
            }
            .reduce(0) { $0 + $1.reps }
    }

    private func getLongestStreak() -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(workoutViewModel.workouts.map { calendar.startOfDay(for: $0.timestamp) }).sorted()
        guard !uniqueDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for index in 1..<uniqueDays.count {
            let dayGap = calendar.dateComponents([.day], from: uniqueDays[index - 1], to: uniqueDays[index]).day ?? 0
            if dayGap == 1 {
                current += 1
                longest = max(longest, current)
            } else if dayGap > 1 {
                current = 1
            }
        }
        return longest
    }

    private func deleteWorkout(_ workout: Workout) {
        workoutViewModel.workouts.removeAll { $0.id == workout.id }
        workoutViewModel.saveUserData()
    }
}

// MARK: - Training Phase Roadmap

private enum TrainingPhase: Int, CaseIterable, Identifiable {
    case foundation = 0
    case building = 1
    case power = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .foundation: return "Foundation"
        case .building: return "Building"
        case .power: return "Power"
        }
    }

    var weekRange: String {
        switch self {
        case .foundation: return "Weeks 1–2"
        case .building: return "Weeks 3–4"
        case .power: return "Week 5+"
        }
    }

    var setsLabel: String {
        switch self {
        case .foundation: return "4 sets"
        case .building: return "3 sets"
        case .power: return "2 sets"
        }
    }

    var icon: String {
        switch self {
        case .foundation: return "figure.walk"
        case .building: return "figure.run"
        case .power: return "bolt.fill"
        }
    }

    var summary: String {
        switch self {
        case .foundation:
            return "Build consistency with more sets and moderate reps per round."
        case .building:
            return "Fewer sets, higher reps — intensity climbs while you stay structured."
        case .power:
            return "Peak challenge: 2 heavy sets and adaptive weekly goals."
        }
    }
}

private enum TrainingPhaseStatus {
    case completed
    case current
    case upcoming
}

private struct TrainingPhaseRoadmapRow: View {
    let phase: TrainingPhase
    let status: TrainingPhaseStatus
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 34, height: 34)
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconForeground)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(phase.title)
                        .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                        .foregroundColor(titleColor)
                    Text("·")
                        .foregroundColor(.customSecondaryLabel)
                    Text(phase.weekRange)
                        .font(.system(size: AppTypography.captionSmall, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }

                Text("\(phase.setsLabel) per exercise")
                    .font(.system(size: AppTypography.caption, weight: .semibold))
                    .foregroundColor(status == .current ? accentColor : .customSecondaryLabel)

                Text(phase.summary)
                    .font(.system(size: AppTypography.captionSmall, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            if status == .current {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.35), lineWidth: 1)
            }
        }
    }

    private var statusIcon: String {
        switch status {
        case .completed: return "checkmark"
        case .current: return phase.icon
        case .upcoming: return phase.icon
        }
    }

    private var iconBackground: Color {
        switch status {
        case .completed: return Color.green.opacity(0.15)
        case .current: return accentColor.opacity(0.18)
        case .upcoming: return Color.primary.opacity(0.06)
        }
    }

    private var iconForeground: Color {
        switch status {
        case .completed: return .green
        case .current: return accentColor
        case .upcoming: return .customSecondaryLabel
        }
    }

    private var titleColor: Color {
        status == .upcoming ? .customSecondaryLabel : .customLabel
    }

    private var rowBackground: Color {
        switch status {
        case .current: return accentColor.opacity(0.06)
        case .completed, .upcoming: return Color.primary.opacity(0.03)
        }
    }
}

private struct TrainingJourneyStatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: AppTypography.captionSmall, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value)
                .font(.system(size: AppTypography.bodyMedium, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Compact Day Container

struct CompactDayContainer: View {
    let date: Date
    let hasWorkout: Bool
    let isToday: Bool
    let themeColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(formatDayLabel(date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .textCase(.uppercase)

            ZStack {
                Circle()
                    .stroke(borderColor, lineWidth: 2)
                    .frame(width: 28, height: 28)

                if hasWorkout {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 28, height: 28)
                }

                Text(formatDateLabel(date))
                    .font(.system(size: 12, weight: textWeight))
                    .foregroundColor(textColor)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var borderColor: Color {
        if hasWorkout || isToday { return themeColor }
        return Color.gray.opacity(0.3)
    }

    private var textColor: Color {
        if hasWorkout { return .white }
        if isToday { return themeColor }
        return .customLabel
    }

    private var textWeight: Font.Weight {
        isToday ? .bold : .regular
    }

    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Lifetime Stat Card

struct CompactLifetimeStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: AppTypography.captionSmall, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(value)
                    .font(.system(size: AppTypography.bodyMedium, weight: .bold, design: .rounded))
                    .foregroundColor(.customLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Compact Activity Item

struct CompactActivityItem: View {
    let workout: Workout
    let themeColor: Color
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(systemName: exerciseIcon(workout.exercise), color: themeColor, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(CoreWorkoutSupport.isCoreWorkoutLog(workout.exercise)
                     ? CoreWorkoutSupport.displayName(forExerciseId: workout.exercise)
                     : workout.exercise.capitalized)
                    .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                    .foregroundColor(.customLabel)
                HStack(spacing: 8) {
                    Text("\(workout.reps) reps")
                    Text("•")
                    Text(formatTime(workout.timeSpent))
                }
                .font(.system(size: AppTypography.captionSmall, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
            }

            Spacer(minLength: 8)

            Text(formatDate(workout.timestamp))
                .font(.system(size: AppTypography.captionSmall, weight: .medium))
                .foregroundColor(.customSecondaryLabel)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private func exerciseIcon(_ exercise: String) -> String {
        if exercise.lowercased().contains("push") { return "figure.strengthtraining.traditional" }
        if CoreWorkoutSupport.isCorePlanExercise(exercise) || CoreWorkoutSupport.isCoreMoveId(exercise) {
            return "figure.core.training"
        }
        if exercise.lowercased().contains("squat") || exercise.lowercased().contains("leg") { return "figure.flexibility" }
        return "figure.walk"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m"
    }
}

#Preview {
    ProgressScreen(workoutViewModel: WorkoutViewModel())
}
