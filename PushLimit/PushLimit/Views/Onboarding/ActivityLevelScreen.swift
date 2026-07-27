import SwiftUI

struct ActivityLevelScreen: View {
    @Binding var selectedLevel: UserProfile.ActivityLevel
    var themeColor: Color = .customOrange
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 60))
                        .foregroundColor(themeColor)
                    
                    Text("Current Activity Level")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)
                    
                    Text("How would you describe your current fitness routine?")
                        .font(.system(size: 16))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Activity Level Options
                VStack(spacing: 16) {
                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: selectedLevel == level,
                            accentColor: themeColor,
                            action: {
                                selectedLevel = level
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .background(Color.customBackground)
    }
}

// MARK: - Activity Level Card
struct ActivityLevelCard: View {
    let level: UserProfile.ActivityLevel
    let isSelected: Bool
    var accentColor: Color = .customOrange
    var displayDays: [Int]? = nil
    let action: () -> Void
    
    private var daysToShow: [Int] {
        displayDays ?? level.workoutDays
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: level.icon)
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? accentColor : .customLabel)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(level.rawValue)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? accentColor : .customLabel)
                        
                        Text(level.description)
                            .font(.system(size: 14))
                            .foregroundColor(.customSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                    }
                }
                
                // Workout days indicator
                HStack(spacing: 4) {
                    Text("\(daysToShow.count) workout days per week:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                    
                    ForEach(daysToShow, id: \.self) { day in
                        Text(dayShortName(day))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? accentColor : .customLabel)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? accentColor.opacity(0.1) : Color.customSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dayShortName(_ day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day - 1]
    }
}

#Preview {
    ActivityLevelScreen(
        selectedLevel: .constant(.beginner),
        onContinue: {}
    )
}

