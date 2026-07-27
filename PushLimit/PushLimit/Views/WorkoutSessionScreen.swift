import SwiftUI

struct WorkoutSessionScreen: View {
    let exercise: Exercise
    let repGoal: Int
    @Binding var selectedTab: Int
    @ObservedObject var workoutViewModel: WorkoutViewModel
    var onWorkoutCompleted: (() -> Void)?
    
    @State private var currentSetIndex = 0
    @State private var isResting = false
    @State private var restSeconds = 60
    /// Snapshot of rest duration when rest period starts (for progress ring UI).
    @State private var restPeriodTotal = 60
    /// User preference: break between sets (persisted per exercise).
    @State private var configuredRestSeconds = 60
    /// User preference: break between wall-sit holds (persisted globally).
    @State private var configuredWallSitRestSeconds = 30
    @State private var restTimer: Timer? = nil
    @State private var showCompletionSheet = false
    @State private var isPaused = false
    @State private var elapsedSeconds = 0
    @State private var showCancelAlert = false
    @State private var showInfo = false
    @State private var showSessionSettings = false
    @State private var showEndWorkoutConfirm = false
    @State private var elapsedTimer: Timer? = nil
    /// Prevents re-running first-entry setup when returning from another screen.
    @State private var didConfigureInitialSession = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    // Draft values edited in the settings sheet (committed on Save).
    @State private var draftSecondsPerRep: Double = 1.67
    @State private var draftRestSeconds: Int = 60
    @State private var draftWallSitRestSeconds: Int = 30
    @State private var didSaveSessionSettings = false
    
    /// Reps from fully finished sets (updated in `completeSet`).
    @State private var completedRepsThisSession = 0
    /// Values shown on the completion sheet (full or early finish).
    @State private var finishedReps = 0
    @State private var finishedXP = 0
    @State private var finishedWallSitTime: Int? = nil
    @State private var finishedAsEarlyEnd = false
    @State private var earlyQuitHapticTick = 0
    
    // New timer states
    @State private var isReadyPhase = true
    @State private var isTimerRunning = false
    @State private var currentRep = 1
    @State private var repTimeRemaining: Double = 2.0  // Initial value, will be set based on exercise
    @State private var repTimer: Timer? = nil
    
    // Wall sit states (for leg workouts)
    @State private var isWallSitPhase = false
    @State private var currentWallSitSet = 0
    @State private var wallSitSecondsRemaining = 30
    @State private var wallSitTimer: Timer? = nil
    @State private var totalWallSitTimeThisWorkout = 0  // Track total wall sit time for this workout
    /// Length of the current wall-sit hold segment (may be shorter when resuming mid-hold).
    @State private var wallSitSegmentDuration = 30
    private let totalWallSitSets = 2
    private let wallSitDuration = 30  // seconds
    
    /// First unfinished rep in the current set (always 1 — sessions restart from the top).
    @State private var resumeStartRepInSet = 1
    @State private var didFinalizeSession = false
    
    /// Seconds allotted per rep on the auto rep counter (user-adjustable, persisted per exercise).
    @State private var secondsPerRep: Double = 1.67
    
    private static let defaultPushRepPace: Double = 1.33
    private static let defaultOtherRepPace: Double = 1.67
    private static let minRepPaceSeconds: Double = 0.5
    private static let maxRepPaceSeconds: Double = 6.0
    /// Step size for faster/slower controls (50 ms).
    private static let repPaceStepSeconds: Double = 0.05
    private static let repTimerTickInterval: Double = 0.05
    
    private static let defaultRestSeconds = 60
    private static let defaultWallSitRestSeconds = 30
    private static let minRestSeconds = 10
    private static let maxRestSeconds = 90
    private static let restStepSeconds = 5
    
    private var isLegWorkout: Bool {
        let id = exercise.id.lowercased()
        return id.contains("squat") || id.contains("leg")
    }
    
    private var defaultSecondsPerRep: Double {
        exercise.id.lowercased().contains("push")
            ? Self.defaultPushRepPace
            : Self.defaultOtherRepPace
    }
    
    private var repPaceStorageKey: String {
        "repPaceSeconds_\(exercise.id)"
    }
    
    private var restDurationStorageKey: String {
        "restDurationSeconds_\(exercise.id)"
    }
    
    private static let wallSitRestDurationStorageKey = "wallSitRestDurationSeconds"
    
    // Get the actual workout plan data for this exercise
    private var workoutPlanData: (sets: Int, repsPerSet: Int, totalReps: Int)? {
        // Core circuit moves are always 1 × today's per-move quota.
        if CoreWorkoutSupport.isCoreMoveId(exercise.id) {
            return (sets: 1, repsPerSet: repGoal, totalReps: repGoal)
        }
        
        guard let todaysPlan = workoutViewModel.getTodaysRecommendation() else { return nil }
        
        let planExercise = todaysPlan.exercises.first { planEx in
            let planName = planEx.exercise.lowercased()
            let exerciseName = exercise.name.lowercased()
            
            return planName.contains(exerciseName) || 
                   exerciseName.contains(planName) ||
                   (exerciseName.contains("push") && planName.contains("push")) ||
                   (CoreWorkoutSupport.isCoreCatalogId(exercise.id) && CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)) ||
                   (exerciseName.contains("squat") && planName.contains("squat"))
        }
        
        if let planExercise = planExercise {
            return (sets: planExercise.sets, repsPerSet: planExercise.repsPerSet, totalReps: planExercise.totalReps)
        }
        
        return nil
    }
    
    private var totalSets: Int { 
        workoutPlanData?.sets ?? getSetBreakdown(repGoal).count
    }
    private var currentSetReps: Int { 
        workoutPlanData?.repsPerSet ?? getSetBreakdown(repGoal)[safe: currentSetIndex] ?? 0
    }
    
    // Workout phase management
    private var workoutPhase: WorkoutPhase {
        if isCountdownPhase {
            return .countdown
        } else if isWallSitPhase {
            // If resting between wall sit sets, show rest view with wall sit context
            if isResting {
                return .rest
            } else if isReadyPhase {
                return .wallSit  // Wall sit ready phase
            } else {
                return .wallSit  // Wall sit timer running
            }
        } else if isReadyPhase {
            return .ready
        } else if isTimerRunning {
            return .timer
        } else if isResting {
            return .rest
        } else {
            return .complete
        }
    }
    
    enum WorkoutPhase {
        case ready
        case countdown
        case timer
        case rest
        case wallSit
        case complete
    }
    
    /// Spoken beat before reps / wall sit: "Ready" → "Go".
    private enum CountdownBeat: Equatable {
        case ready
        case go
    }
    
    @State private var isCountdownPhase = false
    @State private var countdownBeat: CountdownBeat = .ready
    @State private var countdownTimer: Timer? = nil
    private static let readyBeatDuration: TimeInterval = 0.9
    private static let goBeatDuration: TimeInterval = 0.55
    
    /// Warm-up sheet — auto-shown once when the session starts; can reopen from ready screen.
    @State private var showWarmup = false
    @State private var showFitnessDisclaimer = false
    @State private var hasPresentedEntryWarmup = false
    
    /// Clears the tab bar so bottom session controls stay visible.
    private let tabBarClearance: CGFloat = 52
    private let sessionRingSize: CGFloat = 168
    private let sessionRingLineWidth: CGFloat = 10
    
    var body: some View {
        VStack(spacing: 0) {
            AppLockNotificationView()
            
            // Session context: exercise + plan summary + elapsed
            if let todaysPlan = workoutViewModel.getTodaysRecommendation() {
                sessionTopBanner(plan: todaysPlan)
            } else {
                sessionTopBannerFallback
            }
            
            Group {
                switch workoutPhase {
                case .ready:
                    compactReadyView
                case .countdown:
                    countdownView
                case .timer:
                    compactTimerView
                case .rest:
                    compactRestView
                case .wallSit:
                    wallSitView
                case .complete:
                    compactSetView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: 600)
        .centerOnIPad(700)
        .padding(.top, isIPad ? 12 : 4)
        .padding(.bottom, isIPad ? 12 : 4)
        .background(Color.customBackground)
        .navigationBarBackButtonHidden(true)
        .overlay {
            if showWarmup {
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(0.34)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { showWarmup = false }
                        
                        compactWarmupSheet(
                            exercise: exercise,
                            themeColor: workoutViewModel.themeColor,
                            dismiss: { showWarmup = false }
                        )
                        .frame(maxWidth: min(geo.size.width - 24, 420))
                        .frame(maxHeight: min(geo.size.height * 0.52, 380))
                        .padding(.horizontal, 16)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 12))
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeOut(duration: 0.22), value: showWarmup)
            }
        }
        .sheet(isPresented: $showFitnessDisclaimer) {
            FitnessDisclaimerSheet(themeColor: workoutViewModel.themeColor) {
                LegalConsentStore.recordFitnessDisclaimerAcceptance()
                showFitnessDisclaimer = false
                presentEntryWarmupIfNeeded()
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
            WorkoutCompletedScreen(
                exercise: exercise,
                totalReps: finishedReps,
                timeSpent: elapsedSeconds,
                xpEarned: finishedXP,
                wallSitTime: finishedWallSitTime,
                workoutViewModel: workoutViewModel,
                selectedTab: $selectedTab,
                onWorkoutCompleted: {
                    showCompletionSheet = false
                    onWorkoutCompleted?()
                },
                themeColor: workoutViewModel.themeColor,
                wasEarlyEnd: finishedAsEarlyEnd
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("Cancel Workout?", isPresented: $showCancelAlert) {
            Button("Keep Going", role: .cancel) {}
            Button("Cancel Workout", role: .destructive) {
                discardSessionWithoutCredit()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .alert("End workout?", isPresented: $showEndWorkoutConfirm) {
            Button("Keep going", role: .cancel) {}
            Button("End & save", role: .destructive) {
                endWorkoutEarly()
            }
        } message: {
            Text(endWorkoutConfirmMessage)
        }
        .sheet(isPresented: $showSessionSettings) {
            sessionSettingsSheet
        }
        .sensoryFeedback(.success, trigger: didSaveSessionSettings)
        .sensoryFeedback(.warning, trigger: earlyQuitHapticTick)
        .onAppear {
            if !didConfigureInitialSession {
                loadSavedRepPace()
                loadSavedRestDurations()
                repTimeRemaining = secondsPerRep
                presentSessionEntryFlowIfNeeded()
                didConfigureInitialSession = true
            }
            // Keep work paused after leaving; user taps Resume once to continue *this sitting*.
            if !isPaused {
                startElapsedTimer()
            }
        }
        .onDisappear {
            // Leaving the session screen abandons mid-workout resume — credit progress, then restart next time.
            if !didFinalizeSession && !showCompletionSheet {
                creditAbandonedSessionIfNeeded()
            } else {
                pauseSessionBecauseLeftScreen()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                pauseSessionBecauseLeftScreen()
            }
        }
    }
    
    /// Fitness disclaimer first (if needed), then recommended warm-up on first appearance.
    private func presentSessionEntryFlowIfNeeded() {
        guard !hasPresentedEntryWarmup else { return }
        if LegalConsentStore.hasAcceptedFitnessDisclaimer {
            presentEntryWarmupIfNeeded()
        } else {
            showFitnessDisclaimer = true
        }
    }

    /// Presents the recommended warm-up the first time this session screen appears.
    private func presentEntryWarmupIfNeeded() {
        guard !hasPresentedEntryWarmup else { return }
        hasPresentedEntryWarmup = true
        showWarmup = true
    }
    
    // MARK: - Session top banner
    private func sessionTopBanner(plan: WorkoutPlan.DailyRecommendation) -> some View {
        Group {
            if let currentExercisePlan = plan.exercises.first(where: { planEx in
                let planName = planEx.exercise.lowercased()
                let exerciseId = exercise.id.lowercased()
                return planName.contains(exerciseId) ||
                       exerciseId.contains(planName) ||
                       (exerciseId == "pushups" && planName.contains("push")) ||
                       (CoreWorkoutSupport.isCoreMoveId(exerciseId) && CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)) ||
                       (CoreWorkoutSupport.isCoreCatalogId(exerciseId) && CoreWorkoutSupport.isCorePlanExercise(planEx.exercise)) ||
                       (exerciseId == "squats" && (planName.contains("squat") || planName.contains("leg")))
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [workoutViewModel.themeColor.opacity(0.35), workoutViewModel.themeColor.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: exerciseIcon(currentExercisePlan.exercise))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentExercisePlan.exercise)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.customLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("\(currentExercisePlan.sets)×\(currentExercisePlan.repsPerSet) · \(currentExercisePlan.totalReps) total")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatTime(elapsedSeconds))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(workoutViewModel.themeColor)
                            .monospacedDigit()
                        Text("elapsed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                        sessionSettingsGearButton
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.customSecondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(workoutViewModel.themeColor.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            } else {
                sessionTopBannerFallback
            }
        }
    }
    
    private var sessionTopBannerFallback: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [workoutViewModel.themeColor.opacity(0.35), workoutViewModel.themeColor.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: exerciseIconForSession(exercise.id))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.customLabel)
                    .lineLimit(1)
                Text("Session")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(elapsedSeconds))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(workoutViewModel.themeColor)
                    .monospacedDigit()
                Text("elapsed")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                sessionSettingsGearButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.customSecondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(workoutViewModel.themeColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
    
    private var sessionSettingsGearButton: some View {
        Button(action: openSessionSettings) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(workoutViewModel.themeColor)
                .frame(width: 28, height: 28)
                .background(workoutViewModel.themeColor.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Session settings")
    }
    
    private func exerciseIconForSession(_ id: String) -> String {
        let lower = id.lowercased()
        if lower.contains("push") { return "figure.strengthtraining.traditional" }
        if CoreWorkoutSupport.isCoreMoveId(lower) || CoreWorkoutSupport.isCoreCatalogId(lower) || CoreWorkoutSupport.isCorePlanExercise(lower) {
            return "figure.core.training"
        }
        if lower.contains("squat") || lower.contains("leg") { return "figure.flexibility" }
        return "figure.walk"
    }
    
    private func exerciseIcon(_ exercise: String) -> String {
        if exercise.lowercased().contains("push") {
            return "figure.strengthtraining.traditional"
        } else if CoreWorkoutSupport.isCorePlanExercise(exercise) || CoreWorkoutSupport.isCoreMoveId(exercise) {
            return "figure.core.training"
        } else if exercise.lowercased().contains("squat") || exercise.lowercased().contains("leg") {
            return "figure.flexibility"
        }
        return "figure.walk"
    }
    
    // MARK: - Compact Ready View
    private var compactReadyView: some View {
        VStack(spacing: 0) {
            sessionTopControls {
                VStack(spacing: 8) {
                    Text("Set \(currentSetIndex + 1) of \(totalSets)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(workoutViewModel.themeColor)
                    SessionSetProgressBar(
                        current: currentSetIndex + 1,
                        total: max(1, totalSets),
                        themeColor: workoutViewModel.themeColor
                    )
                }
            }
            
            sessionCenteredStack {
                VStack(spacing: 14) {
                    repCounterRing(
                        progress: 1,
                        caption: "This set",
                        mainText: "\(currentSetReps)",
                        subText: "reps",
                        mainFontSize: 52
                    )
                    
                    Text("Get in position, then tap I'm ready for Ready → Go.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showWarmup = true }) {
                        HStack(spacing: 0) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(workoutViewModel.themeColor)
                                .frame(width: 22, alignment: .leading)
                            
                            Text("View warm-up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(workoutViewModel.themeColor)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.customSecondaryLabel)
                                .frame(width: 22, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(workoutViewModel.themeColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            sessionBottomBar {
                sessionPrimaryActionButton(
                    title: "I'm ready",
                    icon: "hand.tap.fill",
                    colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                    action: beginSetWithCountdown
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Ready → Go countdown
    private var countdownView: some View {
        let label = countdownBeat == .ready ? "Ready" : "Go"
        let accent = countdownBeat == .ready ? workoutViewModel.themeColor : Color.green
        
        return VStack(spacing: 0) {
            sessionTopControls {
                VStack(spacing: 8) {
                    Text(isWallSitPhase
                          ? "Wall sit \(currentWallSitSet + 1) of \(totalWallSitSets)"
                          : "Set \(currentSetIndex + 1) of \(totalSets)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)
                    if !isWallSitPhase {
                        SessionSetProgressBar(
                            current: currentSetIndex + 1,
                            total: max(1, totalSets),
                            themeColor: accent
                        )
                    }
                }
            }
            
            sessionCenteredStack {
                VStack(spacing: 16) {
                    Text(label)
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(accent)
                        .scaleEffect(countdownBeat == .go ? 1.08 : 1.0)
                        .animation(.spring(response: 0.32, dampingFraction: 0.66), value: countdownBeat)
                    
                    Text(countdownBeat == .ready
                          ? "Get set…"
                          : (isWallSitPhase ? "Hold it!" : "Rep 1 starting"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customSecondaryLabel)
                }
            }
            
            sessionBottomBar {
                Color.clear.frame(height: 52)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.impact(flexibility: .solid, intensity: countdownBeat == .go ? 1.0 : 0.7), trigger: countdownBeat)
    }
    
    // MARK: - Compact Timer View
    private var compactTimerView: some View {
        let paceProgress = CGFloat(max(0, min(1, repTimeRemaining / max(secondsPerRep, 0.0001))))
        
        return VStack(spacing: 0) {
            sessionCenteredStack {
                repCounterRing(
                    progress: paceProgress,
                    caption: "Rep \(currentRep) of \(currentSetReps)",
                    mainText: "\(currentRep)",
                    subText: "current",
                    mainFontSize: 52
                )
            }
            .layoutPriority(-1)
            
            sessionBottomBar {
                sessionPrimaryActionButton(
                    title: isPaused ? "Resume" : "Pause",
                    icon: isPaused ? "play.fill" : "pause.fill",
                    colors: isPaused
                        ? [Color.green, Color.green.opacity(0.85)]
                        : [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                    action: togglePause
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Compact Set View
    private var compactSetView: some View {
        VStack(spacing: 0) {
            sessionCenteredStack {
                VStack(spacing: 14) {
                    VStack(spacing: 8) {
                        Text("Set \(currentSetIndex + 1) of \(totalSets) complete")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                        SessionSetProgressBar(
                            current: currentSetIndex + 1,
                            total: max(1, totalSets),
                            themeColor: workoutViewModel.themeColor
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    repCounterRing(
                        progress: 1,
                        caption: "Nice work",
                        mainText: "\(currentSetReps)",
                        subText: "reps this set",
                        mainFontSize: 52
                    )
                    
                    if let planData = workoutPlanData {
                        Text("\(planData.sets) sets × \(planData.repsPerSet) · \(planData.totalReps) total")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }
                }
            }
            
            sessionBottomBar {
                sessionPrimaryActionButton(
                    title: "Finish & continue",
                    icon: "checkmark.circle.fill",
                    colors: [Color.green, Color.green.opacity(0.85)],
                    action: handleCompleteSet
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Compact Rest View
    private var compactRestView: some View {
        let restProgress = CGFloat(max(0, min(1, Double(restSeconds) / Double(max(restPeriodTotal, 1)))))
        let restCaption = isWallSitPhase
            ? "Wall sit break · set \(currentWallSitSet + 1) of \(totalWallSitSets)"
            : "Recover · set \(currentSetIndex + 1) of \(totalSets)"
        
        return VStack(spacing: 0) {
            sessionCenteredStack {
                VStack(spacing: 10) {
                    repCounterRing(
                        progress: restProgress,
                        caption: restCaption,
                        mainText: formatTime(restSeconds),
                        subText: "remaining",
                        mainFontSize: 40
                    )
                    
                    if isWallSitPhase, currentWallSitSet < totalWallSitSets {
                        Text("Next: wall sit · Ready → Go starts automatically")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    } else if !isWallSitPhase, currentSetIndex < totalSets - 1 {
                        Text("Next: set \(currentSetIndex + 2) · Ready → Go starts automatically")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
            }
            
            sessionBottomBar {
                // Rest ending auto-starts Ready → Go; keep Pause / Skip while counting down.
                sessionActionButtonPair(
                    primaryTitle: isPaused ? "Resume" : "Pause",
                    primaryIcon: isPaused ? "play.fill" : "pause.fill",
                    primaryColors: isPaused
                        ? [Color.green, Color.green.opacity(0.85)]
                        : [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                    primaryAction: togglePause,
                    secondaryTitle: "Skip rest",
                    secondaryAction: skipRest
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !isPaused {
                startRestTimer()
            }
        }
    }
    
    // MARK: - Shared session layout
    
    private func sessionCenteredStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            content()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func sessionTopControls<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) {
            content()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
    
    private func sessionBottomBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, tabBarClearance)
    }
    
    @ViewBuilder
    private func repCounterRing(
        progress: CGFloat,
        caption: String,
        mainText: String,
        subText: String,
        mainFontSize: CGFloat
    ) -> some View {
        VStack(spacing: 10) {
            Text(caption)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.customSecondaryLabel)
                .textCase(.uppercase)
                .tracking(0.8)
                .multilineTextAlignment(.center)
            
            ZStack {
                RepPaceRing(
                    progress: progress,
                    lineWidth: sessionRingLineWidth,
                    themeColor: workoutViewModel.themeColor
                )
                .frame(width: sessionRingSize, height: sessionRingSize)
                
                VStack(spacing: 4) {
                    Text(mainText)
                        .font(.system(size: mainFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(workoutViewModel.themeColor)
                        .monospacedDigit()
                    Text(subText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }
            }
        }
    }
    
    private func sessionPrimaryActionButton(
        title: String,
        icon: String,
        colors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
        }
    }
    
    @ViewBuilder
    private func sessionActionButtonPair(
        primaryTitle: String,
        primaryIcon: String,
        primaryColors: [Color],
        primaryAction: @escaping () -> Void,
        secondaryTitle: String,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            sessionPrimaryActionButton(
                title: primaryTitle,
                icon: primaryIcon,
                colors: primaryColors,
                action: primaryAction
            )
            
            Button(action: secondaryAction) {
                Text(secondaryTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(workoutViewModel.themeColor.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Wall Sit View
    private var wallSitView: some View {
        VStack(spacing: 0) {
            if isReadyPhase {
                // Ready phase for wall sit
                VStack(spacing: 16) {
                    Spacer(minLength: 8)
                    
                    VStack(spacing: 6) {
                        Text("Wall Sit")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)
                        
                        Text("Set \(currentWallSitSet + 1) of \(totalWallSitSets)")
                            .font(.system(size: 16))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(wallSitDuration)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(workoutViewModel.themeColor)
                            .multilineTextAlignment(.center)
                        
                        Text("seconds")
                            .font(.system(size: 20))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Get in position against the wall")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: 8)
                    
                    VStack(spacing: 12) {
                        Button(action: beginWallSitWithCountdown) {
                            Text("I'm ready")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(workoutViewModel.themeColor)
                                .cornerRadius(12)
                        }
                        
                        Text("Ready → Go, then the hold starts.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            } else {
                // Wall sit timer running
                VStack(spacing: 16) {
                    Spacer(minLength: 8)
                    
                    VStack(spacing: 6) {
                        Text("Wall Sit")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)
                        
                        Text("Set \(currentWallSitSet + 1) of \(totalWallSitSets)")
                            .font(.system(size: 16))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(wallSitSecondsRemaining)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(workoutViewModel.themeColor)
                            .multilineTextAlignment(.center)
                        
                        Text("seconds")
                            .font(.system(size: 20))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Hold your position!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(workoutViewModel.themeColor)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: 8)
                    
                    VStack(spacing: 12) {
                        Button(action: togglePause) {
                            Text(isPaused ? "Resume" : "Pause")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isPaused ? Color.green : workoutViewModel.themeColor)
                                .cornerRadius(12)
                        }
                        
                        Button(action: completeWallSitSet) {
                            Text("Complete Set")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(workoutViewModel.themeColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(workoutViewModel.themeColor.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            if !isReadyPhase && !isPaused && wallSitTimer == nil {
                startWallSitTimer()
            }
        }
    }
    
    // MARK: - Session settings (gear)
    
    private func openSessionSettings() {
        draftSecondsPerRep = secondsPerRep
        draftRestSeconds = configuredRestSeconds
        draftWallSitRestSeconds = configuredWallSitRestSeconds
        showSessionSettings = true
    }
    
    private var sessionSettingsHaveChanges: Bool {
        abs(draftSecondsPerRep - secondsPerRep) > 0.001
            || draftRestSeconds != configuredRestSeconds
            || (isLegWorkout && draftWallSitRestSeconds != configuredWallSitRestSeconds)
    }
    
    private var sessionSettingsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Saved for \(exercise.name). Changes apply after you tap Save.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    settingsCard(title: "Rep pace", subtitle: "How long each auto-counted rep takes.") {
                        settingsValueLabel(String(format: "%.2f sec", draftSecondsPerRep))
                        
                        Slider(
                            value: $draftSecondsPerRep,
                            in: Self.minRepPaceSeconds...Self.maxRepPaceSeconds,
                            step: Self.repPaceStepSeconds
                        )
                        .tint(workoutViewModel.themeColor)
                        .onChange(of: draftSecondsPerRep) { _, newValue in
                            draftSecondsPerRep = snapRepPace(newValue)
                        }
                        
                        HStack(spacing: 10) {
                            settingsChipButton(title: "Faster", icon: "hare.fill") {
                                draftSecondsPerRep = snapRepPace(draftSecondsPerRep - Self.repPaceStepSeconds)
                            }
                            settingsChipButton(title: "Default", icon: nil) {
                                draftSecondsPerRep = defaultSecondsPerRep
                            }
                            settingsChipButton(title: "Slower", icon: "tortoise.fill") {
                                draftSecondsPerRep = snapRepPace(draftSecondsPerRep + Self.repPaceStepSeconds)
                            }
                        }
                    }
                    
                    settingsCard(title: "Rest between sets", subtitle: "Break after each set before Ready → Go.") {
                        settingsValueLabel(restDurationPrimaryLabel(draftRestSeconds))
                        
                        Slider(
                            value: Binding(
                                get: { Double(draftRestSeconds) },
                                set: { draftRestSeconds = snapRestDuration(Int($0.rounded())) }
                            ),
                            in: Double(Self.minRestSeconds)...Double(Self.maxRestSeconds),
                            step: Double(Self.restStepSeconds)
                        )
                        .tint(workoutViewModel.themeColor)
                        
                        HStack(spacing: 10) {
                            settingsChipButton(title: "−5s", icon: nil) {
                                draftRestSeconds = snapRestDuration(draftRestSeconds - Self.restStepSeconds)
                            }
                            settingsChipButton(title: "Default", icon: nil) {
                                draftRestSeconds = Self.defaultRestSeconds
                            }
                            settingsChipButton(title: "+5s", icon: nil) {
                                draftRestSeconds = snapRestDuration(draftRestSeconds + Self.restStepSeconds)
                            }
                        }
                    }
                    
                    if isLegWorkout {
                        settingsCard(title: "Wall sit rest", subtitle: "Break between wall sit holds.") {
                            settingsValueLabel(restDurationPrimaryLabel(draftWallSitRestSeconds))
                            
                            Slider(
                                value: Binding(
                                    get: { Double(draftWallSitRestSeconds) },
                                    set: { draftWallSitRestSeconds = snapRestDuration(Int($0.rounded())) }
                                ),
                                in: Double(Self.minRestSeconds)...Double(Self.maxRestSeconds),
                                step: Double(Self.restStepSeconds)
                            )
                            .tint(workoutViewModel.themeColor)
                            
                            HStack(spacing: 10) {
                                settingsChipButton(title: "−5s", icon: nil) {
                                    draftWallSitRestSeconds = snapRestDuration(draftWallSitRestSeconds - Self.restStepSeconds)
                                }
                                settingsChipButton(title: "Default", icon: nil) {
                                    draftWallSitRestSeconds = Self.defaultWallSitRestSeconds
                                }
                                settingsChipButton(title: "+5s", icon: nil) {
                                    draftWallSitRestSeconds = snapRestDuration(draftWallSitRestSeconds + Self.restStepSeconds)
                                }
                            }
                        }
                    }
                    
                    Button(action: saveSessionSettings) {
                        Text("Save settings")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                sessionSettingsHaveChanges
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    : AnyShapeStyle(Color.gray.opacity(0.35))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!sessionSettingsHaveChanges)
                    
                    Button("Reset all to defaults") {
                        draftSecondsPerRep = defaultSecondsPerRep
                        draftRestSeconds = Self.defaultRestSeconds
                        draftWallSitRestSeconds = Self.defaultWallSitRestSeconds
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        showSessionSettings = false
                        showEndWorkoutConfirm = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "flag.checkered")
                            Text("End workout")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Text("Saves completed reps (and wall-sit time) toward today’s goals, then ends the session.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Session settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSessionSettings = false
                    }
                    .foregroundColor(.customSecondaryLabel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSessionSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(workoutViewModel.themeColor)
                    .disabled(!sessionSettingsHaveChanges)
                }
            }
        }
    }
    
    private func settingsCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.customLabel)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func settingsValueLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(workoutViewModel.themeColor)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private func settingsChipButton(title: String, icon: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundColor(workoutViewModel.themeColor)
            .background(workoutViewModel.themeColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func saveSessionSettings() {
        applyRepPace(draftSecondsPerRep, persist: true)
        applyRestDuration(draftRestSeconds, wallSitBreak: false, liveUpdateCurrentRest: true)
        if isLegWorkout {
            applyRestDuration(draftWallSitRestSeconds, wallSitBreak: true, liveUpdateCurrentRest: true)
        }
        didSaveSessionSettings.toggle()
        showSessionSettings = false
    }
    
    // MARK: - Rep pace persistence
    
    private func snapRepPace(_ value: Double) -> Double {
        let steps = (value / Self.repPaceStepSeconds).rounded()
        let snapped = steps * Self.repPaceStepSeconds
        return min(Self.maxRepPaceSeconds, max(Self.minRepPaceSeconds, snapped))
    }
    
    private func loadSavedRepPace() {
        let saved = UserDefaults.standard.double(forKey: repPaceStorageKey)
        if UserDefaults.standard.object(forKey: repPaceStorageKey) != nil,
           saved >= Self.minRepPaceSeconds, saved <= Self.maxRepPaceSeconds {
            secondsPerRep = snapRepPace(saved)
        } else {
            secondsPerRep = defaultSecondsPerRep
        }
    }
    
    private func persistRepPace() {
        UserDefaults.standard.set(secondsPerRep, forKey: repPaceStorageKey)
    }
    
    private func applyRepPace(_ value: Double, persist: Bool = true) {
        let previousPace = secondsPerRep
        secondsPerRep = snapRepPace(value)
        if persist {
            persistRepPace()
        }
        if isTimerRunning {
            let progress = repTimeRemaining / max(previousPace, 0.0001)
            repTimeRemaining = secondsPerRep * min(1, max(0, progress))
        } else if isReadyPhase || isCountdownPhase {
            repTimeRemaining = secondsPerRep
        }
    }
    
    // MARK: - Rest duration persistence
    
    private func restDurationPrimaryLabel(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainder = seconds % 60
            if remainder == 0 {
                return "\(minutes) min"
            }
            return String(format: "%d:%02d", minutes, remainder)
        }
        return "\(seconds) sec"
    }
    
    private func snapRestDuration(_ value: Int) -> Int {
        let steps = (value + Self.restStepSeconds / 2) / Self.restStepSeconds
        let snapped = steps * Self.restStepSeconds
        return min(Self.maxRestSeconds, max(Self.minRestSeconds, snapped))
    }
    
    private func loadSavedRestDurations() {
        let savedRest = UserDefaults.standard.integer(forKey: restDurationStorageKey)
        if UserDefaults.standard.object(forKey: restDurationStorageKey) != nil,
           savedRest >= Self.minRestSeconds {
            configuredRestSeconds = snapRestDuration(savedRest)
        } else {
            configuredRestSeconds = Self.defaultRestSeconds
        }
        
        let savedWallSit = UserDefaults.standard.integer(forKey: Self.wallSitRestDurationStorageKey)
        if UserDefaults.standard.object(forKey: Self.wallSitRestDurationStorageKey) != nil,
           savedWallSit >= Self.minRestSeconds {
            configuredWallSitRestSeconds = snapRestDuration(savedWallSit)
        } else {
            configuredWallSitRestSeconds = Self.defaultWallSitRestSeconds
        }
    }
    
    private func persistRestDuration(wallSitBreak: Bool) {
        if wallSitBreak {
            UserDefaults.standard.set(configuredWallSitRestSeconds, forKey: Self.wallSitRestDurationStorageKey)
        } else {
            UserDefaults.standard.set(configuredRestSeconds, forKey: restDurationStorageKey)
        }
    }
    
    private func applyRestDuration(_ seconds: Int, wallSitBreak: Bool, liveUpdateCurrentRest: Bool = true) {
        let snapped = snapRestDuration(seconds)
        if wallSitBreak {
            configuredWallSitRestSeconds = snapped
        } else {
            configuredRestSeconds = snapped
        }
        persistRestDuration(wallSitBreak: wallSitBreak)
        
        guard liveUpdateCurrentRest, isResting, isWallSitPhase == wallSitBreak else { return }
        let elapsed = max(0, restPeriodTotal - restSeconds)
        restPeriodTotal = snapped
        restSeconds = max(0, snapped - elapsed)
    }
    
    private func beginRestPeriod(wallSitBreak: Bool) {
        isResting = true
        let duration = wallSitBreak ? configuredWallSitRestSeconds : configuredRestSeconds
        restPeriodTotal = duration
        restSeconds = duration
    }
    
    // MARK: - Timer Logic
    private func beginSetWithCountdown() {
        startReadyGoCountdown {
            startRepTimer()
        }
    }
    
    private func beginWallSitWithCountdown() {
        startReadyGoCountdown {
            startWallSitTimer()
        }
    }
    
    private func startReadyGoCountdown(then startWork: @escaping () -> Void) {
        countdownTimer?.invalidate()
        repTimer?.invalidate()
        repTimer = nil
        wallSitTimer?.invalidate()
        wallSitTimer = nil
        
        isReadyPhase = false
        isTimerRunning = false
        isPaused = false
        isCountdownPhase = true
        countdownBeat = .ready
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: Self.readyBeatDuration, repeats: false) { _ in
            countdownBeat = .go
            countdownTimer = Timer.scheduledTimer(withTimeInterval: Self.goBeatDuration, repeats: false) { _ in
                countdownTimer?.invalidate()
                countdownTimer = nil
                isCountdownPhase = false
                startWork()
            }
        }
    }
    
    private func startRepTimer() {
        isCountdownPhase = false
        isReadyPhase = false
        isTimerRunning = true
        isPaused = false
        
        if currentRep == 1 {
            repTimeRemaining = secondsPerRep
        }
        
        repTimer?.invalidate()
        repTimer = Timer.scheduledTimer(withTimeInterval: Self.repTimerTickInterval, repeats: true) { _ in
            if !isPaused && repTimeRemaining > 0 {
                repTimeRemaining -= Self.repTimerTickInterval
            } else if !isPaused && repTimeRemaining <= 0 {
                currentRep += 1
                repTimeRemaining = self.secondsPerRep
                
                if currentRep > currentSetReps {
                    completeSet()
                }
            }
        }
    }
    
    private func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            pauseAllWorkTimers()
        } else {
            resumeAfterPause()
        }
    }
    
    /// Stops active work when leaving the session UI / app; leaves button on Resume.
    private func pauseSessionBecauseLeftScreen() {
        let wasActivelyTiming = isTimerRunning
            || isResting
            || isCountdownPhase
            || (isWallSitPhase && !isReadyPhase)
            || repTimer != nil
            || wallSitTimer != nil
            || restTimer != nil
        
        pauseAllWorkTimers()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        
        // Don't resume into a half-finished Ready→Go beat — return to Ready.
        if isCountdownPhase {
            isCountdownPhase = false
            isReadyPhase = true
        }
        
        // Timed work was running: show Resume so one tap continues.
        if wasActivelyTiming {
            isPaused = true
        }
    }
    
    private func pauseAllWorkTimers() {
        restTimer?.invalidate()
        restTimer = nil
        repTimer?.invalidate()
        repTimer = nil
        wallSitTimer?.invalidate()
        wallSitTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func resumeAfterPause() {
        startElapsedTimer()
        
        if isResting {
            startRestTimer()
        } else if isWallSitPhase && !isReadyPhase && !isCountdownPhase {
            startWallSitTimer()
        } else if isTimerRunning {
            startRepTimer()
        }
        // Ready phase: user taps through Ready → Go; no timer to restart yet.
    }
    
    private func completeSet() {
        repTimer?.invalidate()
        repTimer = nil
        isTimerRunning = false
        let repsFromThisSet = max(0, currentSetReps - (resumeStartRepInSet - 1))
        completedRepsThisSession += repsFromThisSet
        resumeStartRepInSet = 1
        
        if currentSetIndex < totalSets - 1 {
            beginRestPeriod(wallSitBreak: false)
        } else {
            // All squat sets complete - check if leg workout needs wall sits
            if exercise.id.lowercased().contains("squat") || exercise.id.lowercased().contains("leg") {
                // Start wall sits
                startWallSits()
            } else {
                // Workout complete
                finishWorkout(earlyEnd: false)
            }
        }
    }
    
    // MARK: - Set/Rest Logic
    private func handleCompleteSet() {
        if currentSetIndex < totalSets - 1 {
            beginRestPeriod(wallSitBreak: false)
        } else {
            // All squat sets complete - check if leg workout needs wall sits
            if exercise.id.lowercased().contains("squat") || exercise.id.lowercased().contains("leg") {
                // Start wall sits
                startWallSits()
            } else {
                // Workout complete
                finishWorkout(earlyEnd: false)
            }
        }
    }
    
    // MARK: - Wall Sit Functions
    private func startWallSits() {
        isWallSitPhase = true
        currentWallSitSet = 0
        wallSitSegmentDuration = wallSitDuration
        wallSitSecondsRemaining = wallSitDuration
        isReadyPhase = true  // Show ready phase for first wall sit
        isTimerRunning = false  // Make sure rep timer is off
        repTimer?.invalidate()  // Stop any running rep timer
        repTimer = nil
    }
    
    private func startWallSitTimer() {
        isCountdownPhase = false
        isReadyPhase = false
        wallSitTimer?.invalidate()
        wallSitTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused && wallSitSecondsRemaining > 0 {
                wallSitSecondsRemaining -= 1
            } else if !isPaused && wallSitSecondsRemaining <= 0 {
                completeWallSitSet()
            }
        }
    }
    
    private func completeWallSitSet() {
        wallSitTimer?.invalidate()
        wallSitTimer = nil
        
        // Track wall sit time completed for this segment (may be short when resuming).
        let timeCompleted = max(0, wallSitSegmentDuration - wallSitSecondsRemaining)
        totalWallSitTimeThisWorkout += timeCompleted  // Accumulate for this workout
        workoutViewModel.updateWallSitTime(seconds: timeCompleted)
        
        currentWallSitSet += 1
        wallSitSegmentDuration = wallSitDuration
        
        if currentWallSitSet < totalWallSitSets {
            beginRestPeriod(wallSitBreak: true)
        } else {
            // All wall sits complete
            finishWorkout(earlyEnd: false)
        }
    }
    
    /// Reps finished fully + reps counted in the current set (if mid-set).
    private var repsCompletedTowardCredit: Int {
        var total = completedRepsThisSession
        let activelyCountingReps = isTimerRunning
            && !isResting
            && !isReadyPhase
            && !isCountdownPhase
            && !isWallSitPhase
        if activelyCountingReps {
            // resumeStartRepInSet accounts for reps already credited before Continue.
            total += max(0, currentRep - resumeStartRepInSet)
        }
        return total
    }
    
    /// Wall-sit seconds held in the current unfinished set (not yet credited).
    private var partialWallSitSecondsInProgress: Int {
        guard isWallSitPhase,
              !isReadyPhase,
              !isCountdownPhase,
              !isResting,
              wallSitSecondsRemaining < wallSitSegmentDuration else {
            return 0
        }
        return max(0, wallSitSegmentDuration - wallSitSecondsRemaining)
    }
    
    private var endWorkoutConfirmMessage: String {
        let reps = repsCompletedTowardCredit
        let wallPartial = partialWallSitSecondsInProgress
        let wallTotal = totalWallSitTimeThisWorkout + wallPartial
        if reps == 0 && wallTotal == 0 {
            return "You haven’t finished any reps yet. Ending now won’t count toward today’s goals."
        }
        var savedParts: [String] = []
        if reps > 0 {
            savedParts.append("\(reps) rep\(reps == 1 ? "" : "s")")
        }
        if wallTotal > 0 {
            savedParts.append("\(wallTotal)s of wall sit")
        }
        let saved = savedParts.joined(separator: " and ")
        return "We’ll save \(saved) toward today’s goals. To mark this workout Done, you’ll need to restart and finish the full set–rest session in one sitting — that’s where the stimulus comes from."
    }
    
    private func stopAllSessionTimers() {
        restTimer?.invalidate()
        restTimer = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        repTimer?.invalidate()
        repTimer = nil
        wallSitTimer?.invalidate()
        wallSitTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        isTimerRunning = false
    }
    
    private func creditPartialWallSitIfNeeded() {
        let partial = partialWallSitSecondsInProgress
        guard partial > 0 else { return }
        totalWallSitTimeThisWorkout += partial
        workoutViewModel.updateWallSitTime(seconds: partial)
        wallSitSegmentDuration = max(1, wallSitSecondsRemaining)
    }
    
    private func discardSessionWithoutCredit() {
        didFinalizeSession = true
        stopAllSessionTimers()
        workoutViewModel.clearSessionDraft(for: exercise.id)
        onWorkoutCompleted?()
    }
    
    /// Navigation leave without finishing — credit completed work; next Start is a full session.
    private func creditAbandonedSessionIfNeeded() {
        guard !didFinalizeSession, !showCompletionSheet else {
            pauseSessionBecauseLeftScreen()
            return
        }
        if showSessionSettings || showFitnessDisclaimer || showWarmup {
            pauseSessionBecauseLeftScreen()
            return
        }
        
        let earlyReps = repsCompletedTowardCredit
        let wallTowardCredit = totalWallSitTimeThisWorkout + partialWallSitSecondsInProgress
        if earlyReps <= 0 && wallTowardCredit <= 0 {
            didFinalizeSession = true
            stopAllSessionTimers()
            return
        }
        
        finishWorkout(
            earlyEnd: true,
            earlyRepsOverride: earlyReps,
            presentCompletionUI: false
        )
    }
    
    private func endWorkoutEarly() {
        showSessionSettings = false
        let earlyReps = repsCompletedTowardCredit
        let wallTowardCredit = totalWallSitTimeThisWorkout + partialWallSitSecondsInProgress
        
        if earlyReps <= 0 && wallTowardCredit <= 0 {
            discardSessionWithoutCredit()
            return
        }
        
        finishWorkout(
            earlyEnd: true,
            earlyRepsOverride: earlyReps,
            presentCompletionUI: true
        )
    }
    
    private func finishWorkout(
        earlyEnd: Bool,
        earlyRepsOverride: Int? = nil,
        presentCompletionUI: Bool = true
    ) {
        guard !didFinalizeSession else { return }
        didFinalizeSession = true
        
        let capturedEarlyReps = earlyRepsOverride ?? (earlyEnd ? repsCompletedTowardCredit : nil)
        if earlyEnd {
            creditPartialWallSitIfNeeded()
        }
        stopAllSessionTimers()
        
        let planReps = workoutPlanData?.totalReps ?? repGoal
        let priorLogged = workoutViewModel.repsLoggedToday(forExerciseId: exercise.id)
        
        let sessionReps: Int
        if earlyEnd {
            sessionReps = max(0, capturedEarlyReps ?? completedRepsThisSession)
        } else {
            sessionReps = max(completedRepsThisSession, planReps)
        }
        
        let hasWallCredit = isLegWorkout && totalWallSitTimeThisWorkout > 0
        if sessionReps <= 0 && !hasWallCredit && earlyEnd {
            // Reset finalize so discard can set it — already set; just exit cleanly
            workoutViewModel.clearSessionDraft(for: exercise.id)
            onWorkoutCompleted?()
            return
        }
        
        // Early quit: credit what they did. Full sitting: fill remaining daily room (avoid double-counting after a partial).
        let repsToLog: Int = {
            if earlyEnd { return sessionReps }
            let room = max(0, planReps - priorLogged)
            if room > 0 { return min(sessionReps, room) }
            return sessionReps
        }()
        
        if repsToLog > 0 || !earlyEnd {
            let workout = Workout(
                exercise: exercise.id,
                reps: max(repsToLog, 0),
                timestamp: Date(),
                timeSpent: elapsedSeconds,
                isFullSessionCompletion: !earlyEnd
            )
            workoutViewModel.workouts.insert(workout, at: 0)
            if workout.reps > 0 {
                let progressLabel = CoreWorkoutSupport.isCoreMoveId(exercise.id)
                    ? CoreWorkoutSupport.goalDisplayName
                    : exercise.name
                workoutViewModel.updateWeeklyProgress(for: progressLabel, reps: workout.reps)
            }
        }
        
        let fullPlanXP = calculateXP(repGoal: planReps)
        let adjustedXP: Int
        if earlyEnd, planReps > 0, repsToLog > 0, repsToLog < planReps {
            adjustedXP = max(5, Int((Double(fullPlanXP) * Double(repsToLog) / Double(planReps)).rounded()))
        } else if repsToLog == 0 && earlyEnd {
            adjustedXP = hasWallCredit ? 5 : 0
        } else if !earlyEnd {
            adjustedXP = fullPlanXP
        } else {
            adjustedXP = calculateXP(repGoal: max(repsToLog, 1))
        }
        
        finishedReps = repsToLog
        finishedXP = adjustedXP
        finishedWallSitTime = isLegWorkout ? totalWallSitTimeThisWorkout : nil
        finishedAsEarlyEnd = earlyEnd
        
        if adjustedXP > 0 {
            workoutViewModel.addXP(adjustedXP)
        }
        
        workoutViewModel.clearSessionDraft(for: exercise.id)
        
        if earlyEnd {
            earlyQuitHapticTick &+= 1
            WorkoutNotificationService.shared.scheduleEarlyQuitDebtNotification(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                leftoverReps: max(0, planReps - (priorLogged + repsToLog)),
                extraSetReps: 0,
                completedReps: repsToLog,
                delaySeconds: 8
            )
        }
        // Full-session success haptic plays on the completion screen.
        
        workoutViewModel.saveUserData()
        workoutViewModel.updateWorkoutNotifications()
        
        AppRestrictionService.shared.completeWorkoutRestriction()
        
        if presentCompletionUI {
            showCompletionSheet = true
        } else {
            onWorkoutCompleted?()
        }
    }
    
    private func startRestTimer() {
        restTimer?.invalidate()
        // Store if we're in wall sit phase before rest
        let wasInWallSitPhase = isWallSitPhase
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isPaused { return }
            
            if restSeconds > 1 {
                restSeconds -= 1
            } else if restSeconds > 0 {
                // Hit zero this tick — immediately start next work (no Continue button).
                restSeconds = 0
                restTimer?.invalidate()
                restTimer = nil
                finishRestAndBeginNextWork(wasInWallSitPhase: wasInWallSitPhase)
            }
        }
    }
    
    private func finishRestAndBeginNextWork(wasInWallSitPhase: Bool) {
        isResting = false
        isPaused = false
        
        if wasInWallSitPhase {
            isWallSitPhase = true
            isReadyPhase = false
            wallSitSegmentDuration = wallSitDuration
            wallSitSecondsRemaining = wallSitDuration
            isTimerRunning = false
            beginWallSitWithCountdown()
        } else if currentSetIndex < totalSets - 1 {
            currentSetIndex += 1
            currentRep = 1
            repTimeRemaining = secondsPerRep
            isReadyPhase = false
            beginSetWithCountdown()
        }
    }
    
    private func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        let wasInWallSitPhase = isWallSitPhase
        finishRestAndBeginNextWork(wasInWallSitPhase: wasInWallSitPhase)
    }
    
    private func startNextSet() {
        skipRest()
    }
    
    private func getSetBreakdown(_ totalReps: Int) -> [Int] {
        let breakdowns: [Int: [Int]] = [
            5: [1, 1, 1, 2],
            10: [4, 2, 1, 3],
            15: [2, 3, 4, 6],
            20: [3, 4, 5, 8],
            25: [6, 7, 4, 8],
            30: [5, 8, 7, 10],
            35: [6, 9, 8, 12],
            40: [7, 8, 9, 16],
            45: [8, 14, 10, 13],
            50: [12, 18, 8, 12]
        ]
        return breakdowns[totalReps] ?? []
    }
    
    private func calculateXP(repGoal: Int) -> Int {
        let xp: Int
        switch repGoal {
        case 5...10:
            xp = 10
        case 11...20:
            xp = 20
        case 21...30:
            xp = 30
        case 31...40:
            xp = 40
        case 41...50:
            xp = 50
        default:
            xp = 25
        }
        return xp
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Session UI helpers

private struct SessionSetProgressBar: View {
    let current: Int
    let total: Int
    let themeColor: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.customLabel.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [themeColor, themeColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * CGFloat(current) / CGFloat(max(total, 1))))
            }
        }
        .frame(height: 6)
    }
}

/// Circular progress ring (rep pace or rest countdown). `progress` is 0...1 remaining-style fill.
private struct RepPaceRing: View {
    var progress: CGFloat
    var lineWidth: CGFloat
    var themeColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.customLabel.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [themeColor.opacity(0.65), themeColor, themeColor.opacity(0.9)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Compact Warmup Sheet
private func compactWarmupSheet(exercise: Exercise, themeColor: Color, dismiss: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [themeColor, themeColor.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 4)
            .padding(.bottom, 12)
        
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Warm-up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.customLabel)
                    Text("Recommended")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeColor.opacity(0.14))
                        .clipShape(Capsule())
                }
                Text("Optional • ~1 minute • primes joints & muscles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 12)
        
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(warmupItems(for: exercise).enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeColor)
                            .frame(width: 22, height: 22)
                            .background(themeColor.opacity(0.15))
                            .clipShape(Circle())
                        Text(item)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.customLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: 148)
        
        VStack(spacing: 10) {
            Button(action: dismiss) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Ready — continue")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [themeColor, themeColor.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: themeColor.opacity(0.28), radius: 8, x: 0, y: 3)
            }
            Button("Skip for now", action: dismiss)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
        }
        .padding(.top, 14)
        .padding(.horizontal, 4)
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.customSecondaryBackground)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(themeColor.opacity(0.12), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 8)
}

private func warmupItems(for exercise: Exercise) -> [String] {
    let id = exercise.id.lowercased()
    if id.contains("push") {
        return [
            "Arm circles (10 reps)",
            "Arm swings front–back (10 reps)",
            "Wrist circles (10/side)",
            "Shoulder rolls (10 reps)"
        ]
    } else if id.contains("sit") || CoreWorkoutSupport.isCoreMoveId(id) {
        return [
            "Cat–Cow (10 reps)",
            "Hip flexor stretch (15s/side)",
            "Thoracic rotations (10/side)",
            "Torso twists (10/side)"
        ]
    } else if id.contains("squat") {
        return [
            "Bodyweight squats (10 reps)",
            "Ankle rocks (10/side)",
            "Hip circles (10/side)",
            "Leg swings front–back (10/side)"
        ]
    } else {
        return [
            "Easy jumping jacks (15 reps)",
            "Arm circles (10 reps)",
            "Hip circles (10/side)",
            "Gentle joint circles (10 reps)"
        ]
    }
}

#Preview {
    WorkoutSessionScreen(
        exercise: Exercise(
            id: "pushups",
            name: "Push-Ups",
            description: "Hands shoulder-width, body straight. Lower chest to ground, elbows at 45°. Push up explosively.",
            muscleGroups: ["Chest", "Shoulders", "Triceps", "Core"]
        ),
        repGoal: 25,
        selectedTab: .constant(0),
        workoutViewModel: WorkoutViewModel(),
        onWorkoutCompleted: {}
    )
} 
