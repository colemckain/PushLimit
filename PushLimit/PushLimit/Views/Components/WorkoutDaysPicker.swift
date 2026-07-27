import SwiftUI

// MARK: - Workout day picker

struct WorkoutDaysPicker: View {
    @Binding var selectedDays: [Int]
    let requiredCount: Int
    let accentColor: Color
    var showsHeader: Bool = true

    private var isValid: Bool {
        Set(selectedDays).count == requiredCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsHeader {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout days")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customLabel)

                    Text("Pick \(requiredCount) day\(requiredCount == 1 ? "" : "s") that fit your week.")
                        .font(.system(size: 13))
                        .foregroundColor(.customSecondaryLabel)
                }
            }

            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    WorkoutDayChip(
                        label: UserProfile.weekdayShortNames[day - 1],
                        isSelected: selectedDays.contains(day),
                        accentColor: accentColor
                    ) {
                        toggleDay(day)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isValid ? accentColor : .customSecondaryLabel)

                Text(isValid
                     ? UserProfile.formattedWorkoutDays(selectedDays.sorted())
                     : "\(selectedDays.count) of \(requiredCount) selected")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isValid ? .customLabel : .customSecondaryLabel)
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
            return
        }

        guard selectedDays.count < requiredCount else { return }
        selectedDays.append(day)
        selectedDays.sort()
    }
}

private struct WorkoutDayChip: View {
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .white : .customLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? accentColor : Color.customSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? accentColor : Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile settings sheet

struct WorkoutDaysSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let themeColor: Color
    let activityLevel: UserProfile.ActivityLevel
    let onSave: ([Int]) -> Void
    let onCancel: () -> Void

    @State private var selectedDays: [Int]

    init(
        currentDays: [Int],
        activityLevel: UserProfile.ActivityLevel,
        themeColor: Color,
        onSave: @escaping ([Int]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.themeColor = themeColor
        self.activityLevel = activityLevel
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedDays = State(initialValue: currentDays.sorted())
    }

    private var requiredCount: Int {
        activityLevel.workoutDays.count
    }

    private var canSave: Bool {
        Set(selectedDays).count == requiredCount
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 36))
                            .foregroundColor(themeColor)

                        Text("Your \(activityLevel.rawValue.lowercased()) plan uses \(requiredCount) workout days per week. Choose the days that work best for you.")
                            .font(.system(size: 15))
                            .foregroundColor(.customSecondaryLabel)
                    }

                    WorkoutDaysPicker(
                        selectedDays: $selectedDays,
                        requiredCount: requiredCount,
                        accentColor: themeColor,
                        showsHeader: false
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Workout days")
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
                        onSave(selectedDays.sorted())
                        dismiss()
                    }
                    .foregroundColor(themeColor)
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    WorkoutDaysPicker(
        selectedDays: .constant([1, 3, 5]),
        requiredCount: 3,
        accentColor: .customOrange
    )
    .padding()
}
