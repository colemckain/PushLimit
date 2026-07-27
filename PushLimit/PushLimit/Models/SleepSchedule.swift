import Foundation

/// User's typical sleep window — stored in `UserProfile` and synced to Firestore.
struct SleepSchedule: Codable, Equatable {
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var wakeHour: Int
    var wakeMinute: Int

    static let recommendedDefault = SleepSchedule(
        bedtimeHour: 22,
        bedtimeMinute: 30,
        wakeHour: 6,
        wakeMinute: 30
    )

    init(bedtimeHour: Int, bedtimeMinute: Int, wakeHour: Int, wakeMinute: Int) {
        self.bedtimeHour = Self.clampHour(bedtimeHour)
        self.bedtimeMinute = Self.clampMinute(bedtimeMinute)
        self.wakeHour = Self.clampHour(wakeHour)
        self.wakeMinute = Self.clampMinute(wakeMinute)
    }

    // MARK: - Formatting

    var formattedBedtime: String {
        Self.format(hour: bedtimeHour, minute: bedtimeMinute)
    }

    var formattedWakeTime: String {
        Self.format(hour: wakeHour, minute: wakeMinute)
    }

    var formattedDuration: String {
        let hours = durationHours
        if abs(hours.rounded() - hours) < 0.05 {
            return "\(Int(hours.rounded()))h"
        }
        return String(format: "%.1fh", hours)
    }

    /// Hours between bedtime and wake (handles crossing midnight).
    var durationHours: Double {
        let bed = bedtimeHour * 60 + bedtimeMinute
        var wake = wakeHour * 60 + wakeMinute
        if wake <= bed {
            wake += 24 * 60
        }
        return Double(wake - bed) / 60.0
    }

    var isHealthyDuration: Bool {
        durationHours >= 7.0
    }

    var durationQualityLabel: String {
        switch durationHours {
        case ..<6:
            return "Below target"
        case 6..<7:
            return "Almost there"
        case 7..<9:
            return "Strong recovery"
        default:
            return "Plenty of rest"
        }
    }

    // MARK: - Time-of-day context

    enum DayPhase {
        case activeDay
        case windDown
        case sleeping
        case morningRecovery
    }

    func dayPhase(at date: Date = Date(), calendar: Calendar = .current) -> DayPhase {
        let nowMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let bedMinutes = bedtimeHour * 60 + bedtimeMinute
        var wakeMinutes = wakeHour * 60 + wakeMinute

        if wakeMinutes <= bedMinutes {
            // Sleep crosses midnight
            let inLateNight = nowMinutes >= bedMinutes
            let inEarlyMorning = nowMinutes < wakeMinutes
            if inLateNight || inEarlyMorning {
                return .sleeping
            }
            let windDownStart = max(0, bedMinutes - 60)
            if nowMinutes >= windDownStart && nowMinutes < bedMinutes {
                return .windDown
            }
            let morningEnd = min(24 * 60, wakeMinutes + 120)
            if nowMinutes >= wakeMinutes && nowMinutes < morningEnd {
                return .morningRecovery
            }
            return .activeDay
        }

        // Same-calendar-day sleep (unusual but supported)
        if nowMinutes >= bedMinutes && nowMinutes < wakeMinutes {
            return .sleeping
        }
        let windDownStart = max(0, bedMinutes - 60)
        if nowMinutes >= windDownStart && nowMinutes < bedMinutes {
            return .windDown
        }
        if nowMinutes >= wakeMinutes && nowMinutes < wakeMinutes + 120 {
            return .morningRecovery
        }
        return .activeDay
    }

    func habitHeadline(at date: Date = Date()) -> String {
        PushLimitVoiceCopy.sleepHabitHeadline(
            phase: dayPhase(at: date),
            isHealthyDuration: isHealthyDuration
        )
    }

    func habitMessage(at date: Date = Date()) -> String {
        PushLimitVoiceCopy.sleepHabitMessage(
            phase: dayPhase(at: date),
            formattedBedtime: formattedBedtime,
            formattedWakeTime: formattedWakeTime,
            formattedDuration: formattedDuration,
            isHealthyDuration: isHealthyDuration
        )
    }

    func habitMessageBrief(at date: Date = Date()) -> String {
        PushLimitVoiceCopy.sleepHabitMessageBrief(
            phase: dayPhase(at: date),
            formattedBedtime: formattedBedtime,
            formattedDuration: formattedDuration,
            isHealthyDuration: isHealthyDuration
        )
    }

    func statusBadge(at date: Date = Date()) -> (label: String, isPositive: Bool) {
        PushLimitVoiceCopy.sleepStatusBadge(
            phase: dayPhase(at: date),
            isHealthyDuration: isHealthyDuration
        )
    }

    // MARK: - Date helpers for pickers

    func bedtimeDate(on reference: Date = Date(), calendar: Calendar = .current) -> Date {
        date(hour: bedtimeHour, minute: bedtimeMinute, on: reference, calendar: calendar)
    }

    func wakeDate(on reference: Date = Date(), calendar: Calendar = .current) -> Date {
        date(hour: wakeHour, minute: wakeMinute, on: reference, calendar: calendar)
    }

    mutating func setBedtime(from date: Date, calendar: Calendar = .current) {
        bedtimeHour = calendar.component(.hour, from: date)
        bedtimeMinute = calendar.component(.minute, from: date)
    }

    mutating func setWakeTime(from date: Date, calendar: Calendar = .current) {
        wakeHour = calendar.component(.hour, from: date)
        wakeMinute = calendar.component(.minute, from: date)
    }

    // MARK: - Private

    private static func clampHour(_ value: Int) -> Int {
        min(23, max(0, value))
    }

    private static func clampMinute(_ value: Int) -> Int {
        min(59, max(0, value))
    }

    private static func format(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else {
            return String(format: "%d:%02d", hour, minute)
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func date(hour: Int, minute: Int, on reference: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: reference)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? reference
    }
}
