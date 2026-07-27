import SwiftUI

struct WelcomeScreen: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentSlide = 0
    
    private let totalSlides = 5
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.customBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main Content Area
                    TabView(selection: $currentSlide) {
                        // Slide 1: Header
                        headerSlide
                            .tag(0)
                        
                        // Slide 2: Main Features
                        mainFeaturesSlide
                            .tag(1)
                        
                        // Slide 3: Navigation Guide
                        navigationGuideSlide
                            .tag(2)
                        
                        // Slide 4: Workout Flow
                        workoutFlowSlide
                            .tag(3)
                        
                        // Slide 5: Progress Features
                        progressFeaturesSlide
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: 600)
                    .centerOnIPad(700)
                    
                    // Bottom Navigation Area
                    bottomNavigationArea
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Slide 1: Header
    private var headerSlide: some View {
        VStack(spacing: isIPad ? 40 : 32) {
            Spacer()
                .frame(height: isIPad ? 60 : 40)
            
            Image("flame")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isIPad ? 120 : 100, height: isIPad ? 120 : 100)
                .foregroundColor(.customOrange)
                .scaleEffect(currentSlide == 0 ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.3), value: currentSlide)
            
            VStack(spacing: isIPad ? 24 : 16) {
                Text("Welcome to PushLimit!")
                    .responsiveFont(.largeTitle, weight: .bold)
                    .foregroundColor(.customLabel)
                    .multilineTextAlignment(.center)
                
                Text("Your personal fitness companion")
                    .responsiveFont(.title3)
                    .foregroundColor(.customLabel)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .responsivePadding(.horizontal)
        .frame(maxWidth: 600)
        .centerOnIPad(700)
    }
    
    // MARK: - Slide 2: Main Features
    private var mainFeaturesSlide: some View {
        VStack(spacing: isIPad ? 24 : 20) {
            Spacer()
                .frame(height: isIPad ? 40 : 30)
            
            VStack(spacing: isIPad ? 12 : 8) {
                Text("What PushLimit Offers")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text("Everything you need for your fitness journey")
                    .font(.system(size: 16))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            // Compact Feature Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    CompactFeatureCard(
                        icon: "house.fill",
                        title: "Dashboard",
                        description: "Track streak & daily stats",
                        color: .customOrange
                    )
                    
                    CompactFeatureCard(
                        icon: "figure.run",
                        title: "Workouts",
                        description: "Quick exercise sessions",
                        color: .blue
                    )
                }
                
                HStack(spacing: 12) {
                    CompactFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress",
                        description: "Monitor achievements",
                        color: .green
                    )
                    
                    CompactFeatureCard(
                        icon: "person.fill",
                        title: "Profile",
                        description: "Customize experience",
                        color: .purple
                    )
                }
            }
            
            Spacer()
        }
        .responsivePadding(.horizontal)
        .frame(maxWidth: 600)
        .centerOnIPad(700)
    }
    
    // MARK: - Slide 3: Navigation Guide
    private var navigationGuideSlide: some View {
        VStack(spacing: isIPad ? 24 : 20) {
            Spacer()
                .frame(height: isIPad ? 40 : 30)
            
            VStack(spacing: isIPad ? 12 : 8) {
                Text("Navigation")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text("Easy access to all features")
                    .font(.system(size: 16))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            // Compact Navigation Cards
            VStack(spacing: 8) {
                CompactNavigationRow(
                    icon: "house",
                    title: "Home",
                    description: "Dashboard with stats and activity",
                    color: .customOrange
                )
                
                CompactNavigationRow(
                    icon: "figure.run",
                    title: "Workout",
                    description: "Start sessions and track progress",
                    color: .blue
                )
                
                CompactNavigationRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    description: "View achievements and history",
                    color: .green
                )
                
                CompactNavigationRow(
                    icon: "person",
                    title: "Profile",
                    description: "Settings and goal management",
                    color: .purple
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .customShadow()
            
            Spacer()
        }
        .responsivePadding(.horizontal)
        .frame(maxWidth: 600)
        .centerOnIPad(700)
    }
    
    // MARK: - Slide 4: Workout Flow
    private var workoutFlowSlide: some View {
        VStack(spacing: isIPad ? 24 : 20) {
            Spacer()
                .frame(height: isIPad ? 40 : 30)
            
            VStack(spacing: isIPad ? 12 : 8) {
                Text("How to Start a Workout")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text("Simple 3-step process to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            // Compact Workout Steps
            VStack(spacing: 8) {
                CompactWorkoutStepRow(
                    stepNumber: 1,
                    title: "Select Exercise",
                    description: "Push-Ups, Core, or Legs",
                    icon: "figure.strengthtraining.traditional"
                )
                
                CompactWorkoutStepRow(
                    stepNumber: 2,
                    title: "Follow Your Plan",
                    description: "Algorithm-generated targets",
                    icon: "target"
                )
                
                CompactWorkoutStepRow(
                    stepNumber: 3,
                    title: "Start Training",
                    description: "Guided reps with rest periods",
                    icon: "play.fill"
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .customShadow()
            
            Spacer()
        }
        .responsivePadding(.horizontal)
        .frame(maxWidth: 600)
        .centerOnIPad(700)
    }
    
    // MARK: - Slide 5: Progress Features
    private var progressFeaturesSlide: some View {
        VStack(spacing: isIPad ? 24 : 20) {
            Spacer()
                .frame(height: isIPad ? 40 : 30)
            
            VStack(spacing: isIPad ? 12 : 8) {
                Text("Track Your Progress")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text("Stay motivated with detailed insights")
                    .font(.system(size: 16))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            // Compact Progress Features
            VStack(spacing: 8) {
                CompactProgressFeatureRow(
                    icon: "chart.bar.fill",
                    title: "Weekly Goals",
                    description: "Track your weekly targets",
                    color: .customOrange
                )
                
                CompactProgressFeatureRow(
                    icon: "trophy.fill",
                    title: "Lifetime Stats",
                    description: "Total workouts and achievements",
                    color: .yellow
                )
                
                CompactProgressFeatureRow(
                    icon: "clock.fill",
                    title: "Activity History",
                    description: "Browse workout performance",
                    color: .blue
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .customShadow()
            
            Spacer()
        }
        .responsivePadding(.horizontal)
        .frame(maxWidth: 600)
        .centerOnIPad(700)
    }
    
    // MARK: - Bottom Navigation Area
    private var bottomNavigationArea: some View {
        VStack(spacing: isIPad ? 24 : 16) {
            // Navigation Dots
            HStack(spacing: 8) {
                ForEach(0..<totalSlides, id: \.self) { index in
                    Circle()
                        .fill(index == currentSlide ? Color.customOrange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentSlide ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentSlide)
                }
            }
            .padding(.top, isIPad ? 16 : 12)
            
            // Navigation Arrows and Buttons
            HStack {
                // Previous Arrow
                if currentSlide > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentSlide -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                            .foregroundColor(.customOrange)
                            .frame(width: isIPad ? 44 : 40, height: isIPad ? 44 : 40)
                            .background(Color.customOrange.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    Spacer()
                        .frame(width: isIPad ? 44 : 40)
                }
                
                Spacer()
                
                // Skip Button (always visible)
                Button(action: {
                    DebugLog.log("Skip button tapped")
                    isFirstLaunch = false
                    DebugLog.log("isFirstLaunch set to false")
                }) {
                    Text("Skip")
                        .responsiveFont(.body, weight: .medium)
                        .foregroundColor(.customLabel.opacity(0.7))
                        .padding(.horizontal, isIPad ? 20 : 16)
                        .padding(.vertical, isIPad ? 12 : 8)
                }
                
                Spacer()
                
                // Next Arrow or Get Started Button
                if currentSlide < totalSlides - 1 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentSlide += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                            .foregroundColor(.customOrange)
                            .frame(width: isIPad ? 44 : 40, height: isIPad ? 44 : 40)
                            .background(Color.customOrange.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    // Get Started Button (only on last slide)
                    Button(action: {
                        DebugLog.log("Get Started button tapped")
                        isFirstLaunch = false
                        DebugLog.log("isFirstLaunch set to false")
                    }) {
                        Text("Get Started")
                            .responsiveFont(.body, weight: .bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, isIPad ? 24 : 20)
                            .padding(.vertical, isIPad ? 12 : 10)
                            .background(Color.customOrange)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, isIPad ? 32 : 24)
            .padding(.bottom, isIPad ? 32 : 24)
        }
        .background(Color.customBackground)
    }
}

// MARK: - Compact Supporting Views

struct CompactFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .customShadow()
    }
}

struct CompactNavigationRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.customLabel)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct CompactWorkoutStepRow: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.customOrange)
                    .frame(width: 28, height: 28)
                
                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.customLabel)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.customOrange)
        }
        .padding(.vertical, 8)
    }
}

struct CompactProgressFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.customLabel)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.customSecondaryLabel)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WelcomeScreen(isFirstLaunch: .constant(true))
} 
