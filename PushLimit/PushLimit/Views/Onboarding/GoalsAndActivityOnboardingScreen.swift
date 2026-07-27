import SwiftUI

/// Single step: fitness goal + activity level (replaces two separate onboarding screens).
struct GoalsAndActivityOnboardingScreen: View {
    @Binding var selectedGoal: UserProfile.FitnessGoal
    @Binding var selectedLevel: UserProfile.ActivityLevel
    @Binding var selectedWorkoutDays: [Int]
    let themeColor: Color
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasChosenGoal = false
    @State private var hasChosenActivity = false

    private enum SectionID {
        static let header = "goals_header"
        static let goal = "goals_goal"
        static let activity = "goals_activity"
        static let workoutDays = "goals_workout_days"
    }

    private var requiredWorkoutDayCount: Int {
        selectedLevel.workoutDays.count
    }

    private var hasValidWorkoutDays: Bool {
        Set(selectedWorkoutDays).count == requiredWorkoutDayCount
    }

    private var canContinue: Bool {
        hasChosenGoal && hasChosenActivity && hasValidWorkoutDays
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 12)

                    VStack(spacing: 10) {
                        Text("Your starting point")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)

                        Text("Pick a goal and activity level, then continue with the arrow below.")
                            .font(.system(size: 15))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .id(SectionID.header)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Primary goal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.customSecondaryLabel)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                                CompactGoalOptionCard(
                                    goal: goal,
                                    isSelected: selectedGoal == goal,
                                    accentColor: themeColor,
                                    action: {
                                        selectedGoal = goal
                                        hasChosenGoal = true
                                        onboardingScrollTo(
                                            SectionID.activity,
                                            proxy: proxy,
                                            reduceMotion: reduceMotion,
                                            anchor: .top
                                        )
                                    }
                                )
                            }
                        }
                        .padding(14)
                        .background(Color.customSecondaryBackground)
                        .cornerRadius(16)
                        .customShadow()
                    }
                    .padding(.horizontal, 20)
                    .id(SectionID.goal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How active are you today?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.customSecondaryLabel)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                                ActivityLevelCard(
                                    level: level,
                                    isSelected: selectedLevel == level,
                                    accentColor: themeColor,
                                    displayDays: selectedLevel == level ? selectedWorkoutDays : level.workoutDays,
                                    action: {
                                        selectedLevel = level
                                        if selectedWorkoutDays.count != level.workoutDays.count {
                                            selectedWorkoutDays = level.workoutDays
                                        }
                                        if hasChosenGoal {
                                            hasChosenActivity = true
                                            onboardingScrollTo(
                                                SectionID.workoutDays,
                                                proxy: proxy,
                                                reduceMotion: reduceMotion,
                                                anchor: .top
                                            )
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .id(SectionID.activity)

                    if hasChosenActivity {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Choose your workout days")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.customSecondaryLabel)
                                .padding(.horizontal, 4)

                            WorkoutDaysPicker(
                                selectedDays: $selectedWorkoutDays,
                                requiredCount: requiredWorkoutDayCount,
                                accentColor: themeColor
                            )
                            .padding(14)
                            .background(Color.customSecondaryBackground)
                            .cornerRadius(16)
                            .customShadow()
                        }
                        .padding(.horizontal, 20)
                        .id(SectionID.workoutDays)
                    }

                    Spacer().frame(height: 20)
                }
                .onboardingScrollBottomInset()
            }
            .background(Color.customBackground)
            .onboardingForwardAction(step: 3, enabled: canContinue, action: onContinue)
        }
    }
}

#Preview {
    GoalsAndActivityOnboardingScreen(
        selectedGoal: .constant(.maintainHealth),
        selectedLevel: .constant(.beginner),
        selectedWorkoutDays: .constant([1, 3, 5]),
        themeColor: .customOrange,
        onContinue: {}
    )
}
