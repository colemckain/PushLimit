import SwiftUI

struct WorkoutSessionScreen: View {
    var body: some View {
        VStack {
            Text("Workout Session Screen")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Workout Session")
    }
}

#Preview {
    WorkoutSessionScreen()
} 