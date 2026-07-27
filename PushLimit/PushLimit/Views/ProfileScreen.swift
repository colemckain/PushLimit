import SwiftUI
import UIKit

struct ProfileScreen: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject private var accountAuth = FirebaseUserDataService.shared
    @Environment(\.openURL) private var openURL
    @State private var showingProfileCustomizer = false
    @State private var isEditingName = false
    @State private var tempName = ""
    
    init(workoutViewModel: WorkoutViewModel = WorkoutViewModel()) {
        self._workoutViewModel = ObservedObject(wrappedValue: workoutViewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sectionGap) {
                profileHeader
                profileFoldersSection
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.vertical, isIPad ? 32 : 0)
        }
        .background(Color.customBackground)
        .ignoresSafeArea(.container, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaPadding(.top, 8)
        .onAppear {
            tempName = workoutViewModel.userName
        }
        .sheet(isPresented: $showingProfileCustomizer) {
            ProfileCustomizerSheet(
                userName: workoutViewModel.userName,
                selectedPreset: workoutViewModel.profileAvatarPreset,
                selectedColor: workoutViewModel.profileColor,
                themeColor: workoutViewModel.themeColor,
                onSave: { preset, color in
                    workoutViewModel.updateProfileAvatar(preset: preset, color: color)
                    showingProfileCustomizer = false
                }
            )
        }
    }

    // MARK: - Folder hub

    private var profileFoldersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, AppSpacing.screenHorizontal + 4)

            AppGroupedSection {
                VStack(spacing: 0) {
                    NavigationLink {
                        ProfileAccountDetailView(workoutViewModel: workoutViewModel)
                    } label: {
                        ProfileFolderRow(
                            icon: "person.crop.circle.fill",
                            title: "Account & sync",
                            subtitle: accountFolderSubtitle,
                            tint: workoutViewModel.themeColor
                        )
                    }
                    .buttonStyle(.plain)

                    folderDivider

                    NavigationLink {
                        ProfilePlanDetailView(workoutViewModel: workoutViewModel)
                    } label: {
                        ProfileFolderRow(
                            icon: "slider.horizontal.3",
                            title: profileDisplayName,
                            subtitle: planFolderSubtitle,
                            tint: workoutViewModel.themeColor
                        )
                    }
                    .buttonStyle(.plain)

                    folderDivider

                    NavigationLink {
                        ProfileHelpDetailView(themeColor: workoutViewModel.themeColor)
                    } label: {
                        ProfileFolderRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & legal",
                            subtitle: "Support, feedback, privacy & terms",
                            tint: workoutViewModel.themeColor
                        )
                    }
                    .buttonStyle(.plain)

                    folderDivider

                    NavigationLink {
                        ProfileDataDetailView()
                    } label: {
                        ProfileFolderRow(
                            icon: "lock.shield.fill",
                            title: "Data & privacy",
                            subtitle: "Reset app data and version info",
                            tint: .red.opacity(0.85)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var folderDivider: some View {
        Divider().opacity(0.35).padding(.leading, 70)
    }

    private var accountFolderSubtitle: String {
        if !FirebaseUserDataService.isCloudSyncAvailable {
            return "Local storage only"
        }
        if accountAuth.isSignedIn {
            if accountAuth.needsEmailVerification {
                return "Signed in · verify email for backup"
            }
            return accountAuth.email ?? "Signed in · cloud backup enabled"
        }
        return "Sign in to back up across devices"
    }

    private var profileDisplayName: String {
        let trimmed = workoutViewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "User" {
            return "My profile"
        }
        return trimmed
    }

    private var planFolderSubtitle: String {
        var parts: [String] = ["Goals & preferences"]
        if let plan = workoutViewModel.currentWorkoutPlan {
            parts.append(plan.name)
        }
        if workoutViewModel.userProfile.sleepSchedule != nil {
            parts.append("Sleep set")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Profile Header (hero)
    private var profileHeader: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 18) {
                profileAvatarWithLevelRing
                profileIdentityColumn
            }

            profileQuickStatsRow
            xpProgressSection
            Text(levelProgressMotivation)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                AppGroupedSurface(cornerRadius: AppSpacing.groupRadius + 4)
                LinearGradient(
                    colors: [
                        workoutViewModel.themeColor.opacity(0.14),
                        workoutViewModel.profileColor.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius + 4, style: .continuous))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius + 4, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(workoutViewModel.themeColor.opacity(0.1))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .offset(x: 20, y: -20)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, 4)
    }

    private var profileAvatarWithLevelRing: some View {
        Button {
            showingProfileCustomizer = true
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.customLabel.opacity(0.08), lineWidth: 7)
                    .frame(width: 118, height: 118)

                Circle()
                    .trim(from: 0, to: CGFloat(min(1, max(0, workoutViewModel.levelInfo.progress))))
                    .stroke(
                        LinearGradient(
                            colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: workoutViewModel.levelInfo.progress)

                ProfileAvatarView(
                    preset: workoutViewModel.profileAvatarPreset,
                    userName: workoutViewModel.userName,
                    profileColor: workoutViewModel.profileColor,
                    size: 100,
                    showEditBadge: true,
                    themeColor: workoutViewModel.themeColor
                )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(showingProfileCustomizer ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: showingProfileCustomizer)
    }

    private var profileIdentityColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            nameSection
            levelBadgeRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileQuickStatsRow: some View {
        HStack(spacing: 10) {
            profileStatChip(
                icon: "star.fill",
                label: "Level",
                value: "\(workoutViewModel.levelInfo.level)"
            )
            profileStatChip(
                icon: "bolt.fill",
                label: "XP",
                value: "\(workoutViewModel.levelInfo.xpInCurrentLevel)"
            )
            profileStatChip(
                icon: "flame.fill",
                label: "Streak",
                value: "\(workoutViewModel.getCurrentStreak())"
            )
        }
    }

    private func profileStatChip(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(workoutViewModel.themeColor)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.customLabel)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(workoutViewModel.themeColor.opacity(0.1), lineWidth: 0.5)
        }
    }
    
    private var levelProgressMotivation: String {
        PushLimitVoiceCopy.profileLevelMotivation(progress: workoutViewModel.levelInfo.progress)
    }
    
    private var levelBadgeRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                Text("Lv. \(workoutViewModel.levelInfo.level)")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )

            Text(workoutViewModel.levelInfo.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.customLabel)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.customBackground.opacity(0.65))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.customLabel.opacity(0.08), lineWidth: 1)
                )
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditingName {
                HStack(spacing: 8) {
                    TextField("Name", text: $tempName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.customLabel)
                        .textFieldStyle(PlainTextFieldStyle())
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(workoutViewModel.themeColor),
                            alignment: .bottom
                        )

                    Button("Save") {
                        handleNameSave()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(workoutViewModel.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            } else {
                Button(action: handleNameEdit) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(profileDisplayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.customLabel)
                            .multilineTextAlignment(.leading)

                        Text("Tap to edit name")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var xpProgressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Experience")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.customSecondaryLabel)
                    .tracking(0.6)
                Spacer(minLength: 8)
                let pct = Int((workoutViewModel.levelInfo.progress * 100).rounded())
                Text("\(pct)% to next level")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
            }
            GeometryReader { geo in
                let w = max(12, geo.size.width * CGFloat(min(1, max(0, workoutViewModel.levelInfo.progress))))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.customLabel.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    workoutViewModel.themeColor,
                                    workoutViewModel.themeColor.opacity(0.65)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w)
                        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: workoutViewModel.levelInfo.progress)
                }
            }
            .frame(height: 11)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(workoutViewModel.levelInfo.xpInCurrentLevel)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.customLabel)
                Text("/ \(workoutViewModel.levelInfo.xpToNextLevel) XP")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    
    private func handleNameSave() {
        if !tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            workoutViewModel.userName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
            workoutViewModel.saveUserData()
        }
        isEditingName = false
    }
    
    private func handleNameEdit() {
        tempName = workoutViewModel.userName
        isEditingName = true
    }
    
    
}

// MARK: - Supporting Views

struct MenuItem: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.customLabel)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileScreen()
}

// MARK: - Profile Customizer Sheet
struct ProfileCustomizerSheet: View {
    let userName: String
    let selectedPreset: ProfileAvatarPreset
    let selectedColor: Color
    let themeColor: Color
    let onSave: (ProfileAvatarPreset, Color) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftPreset: ProfileAvatarPreset
    @State private var draftColor: Color

    init(
        userName: String,
        selectedPreset: ProfileAvatarPreset,
        selectedColor: Color,
        themeColor: Color,
        onSave: @escaping (ProfileAvatarPreset, Color) -> Void
    ) {
        self.userName = userName
        self.selectedPreset = selectedPreset
        self.selectedColor = selectedColor
        self.themeColor = themeColor
        self.onSave = onSave
        _draftPreset = State(initialValue: selectedPreset)
        _draftColor = State(initialValue: selectedColor)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        ProfileAvatarView(
                            preset: draftPreset,
                            userName: userName,
                            profileColor: draftColor,
                            size: 110,
                            themeColor: themeColor
                        )

                        Text("Customize your profile")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.customLabel)

                        Text("Pick an avatar and accent color that shows up on your profile.")
                            .font(.system(size: 15))
                            .foregroundColor(.customSecondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Avatar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.customLabel)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                            spacing: 12
                        ) {
                            ForEach(ProfileAvatarPreset.allCases) { preset in
                                Button {
                                    draftPreset = preset
                                } label: {
                                    VStack(spacing: 6) {
                                        ProfileAvatarView(
                                            preset: preset,
                                            userName: userName,
                                            profileColor: draftColor,
                                            size: 56,
                                            themeColor: themeColor
                                        )
                                        .overlay {
                                            if draftPreset == preset {
                                                Circle()
                                                    .stroke(themeColor, lineWidth: 2.5)
                                                    .frame(width: 60, height: 60)
                                            }
                                        }

                                        Text(preset.label)
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(draftPreset == preset ? themeColor : .customSecondaryLabel)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Accent color")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.customLabel)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                            ForEach(WorkoutViewModel.availableProfileColors, id: \.self) { color in
                                ColorOptionView(
                                    color: color,
                                    isSelected: color == draftColor,
                                    onTap: { draftColor = color }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.customBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(draftPreset, draftColor)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColor)
                }
            }
        }
    }
}

// MARK: - Profile Color Picker View (legacy)
struct ProfileColorPickerView: View {
    let selectedColor: Color
    let themeColor: Color
    let onColorSelected: (Color) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Choose Profile Color")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.customLabel)
                    
                    Text("Select a color for your profile circle")
                        .font(.system(size: 16))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Color Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                    ForEach(WorkoutViewModel.availableProfileColors, id: \.self) { color in
                        ColorOptionView(
                            color: color,
                            isSelected: color == selectedColor,
                            onTap: {
                                onColorSelected(color)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Preview
                VStack(spacing: 16) {
                    Text("Preview")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.customLabel)
                    
                    ZStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 80, height: 80)
                        
                        Text("A")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.customBackground)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeColor)
                }
            }
        }
    }
}

// MARK: - Color Option View
struct ColorOptionView: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.customSecondaryLabel)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.customSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Assessment Badge
struct AssessmentBadge: View {
    let label: String
    let value: Int
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeColor)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.customSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.customSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Compact Info Item
struct CompactInfoItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.customBackground)
        .cornerRadius(8)
    }
}

// MARK: - Compact Assessment Badge  
struct CompactAssessmentBadge: View {
    let label: String
    let value: Int
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeColor)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.customSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.customBackground)
        .cornerRadius(6)
    }
} 

// MARK: - Profile Goal Editor Sheet
struct ProfileGoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    private let onSave: (UserProfile) -> Void
    private let onCancel: () -> Void
    let themeColor: Color
    @State private var selectedGoal: UserProfile.FitnessGoal
    @State private var selectedActivity: UserProfile.ActivityLevel
    @State private var selectedWorkoutDays: [Int]
    @State private var ageText: String
    @State private var showAgeField: Bool
    private let originalProfile: UserProfile
    
    init(
        profile: UserProfile,
        themeColor: Color,
        onSave: @escaping (UserProfile) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        self.themeColor = themeColor
        self.originalProfile = profile
        _selectedGoal = State(initialValue: profile.fitnessGoal)
        _selectedActivity = State(initialValue: profile.activityLevel)
        _selectedWorkoutDays = State(initialValue: profile.effectiveWorkoutDays)
        let ageString = profile.age.map { String($0) } ?? ""
        _ageText = State(initialValue: ageString)
        _showAgeField = State(initialValue: profile.age != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    goalSection
                    activitySection
                    workoutDaysSection
                    ageSection
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Edit Fitness Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                    .foregroundColor(.customSecondaryLabel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        handleSave()
                    }
                    .foregroundColor(themeColor)
                    .disabled(!hasChanges || !hasValidWorkoutDays)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 40))
                .foregroundColor(themeColor)
            Text("Update your goals and activity to keep your plan personalized.")
                .font(.system(size: 15))
                .foregroundColor(.customSecondaryLabel)
                .multilineTextAlignment(.center)
        }
    }
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fitness Goal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.customLabel)
            AppGroupedSection {
                VStack(spacing: 8) {
                    ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                        CompactGoalOptionCard(
                            goal: goal,
                            isSelected: selectedGoal == goal,
                            action: {
                                selectedGoal = goal
                            }
                        )
                    }
                }
                .padding(AppSpacing.groupInner)
            }
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Level")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.customLabel)
            VStack(spacing: 10) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    CompactActivityLevelOption(
                        level: level,
                        isSelected: selectedActivity == level,
                        themeColor: themeColor,
                        displayDays: selectedActivity == level ? selectedWorkoutDays : level.workoutDays,
                        action: {
                            selectedActivity = level
                            if selectedWorkoutDays.count != level.workoutDays.count {
                                selectedWorkoutDays = level.workoutDays
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var workoutDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Days")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.customLabel)
            AppGroupedSection {
                WorkoutDaysPicker(
                    selectedDays: $selectedWorkoutDays,
                    requiredCount: selectedActivity.workoutDays.count,
                    accentColor: themeColor
                )
                .padding(AppSpacing.groupInner)
            }
        }
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Age (Optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
                Spacer()
                Toggle("", isOn: $showAgeField)
                    .labelsHidden()
            }
            if showAgeField {
                TextField("Enter age", text: Binding(
                    get: { ageText },
                    set: { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        ageText = String(filtered.prefix(3))
                    }
                ))
                .keyboardType(.numberPad)
                .padding(12)
                .appInsetPanel()
            }
        }
    }
    
    private var hasValidWorkoutDays: Bool {
        Set(selectedWorkoutDays).count == selectedActivity.workoutDays.count
    }

    private var hasChanges: Bool {
        let currentAge = originalProfile.age.map { String($0) } ?? ""
        let trimmedAge = ageText.trimmingCharacters(in: .whitespaces)
        let workoutDaysChanged = selectedWorkoutDays.sorted() != originalProfile.effectiveWorkoutDays
        return selectedGoal != originalProfile.fitnessGoal ||
            selectedActivity != originalProfile.activityLevel ||
            workoutDaysChanged ||
            (showAgeField ? trimmedAge != currentAge : originalProfile.age != nil)
    }
    
    private func handleSave() {
        var updatedProfile = originalProfile
        updatedProfile.fitnessGoal = selectedGoal
        updatedProfile.activityLevel = selectedActivity
        updatedProfile.preferredWorkoutDays = selectedWorkoutDays.sorted()
        let trimmedAge = ageText.trimmingCharacters(in: .whitespaces)
        if showAgeField, let ageValue = Int(trimmedAge), ageValue > 0 {
            updatedProfile.age = ageValue
        } else {
            updatedProfile.age = nil
        }
        onSave(updatedProfile)
        dismiss()
    }
}

// MARK: - Compact Activity Level Option
private struct CompactActivityLevelOption: View {
    let level: UserProfile.ActivityLevel
    let isSelected: Bool
    let themeColor: Color
    var displayDays: [Int]? = nil
    let action: () -> Void

    private var daysToShow: [Int] {
        displayDays ?? level.workoutDays
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: level.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? themeColor : .customLabel)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(level.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.customLabel)
                        Text(level.description)
                            .font(.system(size: 13))
                            .foregroundColor(.customSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeColor)
                    }
                }
                HStack(spacing: 6) {
                    Text("Workout days: ")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                    ForEach(daysToShow, id: \.self) { day in
                        Text(shortDayName(day))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .customLabel)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? themeColor : Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? themeColor.opacity(0.1) : Color.customSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func shortDayName(_ day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[max(0, min(days.count - 1, day - 1))]
    }
} 