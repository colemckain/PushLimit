import SwiftUI

struct FitnessGoalsScreen: View {
    @Binding var selectedGoal: UserProfile.FitnessGoal
    var themeColor: Color = .customOrange
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)
                
                // Compact Header
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(themeColor)
                    
                    VStack(spacing: 8) {
                        Text("What's Your Goal?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.center)
                        
                        Text("We'll tailor your workout plan to help you achieve it")
                            .font(.system(size: 15))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Compact Goal Options
                VStack(spacing: 8) {
                    ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                        CompactGoalOptionCard(
                            goal: goal,
                            isSelected: selectedGoal == goal,
                            accentColor: themeColor,
                            action: {
                                selectedGoal = goal
                            }
                        )
                    }
                }
                .padding(16)
                .background(Color.customSecondaryBackground)
                .cornerRadius(16)
                .customShadow()
                .padding(.horizontal, 20)
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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

// MARK: - Compact Goal Option Card
struct CompactGoalOptionCard: View {
    let goal: UserProfile.FitnessGoal
    let isSelected: Bool
    var accentColor: Color = .customOrange
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? accentColor : .customLabel)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customLabel)
                    
                    Text(goal.description)
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? accentColor.opacity(0.1) : Color.customBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FitnessGoalsScreen(
        selectedGoal: .constant(.maintainHealth),
        onContinue: {}
    )
}

