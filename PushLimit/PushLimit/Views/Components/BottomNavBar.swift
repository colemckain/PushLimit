import SwiftUI

struct BottomNavBar: View {
    let currentRoute: String
    let themeColor: Color
    let onTabSelected: (String) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            NavItem(
                title: "Home",
                icon: "house",
                isActive: currentRoute == "Home",
                themeColor: themeColor,
                action: { onTabSelected("Home") }
            )
            
            NavItem(
                title: "Workout",
                icon: "figure.run",
                isActive: currentRoute == "Workout",
                themeColor: themeColor,
                action: { onTabSelected("Workout") }
            )
            
            NavItem(
                title: "Progress",
                icon: "chart.line.uptrend.xyaxis",
                isActive: currentRoute == "Progress",
                themeColor: themeColor,
                action: { onTabSelected("Progress") }
            )
            
            NavItem(
                title: "Profile",
                icon: "person",
                isActive: currentRoute == "Profile",
                themeColor: themeColor,
                action: { onTabSelected("Profile") }
            )
        }
        .background(Color.customBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
        .centerOnIPad(600) // Center navigation on iPad
    }
}

struct NavItem: View {
    let title: String
    let icon: String
    let isActive: Bool
    let themeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: isIPad ? 8 : 4) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 24 : 20))
                    .foregroundColor(isActive ? themeColor : .customLabel)
                    .symbolEffect(.bounce, value: isActive)
                
                Text(title)
                    .font(isIPad ? .system(size: 12, weight: .medium) : .caption)
                    .foregroundColor(isActive ? themeColor : .customLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isIPad ? 16 : 8)
            .overlay(
                Rectangle()
                    .frame(height: isIPad ? 3 : 2)
                    .foregroundColor(isActive ? themeColor : .clear),
                alignment: .top
            )
        }
        .buttonStyle(.pressableSubtle)
    }
}

#Preview {
    BottomNavBar(currentRoute: "Home", themeColor: .customOrange) { _ in }
}
