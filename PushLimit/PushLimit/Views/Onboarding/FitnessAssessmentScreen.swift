import SwiftUI

struct FitnessAssessmentScreen: View {
    let onComplete: (FitnessAssessment) -> Void
    /// When set (e.g. onboarding), offer skip with clear expectations.
    var onSkipForNow: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var navigationBridge: OnboardingNavigationBridge
    @Environment(\.onboardingActiveStep) private var activeStep

    @State private var currentExerciseIndex = 0
    @State private var pushupCount: Double = 0
    @State private var situpCount: Double = 0
    @State private var squatCount: Double = 0
    /// Highest exercise index the user has reached (0–3; 3 = completion).
    @State private var farthestExerciseIndex = 0
    /// After jumping back from the summary to edit, Continue returns to the summary.
    @State private var returnToCompletionAfterEdit = false

    private let exercises = ["Push-ups", "Sit-ups", "Squats"]
    private let onboardingStepTag = 7

    private var isOnCompletion: Bool {
        currentExerciseIndex >= exercises.count
    }

    private var canGoBackWithinAssessment: Bool {
        currentExerciseIndex > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            if isOnCompletion {
                completionView
            } else {
                assessmentView
            }
        }
        .background(Color.customBackground)
        .onAppear { syncBackHandler() }
        .onChange(of: currentExerciseIndex) { _, _ in syncBackHandler() }
        .onChange(of: activeStep) { _, _ in syncBackHandler() }
        .onDisappear {
            if activeStep == onboardingStepTag || activeStep == -1 {
                navigationBridge.clearBackHandler()
            }
        }
    }

    // MARK: - Assessment View
    private var assessmentView: some View {
        VStack(spacing: 16) {
            progressDots
                .padding(.top, 20)

            VStack(spacing: 8) {
                Image(systemName: exerciseIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.customOrange)

                Text("Fitness Assessment")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.customLabel)

                Text(assessmentPrompt)
                    .font(.system(size: 16))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                Text("Exercise \(currentExerciseIndex + 1) of \(exercises.count) · tap a previous dot to edit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }

            VStack(alignment: .leading, spacing: 8) {
                CompactInstructionRow(icon: "1.circle.fill", text: "Do max reps with proper form")
                CompactInstructionRow(icon: "2.circle.fill", text: "Quality over quantity")
                CompactInstructionRow(icon: "3.circle.fill", text: "Stop when form breaks down")
            }
            .padding(12)
            .background(Color.customSecondaryBackground)
            .cornerRadius(12)
            .customShadow()
            .padding(.horizontal, 20)

            VStack(spacing: 20) {
                Text("\(Int(currentCount))")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.customOrange)
                    .frame(minWidth: 100)

                Text("reps")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)

                VStack(spacing: 8) {
                    Slider(value: currentCountBinding, in: 0...100, step: 1)
                        .tint(.customOrange)
                        .padding(.horizontal, 30)

                    HStack {
                        Text("0")
                            .font(.system(size: 12))
                            .foregroundColor(.customSecondaryLabel)
                        Spacer()
                        Text("100")
                            .font(.system(size: 12))
                            .foregroundColor(.customSecondaryLabel)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)

            if let onSkip = onSkipForNow {
                VStack(spacing: 10) {
                    Text("Without your max reps, weekly targets are less precise.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Button(action: onSkip) {
                        Text("Skip for now (you can retake in Profile)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.customOrange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.customSecondaryBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.customOrange.opacity(0.45), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.bottom, 16)
        .onboardingForwardAction(step: onboardingStepTag, action: nextExercise)
    }

    // MARK: - Progress dots (tappable to revisit)

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<exercises.count, id: \.self) { index in
                Button {
                    goToExercise(index)
                } label: {
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: index == currentExerciseIndex && !isOnCompletion ? 12 : 10,
                               height: index == currentExerciseIndex && !isOnCompletion ? 12 : 10)
                }
                .buttonStyle(.plain)
                .disabled(index > farthestExerciseIndex)
                .accessibilityLabel("\(exercises[index])")
                .accessibilityHint(index <= farthestExerciseIndex ? "Double tap to edit" : "Not reached yet")
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentExerciseIndex || (isOnCompletion && index <= farthestExerciseIndex) {
            return .green
        }
        if index == currentExerciseIndex && !isOnCompletion {
            return .customOrange
        }
        return Color.gray.opacity(0.3)
    }

    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            progressDots

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.customOrange)

            VStack(spacing: 8) {
                Text("Assessment Complete!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.customLabel)

                Text("Tap a result to edit, then continue with the arrow below.")
                    .font(.system(size: 14))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 8) {
                Button { goToExercise(0) } label: {
                    CompactAssessmentResultRow(exercise: "Push-ups", count: Int(pushupCount), showsEditHint: true)
                }
                .buttonStyle(.plain)

                Button { goToExercise(1) } label: {
                    CompactAssessmentResultRow(exercise: "Core", count: Int(situpCount), showsEditHint: true)
                }
                .buttonStyle(.plain)

                Button { goToExercise(2) } label: {
                    CompactAssessmentResultRow(exercise: "Squats", count: Int(squatCount), showsEditHint: true)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color.customSecondaryBackground)
            .cornerRadius(12)
            .customShadow()
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.bottom, 16)
        .onboardingForwardAction(step: onboardingStepTag, action: finishAssessment)
    }

    private var currentCount: Double {
        switch currentExerciseIndex {
        case 0: return pushupCount
        case 1: return situpCount
        case 2: return squatCount
        default: return 0
        }
    }

    private var currentCountBinding: Binding<Double> {
        switch currentExerciseIndex {
        case 0: return $pushupCount
        case 1: return $situpCount
        case 2: return $squatCount
        default: return .constant(0)
        }
    }

    private var exerciseIcon: String {
        guard currentExerciseIndex < exercises.count else { return "figure.walk" }
        switch exercises[currentExerciseIndex] {
        case "Push-ups": return "figure.strengthtraining.traditional"
        case "Sit-ups": return "figure.core.training"
        case "Squats": return "figure.flexibility"
        default: return "figure.walk"
        }
    }
    
    private var assessmentPrompt: String {
        guard currentExerciseIndex < exercises.count else {
            return "How many reps can you do?"
        }
        if exercises[currentExerciseIndex] == "Sit-ups" {
            return "How many sit-ups can you do? We’ll use this to size your Core Workout."
        }
        return "How many \(exercises[currentExerciseIndex].lowercased()) can you do?"
    }

    private func nextExercise() {
        // Editing from the summary → return there after adjusting this exercise.
        if returnToCompletionAfterEdit, farthestExerciseIndex >= exercises.count {
            returnToCompletionAfterEdit = false
            if reduceMotion {
                currentExerciseIndex = exercises.count
            } else {
                withAnimation(.easeInOut(duration: 0.28)) {
                    currentExerciseIndex = exercises.count
                }
            }
            return
        }

        let next = currentExerciseIndex + 1
        farthestExerciseIndex = max(farthestExerciseIndex, next)
        if reduceMotion {
            currentExerciseIndex = next
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentExerciseIndex = next
            }
        }
    }

    private func previousExercise() {
        guard canGoBackWithinAssessment else { return }
        if isOnCompletion {
            returnToCompletionAfterEdit = false
            goToExercise(exercises.count - 1)
            return
        }
        goToExercise(currentExerciseIndex - 1)
    }

    private func goToExercise(_ index: Int) {
        guard index >= 0, index <= farthestExerciseIndex, index < exercises.count else { return }
        returnToCompletionAfterEdit = isOnCompletion || farthestExerciseIndex >= exercises.count
        if reduceMotion {
            currentExerciseIndex = index
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentExerciseIndex = index
            }
        }
    }

    private func syncBackHandler() {
        // Only own Back while this onboarding step is active (or when used outside onboarding).
        guard activeStep == onboardingStepTag || activeStep == -1 else {
            navigationBridge.clearBackHandler()
            return
        }

        if canGoBackWithinAssessment {
            navigationBridge.setBackHandler {
                previousExercise()
            }
        } else {
            navigationBridge.clearBackHandler()
        }
    }

    private func finishAssessment() {
        let assessment = FitnessAssessment(
            maxPushups: Int(pushupCount),
            maxSitups: Int(situpCount),
            maxSquats: Int(squatCount),
            skipped: false
        )
        onComplete(assessment)
    }
}

// MARK: - Compact Instruction Row
struct CompactInstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.customOrange)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.customLabel)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Compact Assessment Result Row
struct CompactAssessmentResultRow: View {
    let exercise: String
    let count: Int
    var showsEditHint: Bool = false

    var body: some View {
        HStack {
            Text(exercise)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.customLabel)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.customOrange)

            if showsEditHint {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.customBackground.opacity(0.65))
        .cornerRadius(8)
    }
}

#Preview {
    FitnessAssessmentScreen(
        onComplete: { _ in },
        onSkipForNow: {}
    )
    .environmentObject(OnboardingNavigationBridge())
}
