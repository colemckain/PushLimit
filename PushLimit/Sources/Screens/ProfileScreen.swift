import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        VStack {
            Text("Profile Screen")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileScreen()
}