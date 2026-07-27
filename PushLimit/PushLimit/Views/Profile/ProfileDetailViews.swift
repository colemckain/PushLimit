import SwiftUI
import UIKit

// MARK: - Account & sync

struct ProfileAccountDetailView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject private var accountAuth = FirebaseUserDataService.shared

    @State private var showingAccountSignIn = false
    @State private var signInSheetAuthenticated = false
    @State private var showingSignOutConfirm = false
    @State private var isEmailVerificationBusy = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sectionGap) {
                ProfileDetailHeader(title: "Account")
                syncSection
                accountSection
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
        }
        .background(Color.customBackground)
        .profileDetailNavigation()
        .sheet(isPresented: $showingAccountSignIn) {
            NavigationView {
                AuthenticationScreen(
                    isAuthenticated: $signInSheetAuthenticated,
                    themeColor: workoutViewModel.themeColor,
                    onContinue: {
                        showingAccountSignIn = false
                        signInSheetAuthenticated = false
                    }
                )
                .navigationTitle("Account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAccountSignIn = false }
                            .foregroundColor(workoutViewModel.themeColor)
                    }
                }
            }
        }
        .alert("Sign out?", isPresented: $showingSignOutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                accountAuth.signOut()
            }
        } message: {
            Text("You'll stay signed out of cloud backup on this device. Your local workouts, plan, and profile are kept here. Sign in again anytime to sync.")
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "arrow.triangle.2.circlepath.circle.fill", title: "Backup & sync")

            VStack(alignment: .leading, spacing: 10) {
                statusPillRow
                Text(syncConfidenceLine)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(syncConfidenceColor)
                if accountAuth.shouldShowBackupPermissionIssue {
                    Text("Publish Firestore rules for users/{userId}, then tap Retry.")
                        .font(.system(size: 12))
                        .foregroundColor(.customSecondaryLabel)
                }
                if let syncError = accountAuth.lastSyncError, !accountAuth.shouldShowBackupPermissionIssue {
                    Text(syncError)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                if FirebaseUserDataService.isCloudSyncAvailable,
                   accountAuth.isSignedIn,
                   accountAuth.lastSyncError != nil || accountAuth.shouldShowBackupPermissionIssue {
                    Button {
                        Task { await accountAuth.retryCloudSync() }
                    } label: {
                        Text("Retry backup")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(workoutViewModel.themeColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(workoutViewModel.themeColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .appInsetPanel()
        }
        .appSectionContainer()
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "person.crop.circle.fill", title: "Account info")

            if !FirebaseUserDataService.isCloudSyncAvailable {
                Text("Cloud sync isn’t available in this build.")
                    .font(.system(size: 13))
                    .foregroundColor(.customSecondaryLabel)
            } else if accountAuth.isSignedIn {
                signedInCard
            } else {
                signInPrompt
            }
        }
        .appSectionContainer()
    }

    private var signedInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow(icon: "envelope.fill", label: "Email", value: accountAuth.email ?? "—")
            detailRow(icon: "person.fill", label: "Name", value: workoutViewModel.userName)
            if let age = workoutViewModel.userProfile.age {
                detailRow(icon: "calendar", label: "Age", value: "\(age)")
            }
            detailRow(icon: "figure.stand", label: "Gender", value: workoutViewModel.userProfile.gender.rawValue)
            detailRow(icon: "target", label: "Fitness goal", value: workoutViewModel.userProfile.fitnessGoal.rawValue)
            detailRow(icon: "flame.fill", label: "Activity", value: workoutViewModel.userProfile.activityLevel.rawValue)

            if accountAuth.needsEmailVerification {
                emailVerificationBlock
            }

            if accountAuth.isSyncing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.9)
                    Text("Syncing…")
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryLabel)
                }
            } else if let msg = accountAuth.lastSyncMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(.customSecondaryLabel)
            }

            Button { showingSignOutConfirm = true } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign out")
                    Spacer()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .padding(14)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.customBackground.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var signInPrompt: some View {
        Button { showingAccountSignIn = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(workoutViewModel.themeColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign in")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text("Back up and sync across devices.")
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryLabel)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.customSecondaryLabel)
            }
            .padding(14)
            .background(Color.customBackground.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var emailVerificationBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verify your email to enable cloud backup.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
            HStack(spacing: 10) {
                Button {
                    Task {
                        isEmailVerificationBusy = true
                        defer { isEmailVerificationBusy = false }
                        await accountAuth.sendVerificationEmail()
                    }
                } label: {
                    Text(isEmailVerificationBusy ? "Sending…" : "Resend")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(workoutViewModel.themeColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(isEmailVerificationBusy)

                Button {
                    Task {
                        isEmailVerificationBusy = true
                        defer { isEmailVerificationBusy = false }
                        _ = await accountAuth.refreshEmailVerificationStatus()
                    }
                } label: {
                    Text("I've verified")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .background(workoutViewModel.themeColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(isEmailVerificationBusy)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusPillRow: some View {
        HStack(spacing: 8) {
            statusPill(
                icon: accountAuth.isSignedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.exclamationmark",
                text: accountAuth.isSignedIn ? "Signed in" : "Local only",
                tint: accountAuth.isSignedIn ? .green : .orange
            )
            statusPill(
                icon: accountAuth.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.icloud.fill",
                text: accountAuth.isSyncing ? "Syncing" : "Sync ready",
                tint: accountAuth.isSyncing ? workoutViewModel.themeColor : .blue
            )
            Spacer(minLength: 0)
        }
    }

    private var syncConfidenceLine: String {
        if !FirebaseUserDataService.isCloudSyncAvailable {
            return "Cloud backup isn’t available in this build."
        }
        if !accountAuth.isSignedIn { return "Not connected — local only" }
        if accountAuth.shouldShowBackupPermissionIssue { return "Permission issue — backup disabled" }
        if let date = accountAuth.lastSuccessfulSyncAt {
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .abbreviated
            return "Last synced \(f.localizedString(for: date, relativeTo: Date()))"
        }
        if accountAuth.isSyncing { return "Syncing your profile…" }
        return "Connected — waiting for first backup"
    }

    private var syncConfidenceColor: Color {
        accountAuth.shouldShowBackupPermissionIssue ? .red : .customSecondaryLabel
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(workoutViewModel.themeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
            }
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.customLabel)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private func statusPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.14))
        .clipShape(Capsule())
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(workoutViewModel.themeColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.customLabel)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Plan & preferences

struct ProfilePlanDetailView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.openURL) private var openURL

    @State private var showingProfileEditor = false
    @State private var showingWorkoutDaysEditor = false
    @State private var showingSleepEditor = false
    @State private var showingThemeColorPicker = false
    @State private var showingFeedbackToneEditor = false
    @State private var navigateToAssessment = false
    @State private var devStreakDays = "7"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sectionGap) {
                ProfileDetailHeader(title: "Plan & preferences")
                weeklyGoalsSection
                preferencesSection
                devToolsSection
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
        }
        .background(Color.customBackground)
        .profileDetailNavigation()
        .background {
            NavigationLink(
                destination: FitnessAssessmentScreen(
                    onComplete: { assessment in
                        workoutViewModel.saveFitnessAssessment(assessment)
                        let newPlan = WorkoutPlanGenerator.generateWorkoutPlan(
                            profile: workoutViewModel.userProfile,
                            assessment: assessment
                        )
                        workoutViewModel.saveWorkoutPlan(newPlan)
                        navigateToAssessment = false
                    }
                )
                .environmentObject(OnboardingNavigationBridge()),
                isActive: $navigateToAssessment
            ) { EmptyView() }
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileGoalEditorView(
                profile: workoutViewModel.userProfile,
                themeColor: workoutViewModel.themeColor,
                onSave: { updated in
                    var profile = updated
                    profile.hasCompletedOnboarding = true
                    profile.onboardingCompletedDate = workoutViewModel.userProfile.onboardingCompletedDate ?? Date()
                    workoutViewModel.updateUserProfile(profile)
                    let newPlan = WorkoutPlanGenerator.generateWorkoutPlan(
                        profile: profile,
                        assessment: workoutViewModel.fitnessAssessment
                    )
                    workoutViewModel.saveWorkoutPlan(newPlan)
                    showingProfileEditor = false
                },
                onCancel: { showingProfileEditor = false }
            )
        }
        .sheet(isPresented: $showingWorkoutDaysEditor) {
            WorkoutDaysSettingsSheet(
                currentDays: workoutViewModel.userProfile.effectiveWorkoutDays,
                activityLevel: workoutViewModel.userProfile.activityLevel,
                themeColor: workoutViewModel.themeColor,
                onSave: { updatedDays in
                    var profile = workoutViewModel.userProfile
                    profile.preferredWorkoutDays = updatedDays
                    workoutViewModel.updateUserProfile(profile)
                    let newPlan = WorkoutPlanGenerator.generateWorkoutPlan(
                        profile: profile,
                        assessment: workoutViewModel.fitnessAssessment
                    )
                    workoutViewModel.saveWorkoutPlan(newPlan)
                    showingWorkoutDaysEditor = false
                },
                onCancel: { showingWorkoutDaysEditor = false }
            )
        }
        .sheet(isPresented: $showingSleepEditor) {
            SleepScheduleProfileEditorSheet(
                schedule: workoutViewModel.userProfile.sleepSchedule ?? .recommendedDefault,
                themeColor: workoutViewModel.themeColor,
                onSave: { updated in
                    var profile = workoutViewModel.userProfile
                    profile.sleepSchedule = updated
                    workoutViewModel.updateUserProfile(profile)
                    showingSleepEditor = false
                },
                onCancel: { showingSleepEditor = false }
            )
        }
        .sheet(isPresented: $showingFeedbackToneEditor) {
            FeedbackToneSettingsSheet(workoutViewModel: workoutViewModel)
        }
        .sheet(isPresented: $showingThemeColorPicker) {
            NavigationView {
                ThemeColorPickerView(workoutViewModel: workoutViewModel)
            }
        }
    }

    private var weeklyGoalsSection: some View {
        let goalProgress = workoutViewModel.getAlgorithmGoalProgress().filter { $0.workoutType != "Wall Sits" }

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "target", title: "Weekly goals")

            if goalProgress.isEmpty {
                Text("Complete onboarding to get personalized weekly goals.")
                    .font(.system(size: 13))
                    .foregroundColor(.customSecondaryLabel)
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(goalProgress, id: \.workoutType) { progress in
                        weeklyRow(progress)
                    }
                }
                .padding(14)
                .background(Color.customBackground.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .appSectionContainer()
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "slider.horizontal.3", title: "Your settings")

            VStack(spacing: 0) {
                if workoutViewModel.hasCompletedOnboarding {
                    prefRow(icon: "person.text.rectangle.fill", title: "Fitness profile", subtitle: "\(workoutViewModel.userProfile.fitnessGoal.rawValue) · \(workoutViewModel.userProfile.activityLevel.rawValue)") {
                        showingProfileEditor = true
                    }
                    divider
                    prefRow(icon: "calendar", title: "Workout days", subtitle: workoutViewModel.userProfile.workoutDaysSummary) {
                        showingWorkoutDaysEditor = true
                    }
                    divider
                    prefRow(icon: "moon.zzz.fill", title: "Sleep schedule", subtitle: sleepSubtitle) {
                        showingSleepEditor = true
                    }
                    divider
                    prefRow(icon: "figure.strengthtraining.traditional", title: "Retake fitness test", subtitle: "Update your baseline assessment") {
                        navigateToAssessment = true
                    }
                    divider
                }

                if let plan = workoutViewModel.currentWorkoutPlan {
                    prefRow(icon: plan.fitnessLevel.icon, title: plan.name, subtitle: "\(plan.workoutDaysPerWeek) days/week · \(plan.estimatedWeeklyDuration)m", action: nil)
                    divider
                }

                prefRow(
                    icon: workoutViewModel.feedbackTone.icon,
                    title: "Coaching style",
                    subtitle: workoutViewModel.feedbackTone.title
                ) {
                    showingFeedbackToneEditor = true
                }

                divider

                prefRow(
                    icon: "paintpalette.fill",
                    title: "Theme color",
                    subtitle: workoutViewModel.levelInfo.level >= 3 ? "Customize app highlights" : "Unlock at level 3"
                ) {
                    if workoutViewModel.levelInfo.level >= 3 {
                        showingThemeColorPicker = true
                    }
                }

                divider

                prefRow(icon: "bell.badge.fill", title: "Reminders", subtitle: "Discipline nudges — workout, sleep & wake") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            .background(Color.customBackground.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .appSectionContainer()
    }

    private var devToolsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Test & cheats")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.customLabel)
                    Text("Testing only — quick controls for XP, notifications, streaks, and plan phase.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 14) {
                devButtonRow(
                    title: "Level up once",
                    subtitle: "Add exactly enough XP for the next level",
                    icon: "arrow.up.circle.fill",
                    tint: workoutViewModel.themeColor
                ) {
                    workoutViewModel.devAddLevel()
                }

                devDivider

                devButtonRow(
                    title: "Add 100 XP",
                    subtitle: "Quick XP boost without forcing a full level",
                    icon: "plus.circle.fill",
                    tint: workoutViewModel.themeColor
                ) {
                    workoutViewModel.addXP(100)
                }

                devDivider

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set streak days")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.customLabel)
                            Text("Rewrite recent workout dates for streak testing")
                                .font(.system(size: 12))
                                .foregroundColor(.customSecondaryLabel)
                        }
                        Spacer()
                        TextField("7", text: $devStreakDays)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 56)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Button("Apply") {
                            workoutViewModel.devSetCurrentStreak(days: Int(devStreakDays) ?? 0)
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(workoutViewModel.themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                devDivider

                VStack(alignment: .leading, spacing: 10) {
                    Text("Notifications")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text("Fire immediate local test notifications using the current coaching tone.")
                        .font(.system(size: 12))
                        .foregroundColor(.customSecondaryLabel)

                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 10) {
                        devMiniButton("Test morning", icon: "sun.max.fill", tint: workoutViewModel.themeColor) {
                            WorkoutNotificationService.shared.testMorningNotification(workoutViewModel: workoutViewModel)
                        }
                        devMiniButton("Test afternoon", icon: "sun.haze.fill", tint: workoutViewModel.themeColor) {
                            WorkoutNotificationService.shared.testAfternoonNotification(workoutViewModel: workoutViewModel)
                        }
                        devMiniButton("Test bedtime", icon: "moon.fill", tint: .indigo) {
                            SleepNotificationService.shared.testBedtimeNotification(streak: workoutViewModel.getCurrentStreak())
                        }
                        devMiniButton("Test wake", icon: "alarm.fill", tint: .indigo) {
                            SleepNotificationService.shared.testWakeNotification(streak: workoutViewModel.getCurrentStreak())
                        }
                        devMiniButton("Test early quit", icon: "flag.checkered", tint: .orange) {
                            WorkoutNotificationService.shared.testEarlyQuitNotification()
                        }
                    }
                }

                devDivider

                VStack(alignment: .leading, spacing: 10) {
                    Text("Plan phase")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(planPhaseSummary)
                        .font(.system(size: 12))
                        .foregroundColor(.customSecondaryLabel)

                    HStack(spacing: 10) {
                        devMiniButton("Foundation", icon: "1.circle.fill", tint: .orange) {
                            workoutViewModel.devSetPlanWeek(1)
                        }
                        devMiniButton("Building", icon: "2.circle.fill", tint: .blue) {
                            workoutViewModel.devSetPlanWeek(3)
                        }
                        devMiniButton("Power", icon: "3.circle.fill", tint: .purple) {
                            workoutViewModel.devSetPlanWeek(5)
                        }
                    }
                }

                devDivider

                HStack(spacing: 10) {
                    devMiniButton("New week", icon: "calendar.badge.clock", tint: .green) {
                        workoutViewModel.devShiftWeeklyProgress(days: -8)
                    }
                    devMiniButton("Toggle tone", icon: "text.bubble.fill", tint: .pink) {
                        workoutViewModel.devCycleFeedbackTone()
                    }
                }
            }
            .padding(14)
            .background(Color.orange.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
            }
        }
        .appSectionContainer(strokeColor: Color.orange.opacity(0.18))
    }

    private var sleepSubtitle: String {
        if let s = workoutViewModel.userProfile.sleepSchedule {
            return "\(s.formattedBedtime) → \(s.formattedWakeTime)"
        }
        return "Set bedtime and wake time"
    }

    private var planPhaseSummary: String {
        guard let plan = workoutViewModel.currentWorkoutPlan else {
            return "No active plan yet."
        }
        return "Current: Week \(plan.currentWeek) · \(plan.progressionPhase)"
    }

    private var divider: some View {
        Divider().opacity(0.35).padding(.leading, 52)
    }

    private var devDivider: some View {
        Divider().opacity(0.3)
    }

    private func weeklyRow(_ progress: GoalProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(progress.workoutType)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(progress.completed)/\(progress.weeklyGoal)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.customLabel.opacity(0.09))
                    Capsule()
                        .fill(workoutViewModel.themeColor)
                        .frame(width: geo.size.width * max(0, min(1, progress.progressPercentage)))
                }
            }
            .frame(height: 7)
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(workoutViewModel.themeColor.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(workoutViewModel.themeColor)
            }
            Text(title).font(.system(size: 18, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func prefRow(icon: String, title: String, subtitle: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(workoutViewModel.themeColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.customSecondaryLabel)
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.customSecondaryLabel)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func devButtonRow(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.customSecondaryLabel)
                }
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func devMiniButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(tint.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Help & legal

struct ProfileHelpDetailView: View {
    let themeColor: Color
    @Environment(\.openURL) private var openURL
    @State private var showingWelcomeScreen = false

    private let supportEmail = "richcmckain@gmail.com"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sectionGap) {
                helpHeroBanner

                supportSection

                legalSection

                helpFooterNote
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
        }
        .background(Color.customBackground)
        .profileDetailNavigation()
        .sheet(isPresented: $showingWelcomeScreen) {
            AppInfoScreen(themeColor: themeColor)
        }
    }

    private var helpHeroBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeColor.opacity(0.28), themeColor.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    Image("flame")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Help & legal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.customLabel)
                    Text("Support, app info, and your rights")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }
            }

            Text("Questions about workouts, your account, or how we handle your data? Start here — everything you need is a tap away.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.groupInner + 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous)
                        .strokeBorder(themeColor.opacity(0.16), lineWidth: 0.5)
                }
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(themeColor.opacity(0.12))
                .frame(width: 120, height: 120)
                .blur(radius: 28)
                .offset(x: 24, y: -24)
                .allowsHitTesting(false)
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            helpSectionHeader(icon: "lifepreserver.fill", title: "Support")

            VStack(spacing: 0) {
                ProfileHelpActionRow(
                    icon: "sparkles",
                    title: "Help & app info",
                    subtitle: "What PushLimit does and how to get the most from it",
                    tint: themeColor,
                    trailing: .chevron
                ) {
                    showingWelcomeScreen = true
                }

                helpRowDivider

                ProfileHelpActionRow(
                    icon: "envelope.fill",
                    title: "Send feedback",
                    subtitle: supportEmail,
                    tint: themeColor,
                    trailing: .external
                ) {
                    if let url = URL(string: "mailto:\(supportEmail)?subject=PushLimit%20Feedback") {
                        openURL(url)
                    }
                }
            }
            .appInsetPanel()
        }
        .appSectionContainer()
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            helpSectionHeader(icon: "doc.text.fill", title: "Legal documents")

            Text("Review how we protect your data and the terms for using PushLimit.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                NavigationLink(destination: PrivacyPolicyScreen()) {
                    ProfileHelpDocumentCard(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        subtitle: "What we collect, how we use it, and your rights",
                        tint: themeColor,
                        version: LegalCopy.policyVersion
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: TermsOfServiceScreen()) {
                    ProfileHelpDocumentCard(
                        icon: "doc.plaintext.fill",
                        title: "Terms of Service",
                        subtitle: "Rules of use, fitness disclaimer, and liability",
                        tint: themeColor,
                        version: LegalCopy.policyVersion
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .appSectionContainer()
    }

    private var helpFooterNote: some View {
        VStack(spacing: 6) {
            Text("PushLimit · Apex Applications")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
            Text("Effective \(LegalCopy.policyVersion)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.customSecondaryLabel.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func helpSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColor)
            }
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.customLabel)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private var helpRowDivider: some View {
        Divider().opacity(0.35).padding(.leading, 54)
    }
}

private struct ProfileHelpActionRow: View {
    enum TrailingStyle {
        case chevron
        case external
    }

    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let trailing: TrailingStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: trailing == .external ? "arrow.up.right" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel.opacity(0.85))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileHelpDocumentCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let version: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.22), tint.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Spacer(minLength: 8)
                    Text("v\(version)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tint.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel.opacity(0.85))
                .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.12), lineWidth: 0.5)
        }
    }
}

// MARK: - Data & privacy

struct ProfileDataDetailView: View {
    @ObservedObject private var accountAuth = FirebaseUserDataService.shared
    @State private var showingResetAlert = false
    @State private var isResettingAllData = false
    @State private var showingResetFailedAlert = false
    @State private var resetFailureMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sectionGap) {
                ProfileDetailHeader(title: "Data & privacy")
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.red.opacity(0.15)).frame(width: 36, height: 36)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red.opacity(0.9))
                        }
                        Text("Danger zone")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.red.opacity(0.95))
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    Button { showingResetAlert = true } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset all data")
                            Spacer()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 15)
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isResettingAllData)

                    Text("Permanently removes workouts, progress, goals, and settings on this device.")
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryLabel)

                    Text("Version 3.1.0")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .appSectionContainer(strokeColor: Color.red.opacity(0.25))
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
        }
        .background(Color.customBackground)
        .profileDetailNavigation()
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All Data", role: .destructive) {
                performPermanentReset()
            }
        } message: {
            Text(resetAllDataAlertMessage)
        }
        .alert("Couldn’t delete cloud backup", isPresented: $showingResetFailedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resetFailureMessage)
        }
    }

    private var resetAllDataAlertMessage: String {
        if accountAuth.isSignedIn {
            return "This permanently deletes all workouts, progress, goals, and profile data on this device and removes your backed-up data from Firebase. You will be signed out and returned to onboarding. This cannot be undone."
        }
        return "This permanently deletes all workouts, progress, goals, and profile data on this device and returns you to onboarding. This cannot be undone."
    }

    private func performPermanentReset() {
        guard !isResettingAllData else { return }
        isResettingAllData = true
        Task {
            let cloudError = await accountAuth.resetAllDataPermanently()
            await MainActor.run {
                isResettingAllData = false
                if let cloudError {
                    resetFailureMessage = "Local data was cleared, but cloud backup could not be deleted: \(cloudError)."
                    showingResetFailedAlert = true
                }
            }
        }
    }
}
