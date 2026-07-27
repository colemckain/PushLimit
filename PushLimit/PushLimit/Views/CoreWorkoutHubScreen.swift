import SwiftUI

/// Hub for today's 5-move core circuit (replaces a single sit-up session).
struct CoreWorkoutHubScreen: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Binding var selectedTab: Int
    var onCoreDayCompleted: (() -> Void)?
    
    /// Optional override (e.g. rest-day challenge). nil = use today's plan / assessment.
    var dailyTotalOverride: Int? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionExercise: Exercise?
    @State private var sessionReps: Int?
    @State private var navigateToSession = false
    @State private var showDayCompleteBanner = false
    
    private var dailyTotal: Int {
        if let dailyTotalOverride { return CoreWorkoutSupport.normalizedDailyTotal(from: dailyTotalOverride).dailyTotal }
        if let plan = workoutViewModel.getTodaysRecommendation(),
           let core = plan.exercises.first(where: { CoreWorkoutSupport.isCorePlanExercise($0.exercise) }) {
            return CoreWorkoutSupport.normalizedDailyTotal(from: core.totalReps).dailyTotal
        }
        let maxSitups = workoutViewModel.fitnessAssessment?.maxSitups
        let base = CoreWorkoutSupport.dailyTotal(
            maxSitups: maxSitups,
            activityLevel: workoutViewModel.userProfile.activityLevel
        )
        return CoreWorkoutSupport.normalizedDailyTotal(from: base).dailyTotal
    }
    
    private var repsPerMove: Int {
        CoreWorkoutSupport.repsPerMove(dailyTotal: dailyTotal)
    }
    
    private var todaysWorkouts: [Workout] {
        workoutViewModel.getTodaysWorkouts()
    }
    
    private var completedCoreReps: Int {
        min(dailyTotal, CoreWorkoutSupport.totalCoreRepsToday(in: todaysWorkouts))
    }
    
    private var isDayComplete: Bool {
        workoutViewModel.isCoreWorkoutCompletedToday()
    }
    
    private let tabBarClearance: CGFloat = 52
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                
                progressCard
                
                Text("Each move is one full sitting · \(repsPerMove) reps")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
                
                VStack(spacing: 12) {
                    ForEach(Array(CoreWorkoutSupport.moves.enumerated()), id: \.element.id) { index, move in
                        moveRow(move: move, index: index + 1)
                    }
                }
                
                if isDayComplete {
                    dayCompleteFooter
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, tabBarClearance + 24)
        }
        .background(Color.customBackground.ignoresSafeArea())
        .navigationTitle("Core Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.customSecondaryLabel)
            }
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
                        sessionExercise = nil
                        sessionReps = nil
                        if isDayComplete {
                            showDayCompleteBanner = true
                            onCoreDayCompleted?()
                        }
                    }
                )
            }
        }
        .onAppear {
            if isDayComplete {
                showDayCompleteBanner = true
            }
        }
        .onChange(of: workoutViewModel.workouts.count) { _, _ in
            if isDayComplete {
                showDayCompleteBanner = true
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today’s core circuit")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.customLabel)
            Text("\(dailyTotal) total reps · \(CoreWorkoutSupport.moveCount) moves · \(repsPerMove) each")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Session progress")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
                Spacer()
                Text("\(completedCoreReps)/\(dailyTotal)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(workoutViewModel.themeColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.customSecondaryLabel.opacity(0.15))
                    Capsule()
                        .fill(workoutViewModel.themeColor)
                        .frame(width: geo.size.width * progressFraction)
                }
            }
            .frame(height: 8)
            
            Text(isDayComplete
                 ? "Core day complete — nice work."
                 : "\(movesRemainingCount) move\(movesRemainingCount == 1 ? "" : "s") left")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
        }
        .padding(16)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var progressFraction: CGFloat {
        guard dailyTotal > 0 else { return 0 }
        return CGFloat(completedCoreReps) / CGFloat(dailyTotal)
    }
    
    private var movesRemainingCount: Int {
        CoreWorkoutSupport.moves.filter {
            !workoutViewModel.hasFullSessionCompletionToday(forExerciseId: $0.id)
        }.count
    }
    
    private func moveRow(move: CoreWorkoutSupport.Move, index: Int) -> some View {
        let doneReps = CoreWorkoutSupport.repsCompletedToday(in: todaysWorkouts, moveId: move.id)
        let complete = workoutViewModel.hasFullSessionCompletionToday(forExerciseId: move.id)
        let partialLogged = !complete && doneReps > 0
        
        return Button {
            guard !complete else { return }
            startMove(move)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(complete
                              ? Color.green.opacity(0.2)
                              : workoutViewModel.themeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    if complete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("\(index)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(workoutViewModel.themeColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(move.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.customLabel)
                    Text(move.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(complete ? "\(repsPerMove)/\(repsPerMove)" : "0/\(repsPerMove)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(complete ? .green : workoutViewModel.themeColor)
                    if complete {
                        Text("Done")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    } else if partialLogged {
                        Text("Restart")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                    } else {
                        Text("Start")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.customSecondaryLabel)
                    }
                }
            }
            .padding(14)
            .background(Color.customSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        complete ? Color.green.opacity(0.35) : workoutViewModel.themeColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .opacity(complete ? 0.85 : 1)
        }
        .buttonStyle(.plain)
        .disabled(complete)
    }
    
    private var dayCompleteFooter: some View {
        VStack(spacing: 12) {
            Text("You’ve hit today’s core target.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.customLabel)
                .frame(maxWidth: .infinity)
            
            Button {
                onCoreDayCompleted?()
                dismiss()
            } label: {
                Text("Back to workouts")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(workoutViewModel.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.top, 8)
    }
    
    private func startMove(_ move: CoreWorkoutSupport.Move) {
        // Always a full one-sitting quota — early quits credit reps but do not resume mid-move.
        let repsForSession = repsPerMove
        
        let restrictionService = AppRestrictionService.shared
        if restrictionService.isAuthorized {
            restrictionService.startWorkoutRestriction()
        }
        
        sessionExercise = CoreWorkoutSupport.exercise(for: move)
        sessionReps = repsForSession
        navigateToSession = true
    }
}
