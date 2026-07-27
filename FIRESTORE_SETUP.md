# Firebase security & Firestore setup

PushLimit saves profile, workouts, and progress to **Cloud Firestore** under `users/{uid}` when the user is signed in with a **verified** Firebase Auth email.

---

## Pre-release security checklist (do before App Store / TestFlight)

Work through these in order. Items marked **repo** are in this project; items marked **console** are done in Firebase / Google Cloud.

### 1. App Check enforcement (console)

The app enables App Check in code (`FirebaseBootstrap.swift` — App Attest in Release, debug provider in Debug).

- [ ] Firebase Console → **Build** → **App Check** → register the iOS app (`com.rcmckain.pushlimit`)
- [ ] Provider: **App Attest** (iOS 14+)
- [ ] Run a **Debug** build once; register the debug token printed in Xcode (`Firebase App Check debug token: …`)
- [ ] Turn on **enforcement** (not just monitoring) for:
  - [ ] **Cloud Firestore**
  - [ ] **Authentication**
- [ ] Confirm a Release/TestFlight build can sign in and sync after enforcement is on

### 2. API key restrictions (console)

The iOS API key ships inside `GoogleService-Info.plist`. Restrict every key in the project.

1. [Google Cloud Console](https://console.cloud.google.com/) → project **pushlimit-5f647**
2. **APIs & Services** → **Credentials**
3. For **each** API key (Browser, iOS, etc.):
   - [ ] **Application restrictions** → **iOS apps** → bundle ID `com.rcmckain.pushlimit`
   - [ ] **API restrictions** → limit to Firebase-related APIs only
4. [ ] Delete or disable any unused / duplicate keys
5. [ ] Re-test sign-in and Firestore sync after saving

### 3. Firestore rules — verified email (repo + console)

Rules in **`firestore.rules`** require:

- Signed-in user owns the document (`uid` match)
- **`email_verified == true`** on the auth token (server-side, not just in the app)
- Default deny on all other paths

**Deploy to Firebase** (pick one):

**Option A — Firebase Console:** Firestore → **Rules** → paste contents of `firestore.rules` → **Publish**

**Option B — Firebase CLI:**

```bash
npm install -g firebase-tools
firebase login
firebase use pushlimit-5f647
firebase deploy --only firestore:rules
```

### 4. Firestore rules — schema & size limits (repo + console)

Same `firestore.rules` file limits:

| Field | Max size |
|--------|----------|
| `userName` | 100 chars |
| `userProfileJson` | 51,200 chars |
| `fitnessAssessmentJson` | 20,480 chars (optional) |
| `workoutPlanJson` | 102,400 chars (optional) |
| `workoutsJson` | 512,000 chars |
| `levelInfoJson` | 10,240 chars |
| `weeklyGoalsJson` | 10,240 chars |
| `weeklyProgressJson` | 10,240 chars |
| `schemaVersion` | int 1–10 |
| `updatedAt` | server timestamp |

Only the fields above are allowed; everything else is rejected.

The app also validates cloud payloads locally via `RemoteSnapshotValidator.swift` before decoding JSON.

### 5. No PII in Release logs (repo — done)

`DebugLog` strips logging in Release builds. Remaining `print()` calls in workout/notification code were migrated to `DebugLog`.

### 6. `GoogleService-Info.plist` not in git (repo)

Real plist files are listed in **`.gitignore`**. A redacted template is committed as **`GoogleService-Info.plist.example`**.

**New machine / clone:**

1. Firebase Console → Project settings → your iOS app → download `GoogleService-Info.plist`
2. Place it at `PushLimit/GoogleService-Info.plist` (referenced by the Xcode project)
3. Do not commit the real file

**If the real plist was already committed:** rotate is not required for iOS-restricted keys, but you should still stop tracking it:

```bash
git rm --cached PushLimit/GoogleService-Info.plist GoogleService-Info.plist
```

Keep your local copies; only remove them from git history going forward.

---

## Firestore database

1. Open the [Firebase Console](https://console.firebase.google.com/) → your project.
2. **Build** → **Firestore Database** → create the database if needed.

## Authentication settings

Firebase Console → **Authentication** → **Settings**:

- Turn on **Email enumeration protection** if available.
- Under **Authorized domains**, keep only domains you use.
- Consider enabling **password policy** to match the app’s 8+ character rule.

## What gets stored

Document path: `users/{Firebase Auth UID}`

| Field | Description |
|--------|-------------|
| `userName` | Display name |
| `userProfileJson` | JSON `UserProfile` |
| `fitnessAssessmentJson` | Optional JSON `FitnessAssessment` |
| `workoutPlanJson` | Optional JSON `WorkoutPlan` |
| `workoutsJson` | Completed workouts |
| `levelInfoJson` | XP / level |
| `weeklyGoalsJson` / `weeklyProgressJson` | Weekly targets & progress |
| `schemaVersion` | `2` |
| `updatedAt` | Server timestamp |

Email is stored in **Firebase Auth** only, not in the Firestore document.

## App behavior

- **Sign up**: verification email is sent; cloud backup stays paused until the user verifies.
- **Sign in**: local app works immediately; cloud sync requires verified email.
- **Local save**: if signed in **and verified**, changes sync to Firestore automatically.
- **Sign out**: ends the cloud session only; **local workouts and profile stay on this device** (stored in Keychain). Sign in again to sync.
- **Reset all data**: wipes local Keychain data and deletes the cloud document when signed in.

PushLimit stays on Firebase’s **free Spark plan**. SMS two-factor authentication is **not** offered because it requires Blaze billing for SMS. Account protection on the free tier: strong passwords, email verification, App Check, Firestore rules, and Keychain local storage.

If you see permission errors, verify the checklist above — especially rules publish, App Check enforcement, API key restrictions, and verified email.
