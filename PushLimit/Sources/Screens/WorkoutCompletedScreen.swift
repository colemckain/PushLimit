import SwiftUI

struct WorkoutCompletedScreen: View {
    var body: some View {
        VStack {
            Text("Workout Completed Screen")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Completed")
    }
}

#Preview {
    WorkoutCompletedScreen()
}