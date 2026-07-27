import SwiftUI

struct AppLockNotificationView: View {
    @ObservedObject var restrictionService = AppRestrictionService.shared
    
    var body: some View {
        if restrictionService.isRestrictionActive {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apps Locked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Complete your workout to unlock")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.customOrange, Color.customOrange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        AppLockNotificationView()
        Spacer()
    }
    .background(Color.customBackground)
}
