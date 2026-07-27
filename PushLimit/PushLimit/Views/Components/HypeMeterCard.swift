import SwiftUI

struct HypeMeterCard: View {
    let workoutCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
            Text("Hype Meter")
                .responsiveFont(.subheadline, weight: .bold)
                .foregroundColor(.customLabel)
            
            HStack(spacing: isIPad ? 6 : 4) {
                ForEach(1...5, id: \.self) { num in
                    Rectangle()
                        .fill(hypeColor(for: num))
                        .frame(height: isIPad ? 32 : 24)
                        .responsiveCornerRadius(4)
                }
            }
            
            Text(hypeText)
                .responsiveFont(.subheadline)
                .foregroundColor(.customLabel)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(isIPad ? 24 : 16)
        .background(Color.customBackground)
        .responsiveCornerRadius(12)
        .customShadow()
    }
    
    private func hypeColor(for bar: Int) -> Color {
        if workoutCount >= bar {
            if bar == 1 {
                return .red
            } else if bar <= 3 {
                return .orange
            } else {
                return .green
            }
        }
        return Color.gray.opacity(0.3)
    }
    
    private var hypeText: String {
        if workoutCount == 0 {
            return "No workouts today"
        } else if workoutCount == 1 {
            return "Just getting started!"
        } else if workoutCount <= 3 {
            return "Keep pushing!"
        } else {
            return "You're on fire!"
        }
    }
}

#Preview {
    HypeMeterCard(workoutCount: 3)
        .padding()
} 