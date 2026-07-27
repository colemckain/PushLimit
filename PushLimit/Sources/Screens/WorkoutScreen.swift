import SwiftUI

struct WorkoutScreen: View {
    var body: some View {
        VStack {
            Text("Workout Screen")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Workout")
    }
}

#Preview {
    WorkoutScreen()
} 