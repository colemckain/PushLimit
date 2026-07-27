import SwiftUI

struct XPProgressRing: View {
    let levelInfo: LevelInfo
    
    private var ringSize: CGFloat { isIPad ? 120 : 80 }
    private var lineWidth: CGFloat { isIPad ? 12 : 8 }
    
    var body: some View {
        VStack(spacing: isIPad ? 12 : 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
                    .frame(width: ringSize, height: ringSize)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: levelInfo.progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: levelInfo.progress)
                    .scaleEffect(levelInfo.progress > 0 ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.3), value: levelInfo.progress)
                
                // Center content
                VStack(spacing: isIPad ? 4 : 2) {
                    Text("\(levelInfo.level)")
                        .responsiveFont(.title, weight: .bold)
                        .foregroundColor(.customLabel)
                    
                    Text("LVL")
                        .responsiveFont(.caption2)
                        .foregroundColor(.customLabel)
                }
            }
            
            VStack(spacing: isIPad ? 6 : 4) {
                Text(levelInfo.title)
                    .responsiveFont(.caption, weight: .semibold)
                    .foregroundColor(.customLabel)
                
                Text("\(levelInfo.xpInCurrentLevel)/\(levelInfo.xpToNextLevel) XP")
                    .responsiveFont(.caption2)
                    .foregroundColor(.customLabel)
            }
        }
    }
}

#Preview {
    XPProgressRing(
        levelInfo: LevelInfo(
            level: 5,
            title: "Intermediate",
            progress: 0.7,
            xpInCurrentLevel: 700,
            xpToNextLevel: 1000
        )
    )
    .padding()
} 