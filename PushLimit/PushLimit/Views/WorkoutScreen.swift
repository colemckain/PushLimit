import SwiftUI

// MARK: - Exercise Model

struct WorkoutScreen: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var selectedExercise: Exercise?
    @State private var sessionExercise: Exercise?
    @State private var sessionReps: Int?
    @State private var navigateToSession = false
    @State private var navigateToRunSession = false
    @State private var navigateToCoreHub = false
    @State private var coreHubDailyOverride: Int? = nil
    @State private var shouldResetNavigation = false
    @State private var restDayLegChoseStrength = false
    @Binding var selectedTab: Int
    @State private var selectedPresetTotal: Int?
    @State private var contentRevealed = false
    @State private var startWorkoutHapticTick = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Space above custom tab bar so the start button stays visible.
    private let tabBarClearance: CGFloat = 52
    /// Fixed height for Push / Core / Legs tiles (Today’s plan still fills remaining space).
    private let exercisePickerTileHeight: CGFloat = 84
    
    private let exercises: [Exercise] = [
        Exercise(
            id: "pushups",
            name: "Push-Ups",
            description: "Hands shoulder-width, body straight. Lower chest to ground, elbows at 45°. Push up explosively.",
            muscleGroups: ["Chest", "Shoulders", "Triceps", "Core"]
        ),
        Exercise(
            id: CoreWorkoutSupport.catalogExerciseId,
            name: "Core Workout",
            description: "Five-move circuit: crunches, bicycles, leg raises, Russian twists, and mountain climbers.",
            muscleGroups: ["Abs", "Obliques", "Hip Flexors", "Core"]
        ),
        Exercise(
            id: "squats",
            name: "Leg Workout",
            description: "Squats & wall sits, or swap in a GPS run for today's leg day.",
            muscleGroups: ["Quads", "Glutes", "Hamstrings", "Core"]
        )
    ]
    
    var body: some View {
        Group {
            if let todaysPlan = todaysRecommendation {
                if isRestDay {
                    ScrollView {
                        restDayScrollContent(todaysPlan)
                    }
                } else {
                    workoutPlanContent(todaysPlan, includeStartButton: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            } else {
                ScrollView {
                    noWorkoutPlanSection
                }
            }
        }
        .frame(maxWidth: 600)
        .centerOnIPad(700)
        .background(Color.customBackground)
        .navigationBarHidden(true)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.85), trigger: startWorkoutHapticTick)
        .onAppear {
            if shouldResetNavigation {
                selectedExercise = nil
                shouldResetNavigation = false
            }
            clearSelectionIfExerciseCompleted()
            selectFirstIncompleteExerciseIfNeeded()
            revealContentIfNeeded()
        }
        .onChange(of: workoutViewModel.workouts.count) { _, _ in
            clearSelectionIfExerciseCompleted()
        }
        .navigationDestination(isPresented: $navigateToSession) {
            if let exercise = sessionExercise, let reps = sessionReps {
                WorkoutSessionScreen(
                    exercise: exercise,
                    repGoal: reps,
                    selectedTab: $selectedTab,
                    workoutViewModel: workoutViewModel,
                    onWorkoutCompleted: {
                        navigateToSession = false
                        selectedExercise = nil
                        sessionExercise = nil
                        sessionReps = nil
                    }
                )
            }
        }
        .navigationDestination(isPresented: $navigateToRunSession) {
            LegRunSessionScreen(
                selectedTab: $selectedTab,
                workoutViewModel: workoutViewModel,
                plannedSquatReps: sessionReps ?? plannedLegSquatReps(),
                onWorkoutCompleted: {
                    navigateToRunSession = false
                    selectedExercise = nil
                    sessionExercise = nil
                    sessionReps = nil
                }
            )
        }
        .navigationDestination(isPresented: $navigateToCoreHub) {
            CoreWorkoutHubScreen(
                workoutViewModel: workoutViewModel,
                selectedTab: $selectedTab,
                onCoreDayCompleted: {
                    navigateToCoreHub = false
                    selectedExercise = nil
                    coreHubDailyOverride = nil
                },
                dailyTotalOverride: coreHubDailyOverride
            )
        }
    }
    
    private var todaysRecommendation: WorkoutPlan.DailyRecommendation? {
        workoutViewModel.getTodaysRecommendation()
    }
    
    private var isRestDay: Bool {
        guard let recommendation = todaysRecommendation else { return false }
        return recommendation.restDay || recommendation.exercises.isEmpty
    }
    
    private var shouldShowLegModeChoice: Bool {
        guard let ex = selectedExercise else { return false }
        return ex.id == LegWorkoutSupport.strengthExerciseId &&
            !workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id)
    }
    
    private var shouldShowCoreStartButton: Bool {
        guard let ex = selectedExercise else { return false }
        return CoreWorkoutSupport.isCoreCatalogId(ex.id) &&
            !workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id)
    }

    private var shouldShowStandardStartButton: Bool {
        guard !isRestDay, let ex = selectedExercise else { return false }
        guard !workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id) else { return false }
        return ex.id != LegWorkoutSupport.strengthExerciseId &&
            !CoreWorkoutSupport.isCoreCatalogId(ex.id)
    }
    
    private var shouldShowPresetSection: Bool {
        guard isRestDay, let ex = selectedExercise else { return false }
        guard !workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id) else { return false }
        // Legs: show Easy/Medium/Hard only after choosing squats (run stays available above).
        if ex.id == LegWorkoutSupport.strengthExerciseId {
            return restDayLegChoseStrength
        }
        // Core: hub handles volume; skip sit-up-style presets.
        if CoreWorkoutSupport.isCoreCatalogId(ex.id) {
            return false
        }
        return true
    }
    
    /// Rest day: compact plan card + exercise picker + optional challenge presets (scrollable).
    @ViewBuilder
    private func restDayScrollContent(_ plan: WorkoutPlan.DailyRecommendation) -> some View {
        VStack(spacing: 10) {
            workoutScreenHeader
                .appearStaggered(index: 0, revealed: contentRevealed, reduceMotion: reduceMotion)
            todaysWorkoutPlanSection(plan, fillsAvailableHeight: false)
                .appearStaggered(index: 1, revealed: contentRevealed, reduceMotion: reduceMotion)
            exerciseSelectionSection
                .appearStaggered(index: 2, revealed: contentRevealed, reduceMotion: reduceMotion)
            if shouldShowLegModeChoice {
                legWorkoutChoiceButtons
                    .appearStaggered(index: 3, revealed: contentRevealed, reduceMotion: reduceMotion)
            }
            if shouldShowCoreStartButton {
                coreWorkoutStartButton
                    .appearStaggered(index: 3, revealed: contentRevealed, reduceMotion: reduceMotion)
            }
            if shouldShowPresetSection, let exercise = selectedExercise {
                presetWorkoutSection(for: exercise)
                    .appearStaggered(index: 4, revealed: contentRevealed, reduceMotion: reduceMotion)
            }
        }
        .padding(.top, isIPad ? 12 : 4)
        .padding(.bottom, tabBarClearance + 16)
    }
    
    @ViewBuilder
    private func workoutPlanContent(
        _ plan: WorkoutPlan.DailyRecommendation,
        includeStartButton: Bool
    ) -> some View {
        GeometryReader { geo in
            let showsStart = includeStartButton && shouldShowStandardStartButton
            let showsLegChoice = includeStartButton && shouldShowLegModeChoice
            let showsCoreStart = includeStartButton && shouldShowCoreStartButton
            let showsDescription = selectedExercise.map {
                !workoutViewModel.hasCompletedExerciseToday(exerciseId: $0.id)
            } ?? false
            let pickerHeight = exerciseSelectionBlockHeight(showsDescription: showsDescription)
            let startButtonHeight: CGFloat = (showsStart || showsLegChoice || showsCoreStart) ? 118 : 0
            let headerHeight: CGFloat = 50
            let verticalChrome: CGFloat = (isIPad ? 12 : 4) + tabBarClearance + 16
            let planHeight = max(
                132,
                geo.size.height - headerHeight - pickerHeight - startButtonHeight - verticalChrome
            )
            
            VStack(spacing: 0) {
                workoutScreenHeader
                    .appearStaggered(index: 0, revealed: contentRevealed, reduceMotion: reduceMotion)
                
                VStack(spacing: 10) {
                    todaysWorkoutPlanSection(plan, fillsAvailableHeight: true)
                        .frame(height: planHeight)
                        .appearStaggered(index: 1, revealed: contentRevealed, reduceMotion: reduceMotion)
                    
                    exerciseSelectionSection
                        .appearStaggered(index: 2, revealed: contentRevealed, reduceMotion: reduceMotion)
                }
                .padding(.top, 6)
                
                Spacer(minLength: 0)
                
                if showsLegChoice {
                    legWorkoutChoiceButtons
                        .appearStaggered(index: 3, revealed: contentRevealed, reduceMotion: reduceMotion)
                } else if showsCoreStart {
                    coreWorkoutStartButton
                        .appearStaggered(index: 3, revealed: contentRevealed, reduceMotion: reduceMotion)
                } else if showsStart {
                    startButton
                        .appearStaggered(index: 3, revealed: contentRevealed, reduceMotion: reduceMotion)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .padding(.top, isIPad ? 12 : 4)
        .padding(.bottom, tabBarClearance)
    }
    
    /// Picker header + tiles + optional description (fixed layout for height budgeting).
    private func exerciseSelectionBlockHeight(showsDescription: Bool) -> CGFloat {
        let sectionHeader: CGFloat = 22
        let spacing: CGFloat = 8
        let description: CGFloat = showsDescription ? 36 : 0
        return sectionHeader + spacing + exercisePickerTileHeight + (description > 0 ? spacing + description : 0)
    }
    
    /// Select the first exercise not yet completed today so Start is available without extra taps.
    private func selectFirstIncompleteExerciseIfNeeded() {
        guard !isRestDay else { return }
        if let current = selectedExercise,
           !workoutViewModel.hasCompletedExerciseToday(exerciseId: current.id) {
            return
        }
        selectedExercise = exercises.first {
            !workoutViewModel.hasCompletedExerciseToday(exerciseId: $0.id)
        }
    }
    
    // MARK: - Screen header
    private var workoutScreenHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(workoutViewModel.themeColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Workout")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.customLabel)
                Text("Today’s plan & pick an exercise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
    
    // MARK: - Today's Workout Plan Section
    private func todaysWorkoutPlanSection(
        _ plan: WorkoutPlan.DailyRecommendation,
        fillsAvailableHeight: Bool
    ) -> some View {
        AppGroupedSection {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(workoutViewModel.themeColor)
                    Text("Today’s plan")
                        .font(.system(size: AppTypography.sectionTitle, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Spacer()
                    if !plan.restDay && !plan.exercises.isEmpty {
                        Text(WorkoutDurationEstimate.tildeMinutesLabel(
                            totalSeconds: plan.exercises.reduce(0) { $0 + $1.sessionEstimatedTotalSeconds }
                        ))
                        .font(.system(size: AppTypography.captionSmall, weight: .semibold))
                        .foregroundColor(workoutViewModel.themeColor)
                    }
                }

                if plan.restDay || plan.exercises.isEmpty {
                    Text("No workouts scheduled for today.")
                        .font(.system(size: AppTypography.bodyMedium, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 6) {
                        ForEach(plan.exercises) { exercise in
                            WorkoutPlanExerciseCard(
                                exercise: exercise,
                                themeColor: workoutViewModel.themeColor,
                                status: workoutViewModel.todaysPlanExerciseStatus(for: exercise.exercise),
                                compact: true,
                                fillHeight: true
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: fillsAvailableHeight ? .infinity : nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: fillsAvailableHeight ? .infinity : nil, alignment: .top)
            .padding(AppSpacing.groupInner)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }
    
    // MARK: - No Workout Plan Section
    private var noWorkoutPlanSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(workoutViewModel.themeColor)
            
            Text("No Workout Plan")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.customLabel)
            
            Text("Complete onboarding to get your personalized workout plan!")
                .font(.system(size: 16))
                .foregroundColor(.customLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                selectedTab = 3 // Navigate to Profile tab
            }) {
                Text("Go to Profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(workoutViewModel.themeColor)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Exercise Selection Section
    private var exerciseSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sectionHeaderGap) {
            HStack(spacing: 6) {
                Text("Pick an exercise")
                    .font(.system(size: AppTypography.sectionTitle, weight: .semibold))
                    .foregroundColor(.customLabel)
                Spacer()
                Text("Tap · 2× start")
                    .font(.system(size: AppTypography.captionSmall, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)

            AppGroupedSection {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(exercises, id: \.id) { exercise in
                            let done = workoutViewModel.hasCompletedExerciseToday(exerciseId: exercise.id)
                            CompactExerciseTile(
                                exercise: exercise,
                                isSelected: selectedExercise?.id == exercise.id,
                                isCompleted: done,
                                themeColor: workoutViewModel.themeColor,
                                compact: true,
                                fillHeight: false,
                                onTap: {
                                    guard !done else { return }
                                    if selectedExercise?.id != exercise.id {
                                        restDayLegChoseStrength = false
                                        selectedPresetTotal = nil
                                    }
                                    selectedExercise = exercise
                                },
                                onDoubleTap: {
                                    guard !done else { return }
                                    if exercise.id == LegWorkoutSupport.strengthExerciseId {
                                        selectedExercise = exercise
                                        // Always offer the run/squats choice — never skip straight past Run.
                                        return
                                    }
                                    if CoreWorkoutSupport.isCoreCatalogId(exercise.id) {
                                        selectedExercise = exercise
                                        openCoreWorkoutHub()
                                        return
                                    }
                                    startWorkoutForExercise(exercise)
                                }
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: exercisePickerTileHeight)
                        }
                    }

                    if let ex = selectedExercise, !workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id) {
                        Text(ex.description)
                            .font(.system(size: AppTypography.captionSmall))
                            .foregroundColor(.customSecondaryLabel)
                            .lineSpacing(2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                }
                .padding(AppSpacing.groupInner)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Leg workout mode choice

    private var legWorkoutChoiceButtons: some View {
        VStack(spacing: 10) {
            Text(isRestDay ? "Choose your off-day leg workout" : "Choose today's leg workout")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            HStack(spacing: 10) {
                Button(action: handleStartSquatWorkout) {
                    legModeCard(
                        title: "Squats & wall sit",
                        subtitle: legStrengthSubtitle,
                        icon: "figure.flexibility"
                    )
                }
                .buttonStyle(.pressable)

                Button(action: handleStartRunWorkout) {
                    legModeCard(
                        title: "Run",
                        subtitle: "GPS · background tracking · route map",
                        icon: "figure.run"
                    )
                }
                .buttonStyle(.pressable)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var legStrengthSubtitle: String {
        if isRestDay {
            return restDayLegChoseStrength
                ? "Pick Easy, Medium, or Hard below"
                : "Challenge levels · wall sits included"
        }
        if let sec = estimatedSecondsForSelectedPlannedWorkout() {
            return "\(WorkoutDurationEstimate.tildeMinutesLabel(totalSeconds: sec)) · rep timer"
        }
        return "Rep timer & wall sits"
    }

    private func legModeCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(workoutViewModel.themeColor)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.customLabel)
                .multilineTextAlignment(.leading)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(workoutViewModel.themeColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func handleStartSquatWorkout() {
        guard let exercise = selectedExercise else { return }
        // Rest day: reveal challenge presets instead of jumping into a fallback session.
        if isRestDay {
            withAnimation(.easeOut(duration: 0.2)) {
                restDayLegChoseStrength = true
            }
            return
        }
        startWorkoutHapticTick &+= 1
        startWorkoutForExercise(exercise)
    }

    private func handleStartRunWorkout() {
        guard let exercise = selectedExercise,
              exercise.id == LegWorkoutSupport.strengthExerciseId else { return }
        guard !workoutViewModel.hasCompletedExerciseToday(exerciseId: exercise.id) else { return }

        startWorkoutHapticTick &+= 1
        let reps = plannedLegSquatReps()
        sessionExercise = exercise
        sessionReps = reps
        navigateToRunSession = true
    }

    private func plannedLegSquatReps() -> Int {
        guard let legExercise = exercises.first(where: { $0.id == LegWorkoutSupport.strengthExerciseId }),
              let planExercise = matchedPlanExercise(for: legExercise) else {
            return getFallbackReps(for: exercises.first(where: { $0.id == LegWorkoutSupport.strengthExerciseId }) ?? exercises[2])
        }
        return planExercise.totalReps
    }

    private var hasIncompleteSelectedWorkout: Bool {
        guard let ex = selectedExercise else { return false }
        return !workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id)
            && workoutViewModel.repsLoggedToday(forExerciseId: ex.id) > 0
    }
    
    private var restartWorkoutSubtitle: String {
        "Full session in one sitting · earlier reps still count"
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: handleStartWorkout) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                VStack(alignment: .center, spacing: 1) {
                    Text("Start \(selectedExercise?.name ?? "Workout")")
                        .font(.system(size: 16, weight: .bold))
                        .multilineTextAlignment(.center)
                    if hasIncompleteSelectedWorkout {
                        Text(restartWorkoutSubtitle)
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.92)
                            .multilineTextAlignment(.center)
                    } else if let sec = estimatedSecondsForSelectedPlannedWorkout() {
                        Text("\(WorkoutDurationEstimate.tildeMinutesLabel(totalSeconds: sec)) · set, rest, repeat")
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.92)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                LinearGradient(
                    colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .shadow(color: workoutViewModel.themeColor.opacity(0.28), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.pressable)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Core workout entry
    
    private var coreWorkoutStartButton: some View {
        VStack(spacing: 10) {
            Text(coreCircuitHasProgress ? "Finish remaining core moves · each one full sitting" : (isRestDay ? "Open your off-day core circuit" : "Open today’s core circuit"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            Button(action: openCoreWorkoutHub) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 14, weight: .bold))
                    VStack(alignment: .center, spacing: 1) {
                        Text(coreCircuitHasProgress ? "Open Core Workout" : "Start Core Workout")
                            .font(.system(size: 16, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(coreStartSubtitle)
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.92)
                            .multilineTextAlignment(.center)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: workoutViewModel.themeColor.opacity(0.28), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var coreStartSubtitle: String {
        if let planExercise = selectedExercise.flatMap({ matchedPlanExercise(for: $0) }) {
            let normalized = CoreWorkoutSupport.normalizedDailyTotal(from: planExercise.totalReps)
            let done = workoutViewModel.repsLoggedToday(forExerciseId: CoreWorkoutSupport.catalogExerciseId)
            if done > 0, !workoutViewModel.isCoreWorkoutCompletedToday() {
                return "\(done) reps saved · unfinished moves restart from the top"
            }
            return "\(normalized.dailyTotal) reps · \(CoreWorkoutSupport.moveCount)×\(normalized.repsPerMove) · one sitting each"
        }
        return "\(CoreWorkoutSupport.baseDailyTotal) reps · \(CoreWorkoutSupport.moveCount)×\(CoreWorkoutSupport.baseRepsPerMove)"
    }
    
    private var coreCircuitHasProgress: Bool {
        !workoutViewModel.isCoreWorkoutCompletedToday()
            && workoutViewModel.repsLoggedToday(forExerciseId: CoreWorkoutSupport.catalogExerciseId) > 0
    }
    
    private func openCoreWorkoutHub() {
        guard let exercise = selectedExercise,
              CoreWorkoutSupport.isCoreCatalogId(exercise.id),
              !workoutViewModel.hasCompletedExerciseToday(exerciseId: exercise.id) else { return }
        startWorkoutHapticTick &+= 1
        coreHubDailyOverride = nil
        navigateToCoreHub = true
    }
    
    // MARK: - Preset Workout Section
    private func presetWorkoutSection(for exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "dial.medium.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                        Text("Challenge level")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.customLabel)
                        Spacer(minLength: 0)
                    }
                    Text(restDayChallengeSubtitle(exerciseName: exercise.name))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(presetWorkoutOptions()) { option in
                    Button {
                        selectedPresetTotal = option.totalReps
                        startPresetWorkout(totalReps: option.totalReps)
                    } label: {
                        PresetWorkoutCard(
                            option: option,
                            exerciseId: exercise.id,
                            isSelected: selectedPresetTotal == option.totalReps,
                            themeColor: workoutViewModel.themeColor
                        )
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Helper Functions
    private func handleStartWorkout() {
        DebugLog.log("🚀 Start button pressed for \(selectedExercise?.name ?? "Unknown")")
        guard let exercise = selectedExercise else { 
            DebugLog.log("❌ No exercise selected")
            return 
        }
        startWorkoutHapticTick &+= 1
        startWorkoutForExercise(exercise)
    }
    
    private func revealContentIfNeeded() {
        guard !contentRevealed else { return }
        if reduceMotion {
            contentRevealed = true
        } else {
            DispatchQueue.main.async {
                contentRevealed = true
            }
        }
    }
    
    private func startWorkoutForExercise(_ exercise: Exercise) {
        guard !workoutViewModel.hasCompletedExerciseToday(exerciseId: exercise.id) else {
            DebugLog.log("⏭️ \(exercise.name) already completed today.")
            return
        }
        DebugLog.log("🎯 Starting workout for \(exercise.name)")
        
        // Get the reps from today's workout plan
        guard let todaysPlan = workoutViewModel.getTodaysRecommendation() else { 
            DebugLog.log("❌ No today's plan found - using fallback reps")
            // Fallback to default reps if no plan
            let fallbackReps = getFallbackReps(for: exercise)
            startWorkoutWithReps(exercise: exercise, reps: fallbackReps)
            return 
        }
        
        DebugLog.log("📋 Today's plan exercises: \(todaysPlan.exercises.map { $0.exercise })")
        DebugLog.log("🎯 Looking for exercise: \(exercise.id)")
        
        // Find the exercise in today's plan to get the reps
        let planExercise = todaysPlan.exercises.first { planEx in
            let planName = planEx.exercise.lowercased()
            let exerciseId = exercise.id.lowercased()
            
            // Try multiple matching strategies
            return planName.contains(exerciseId) || 
                   exerciseId.contains(planName) ||
                   (exerciseId == "pushups" && planName.contains("push")) ||
                   (CoreWorkoutSupport.isCoreCatalogId(exerciseId) && CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)) ||
                   (exerciseId == "squats" && (planName.contains("squat") || planName.contains("leg")))
        }
        
        if let planExercise = planExercise {
            DebugLog.log("✅ Found exercise in plan: \(planExercise.exercise) with \(planExercise.repsPerSet) reps")
            startWorkoutWithReps(exercise: exercise, reps: planExercise.totalReps)
        } else {
            DebugLog.log("❌ No matching exercise found in plan - using fallback reps")
            let fallbackReps = getFallbackReps(for: exercise)
            startWorkoutWithReps(exercise: exercise, reps: fallbackReps)
        }
    }
    
    private func startWorkoutWithReps(exercise: Exercise, reps: Int) {
        DebugLog.log("🚀 Starting workout: \(exercise.name) with \(reps) reps")
        
        // Start app restriction if enabled
        let restrictionService = AppRestrictionService.shared
        if restrictionService.isAuthorized {
            restrictionService.startWorkoutRestriction()
        }
        
        sessionExercise = exercise
        sessionReps = reps
        navigateToSession = true
    }
    
    private func startPresetWorkout(totalReps: Int) {
        guard let exercise = selectedExercise else { return }
        DebugLog.log("🎯 Starting rest-day challenge (\(totalReps) reps) for \(exercise.name)")
        startWorkoutWithReps(exercise: exercise, reps: totalReps)
    }
    
    private func restDayChallengeSubtitle(exerciseName: String) -> String {
        "On a rest day, pick Easy, Medium, or Hard to run \(exerciseName) with a short set breakdown — tap a card to start."
    }
    
    private func presetWorkoutOptions() -> [PresetWorkoutOption] {
        let breakdowns: [Int: [Int]] = [
            10: [4, 2, 1, 3],
            25: [6, 7, 4, 8],
            50: [12, 18, 8, 12]
        ]
        let configs: [(title: String, subtitle: String, total: Int, icon: String)] = [
            ("Easy", "Light volume · great for a quick finish", 10, "leaf.fill"),
            ("Medium", "Balanced push · solid work", 25, "flame.fill"),
            ("Hard", "High volume · max effort", 50, "bolt.fill")
        ]
        return configs.enumerated().compactMap { index, config in
            guard let sets = breakdowns[config.total] else { return nil }
            return PresetWorkoutOption(
                id: index + 1,
                difficultyTitle: config.title,
                subtitle: config.subtitle,
                iconName: config.icon,
                totalReps: config.total,
                setBreakdown: sets
            )
        }
    }
    
    private func clearSelectionIfExerciseCompleted() {
        if let ex = selectedExercise, workoutViewModel.hasCompletedExerciseToday(exerciseId: ex.id) {
            selectedExercise = nil
            restDayLegChoseStrength = false
            selectedPresetTotal = nil
        }
        selectFirstIncompleteExerciseIfNeeded()
    }
    
    private func matchedPlanExercise(for exercise: Exercise) -> WorkoutPlan.ExerciseRecommendation? {
        guard let todaysPlan = workoutViewModel.getTodaysRecommendation() else { return nil }
        return todaysPlan.exercises.first { planEx in
            let planName = planEx.exercise.lowercased()
            let exerciseId = exercise.id.lowercased()
            return planName.contains(exerciseId) ||
                exerciseId.contains(planName) ||
                (exerciseId == "pushups" && planName.contains("push")) ||
                (CoreWorkoutSupport.isCoreCatalogId(exerciseId) && CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)) ||
                (exerciseId == "squats" && (planName.contains("squat") || planName.contains("leg")))
        }
    }
    
    /// Session length for the **selected** exercise (matches `WorkoutSessionScreen` timers + rests + wall sits for legs).
    private func estimatedSecondsForSelectedPlannedWorkout() -> Int? {
        guard let ex = selectedExercise else { return nil }
        if let planExercise = matchedPlanExercise(for: ex) {
            return WorkoutDurationEstimate.totalSessionSeconds(planExercise: planExercise)
        }
        let reps = getFallbackReps(for: ex)
        let breakdown = WorkoutDurationEstimate.setBreakdown(for: reps)
        let setCount = breakdown.isEmpty ? 1 : breakdown.count
        return WorkoutDurationEstimate.totalSessionSeconds(
            totalReps: reps,
            setCount: setCount,
            planExerciseLabel: ex.name,
            fallbackExerciseId: ex.id
        )
    }
    
    private func getFallbackReps(for exercise: Exercise) -> Int {
        // Fallback reps if no workout plan is available
        switch exercise.id {
        case "pushups": return 10
        case CoreWorkoutSupport.catalogExerciseId: return CoreWorkoutSupport.baseRepsPerMove
        case "squats": return 10
        default: return 10
        }
    }
}

// MARK: - Supporting Views

struct WorkoutPlanExerciseCard: View {
    let exercise: WorkoutPlan.ExerciseRecommendation
    let themeColor: Color
    var status: WorkoutViewModel.TodaysPlanExerciseStatus = .notStarted
    var compact: Bool = false
    var fillHeight: Bool = false
    
    private var isCompleted: Bool { status == .done }
    private var isAlmostDone: Bool { status == .almostDone }
    
    var body: some View {
        Group {
            if compact {
                mediumPlanRow
            } else {
                fullPlanCard
            }
        }
        .opacity(isCompleted ? 0.88 : 1)
    }
    
    /// Plan row — scales content to the row height so boxes fill space without hollow padding.
    private var mediumPlanRow: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let iconSize = fillHeight ? min(26, max(15, h * 0.42)) : 15
            let titleSize = fillHeight ? min(17, max(13, h * 0.28)) : 13
            let detailSize = fillHeight ? min(13, max(10, h * 0.21)) : 11
            let metaSize = fillHeight ? min(14, max(11, h * 0.24)) : 12
            let timeSize = fillHeight ? min(12, max(10, h * 0.2)) : 10
            let doneSize = fillHeight ? min(11, max(9, h * 0.18)) : 9
            let hPad = fillHeight ? max(8, h * 0.12) : 8
            let accent = isCompleted ? Color.green : themeColor
            
            HStack(alignment: .center, spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent)
                    .frame(width: 3)
                    .padding(.vertical, max(4, h * 0.1))
                
                HStack(alignment: .center, spacing: max(6, h * 0.08)) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : (isAlmostDone ? "circle.lefthalf.filled" : exerciseIcon(exercise.exercise)))
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundColor(accent)
                        .frame(width: iconSize + 4)
                    
                    VStack(alignment: .leading, spacing: max(1, h * 0.04)) {
                        Text(exercise.exercise)
                            .font(.system(size: titleSize, weight: .semibold))
                            .foregroundColor(.customLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text(mediumSummaryLine)
                            .font(.system(size: detailSize, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    
                    Spacer(minLength: 4)
                    
                    VStack(alignment: .trailing, spacing: max(1, h * 0.04)) {
                        Text("\(exercise.totalReps)")
                            .font(.system(size: metaSize, weight: .bold, design: .rounded))
                            .foregroundColor(themeColor)
                            .monospacedDigit()
                        Text(WorkoutDurationEstimate.tildeMinutesLabel(totalSeconds: exercise.sessionEstimatedTotalSeconds))
                            .font(.system(size: timeSize, weight: .semibold))
                            .foregroundColor(themeColor.opacity(0.9))
                        if isCompleted {
                            Text("Done")
                                .font(.system(size: doneSize, weight: .bold))
                                .foregroundColor(.green)
                        } else if isAlmostDone {
                    Text("Incomplete")
                        .font(.system(size: doneSize, weight: .bold))
                        .foregroundColor(themeColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        }
                    }
                }
                .padding(.leading, hPad)
                .padding(.trailing, max(8, hPad))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground.opacity(isCompleted ? 0.45 : 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var fullPlanCard: some View {
        HStack(alignment: .center, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isCompleted ? Color.green : themeColor)
                .frame(width: 4)
            
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : exerciseIcon(exercise.exercise))
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? .green : themeColor)
                    .frame(width: 22)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exercise)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                        .lineLimit(1)
                    
                    Text(fullSummaryLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                }
                
                Spacer(minLength: 4)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(exercise.totalReps) total")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeColor)
                    Text(WorkoutDurationEstimate.tildeMinutesLabel(totalSeconds: exercise.sessionEstimatedTotalSeconds))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeColor.opacity(0.9))
                    Text(exercise.restDescription)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                    if isCompleted {
                        Text("Done")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    } else if isAlmostDone {
                        Text("Incomplete")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeColor)
                    }
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .padding(.vertical, 12)
        }
        .background(Color.customBackground.opacity(isCompleted ? 0.45 : 0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCompleted ? Color.green.opacity(0.35) : (isAlmostDone ? themeColor.opacity(0.35) : Color.gray.opacity(0.12)), lineWidth: 1)
        )
    }
    
    private var mediumSummaryLine: String {
        var line = "\(exercise.sets)×\(exercise.repsPerSet) reps"
        if exercise.exercise.lowercased().contains("leg") {
            line += " · wall sits 2×30s"
        }
        return line
    }
    
    private var fullSummaryLine: String {
        var line = "\(exercise.sets) sets × \(exercise.repsPerSet) reps"
        if exercise.exercise.lowercased().contains("leg") {
            line += " · wall sits 2×30s"
        }
        return line
    }
    
    private func exerciseIcon(_ exercise: String) -> String {
        if exercise.lowercased().contains("push") {
            return "figure.strengthtraining.traditional"
        } else if CoreWorkoutSupport.isCorePlanExercise(exercise) {
            return "figure.core.training"
        } else if exercise.lowercased().contains("leg") || exercise.lowercased().contains("squat") {
            return "figure.flexibility"
        }
        return "figure.walk"
    }
}

/// Compact tile for the workout tab — icon + short name, selection ring.
struct CompactExerciseTile: View {
    let exercise: Exercise
    let isSelected: Bool
    var isCompleted: Bool = false
    let themeColor: Color
    var compact: Bool = false
    var fillHeight: Bool = false
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    private var tileIconSize: CGFloat { compact ? 38 : 52 }
    private var tileIconFont: CGFloat { compact ? 17 : 22 }
    private var tileVerticalPad: CGFloat { compact ? 6 : 12 }
    
    private var iconName: String {
        switch exercise.id.lowercased() {
        case "pushups": return "figure.strengthtraining.traditional"
        case "situps": return "figure.core.training"
        case "squats": return "figure.flexibility"
        default: return "figure.walk"
        }
    }
    
    private var shortTitle: String {
        switch exercise.id.lowercased() {
        case "pushups": return "Push"
        case "situps": return "Core"
        case "squats": return "Legs"
        default: return exercise.name
        }
    }
    
    var body: some View {
        Group {
            if fillHeight {
                GeometryReader { geo in
                    tileContent(
                        iconSize: min(64, max(40, geo.size.height * 0.44)),
                        iconFont: min(28, max(18, geo.size.height * 0.2)),
                        titleFont: min(15, max(12, geo.size.height * 0.12)),
                        doneFont: min(12, max(10, geo.size.height * 0.1)),
                        spacing: max(4, geo.size.height * 0.06),
                        horizontalPad: max(4, geo.size.width * 0.04)
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                tileContent(
                    iconSize: tileIconSize,
                    iconFont: tileIconFont,
                    titleFont: compact ? 12 : 13,
                    doneFont: compact ? 10 : 12,
                    spacing: compact ? 6 : 10,
                    horizontalPad: 4
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fillHeight ? .infinity : nil)
    }
    
    @ViewBuilder
    private func tileContent(
        iconSize: CGFloat,
        iconFont: CGFloat,
        titleFont: CGFloat,
        doneFont: CGFloat,
        spacing: CGFloat,
        horizontalPad: CGFloat
    ) -> some View {
        if isCompleted {
            VStack(spacing: spacing) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: min(iconSize * 0.58, 32), weight: .semibold))
                        .foregroundColor(.green)
                }
                Text(shortTitle)
                    .font(.system(size: titleFont, weight: .bold))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Done")
                    .font(.system(size: doneFont, weight: .bold))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, maxHeight: fillHeight ? .infinity : nil)
            .padding(.vertical, fillHeight ? 0 : tileVerticalPad)
            .padding(.horizontal, horizontalPad)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.customSecondaryBackground.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.green.opacity(0.35), lineWidth: 1.5)
            )
            .allowsHitTesting(false)
        } else {
            Button(action: onTap) {
                VStack(spacing: spacing) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? themeColor.opacity(0.22) : Color.customSecondaryBackground)
                            .frame(width: iconSize, height: iconSize)
                        Image(systemName: iconName)
                            .font(.system(size: iconFont, weight: .semibold))
                            .foregroundColor(isSelected ? themeColor : .customLabel.opacity(0.85))
                    }
                    Text(shortTitle)
                        .font(.system(size: titleFont, weight: .bold))
                        .foregroundColor(.customLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, maxHeight: fillHeight ? .infinity : nil)
                .padding(.vertical, fillHeight ? 0 : tileVerticalPad)
                .padding(.horizontal, horizontalPad)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(isSelected ? 0.06 : 0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? themeColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 0.5)
                )
            }
            .buttonStyle(.pressable)
            .onTapGesture(count: 2) {
                onDoubleTap()
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let isSelected: Bool
    let themeColor: Color
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text(exercise.description)
                    .font(.system(size: 12))
                    .foregroundColor(.customLabel)
                    .lineSpacing(3)
                    .lineLimit(exercise.id == "squats" ? 4 : 2)
                    .fixedSize(horizontal: false, vertical: true)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                    ForEach(exercise.muscleGroups, id: \.self) { muscle in
                        MuscleTag(text: muscle, themeColor: themeColor)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.customBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .customShadow()
        }
        .buttonStyle(.pressable)
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }
}

struct MuscleTag: View {
    let text: String
    let themeColor: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(themeColor)
            .cornerRadius(16)
    }
}

private struct PresetWorkoutOption: Identifiable {
    let id: Int
    let difficultyTitle: String
    let subtitle: String
    let iconName: String
    let totalReps: Int
    let setBreakdown: [Int]
}

private struct PresetWorkoutCard: View {
    let option: PresetWorkoutOption
    let exerciseId: String
    let isSelected: Bool
    let themeColor: Color
    
    private var sessionSeconds: Int {
        WorkoutDurationEstimate.totalSessionSeconds(
            totalReps: option.totalReps,
            setCount: max(1, option.setBreakdown.count),
            planExerciseLabel: "",
            fallbackExerciseId: exerciseId
        )
    }
    
    private var levelAccent: Color {
        switch option.difficultyTitle {
        case "Easy": return Color(red: 0.22, green: 0.72, blue: 0.48)
        case "Medium": return themeColor
        case "Hard": return Color(red: 0.95, green: 0.38, blue: 0.28)
        default: return themeColor
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [levelAccent.opacity(0.35), levelAccent.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: option.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(levelAccent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.difficultyTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.customLabel)
                    Text(option.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total reps")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.customSecondaryLabel)
                        .textCase(.uppercase)
                        .tracking(0.4)
                    Text("\(option.totalReps)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(levelAccent)
                    Text(WorkoutDurationEstimate.tildeMinutesLabel(totalSeconds: sessionSeconds))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.customSecondaryLabel)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Set breakdown")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
                    .textCase(.uppercase)
                    .tracking(0.3)
                
                HStack(spacing: 6) {
                    ForEach(Array(option.setBreakdown.enumerated()), id: \.offset) { index, value in
                        VStack(spacing: 5) {
                            Text("\(value)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.customLabel)
                            Text("Set \(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.customSecondaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.customBackground.opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(levelAccent.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(levelAccent.opacity(0.85))
            }
        }
        .padding(16)
        .background {
            AppGroupedSurface(cornerRadius: 14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSelected ? levelAccent.opacity(0.55) : Color.primary.opacity(0.07),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
    }
}


#Preview {
    WorkoutScreen(workoutViewModel: WorkoutViewModel(), selectedTab: .constant(0))
} 