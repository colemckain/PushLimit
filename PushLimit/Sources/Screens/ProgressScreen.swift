import SwiftUI

struct ProgressScreen: View {
    var body: some View {
        VStack {
            Text("Progress Screen")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Progress")
    }
}

#Preview {
    ProgressScreen()
} 