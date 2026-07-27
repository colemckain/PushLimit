import SwiftUI

struct GoalQuickViewCard: View {
    let goalProgress: GoalProgress
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: isIPad ? 12 : 8) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: isIPad ? 6 : 4)
                    .frame(width: isIPad ? 60 : 40, height: isIPad ? 60 : 40)
                
                Circle()
                    .trim(from: 0, to: goalProgress.isGoalAchieved ? 1.0 : animatedProgress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: isIPad ? 6 : 4, lineCap: .round))
                    .frame(width: isIPad ? 60 : 40, height: isIPad ? 60 : 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                
                Text("\(Int(goalProgress.progressPercentage * 100))")
                    .font(.system(size: isIPad ? 14 : 10, weight: .bold))
                    .foregroundColor(.customLabel)
            }
            
            // Workout Type
            Text(goalProgress.workoutType)
                .responsiveFont(.subheadline, weight: .medium)
                .foregroundColor(.customLabel)
                .fixedSize(horizontal: false, vertical: true)
            
            // Progress Numbers
            VStack(spacing: isIPad ? 4 : 2) {
                Text("\(goalProgress.completed)/\(goalProgress.weeklyGoal)")
                    .responsiveFont(.caption, weight: .semibold)
                    .foregroundColor(.customOrange)
                
                if !goalProgress.isGoalAchieved && goalProgress.remaining > 0 {
                    Text("\(goalProgress.remaining) left")
                        .responsiveFont(.caption2)
                        .foregroundColor(.red)
                } else if goalProgress.isGoalAchieved {
                    Text("Complete!")
                        .responsiveFont(.caption2, weight: .medium)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(isIPad ? 16 : 8)
        .background(Color.customBackground)
        .responsiveCornerRadius(12)
        .customShadow()
        .onAppear {
            animatedProgress = goalProgress.progressPercentage
        }
        .onChange(of: goalProgress.progressPercentage) { oldValue, newValue in
            animatedProgress = newValue
        }
    }
    
    private var progressColor: Color {
        if goalProgress.isGoalAchieved {
            return .green
        } else if goalProgress.progressPercentage >= 0.8 {
            return .orange
        } else if goalProgress.progressPercentage >= 0.6 {
            return .yellow
        } else {
            return .customOrange
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        GoalQuickViewCard(
            goalProgress: GoalProgress(
                workoutType: "Push-ups",
                weeklyGoal: 100,
                completed: 75,
                daysLeftInWeek: 3
            )
        )
        
        GoalQuickViewCard(
            goalProgress: GoalProgress(
                workoutType: "Core",
                weeklyGoal: 100,
                completed: 100,
                daysLeftInWeek: 3
            )
        )
        
        GoalQuickViewCard(
            goalProgress: GoalProgress(
                workoutType: "Squats",
                weeklyGoal: 100,
                completed: 25,
                daysLeftInWeek: 3
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 