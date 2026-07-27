import SwiftUI

struct HomeScreen: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Home Screen")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeScreen()
} 