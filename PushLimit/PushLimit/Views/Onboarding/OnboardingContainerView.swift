import SwiftUI
import UIKit

struct OnboardingContainerView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Binding var isFirstLaunch: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var currentStep = 0
    @State private var userProfile = UserProfile()
    @State private var userName: String = ""
    @State private var age: String = ""
    @State private var fitnessAssessment: FitnessAssessment?
    @State private var workoutPlan: WorkoutPlan?
    @State private var isAuthenticated = false
    @State private var didRestoreDraft = false
    @State private var feedbackTone: FeedbackTone = .supportive
    @StateObject private var navigationBridge = OnboardingNavigationBridge()
    
    private let totalSteps = 11
    
    var body: some View {
        ZStack {
            Color.customBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Phased progress — hidden on welcome for a cleaner first impression
                if currentStep > 0 {
                    phasedProgressBar
                }
                
                // Content Area — programmatic steps only (no TabView swipe past consent gates)
                ZStack {
                    stepContent
                        .id(currentStep)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: currentStep)
                
                // Bottom Navigation
                bottomNavigation
            }
        }
        .navigationBarHidden(true)
        .environmentObject(navigationBridge)
        .environment(\.onboardingActiveStep, currentStep)
        .onAppear {
            if !didRestoreDraft {
                didRestoreDraft = true
                restoreOnboardingDraftIfAvailable()
            }
        }
    }
    
    // MARK: - Step content (no swipe — only setOnboardingStep advances)

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            OnboardingWelcomeScreen(themeColor: workoutViewModel.themeColor)
        case 1:
            LegalConsentOnboardingScreen(
                themeColor: workoutViewModel.themeColor,
                onContinue: {
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 2:
            PersonalInfoScreen(
                userName: $userName,
                age: $age,
                selectedGender: $userProfile.gender,
                onContinue: {
                    handlePersonalInfo()
                    setOnboardingStep(currentStep + 1)
                },
                themeColor: workoutViewModel.themeColor
            )
        case 3:
            GoalsAndActivityOnboardingScreen(
                selectedGoal: $userProfile.fitnessGoal,
                selectedLevel: $userProfile.activityLevel,
                selectedWorkoutDays: Binding(
                    get: { userProfile.effectiveWorkoutDays },
                    set: { userProfile.preferredWorkoutDays = $0.sorted() }
                ),
                themeColor: workoutViewModel.themeColor,
                onContinue: {
                    userProfile.preferredWorkoutDays = userProfile.effectiveWorkoutDays
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 4:
            SleepScheduleOnboardingScreen(
                schedule: sleepScheduleBinding,
                themeColor: workoutViewModel.themeColor,
                onContinue: {
                    userProfile.sleepSchedule = sleepScheduleBinding.wrappedValue
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 5:
            FeedbackToneOnboardingScreen(
                selectedTone: $feedbackTone,
                themeColor: workoutViewModel.themeColor,
                onContinue: {
                    workoutViewModel.updateFeedbackTone(feedbackTone)
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 6:
            LegRunLocationConsentOnboardingScreen(
                themeColor: workoutViewModel.themeColor,
                onContinue: {
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 7:
            FitnessAssessmentScreen(
                onComplete: { assessment in
                    fitnessAssessment = assessment
                    generateWorkoutPlan()
                    setOnboardingStep(currentStep + 1)
                },
                onSkipForNow: {
                    fitnessAssessment = FitnessAssessment(maxPushups: 0, maxSitups: 0, maxSquats: 0, skipped: true)
                    generateWorkoutPlan()
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 8:
            PersonalizedPlanScreen(
                workoutPlan: workoutPlan,
                assessment: fitnessAssessment,
                profile: userProfile,
                onContinue: {
                    setOnboardingStep(currentStep + 1)
                }
            )
        case 9:
            AuthenticationScreen(
                isAuthenticated: $isAuthenticated,
                themeColor: workoutViewModel.themeColor,
                onContinue: {
                    setOnboardingStep(currentStep + 1)
                },
                onContinueWithoutAccount: {
                    setOnboardingStep(currentStep + 1)
                },
                headline: "Save your plan",
                subtitle: "Sign in to sync your plan and workout history across devices. Or continue on this phone only—everything stays local until you sign in.",
                headerSystemImage: "icloud.and.arrow.up.fill",
                secondaryCtaTitle: "Continue on this device"
            )
        default:
            onboardingFinaleView
        }
    }

    /// Steps with in-screen auth / custom actions only (no pinned forward).
    private var hidesBottomForwardButton: Bool {
        currentStep == 9
    }

    /// Steps that use the pinned bottom-right forward control instead of in-scroll Continue.
    private var usesPinnedBottomForward: Bool {
        (1...8).contains(currentStep)
    }

    private var sleepScheduleBinding: Binding<SleepSchedule> {
        Binding(
            get: { userProfile.sleepSchedule ?? .recommendedDefault },
            set: { userProfile.sleepSchedule = $0 }
        )
    }
    
    private func setOnboardingStep(_ step: Int, playHaptic: Bool = true) {
        let allowed = allowedOnboardingStep(for: step)
        if reduceMotion {
            currentStep = allowed
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentStep = allowed
            }
        }
        if playHaptic {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        // Only persist draft after legal consent — avoids storing PII without acknowledgment.
        if LegalConsentStore.hasAcceptedRequiredLegalConsent {
            persistOnboardingDraft()
        } else {
            clearOnboardingDraft()
        }
    }

    /// Clamps navigation so gated consent steps cannot be skipped.
    private func allowedOnboardingStep(for requested: Int) -> Int {
        var step = max(0, min(totalSteps - 1, requested))

        // Steps 2+ collect / build on profile PII — require Terms + fitness disclaimer first.
        if step >= 2 && !LegalConsentStore.hasAcceptedRequiredLegalConsent {
            step = 1
        }

        // Steps 7+ assume location disclosure for optional leg runs was acknowledged.
        if step >= 7 && !LegalConsentStore.hasAcceptedLegRunLocationDisclosure {
            step = 6
        }

        return step
    }
    
    private func persistOnboardingDraft() {
        let draft = OnboardingDraft(
            currentStep: currentStep,
            userName: userName,
            age: age,
            userProfile: userProfile,
            feedbackTone: feedbackTone,
            isAuthenticated: isAuthenticated,
            fitnessAssessment: fitnessAssessment,
            workoutPlan: workoutPlan
        )
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.UserDefaultsKeys.onboardingDraft)
    }
    
    private func restoreOnboardingDraftIfAvailable() {
        guard isFirstLaunch else { return }
        UserDefaults.standard.removeObject(forKey: "onboardingDraftV1")
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.onboardingDraft) else { return }
        guard let draft = try? JSONDecoder().decode(OnboardingDraft.self, from: data) else { return }
        guard draft.currentStep >= 0, draft.currentStep < totalSteps else { return }

        // If draft somehow advanced without consent, bounce back to the missing gate.
        if !LegalConsentStore.hasAcceptedRequiredLegalConsent {
            clearOnboardingDraft()
            currentStep = min(draft.currentStep, 1)
            return
        }

        userName = draft.userName
        age = draft.age
        userProfile = draft.userProfile
        feedbackTone = draft.feedbackTone
        isAuthenticated = draft.isAuthenticated
        fitnessAssessment = draft.fitnessAssessment
        workoutPlan = draft.workoutPlan
        currentStep = allowedOnboardingStep(for: draft.currentStep)
    }
    
    private func clearOnboardingDraft() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.onboardingDraft)
    }
    
    // MARK: - Phased progress (3 segments)
    /// 0 = About you (steps 0–6), 1 = Your plan (7–8), 2 = You're set (9–10)
    private var onboardingPhaseIndex: Int {
        switch currentStep {
        case 0...6: return 0
        case 7...8: return 1
        default: return 2
        }
    }
    
    private func phaseSegmentFill(phase: Int) -> CGFloat {
        switch phase {
        case 0:
            if currentStep <= 6 { return CGFloat(currentStep + 1) / 7.0 }
            return 1
        case 1:
            if currentStep < 7 { return 0 }
            if currentStep <= 8 { return CGFloat(currentStep - 7 + 1) / 2.0 }
            return 1
        case 2:
            if currentStep < 9 { return 0 }
            return CGFloat(currentStep - 9 + 1) / 2.0
        default:
            return 0
        }
    }
    
    private var phasedProgressBar: some View {
        let titles = ["About you", "Your plan", "You're set"]
        let theme = workoutViewModel.themeColor
        
        return VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { phase in
                    GeometryReader { geo in
                        let fill = phaseSegmentFill(phase: phase)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.gray.opacity(0.22))
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(phase <= onboardingPhaseIndex ? theme : theme.opacity(0.35))
                                .frame(width: max(4, geo.size.width * fill))
                                .animation(.easeInOut(duration: 0.28), value: currentStep)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { phase in
                    Text(titles[phase])
                        .font(.system(size: 11, weight: onboardingPhaseIndex == phase ? .bold : .medium))
                        .foregroundColor(onboardingPhaseIndex == phase ? theme : .customSecondaryLabel)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            
            Text("Stored on device; sign in syncs plan & workout history.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Finale (compact features + confirmation)
    private var onboardingFinaleView: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer().frame(height: 12)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(workoutViewModel.themeColor)
                
                VStack(spacing: 8) {
                    Text("You're ready")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)
                    
                    Text("Your first week is set. Jump in from Home or Workouts whenever you're ready.")
                        .font(.system(size: 16))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                if let plan = workoutPlan {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your plan")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.customSecondaryLabel)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.customLabel)
                                Text("\(plan.workoutDaysPerWeek) workout days · \(plan.progressionPhase)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.customSecondaryLabel)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(workoutViewModel.themeColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Inside PushLimit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 10) {
                        OnboardingFinaleFeatureRow(
                            icon: "text.bubble.fill",
                            text: "Coaching style: supportive or discipline mode — your choice",
                            themeColor: workoutViewModel.themeColor
                        )
                        OnboardingFinaleFeatureRow(
                            icon: "moon.zzz.fill",
                            text: "Sleep habit: recovery window on Home to fuel your training",
                            themeColor: workoutViewModel.themeColor
                        )
                        OnboardingFinaleFeatureRow(
                            icon: "house.fill",
                            text: "Home: streak, today's picks, and quick stats",
                            themeColor: workoutViewModel.themeColor
                        )
                        OnboardingFinaleFeatureRow(
                            icon: "figure.run",
                            text: "Leg runs: optional GPS run on leg day — tracks in the background until you pause or finish",
                            themeColor: workoutViewModel.themeColor
                        )
                        OnboardingFinaleFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            text: "Progress: weekly goals and history",
                            themeColor: workoutViewModel.themeColor
                        )
                        OnboardingFinaleFeatureRow(
                            icon: "trophy.fill",
                            text: "Levels: XP, titles, and achievements",
                            themeColor: workoutViewModel.themeColor
                        )
                    }
                    .padding(14)
                    .background(Color.customSecondaryBackground)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 28)
            }
        }
        .background(Color.customBackground)
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack {
                // Back Button
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    Button(action: {
                        // Let the active step consume Back first (e.g. prior fitness test exercise).
                        if navigationBridge.performBack() { return }
                        setOnboardingStep(currentStep - 1, playHaptic: false)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                            .frame(width: 44, height: 44)
                            .background(workoutViewModel.themeColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    Spacer()
                        .frame(width: 44)
                }
                
                Spacer()
                
                // Next/Continue Button
                if currentStep == 0 {
                    Button(action: {
                        setOnboardingStep(1)
                    }) {
                        HStack(spacing: 8) {
                            Text("Build my plan")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: workoutViewModel.themeColor.opacity(0.32), radius: 8, x: 0, y: 4)
                    }
                } else if currentStep == totalSteps - 1 {
                    Button(action: completeOnboarding) {
                        Text("Let's Go!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(workoutViewModel.themeColor)
                            .clipShape(Capsule())
                    }
                } else if usesPinnedBottomForward {
                    OnboardingBottomForwardButton(
                        enabled: currentStep == 1 ? navigationBridge.forwardEnabled : true,
                        themeColor: workoutViewModel.themeColor
                    ) {
                        navigationBridge.performForward()
                    }
                } else if hidesBottomForwardButton {
                    Spacer()
                        .frame(width: 44)
                } else {
                    // Show Next button/arrow for intermediate steps
                    Button(action: {
                        setOnboardingStep(currentStep + 1)
                    }) {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(workoutViewModel.themeColor)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(workoutViewModel.themeColor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(workoutViewModel.themeColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.customBackground)
    }
    
    // MARK: - Helper Functions
    
    private func handlePersonalInfo() {
        guard LegalConsentStore.hasAcceptedRequiredLegalConsent else {
            setOnboardingStep(1, playHaptic: false)
            return
        }

        // Update view model with user name
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            DebugLog.log("📝 handlePersonalInfo called with name: '\(trimmedName)'")
            workoutViewModel.userName = trimmedName
            workoutViewModel.saveUserData() // Explicitly save the data
            
            // Verify it was saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let saved = SecureUserDataStore.string(forKey: "userName") ?? "NOT FOUND"
                DebugLog.log("✅ Verification - UserDefaults now contains: '\(saved)'")
                DebugLog.log("✅ Verification - workoutViewModel.userName is: '\(self.workoutViewModel.userName)'")
            }
        } else {
            DebugLog.log("⚠️ handlePersonalInfo called but userName is empty or whitespace")
        }
        
        // Update profile with age (optional; cleared when field empty)
        let ageTrim = age.trimmingCharacters(in: .whitespacesAndNewlines)
        if ageTrim.isEmpty {
            userProfile.age = nil
        } else if let ageValue = Int(ageTrim), (13...120).contains(ageValue) {
            userProfile.age = ageValue
        }
    }
    
    private func generateWorkoutPlan() {
        // Generate the workout plan using the WorkoutPlanGenerator
        let plan = WorkoutPlanGenerator.generateWorkoutPlan(
            profile: userProfile,
            assessment: fitnessAssessment
        )
        workoutPlan = plan
    }
    
    private func completeOnboarding() {
        guard LegalConsentStore.hasAcceptedRequiredLegalConsent else {
            setOnboardingStep(1, playHaptic: false)
            return
        }
        guard LegalConsentStore.hasAcceptedLegRunLocationDisclosure else {
            setOnboardingStep(6, playHaptic: false)
            return
        }

        // Ensure userName is saved one more time before completing onboarding
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            workoutViewModel.userName = trimmedName
            DebugLog.log("💾 Final save of userName before completing onboarding: '\(trimmedName)'")
        }
        
        // Save all data to view model
        workoutViewModel.completeOnboarding(
            profile: userProfile,
            assessment: fitnessAssessment,
            plan: workoutPlan
        )
        workoutViewModel.updateFeedbackTone(feedbackTone)
        
        // Close onboarding
        clearOnboardingDraft()
        isFirstLaunch = false
    }
}

// MARK: - Finale feature row

private struct OnboardingFinaleFeatureRow: View {
    let icon: String
    let text: String
    let themeColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeColor)
                .frame(width: 26, alignment: .center)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.customLabel)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Onboarding draft (crash / multitask recovery)

private struct OnboardingDraft: Codable {
    var currentStep: Int
    var userName: String
    var age: String
    var userProfile: UserProfile
    var feedbackTone: FeedbackTone
    var isAuthenticated: Bool
    var fitnessAssessment: FitnessAssessment?
    var workoutPlan: WorkoutPlan?

    init(
        currentStep: Int,
        userName: String,
        age: String,
        userProfile: UserProfile,
        feedbackTone: FeedbackTone = .supportive,
        isAuthenticated: Bool,
        fitnessAssessment: FitnessAssessment?,
        workoutPlan: WorkoutPlan?
    ) {
        self.currentStep = currentStep
        self.userName = userName
        self.age = age
        self.userProfile = userProfile
        self.feedbackTone = feedbackTone
        self.isAuthenticated = isAuthenticated
        self.fitnessAssessment = fitnessAssessment
        self.workoutPlan = workoutPlan
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentStep = try c.decode(Int.self, forKey: .currentStep)
        userName = try c.decode(String.self, forKey: .userName)
        age = try c.decode(String.self, forKey: .age)
        userProfile = try c.decode(UserProfile.self, forKey: .userProfile)
        feedbackTone = try c.decodeIfPresent(FeedbackTone.self, forKey: .feedbackTone) ?? .supportive
        isAuthenticated = try c.decode(Bool.self, forKey: .isAuthenticated)
        fitnessAssessment = try c.decodeIfPresent(FitnessAssessment.self, forKey: .fitnessAssessment)
        workoutPlan = try c.decodeIfPresent(WorkoutPlan.self, forKey: .workoutPlan)
    }
}

#Preview {
    OnboardingContainerView(
        workoutViewModel: WorkoutViewModel(),
        isFirstLaunch: .constant(true)
    )
}

