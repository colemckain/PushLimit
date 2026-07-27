import SwiftUI

struct AppInfoScreen: View {
    @Environment(\.dismiss) private var dismiss
    let themeColor: Color
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image("flame")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text("Welcome to PushLimit")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.customLabel)
                        
                        Text("Your personal fitness companion")
                            .font(.system(size: 16))
                            .foregroundColor(.customSecondaryLabel)
                    }
                    .padding(.top, 20)
                    
                    // What PushLimit Does
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "sparkles", title: "What PushLimit Does", color: themeColor)
                        
                        Text("PushLimit helps you build strength and consistency through personalized workout plans. Track your progress, earn XP, level up, and push your limits every day.")
                            .font(.system(size: 15))
                            .foregroundColor(.customLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    
                    // Key Features
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "star.fill", title: "Key Features", color: themeColor)
                        
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "house.fill",
                                title: "Home Dashboard",
                                description: "View your daily workout recommendations, track your streak, and see your stats at a glance",
                                color: themeColor
                            )
                            
                            FeatureRow(
                                icon: "figure.run",
                                title: "Personalized Workouts",
                                description: "Follow your algorithm-generated workout plan with sets, reps, and rest periods tailored to you",
                                color: themeColor
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress Tracking",
                                description: "Monitor weekly goals, view lifetime statistics, and track your improvement over time",
                                color: themeColor
                            )
                            
                            FeatureRow(
                                icon: "trophy.fill",
                                title: "Level Up System",
                                description: "Earn XP from workouts, unlock new titles, and climb the ranks as you progress",
                                color: themeColor
                            )
                            
                            FeatureRow(
                                icon: "bell.fill",
                                title: "Daily Reminders",
                                description: "Discipline-focused nudges — 10 minutes at home beats another gym excuse you'll postpone",
                                color: themeColor
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // How to Use
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "play.circle.fill", title: "How to Use", color: themeColor)
                        
                        VStack(spacing: 12) {
                            StepRow(
                                number: 1,
                                title: "Check Your Daily Plan",
                                description: "View today's recommended workout on the Home or Workout screen",
                                color: themeColor
                            )
                            
                            StepRow(
                                number: 2,
                                title: "Start Your Workout",
                                description: "Select an exercise and follow the guided session with automatic rest timers",
                                color: themeColor
                            )
                            
                            StepRow(
                                number: 3,
                                title: "Track Progress",
                                description: "See your stats, weekly goals, and achievements on the Progress screen",
                                color: themeColor
                            )
                            
                            StepRow(
                                number: 4,
                                title: "Level Up",
                                description: "Earn XP with each workout to unlock new titles and features",
                                color: themeColor
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "lightbulb.fill", title: "Quick Tips", color: themeColor)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TipRow(text: "Workouts take just 10-15 minutes - perfect for any schedule")
                            TipRow(text: "Complete your daily plan to maximize XP gains")
                            TipRow(text: "Track your streak to build consistency")
                            TipRow(text: "Reach Level 3 to unlock theme color customization")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.customBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeColor)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.customLabel)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.customSecondaryBackground)
        .cornerRadius(12)
        .customShadow()
    }
}

struct StepRow: View {
    let number: Int
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.customSecondaryBackground)
        .cornerRadius(12)
        .customShadow()
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.customLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AppInfoScreen(themeColor: .customOrange)
}

