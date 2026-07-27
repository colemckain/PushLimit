import CoreLocation
import Combine
import UIKit

@MainActor
final class RunTrackingService: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var elapsedSeconds = 0
    @Published var distanceMeters: Double = 0
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var currentLocation: CLLocation?
    @Published var mapCenterCoordinate: CLLocationCoordinate2D?
    @Published var locationError: String?
    @Published private(set) var hasReceivedLocationFix = false

    private let locationManager = CLLocationManager()
    private var elapsedTimer: Timer?
    private var lastAcceptedLocation: CLLocation?
    private var isPreviewingLocation = false

    /// Wall-clock anchors so elapsed time keeps advancing while the app is backgrounded.
    private var runStartedAt: Date?
    private var accumulatedPausedSeconds: TimeInterval = 0
    private var pauseStartedAt: Date?

    override init() {
        authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        // Keep delivering updates during continuous outdoor runs (Apple fitness pattern).
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    var canTrack: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestAuthorization() {
        // When In Use is sufficient for active workout tracking with background location mode.
        // Always authorization is not required and should not be requested for this feature.
        locationManager.requestWhenInUseAuthorization()
    }

    /// Starts GPS updates so the map can center on the user before the run begins.
    func startLocationPreview() {
        guard canTrack else { return }
        guard !isTracking else { return }

        isPreviewingLocation = true
        setBackgroundLocationUpdatesEnabled(false)
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
    }

    func stopLocationPreview() {
        guard isPreviewingLocation, !isTracking else { return }
        isPreviewingLocation = false
        locationManager.stopUpdatingLocation()
    }

    private func handleAuthorizationGranted() {
        startLocationPreview()
    }

    func start() {
        guard canTrack else {
            requestAuthorization()
            return
        }

        resetSessionMetrics()
        isPreviewingLocation = false
        isTracking = true
        isPaused = false
        runStartedAt = Date()
        accumulatedPausedSeconds = 0
        pauseStartedAt = nil

        setBackgroundLocationUpdatesEnabled(true)
        locationManager.startUpdatingLocation()
        setIdleTimerDisabled(true)
        startElapsedTimer()
    }

    func pause() {
        guard isTracking, !isPaused else { return }
        isPaused = true
        pauseStartedAt = Date()
        refreshElapsedSeconds()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        setIdleTimerDisabled(false)
        // Pause must fully stop GPS + background location so the system blue indicator clears.
        setBackgroundLocationUpdatesEnabled(false)
        locationManager.stopUpdatingLocation()
    }

    func resume() {
        guard isTracking, isPaused else { return }
        if let pauseStartedAt {
            accumulatedPausedSeconds += Date().timeIntervalSince(pauseStartedAt)
        }
        pauseStartedAt = nil
        isPaused = false

        setBackgroundLocationUpdatesEnabled(true)
        locationManager.startUpdatingLocation()
        setIdleTimerDisabled(true)
        refreshElapsedSeconds()
        startElapsedTimer()
    }

    func stop() {
        isTracking = false
        isPaused = false
        isPreviewingLocation = false
        refreshElapsedSeconds()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        runStartedAt = nil
        pauseStartedAt = nil
        accumulatedPausedSeconds = 0
        setIdleTimerDisabled(false)
        setBackgroundLocationUpdatesEnabled(false)
        locationManager.stopUpdatingLocation()
    }

    private func resetSessionMetrics() {
        elapsedSeconds = 0
        distanceMeters = 0
        routeCoordinates = []
        currentLocation = nil
        mapCenterCoordinate = nil
        lastAcceptedLocation = nil
        locationError = nil
        hasReceivedLocationFix = false
        runStartedAt = nil
        accumulatedPausedSeconds = 0
        pauseStartedAt = nil
    }

    /// Enables continuous location delivery while an active (non-paused) run is in progress.
    /// Requires `UIBackgroundModes` → `location` in Info.plist. Fatal if set without that key.
    private func setBackgroundLocationUpdatesEnabled(_ enabled: Bool) {
        locationManager.allowsBackgroundLocationUpdates = enabled
        locationManager.showsBackgroundLocationIndicator = enabled
    }

    private func setIdleTimerDisabled(_ disabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disabled
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isTracking, !self.isPaused else { return }
                self.refreshElapsedSeconds()
            }
        }
        // `.common` keeps the timer firing during map interaction / scrolling.
        RunLoop.main.add(timer, forMode: .common)
        elapsedTimer = timer
        refreshElapsedSeconds()
    }

    private func refreshElapsedSeconds() {
        guard let runStartedAt else {
            elapsedSeconds = 0
            return
        }

        var paused = accumulatedPausedSeconds
        if let pauseStartedAt {
            paused += Date().timeIntervalSince(pauseStartedAt)
        }

        elapsedSeconds = max(0, Int(Date().timeIntervalSince(runStartedAt) - paused))
    }

    private func isValidLocation(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0 else { return false }

        let ageSeconds = -location.timestamp.timeIntervalSinceNow
        guard ageSeconds < 30 else { return false }

        let maxAccuracy = isTracking ? 40.0 : 150.0
        return location.horizontalAccuracy <= maxAccuracy
    }

    private func acceptLocation(_ location: CLLocation) {
        guard isValidLocation(location) else { return }

        currentLocation = location
        mapCenterCoordinate = location.coordinate
        hasReceivedLocationFix = true
        locationError = nil

        guard isTracking, !isPaused else { return }

        if routeCoordinates.isEmpty {
            routeCoordinates.append(location.coordinate)
            lastAcceptedLocation = location
            return
        }

        if let previous = lastAcceptedLocation {
            let delta = location.distance(from: previous)
            guard delta >= 2 else { return }
            distanceMeters += delta
            routeCoordinates.append(location.coordinate)
            lastAcceptedLocation = location
        }
    }
}

extension RunTrackingService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if canTrack {
                handleAuthorizationGranted()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            acceptLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
        }
    }
}
