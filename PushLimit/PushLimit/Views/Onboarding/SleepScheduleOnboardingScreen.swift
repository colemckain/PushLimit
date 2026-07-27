import SwiftUI

/// Onboarding + profile editor for bedtime and wake time.
struct SleepScheduleEditorView: View {
    @Binding var schedule: SleepSchedule
    let themeColor: Color
    var showsHeader: Bool = true
    var onContinue: (() -> Void)?

    @State private var bedtimeDate: Date = Date()
    @State private var wakeDate: Date = Date()

    var body: some View {
        VStack(spacing: 24) {
            if showsHeader {
                VStack(spacing: 10) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(themeColor)

                    Text("Recovery is discipline")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)

                    Text(PushLimitVoiceCopy.sleepOnboardingSubtitle())
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 8)
            }

            durationSummaryCard

            VStack(alignment: .leading, spacing: 14) {
                timePickerBlock(
                    title: "Bedtime",
                    subtitle: "When you usually go to sleep",
                    icon: "moon.fill",
                    selection: $bedtimeDate
                )

                timePickerBlock(
                    title: "Wake up",
                    subtitle: "When you usually get up",
                    icon: "sun.max.fill",
                    selection: $wakeDate
                )
            }
            .padding(.horizontal, 20)

            habitInsightCard

            if let onContinue {
                OnboardingContinueButton(
                    title: "Continue",
                    themeColor: themeColor,
                    isEnabled: true,
                    action: {
                        applyPickerValues()
                        onContinue()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            syncPickersFromSchedule()
        }
        .onChange(of: bedtimeDate) { _, _ in applyPickerValues() }
        .onChange(of: wakeDate) { _, _ in applyPickerValues() }
    }

    private var durationSummaryCard: some View {
        HStack(spacing: 16) {
            scheduleTimeColumn(label: "Bed", time: schedule.formattedBedtime, icon: "moon.fill")
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
            scheduleTimeColumn(label: "Wake", time: schedule.formattedWakeTime, icon: "sun.max.fill")

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(schedule.formattedDuration)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(themeColor)
                    .monospacedDigit()
                Text(schedule.durationQualityLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(schedule.isHealthyDuration ? .green : .orange)
            }
        }
        .padding(16)
        .background(themeColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func scheduleTimeColumn(label: String, time: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.customSecondaryLabel)
            Text(time)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.customLabel)
        }
    }

    private func timePickerBlock(
        title: String,
        subtitle: String,
        icon: String,
        selection: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }
            }

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipped()
            .padding(.horizontal, 8)
            .background(Color.customSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var habitInsightCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("Why we track this")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.customLabel)
                Text(PushLimitVoiceCopy.sleepWhyWeTrack())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func syncPickersFromSchedule() {
        bedtimeDate = schedule.bedtimeDate()
        wakeDate = schedule.wakeDate()
    }

    private func applyPickerValues() {
        schedule.setBedtime(from: bedtimeDate)
        schedule.setWakeTime(from: wakeDate)
    }
}

/// Onboarding wrapper with scroll.
struct SleepScheduleOnboardingScreen: View {
    @Binding var schedule: SleepSchedule
    let themeColor: Color
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            SleepScheduleEditorView(
                schedule: $schedule,
                themeColor: themeColor,
                showsHeader: true
            )
            .onboardingScrollBottomInset()
        }
        .background(Color.customBackground)
        .onboardingForwardAction(step: 4, action: onContinue)
    }
}

#Preview {
    SleepScheduleOnboardingScreen(
        schedule: .constant(.recommendedDefault),
        themeColor: .customOrange,
        onContinue: {}
    )
}

// MARK: - Profile sheet

struct SleepScheduleProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let themeColor: Color
    let onSave: (SleepSchedule) -> Void
    let onCancel: () -> Void

    @State private var schedule: SleepSchedule

    init(
        schedule: SleepSchedule,
        themeColor: Color,
        onSave: @escaping (SleepSchedule) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.themeColor = themeColor
        self.onSave = onSave
        self.onCancel = onCancel
        _schedule = State(initialValue: schedule)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                SleepScheduleEditorView(
                    schedule: $schedule,
                    themeColor: themeColor,
                    showsHeader: true
                )
                .padding(.bottom, 24)
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Sleep schedule")
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
                        onSave(schedule)
                        dismiss()
                    }
                    .foregroundColor(themeColor)
                }
            }
        }
    }
}
