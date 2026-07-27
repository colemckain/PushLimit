//
//  PushLimitApp.swift
//  PushLimit
//
//  Created by Cole Mckain on 6/18/25.
//

import SwiftUI
import SwiftData

// MARK: - Status Bar Style Preference Key
struct StatusBarStyleKey: PreferenceKey {
    static var defaultValue: UIStatusBarStyle = .lightContent
    
    static func reduce(value: inout UIStatusBarStyle, nextValue: () -> UIStatusBarStyle) {
        value = nextValue()
    }
}

@main
struct PushLimitApp: App {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var showSplash = true

    init() {
        FirebaseBootstrap.configureIfNeeded()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreen {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                } else {
                    if !workoutViewModel.hasCompletedOnboarding || isFirstLaunch {
                        OnboardingContainerView(
                            workoutViewModel: workoutViewModel,
                            isFirstLaunch: $isFirstLaunch
                        )
                    } else {
                        MainTabView(workoutViewModel: workoutViewModel)
                    }
                }
            }
            .onAppear {
                FirebaseUserDataService.shared.attach(workoutViewModel)
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidResetAllData)) { _ in
                isFirstLaunch = true
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: isFirstLaunch) { oldValue, newValue in
            DebugLog.log("isFirstLaunch changed from \(oldValue) to \(newValue)")
        }
    }
}


