import Foundation

/// PushLimit coaching voice — supportive or discipline mode (`FeedbackTone`).
enum PushLimitVoiceCopy {

    private static var isSupportive: Bool {
        FeedbackTone.current == .supportive
    }

    // MARK: - Notifications — workout (11 AM)

    static func morningWorkout(
        recommendation: WorkoutPlan.DailyRecommendation?
    ) -> (title: String, body: String) {
        guard let recommendation else {
            return pick(morningOnboardingPool, supportiveMorningOnboardingPool)
        }
        if recommendation.restDay || recommendation.exercises.isEmpty {
            return pick(morningRestDayPool, supportiveMorningRestDayPool)
        }
        return pick(morningTrainingPool, supportiveMorningTrainingPool)
    }

    // MARK: - Notifications — workout (3 PM)

    static func afternoonWorkout(
        recommendation: WorkoutPlan.DailyRecommendation?,
        completedCount: Int,
        totalCount: Int,
        nextExercise: String?
    ) -> (title: String, body: String) {
        guard let recommendation else {
            return pick(afternoonOnboardingPool, supportiveAfternoonOnboardingPool)
        }

        if (recommendation.restDay || recommendation.exercises.isEmpty), completedCount == 0 {
            return pick(afternoonRestDayPool, supportiveAfternoonRestDayPool)
        }

        if completedCount == 0 {
            return pick(afternoonNotStartedPool, supportiveAfternoonNotStartedPool)
        }

        if completedCount < totalCount {
            let exercise = nextExercise ?? "your next set"
            if isSupportive {
                return (
                    title: "Nice start",
                    body: "\(completedCount)/\(totalCount) done. Finish with \(exercise) when you're ready."
                )
            }
            return (
                title: "Finish what you started",
                body: "Half done isn't discipline. \(completedCount)/\(totalCount) complete — close with \(exercise)."
            )
        }

        return pick(afternoonCompletePool, supportiveAfternoonCompletePool)
    }

    // MARK: - Notifications — early quit (incomplete workout)

    /// Fired when the user ends a session early with remaining work still owed.
    static func earlyQuitIncomplete(
        exerciseName: String,
        completedReps: Int
    ) -> (title: String, body: String) {
        let name = shortExerciseLabel(exerciseName)
        let repsBit = completedReps > 0 ? "\(completedReps) reps" : "what you knocked out"

        if isSupportive {
            let pool = supportiveEarlyQuitPool.map { title, body in
                (
                    title: title,
                    body: body
                        .replacingOccurrences(of: "{exercise}", with: name)
                        .replacingOccurrences(of: "{reps}", with: repsBit)
                )
            }
            return pool[dayIndex % pool.count]
        }

        let pool = earlyQuitDisciplinedPool.map { title, body in
            (
                title: title,
                body: body
                    .replacingOccurrences(of: "{exercise}", with: name)
                    .replacingOccurrences(of: "{reps}", with: repsBit)
            )
        }
        return pool[dayIndex % pool.count]
    }

    /// Backward-compatible alias used by debt scheduling.
    static func earlyQuitDebt(
        exerciseName: String,
        leftoverReps: Int,
        extraSetReps: Int
    ) -> (title: String, body: String) {
        _ = leftoverReps
        _ = extraSetReps
        return earlyQuitIncomplete(exerciseName: exerciseName, completedReps: 0)
    }

    private static func shortExerciseLabel(_ name: String) -> String {
        if name.lowercased().contains("core") { return "Core" }
        if name.lowercased().contains("push") { return "Push-ups" }
        if name.lowercased().contains("leg") || name.lowercased().contains("squat") { return "Legs" }
        return name
    }

    // MARK: - Notifications — sleep

    static func bedtime(streak: Int) -> (title: String, body: String) {
        _ = streak
        return pick(bedtimePool, supportiveBedtimePool)
    }

    static func wake(streak: Int) -> (title: String, body: String) {
        if isSupportive {
            if streak >= 7 {
                return (
                    title: "Good morning",
                    body: "Day \(streak) of showing up. A short session today keeps your rhythm going."
                )
            }
            if streak >= 1 {
                return (
                    title: "Good morning",
                    body: "You rested well. Your plan is ready whenever you are — no rush."
                )
            }
            let item = supportiveWakePool[dayIndex % supportiveWakePool.count]
            return item
        }

        if streak >= 7 {
            return (
                title: "Day \(streak). Show up.",
                body: "A week of consistency. Protect 10 minutes for yourself today and keep it moving."
            )
        }
        if streak >= 3 {
            return (
                title: "Keep the streak",
                body: "Day \(streak). You want more for yourself — one short session protects that."
            )
        }
        if streak >= 1 {
            return (
                title: "Morning discipline",
                body: "You showed up yesterday. Make 10 minutes for yourself again today."
            )
        }
        return pick(wakePool, supportiveWakePool)
    }

    // MARK: - Workout completion screen

    static func workoutCompletionHeadline() -> String {
        let pool = isSupportive ? supportiveCompletionHeadlines : completionHeadlines
        return pool[dayIndex % pool.count]
    }

    static func workoutCompletionQuote() -> String {
        let pool = isSupportive ? supportiveCompletionQuotes : completionQuotes
        return pool[dayIndex % pool.count]
    }

    static func weeklyGoalCaption(goalAchieved: Bool, remaining: Int) -> String {
        if isSupportive {
            if goalAchieved {
                return "Weekly goal reached — great work. Keep building at your own pace."
            }
            if remaining > 0 {
                return "\(remaining) left this week. Small sessions still move you forward."
            }
            return "Every bit of progress counts. You're building something real."
        }
        if goalAchieved {
            return "Weekly target cleared. Discipline stacks — keep the standard high."
        }
        if remaining > 0 {
            return "\(remaining) left this week. Fifteen minutes for yourself still moves the week forward."
        }
        return "Stack small wins. Consistency is built in minutes, not memberships."
    }

    // MARK: - Profile level progress

    static func profileLevelMotivation(progress: Double) -> String {
        if isSupportive {
            if progress >= 0.9 {
                return "Almost there — one more session gets you to the next level."
            }
            if progress >= 0.65 {
                return "You're close. Keep showing up — momentum is on your side."
            }
            if progress >= 0.35 {
                return "Steady progress. Every workout brings you closer."
            }
            return "You're building something. One session at a time."
        }
        if progress >= 0.9 {
            return "One more session. No drive required — just finish what you started."
        }
        if progress >= 0.65 {
            return "Close to the next rank. Discipline is showing up again before excuses win."
        }
        if progress >= 0.35 {
            return "Momentum is building. Ten minutes at home still counts."
        }
        return "Every rep chips away at the excuse that you don't have time."
    }

    // MARK: - Sleep habit (Home + model)

    static func sleepSetupTitle() -> String {
        isSupportive ? "Recovery matters" : "Recovery is discipline"
    }

    static func sleepSetupSubtitle() -> String {
        isSupportive
            ? "Add sleep times in Profile — we'll send gentle recovery reminders."
            : "Set bedtime and wake time — we'll nudge you, not monitor you."
    }

    static func sleepOnboardingSubtitle() -> String {
        isSupportive
            ? "Good sleep helps you train better. Set your window — we'll remind you, not track you."
            : "You can't out-train bad sleep. Consistent recovery makes the 10-minute sessions count."
    }

    static func sleepWhyWeTrack() -> String {
        isSupportive
            ? "Sleep fuels your training. We use your schedule for kind recovery reminders — never overnight monitoring."
            : "Sleep is the habit behind every rep. We use your schedule for recovery nudges — discipline includes rest."
    }

    static func sleepHabitHeadline(phase: SleepSchedule.DayPhase, isHealthyDuration: Bool) -> String {
        if isSupportive {
            switch phase {
            case .windDown: return "Wind-down time"
            case .sleeping: return "Rest well"
            case .morningRecovery: return "Good morning"
            case .activeDay:
                return isHealthyDuration ? "Sleep supports your training" : "Build your sleep rhythm"
            }
        }
        switch phase {
        case .windDown: return "Wind down on purpose"
        case .sleeping: return "Recovery in progress"
        case .morningRecovery: return "Morning discipline"
        case .activeDay:
            return isHealthyDuration ? "Recovery fuels training" : "Build the sleep habit"
        }
    }

    static func sleepHabitMessage(
        phase: SleepSchedule.DayPhase,
        formattedBedtime: String,
        formattedWakeTime: String,
        formattedDuration: String,
        isHealthyDuration: Bool
    ) -> String {
        if isSupportive {
            switch phase {
            case .windDown:
                return "Bedtime is \(formattedBedtime). Ease into rest — tomorrow's workout will feel better."
            case .sleeping:
                return "You're in your sleep window. Rest up — you've earned it."
            case .morningRecovery:
                return "Up at \(formattedWakeTime). Take your time — your workout is here when you're ready."
            case .activeDay:
                if isHealthyDuration {
                    return "Targeting \(formattedDuration) of sleep. Recovery helps you show up stronger."
                }
                return "Aim for 7+ hours when you can. Better rest makes training feel easier."
            }
        }
        switch phase {
        case .windDown:
            return "Bedtime is \(formattedBedtime). Shut it down — tomorrow's session starts with making time for yourself."
        case .sleeping:
            return "You're in your sleep window. Rest now so tomorrow's 10 minutes actually move the needle."
        case .morningRecovery:
            return "Up at \(formattedWakeTime). No commute required — your floor is waiting when you're ready."
        case .activeDay:
            if isHealthyDuration {
                return "Targeting \(formattedDuration) of sleep. Discipline isn't just workouts — it's protecting your energy."
            }
            return "Aim for 7+ hours. You want more for yourself — recovery makes the short sessions sustainable."
        }
    }

    static func sleepHabitMessageBrief(
        phase: SleepSchedule.DayPhase,
        formattedBedtime: String,
        formattedDuration: String,
        isHealthyDuration: Bool
    ) -> String {
        if isSupportive {
            switch phase {
            case .windDown: return "Wind down for \(formattedBedtime)."
            case .sleeping: return "Rest now — tomorrow's a fresh start."
            case .morningRecovery: return "Good sleep helps you show up."
            case .activeDay:
                return isHealthyDuration
                    ? "\(formattedDuration) target — recovery supports you."
                    : "Aim for 7+ hours when you can."
            }
        }
        switch phase {
        case .windDown: return "Wind down for \(formattedBedtime) — excuses lose tomorrow."
        case .sleeping: return "Rest now. Tomorrow's session is 10 minutes you carve out for yourself."
        case .morningRecovery: return "Consistent sleep. Consistent training. No drive required."
        case .activeDay:
            return isHealthyDuration
                ? "\(formattedDuration) target — recovery is part of discipline."
                : "7+ hours tonight. You can't out-train exhaustion."
        }
    }

    static func sleepStatusBadge(phase: SleepSchedule.DayPhase, isHealthyDuration: Bool) -> (label: String, isPositive: Bool) {
        switch phase {
        case .windDown: return ("Wind down", false)
        case .sleeping: return ("Resting", true)
        case .morningRecovery: return ("Recover", true)
        case .activeDay:
            return isHealthyDuration ? ("On track", true) : (isSupportive ? "Build habit" : "Build habit", false)
        }
    }

    // MARK: - Discipline pools

    private static let morningOnboardingPool: [(String, String)] = [
        ("5 minutes. Your plan.", "Set up once, then make a little time for yourself each day."),
        ("Start where you are", "You don't need an hour. Finish setup, then take 10–15 minutes for yourself.")
    ]

    private static let morningRestDayPool: [(String, String)] = [
        ("Rest is scheduled", "Recovery is discipline too. Optional extra work: 10 minutes, zero commute."),
        ("Off day — your call", "No plan today. If you still want more, take 10 minutes for yourself.")
    ]

    private static let morningTrainingPool: [(String, String)] = [
        ("Make the time", "Ten to fifteen minutes for yourself today — that's discipline."),
        ("No hour required", "You want more for yourself. A short window is enough to show up today."),
        ("Before excuses win", "Too busy later? Protect one short session for yourself right now."),
        ("Consistency starts here", "One workout today beats another promise you'll postpone."),
        ("Your floor. Your time.", "Distance and duration are excuses. Your plan fits in 15 minutes."),
        ("Discipline is showing up", "Not when it's easy — when the day feels too full and you still make the time.")
    ]

    private static let afternoonOnboardingPool: [(String, String)] = [
        ("Still thinking about it?", "Set your plan — 10 minutes for yourself is enough to begin."),
        ("Time you actually have", "Finish setup and train on your terms, in the time you really have.")
    ]

    private static let afternoonRestDayPool: [(String, String)] = [
        ("10 minutes if you want it", "Rest day on the plan. Extra reps are optional if you want a little time for yourself."),
        ("Your standards, your call", "Scheduled off — but discipline doesn't always follow a calendar.")
    ]

    private static let afternoonNotStartedPool: [(String, String)] = [
        ("The day is slipping", "You still have 10–15 minutes to give yourself today."),
        ("Stop negotiating", "You don't need a perfect window. You need one short session for yourself."),
        ("You owe yourself one", "Consistency is making the time even when life gets loud."),
        ("Still winnable today", "Open PushLimit. Take 10–15 minutes for yourself and get it done."),
        ("Discipline, not convenience", "You want more for yourself. Prove it in one session before the day ends.")
    ]

    private static let afternoonCompletePool: [(String, String)] = [
        ("You chose yourself", "Full session done. You made the time and followed through."),
        ("Consistency logged", "You made time when it was easier to skip. That's the whole game."),
        ("Excuses didn't win", "Short session. Real effort. Show up again tomorrow.")
    ]

    private static let bedtimePool: [(String, String)] = [
        ("Shut it down", "Tomorrow's session is built tonight. Discipline includes recovery."),
        ("Recovery on schedule", "You can't out-train bad sleep. Rest now — earn tomorrow's reps."),
        ("Close the day", "Sleep now so tomorrow you can make time for yourself and show up strong."),
        ("Wind down on purpose", "Consistency isn't just workouts — it's protecting your energy.")
    ]

    private static let wakePool: [(String, String)] = [
        ("No commute required", "You want more for yourself. Start with 10 minutes that belong to you."),
        ("Morning discipline", "The day will get loud. Make time for yourself before excuses pile up."),
        ("Small window. Real work.", "You don't need an hour or a membership. You need one session."),
        ("Show up for you", "Consistency beats motivation. Your plan fits before the day steals your time.")
    ]

    /// Discipline mode — early quit incomplete workout.
    private static let earlyQuitDisciplinedPool: [(String, String)] = [
        (
            "Not so fast",
            "Nice try cutting {exercise} short. {reps} counted — but Done only counts when you finish the full set–rest session in one sitting. Restart when you’re ready."
        ),
        (
            "Half isn’t the workout",
            "{reps} saved on {exercise}. Splitting it up skips the burn. Come back and run the full session top to bottom."
        ),
        (
            "No free passes",
            "You quit early on {exercise}. Progress is saved, but you still need one uninterrupted full workout to clear today."
        ),
        (
            "Finish what you start",
            "Progress saved — session incomplete. Return for a full {exercise} sitting when you’re ready to be serious."
        )
    ]

    private static let completionHeadlines: [String] = [
        "Excuses didn't win.",
        "You chose yourself.",
        "Discipline logged.",
        "Consistency counts.",
        "Time made.",
        "You showed up.",
        "Work done."
    ]

    private static let completionQuotes: [String] = [
        "You made time for yourself. Ten minutes done with intention — that's discipline.",
        "Too much going on? You still carved out the time and got it done.",
        "You want more for yourself. Today you proved it by making the time.",
        "Motivation is optional. Showing up isn't — and you did.",
        "Small session. Real standard. Stack another one tomorrow.",
        "Nobody saw it. You did it anyway. That's the whole game.",
        "The excuse was time. You found ten minutes. Keep that energy.",
        "Consistency isn't a membership — it's choosing yourself again."
    ]

    // MARK: - Supportive pools

    private static let supportiveMorningOnboardingPool: [(String, String)] = [
        ("Welcome", "A few quick steps and your plan is ready — train at home, on your schedule."),
        ("Let's get started", "Set up your plan and take 10–15 minutes for yourself at your own pace.")
    ]

    private static let supportiveMorningRestDayPool: [(String, String)] = [
        ("Rest day", "Recovery is part of progress. Optional light work if you feel like it."),
        ("Take it easy today", "Your plan has a rest day. Listen to your body.")
    ]

    private static let supportiveMorningTrainingPool: [(String, String)] = [
        ("Good morning", "Your workout fits in 10–15 minutes at home. Start whenever you're ready."),
        ("You've got this", "A short session today beats waiting for a perfect time."),
        ("Small steps count", "You don't need an hour — just one workout, right where you are."),
        ("Your pace, your place", "Train at home in the time you actually have."),
        ("Ready when you are", "Your plan is set. Open PushLimit when it works for you."),
        ("A win is a win", "Even 10 minutes of movement moves you forward.")
    ]

    private static let supportiveAfternoonOnboardingPool: [(String, String)] = [
        ("Almost there", "Finish setup and your personalized plan is ready."),
        ("Quick setup", "A few more steps — then train at home on your schedule.")
    ]

    private static let supportiveAfternoonRestDayPool: [(String, String)] = [
        ("Rest day", "Optional extra reps if you want them — no pressure."),
        ("Easy does it", "Scheduled rest. Be proud of the work you've already put in.")
    ]

    private static let supportiveAfternoonNotStartedPool: [(String, String)] = [
        ("Gentle reminder", "Your plan is waiting — about 10–15 minutes at home."),
        ("Still time today", "Whenever you're ready, your workout fits in a short break."),
        ("You've got time", "A small session still counts — even if all you have is a short break."),
        ("Meet yourself halfway", "Not feeling up for much? Train in the time you have."),
        ("Progress over perfect", "One workout today is enough. Start small — that's okay.")
    ]

    private static let supportiveAfternoonCompletePool: [(String, String)] = [
        ("Well done today", "Full session complete. You showed up for yourself."),
        ("Proud of you", "You made time to train. That consistency adds up."),
        ("Session complete", "Great work — rest up and come back when you're ready.")
    ]

    private static let supportiveBedtimePool: [(String, String)] = [
        ("Time to rest", "Good sleep helps tomorrow's workout feel better."),
        ("Wind down", "Recovery is part of getting stronger. Rest well tonight."),
        ("Sleep well", "You've done enough today. Let your body recharge."),
        ("Sweet dreams", "Tomorrow is another chance to show up — after you rest.")
    ]

    private static let supportiveWakePool: [(String, String)] = [
        ("Good morning", "Whenever you're ready, your plan fits in a short window at home."),
        ("Fresh start", "A new day — even 10 minutes of movement is a win."),
        ("Take your time", "No rush. Your workout is here when you are."),
        ("You've got this", "Small sessions add up. Start when it feels right.")
    ]

    /// Supportive mode — early quit incomplete workout.
    private static let supportiveEarlyQuitPool: [(String, String)] = [
        (
            "Good job so far",
            "Nice work on the {reps} you finished. When you can, restart {exercise} and finish the full set–rest session in one go — that’s where the payoff is."
        ),
        (
            "Solid start",
            "What you did on {exercise} counts. A full uninterrupted sitting next time will feel even better."
        ),
        (
            "Proud of the effort",
            "Ending early is okay — your progress is saved. Restart from the top whenever you’ve got time for the full {exercise} session."
        ),
        (
            "Almost there",
            "Great job showing up for {exercise}. One full session without stopping mid-way will mark today Done."
        )
    ]

    private static let supportiveCompletionHeadlines: [String] = [
        "You showed up.",
        "Well done.",
        "Session complete.",
        "Nice work today.",
        "That's a win.",
        "You did it.",
        "Progress made."
    ]

    private static let supportiveCompletionQuotes: [String] = [
        "Small session, real progress. Be proud of showing up for yourself.",
        "You didn't need a perfect schedule — you still made time and got it done.",
        "Consistency grows one workout at a time. Today counted.",
        "Future you will be glad you moved today.",
        "Every rep was a choice to take care of yourself.",
        "Not every day is easy — you trained anyway. That matters.",
        "Ten minutes at home beats waiting for the perfect moment.",
        "You're building a habit. Today was another brick."
    ]

    // MARK: - Rotation

    private static var dayIndex: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    }

    private static func pick(
        _ disciplined: [(String, String)],
        _ supportive: [(String, String)]
    ) -> (title: String, body: String) {
        let pool = isSupportive ? supportive : disciplined
        return pool[dayIndex % pool.count]
    }
}

typealias PushLimitNotificationCopy = PushLimitVoiceCopy
