import SwiftUI

struct GoalProgressRow: View {
    let goalProgress: GoalProgress
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with workout type and percentage
            HStack {
                Text(goalProgress.workoutType)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.customLabel)
                
                Spacer()
                
                Text("\(Int(goalProgress.progressPercentage * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(progressColor)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    Rectangle()
                        .fill(progressColor)
                        .frame(
                            width: (goalProgress.isGoalAchieved ? 1.0 : animatedProgress) * geometry.size.width,
                            height: 8
                        )
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                }
            }
            .frame(height: 8)
            
            // Progress Details
            HStack {
                Text(formatProgress(completed: goalProgress.completed, goal: goalProgress.weeklyGoal))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customOrange)
                
                Spacer()
                
                if !goalProgress.isGoalAchieved && goalProgress.remaining > 0 {
                    Text(formatRemaining(remaining: goalProgress.remaining))
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                } else if goalProgress.isGoalAchieved {
                    Text("Goal achieved! 🎉")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
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
    
    private func formatProgress(completed: Int, goal: Int) -> String {
        if goalProgress.workoutType == "Wall Sits" {
            return "\(formatTime(completed))/\(formatTime(goal))"
        } else {
            return "\(completed)/\(goal)"
        }
    }
    
    private func formatRemaining(remaining: Int) -> String {
        if goalProgress.workoutType == "Wall Sits" {
            return "\(formatTime(remaining)) remaining"
        } else {
            return "\(remaining) remaining"
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GoalProgressRow(
            goalProgress: GoalProgress(
                workoutType: "Push-ups",
                weeklyGoal: 100,
                completed: 75,
                daysLeftInWeek: 3
            )
        )
        
        GoalProgressRow(
            goalProgress: GoalProgress(
                workoutType: "Core",
                weeklyGoal: 100,
                completed: 100,
                daysLeftInWeek: 3
            )
        )
        
        GoalProgressRow(
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