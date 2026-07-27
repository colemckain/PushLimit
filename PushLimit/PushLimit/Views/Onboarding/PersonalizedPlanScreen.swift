import SwiftUI

/// Informational onboarding step: user reviews their plan at their own pace (manual Continue).
struct PersonalizedPlanScreen: View {
    let workoutPlan: WorkoutPlan?
    let assessment: FitnessAssessment?
    let profile: UserProfile
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Header with fitness level badge
                VStack(spacing: 16) {
                    if let assessment = assessment {
                        ZStack {
                            Circle()
                                .fill(levelColor.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: assessment.fitnessLevel.icon)
                                .font(.system(size: 50))
                                .foregroundColor(levelColor)
                        }

                        VStack(spacing: 8) {
                            Text(assessment.fitnessLevel.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.customLabel)

                            Text(assessment.fitnessLevel.message)
                                .font(.system(size: 16))
                                .foregroundColor(.customSecondaryLabel)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.customOrange)

                        Text("Your Plan is Ready!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.customLabel)
                    }

                    Text("Take your time—scroll through your plan, then continue when you're ready.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                if let plan = workoutPlan {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.customOrange)
                                Text("Your Personalized Plan")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.customSecondaryLabel)
                            }

                            Text(plan.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.customLabel)

                            Text(plan.description)
                                .font(.system(size: 14))
                                .foregroundColor(.customSecondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.customOrange.opacity(0.1))
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.customOrange)
                                Text("Weekly Goals")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.customLabel)
                            }

                            VStack(spacing: 12) {
                                GoalRow(exercise: "Push-ups", count: plan.weeklyGoals.pushups)
                                GoalRow(exercise: "Core", count: plan.weeklyGoals.situps)
                                GoalRow(exercise: "Squats", count: plan.weeklyGoals.squats)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.customSecondaryBackground)
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.customOrange)
                                Text("Workout Schedule")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.customLabel)
                            }

                            HStack(spacing: 8) {
                                ForEach(1...7, id: \.self) { day in
                                    let isWorkoutDay = plan.dailyRecommendations.first(where: { $0.dayOfWeek == day })?.restDay == false

                                    VStack(spacing: 4) {
                                        Text(dayName(day))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(isWorkoutDay ? .customOrange : .customSecondaryLabel)

                                        Circle()
                                            .fill(isWorkoutDay ? Color.customOrange : Color.gray.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            Text("\(plan.workoutDaysPerWeek) workout days • \(7 - plan.workoutDaysPerWeek) rest days")
                                .font(.system(size: 14))
                                .foregroundColor(.customSecondaryLabel)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.customSecondaryBackground)
                        .cornerRadius(16)

                        if let assessment = assessment {
                            VStack(spacing: 12) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 24))
                                    .foregroundColor(.customOrange.opacity(0.5))

                                Text(WorkoutPlanGenerator.generateMotivationalMessage(for: assessment))
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.customLabel)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)

                                Image(systemName: "quote.closing")
                                    .font(.system(size: 24))
                                    .foregroundColor(.customOrange.opacity(0.5))
                            }
                            .padding(20)
                            .background(Color.customOrange.opacity(0.05))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
                    .frame(height: 20)
            }
            .onboardingScrollBottomInset()
        }
        .background(Color.customBackground)
        .onboardingForwardAction(step: 8, action: onContinue)
    }

    private var levelColor: Color {
        guard let assessment = assessment else { return .customOrange }

        switch assessment.fitnessLevel {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .elite: return .purple
        }
    }

    private func dayName(_ day: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[day - 1]
    }
}

// MARK: - Goal Row
struct GoalRow: View {
    let exercise: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: exerciseIcon)
                .font(.system(size: 20))
                .foregroundColor(.customOrange)
                .frame(width: 28)

            Text(exercise)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.customLabel)

            Spacer()

            Text("\(count) reps")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.customOrange)
        }
        .padding(.vertical, 8)
    }

    private var exerciseIcon: String {
        switch exercise {
        case "Push-ups": return "figure.strengthtraining.traditional"
        case "Sit-ups", "Core": return "figure.core.training"
        case "Squats": return "figure.flexibility"
        default: return "figure.walk"
        }
    }
}

#Preview {
    PersonalizedPlanScreen(
        workoutPlan: WorkoutPlan.sampleBeginnerPlan,
        assessment: FitnessAssessment(maxPushups: 15, maxSitups: 20, maxSquats: 25),
        profile: UserProfile(),
        onContinue: {}
    )
}
