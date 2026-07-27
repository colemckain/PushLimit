# PushLimit

Short workouts for busy, tired, starting-from-zero days. Build a streak, earn XP, and get coached your way — supportive or hard truth.

**PushLimit** is a native iOS fitness app for people who don’t have a perfect schedule — just a goal to show up.

## What it does

- Personalized plan in about a minute
- Short **10–15 minute** sessions that fit real life
- **Streaks, XP, levels,** and weekly goals
- Coaching voice you choose: **supportive** or **discipline**
- Sleep habit / recovery window on Home
- Optional **GPS leg runs** that keep tracking while your phone is locked or you’re in another app — until you pause or finish

## Open in Xcode

```bash
git clone https://github.com/colemckain/PushLimit.git
cd PushLimit
open PushLimit/PushLimit.xcodeproj
```

## Requirements

- macOS with Xcode (recent recommended)
- iOS device or simulator
- Apple Developer signing for device builds

## Setup notes

1. Select your **Team** under Signing & Capabilities in Xcode.
2. Add your Firebase config as `GoogleService-Info.plist` (not committed — see `GoogleService-Info.plist.example` and `FIRESTORE_SETUP.md`).
3. Build and run the **PushLimit** scheme.

## License

All rights reserved. This repository is public for viewing. You may not copy, modify, distribute, or reuse this code without permission.
