import SwiftUI
import MapKit

struct LegRunSessionScreen: View {
    @Binding var selectedTab: Int
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let plannedSquatReps: Int
    var onWorkoutCompleted: (() -> Void)?

    @StateObject private var runTracker = RunTrackingService()
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
    @State private var followsUser = true
    @State private var isProgrammaticCameraMove = false
    @State private var showCompletionSheet = false
    @State private var showCancelAlert = false
    @State private var showLocationDeniedAlert = false
    @State private var showLocationConsentSheet = false
    @State private var completedDistanceMeters: Double = 0
    @State private var completedElapsedSeconds = 0
    @State private var completedXP = 0

    private let tabBarClearance: CGFloat = 52

    var body: some View {
        VStack(spacing: 0) {
            sessionHeader

            runStatsRow
                .padding(.horizontal, 16)
                .padding(.top, 12)

            mapSection
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if let error = runTracker.locationError {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            Spacer(minLength: 12)

            controlSection
                .padding(.horizontal, 16)
                .padding(.bottom, tabBarClearance + 8)
        }
        .frame(maxWidth: 600)
        .centerOnIPad(700)
        .background(Color.customBackground)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if LegalConsentStore.hasAcceptedLegRunLocationDisclosure {
                runTracker.requestAuthorization()
                if runTracker.canTrack {
                    runTracker.startLocationPreview()
                }
            } else {
                showLocationConsentSheet = true
            }
        }
        .onDisappear {
            if !runTracker.isTracking {
                runTracker.stopLocationPreview()
            }
        }
        .sheet(isPresented: $showLocationConsentSheet) {
            LegRunLocationConsentSheet(themeColor: workoutViewModel.themeColor) {
                runTracker.requestAuthorization()
                if runTracker.canTrack {
                    runTracker.startLocationPreview()
                }
            }
        }
        .onChange(of: runTracker.mapCenterCoordinate?.latitude) { _, _ in
            guard followsUser, let coordinate = runTracker.mapCenterCoordinate else { return }
            isProgrammaticCameraMove = true
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: coordinate,
                        distance: 650,
                        heading: 0,
                        pitch: 0
                    )
                )
            }
        }
        .onChange(of: runTracker.authorizationStatus) { _, status in
            if status == .denied || status == .restricted {
                showLocationDeniedAlert = true
            } else if status == .authorizedWhenInUse || status == .authorizedAlways {
                runTracker.startLocationPreview()
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
            WorkoutCompletedScreen(
                exercise: LegWorkoutSupport.runExercise,
                totalReps: plannedSquatReps,
                timeSpent: completedElapsedSeconds,
                xpEarned: completedXP,
                wallSitTime: nil,
                runDistanceMeters: completedDistanceMeters,
                workoutViewModel: workoutViewModel,
                selectedTab: $selectedTab,
                onWorkoutCompleted: {
                    showCompletionSheet = false
                    onWorkoutCompleted?()
                },
                themeColor: workoutViewModel.themeColor
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("Cancel run?", isPresented: $showCancelAlert) {
            Button("Keep running", role: .cancel) {}
            Button("Discard run", role: .destructive) {
                runTracker.stop()
                onWorkoutCompleted?()
            }
        } message: {
            Text("Your run progress will not be saved.")
        }
        .alert("Location access needed", isPresented: $showLocationDeniedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable Location for PushLimit in Settings so we can track distance and map your run — including while the phone is locked or in another app.")
        }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        HStack(spacing: 12) {
            Button {
                if runTracker.isTracking {
                    showCancelAlert = true
                } else {
                    onWorkoutCompleted?()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customLabel)
                    .frame(width: 36, height: 36)
                    .background(Color.customSecondaryBackground)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Leg Run")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.customLabel)
                Text(runTracker.isTracking ? (runTracker.isPaused ? "Paused — location off" : "Tracking (works in background)") : "GPS run for today's legs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }

            Spacer()

            if runTracker.isTracking {
                Text(formatClock(runTracker.elapsedSeconds))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(workoutViewModel.themeColor)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Stats

    private var runStatsRow: some View {
        HStack(spacing: 10) {
            runStatCard(
                icon: "clock.fill",
                label: "Time",
                value: formatClock(runTracker.elapsedSeconds)
            )
            runStatCard(
                icon: "location.fill",
                label: "Distance",
                value: LegWorkoutSupport.formatDistance(runTracker.distanceMeters)
            )
            runStatCard(
                icon: "speedometer",
                label: "Pace",
                value: LegWorkoutSupport.formatPace(
                    distanceMeters: runTracker.distanceMeters,
                    elapsedSeconds: runTracker.elapsedSeconds
                )
            )
        }
    }

    private func runStatCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(workoutViewModel.themeColor)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.customSecondaryLabel)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.customLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.customSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Map

    private var mapSection: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                if runTracker.hasReceivedLocationFix {
                    UserAnnotation()
                }

                if runTracker.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: runTracker.routeCoordinates)
                        .stroke(workoutViewModel.themeColor, lineWidth: 4)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange(frequency: .onEnd) {
                if !isProgrammaticCameraMove {
                    followsUser = false
                }
                isProgrammaticCameraMove = false
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            if runTracker.canTrack && !runTracker.hasReceivedLocationFix {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(workoutViewModel.themeColor)
                    Text("Finding your location…")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customLabel)
                    Text("Make sure Location is enabled for PushLimit.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                followsUser = true
                isProgrammaticCameraMove = true
                if let coordinate = runTracker.mapCenterCoordinate {
                    cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: coordinate,
                            distance: 650,
                            heading: 0,
                            pitch: 0
                        )
                    )
                } else {
                    cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(workoutViewModel.themeColor)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(10)
            .opacity(runTracker.hasReceivedLocationFix ? 1 : 0.6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    // MARK: - Controls

    private var controlSection: some View {
        VStack(spacing: 12) {
            if !runTracker.isTracking {
                Text("Start when you're ready. We'll track time, distance, and your route — even if you lock your phone or switch apps. Pause or Finish to stop tracking.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            HStack(spacing: 12) {
                if runTracker.isTracking {
                    Button(action: togglePause) {
                        controlButtonLabel(
                            title: runTracker.isPaused ? "Resume" : "Pause",
                            icon: runTracker.isPaused ? "play.fill" : "pause.fill",
                            style: .secondary
                        )
                    }

                    Button(action: finishRun) {
                        controlButtonLabel(
                            title: "Finish",
                            icon: "flag.checkered",
                            style: .primary
                        )
                    }
                    .disabled(runTracker.elapsedSeconds < LegWorkoutSupport.minimumRunDurationSeconds)
                    .opacity(runTracker.elapsedSeconds < LegWorkoutSupport.minimumRunDurationSeconds ? 0.55 : 1)
                } else {
                    Button(action: startRun) {
                        controlButtonLabel(
                            title: runTracker.canTrack ? "Start run" : "Enable location",
                            icon: "figure.run",
                            style: .primary
                        )
                    }
                }
            }

            if runTracker.isTracking,
               runTracker.elapsedSeconds < LegWorkoutSupport.minimumRunDurationSeconds {
                Text("Run at least \(LegWorkoutSupport.minimumRunDurationSeconds)s to finish.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.customSecondaryLabel)
            }
        }
    }

    private enum ControlStyle {
        case primary
        case secondary
    }

    @ViewBuilder
    private func controlButtonLabel(title: String, icon: String, style: ControlStyle) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(style == .primary ? .white : workoutViewModel.themeColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            style == .primary
                ? AnyShapeStyle(
                    LinearGradient(
                        colors: [workoutViewModel.themeColor, workoutViewModel.themeColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                : AnyShapeStyle(Color.customSecondaryBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Actions

    private func startRun() {
        guard LegalConsentStore.hasAcceptedLegRunLocationDisclosure else {
            showLocationConsentSheet = true
            return
        }

        if !runTracker.canTrack {
            runTracker.requestAuthorization()
            return
        }

        let restrictionService = AppRestrictionService.shared
        if restrictionService.isAuthorized {
            restrictionService.startWorkoutRestriction()
        }

        runTracker.start()
    }

    private func togglePause() {
        if runTracker.isPaused {
            runTracker.resume()
        } else {
            runTracker.pause()
        }
    }

    private func finishRun() {
        guard runTracker.elapsedSeconds >= LegWorkoutSupport.minimumRunDurationSeconds else { return }

        completedDistanceMeters = runTracker.distanceMeters
        completedElapsedSeconds = runTracker.elapsedSeconds
        completedXP = WorkoutRewards.xp(forRepGoal: plannedSquatReps)

        runTracker.stop()

        workoutViewModel.completeLegRun(
            timeSpent: completedElapsedSeconds,
            distanceMeters: completedDistanceMeters,
            creditedSquatReps: plannedSquatReps
        )

        AppRestrictionService.shared.completeWorkoutRestriction()
        showCompletionSheet = true
    }

    private func formatClock(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    NavigationStack {
        LegRunSessionScreen(
            selectedTab: .constant(1),
            workoutViewModel: WorkoutViewModel(),
            plannedSquatReps: 30
        )
    }
}
