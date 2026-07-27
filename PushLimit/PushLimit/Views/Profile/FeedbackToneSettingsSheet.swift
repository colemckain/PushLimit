import SwiftUI

struct FeedbackToneSettingsSheet: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draftTone: FeedbackTone

    init(workoutViewModel: WorkoutViewModel) {
        self.workoutViewModel = workoutViewModel
        _draftTone = State(initialValue: workoutViewModel.feedbackTone)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choose how PushLimit motivates you — in reminders, completion screens, and coaching copy on Home.")
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        ForEach(FeedbackTone.allCases) { tone in
                            FeedbackToneOptionCard(
                                tone: tone,
                                isSelected: draftTone == tone,
                                themeColor: workoutViewModel.themeColor
                            ) {
                                draftTone = tone
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sounds like")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.customSecondaryLabel)
                        Text("“\(draftTone.previewCompletionHeadline)”")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.customLabel)
                        Text(draftTone.previewCompletionQuote)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background { AppGroupedSurface() }
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 24)
            }
            .background(Color.customBackground)
            .navigationTitle("Coaching style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.customSecondaryLabel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        workoutViewModel.updateFeedbackTone(draftTone)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
                }
            }
        }
    }
}
