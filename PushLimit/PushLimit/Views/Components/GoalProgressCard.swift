import SwiftUI

struct GoalProgressCard: View {
    let goalProgress: GoalProgress
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with workout type and progress ring
            HStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                                    Circle()
                    .trim(from: 0, to: goalProgress.isGoalAchieved ? 1.0 : animatedProgress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(goalProgress.progressPercentage * 100))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.customLabel)
                        
                        Text("%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.customLabel)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goalProgress.workoutType)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.customLabel)
                    
                    Text(goalProgress.motivationalMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Progress Details
            VStack(spacing: 12) {
                // Goal and Completed
                HStack {
                    ProgressDetailItem(
                        label: "Goal",
                        value: "\(goalProgress.weeklyGoal)",
                        color: .customOrange
                    )
                    
                    Spacer()
                    
                    ProgressDetailItem(
                        label: "Completed",
                        value: "\(goalProgress.completed)",
                        color: .green
                    )
                    
                    Spacer()
                    
                    ProgressDetailItem(
                        label: "Remaining",
                        value: "\(goalProgress.remaining)",
                        color: goalProgress.remaining > 0 ? .red : .green
                    )
                }
                
                // Daily Target (if not goal achieved)
                if !goalProgress.isGoalAchieved && goalProgress.dailyTarget > 0 {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.customOrange)
                        
                        Text("Daily target to stay on track:")
                            .font(.system(size: 14))
                            .foregroundColor(.customLabel)
                        
                        Spacer()
                        
                        Text("\(goalProgress.dailyTarget) reps/day")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.customOrange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.customOrange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.customBackground)
        .cornerRadius(16)
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

struct ProgressDetailItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.customLabel)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 16) {
        GoalProgressCard(
            goalProgress: GoalProgress(
                workoutType: "Push-ups",
                weeklyGoal: 100,
                completed: 75,
                daysLeftInWeek: 3
            )
        )
        
        GoalProgressCard(
            goalProgress: GoalProgress(
                workoutType: "Core",
                weeklyGoal: 100,
                completed: 100,
                daysLeftInWeek: 3
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 