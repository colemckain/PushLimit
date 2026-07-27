import SwiftUI
import UserNotifications

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var tabHapticTick = 0
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    init(workoutViewModel: WorkoutViewModel = WorkoutViewModel()) {
        self.workoutViewModel = workoutViewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeScreen(workoutViewModel: workoutViewModel, selectedTab: $selectedTab)
                }
                .tag(0)
                
                NavigationStack {
                    WorkoutScreen(workoutViewModel: workoutViewModel, selectedTab: $selectedTab)
                }
                .tag(1)
                
                NavigationStack {
                    ProgressScreen(workoutViewModel: workoutViewModel)
                }
                .tag(2)
                
                NavigationStack {
                    ProfileScreen(workoutViewModel: workoutViewModel)
                }
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom bottom navigation
            BottomNavBar(currentRoute: getCurrentRoute(), themeColor: workoutViewModel.themeColor) { route in
                let nextTab: Int? = {
                    switch route {
                    case "Home": return 0
                    case "Workout": return 1
                    case "Progress": return 2
                    case "Profile": return 3
                    default: return nil
                    }
                }()
                guard let nextTab, nextTab != selectedTab else { return }
                tabHapticTick &+= 1
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    selectedTab = nextTab
                }
            }
        }
        .background(Color.customBackground)
        .centerOnIPad(800) // Center content on iPad with max width
        .sensoryFeedback(.selection, trigger: tabHapticTick)
        .onAppear {
            // Request notification permissions and setup notifications when app becomes active
            Task {
                await setupWorkoutNotifications()
            }
        }
        .overlay(
            // Level Up Achievement Overlay
            Group {
                if workoutViewModel.showLevelUpAchievement,
                   let levelUpInfo = workoutViewModel.levelUpInfo {
                    LevelUpAchievementView(
                        newLevel: levelUpInfo.newLevel,
                        newTitle: levelUpInfo.newTitle,
                        oldLevel: levelUpInfo.oldLevel,
                        oldTitle: levelUpInfo.oldTitle,
                        themeColor: workoutViewModel.themeColor,
                        onDismiss: {
                            workoutViewModel.showLevelUpAchievement = false
                            workoutViewModel.levelUpInfo = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1000)
                }
            }
        )
    }
    
    private func getCurrentRoute() -> String {
        switch selectedTab {
        case 0:
            return "Home"
        case 1:
            return "Workout"
        case 2:
            return "Progress"
        case 3:
            return "Profile"
        default:
            return "Home"
        }
    }
    
    private func setupWorkoutNotifications() async {
        let notificationService = WorkoutNotificationService.shared
        
        // Request authorization if not already authorized
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = await notificationService.requestAuthorization()
        }

        workoutViewModel.updateWorkoutNotifications()
    }
}

#Preview {
    MainTabView()
}
