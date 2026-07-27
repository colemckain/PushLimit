# ⚡ Quick Manual Signing Checklist

## Step-by-Step (Check off as you complete)

### 🌐 **In Apple Developer Portal** (developer.apple.com)

#### 1️⃣ Create App ID
- [ ] Go to: Certificates, Identifiers & Profiles → Identifiers
- [ ] Click ➕ button
- [ ] Select App IDs → App → Continue
- [ ] Enter:
  - Description: `PushLimit`
  - Bundle ID: `com.rcmckain.pushlimit`
- [ ] Enable capabilities:
  - ✅ Family Controls (MUST HAVE!)
  - ✅ Push Notifications
  - ✅ Time Sensitive Notifications
- [ ] Click Continue → Register

#### 2️⃣ Verify/Create Certificate
- [ ] Go to: Certificates section
- [ ] Check if you have valid "Apple Development" certificate
- [ ] If not, create one:
  - Open Keychain Access
  - Certificate Assistant → Request Certificate
  - Save to disk
  - Upload to developer portal
  - Download and double-click to install

#### 3️⃣ Register Device
- [ ] Connect your iPhone/iPad to Mac
- [ ] Get UDID from Xcode (Window → Devices)
- [ ] Go to: Devices section
- [ ] Click ➕ button
- [ ] Enter device name and UDID
- [ ] Click Register

#### 4️⃣ Create Provisioning Profile
- [ ] Go to: Profiles section
- [ ] Click ➕ button
- [ ] Select: iOS App Development
- [ ] Choose: PushLimit App ID
- [ ] Select: Your development certificate
- [ ] Select: Your registered device(s)
- [ ] Name: `PushLimit Development`
- [ ] Click Generate
- [ ] Download the .mobileprovision file

#### 5️⃣ Install Profile
- [ ] Double-click the downloaded .mobileprovision file
- [ ] Verify it installed (check ~/Library/MobileDevice/Provisioning Profiles/)

---

### 💻 **In Xcode**

#### 6️⃣ Configure Manual Signing
- [ ] Open PushLimit.xcodeproj
- [ ] Select PushLimit target
- [ ] Go to: Signing & Capabilities tab
- [ ] **UNCHECK** "Automatically manage signing"
- [ ] Under Signing (Debug):
  - Select your Team
  - Select "PushLimit Development" profile
  - Verify certificate shows
- [ ] Check that capabilities are present:
  - Family Controls ✅
  - Push Notifications ✅

#### 7️⃣ Build & Test
- [ ] Connect your iPhone/iPad via USB
- [ ] Select your device (not simulator) from device menu
- [ ] Clean build folder (Cmd+Shift+K)
- [ ] Build (Cmd+B)
- [ ] Run (Cmd+R)
- [ ] Trust developer on device if prompted:
  - Settings → General → VPN & Device Management

---

## ✅ Success Indicators

You'll know it worked when:
- ✅ Xcode shows no signing errors
- ✅ Build completes successfully
- ✅ App installs on your device
- ✅ App launches without "Untrusted Developer" error

---

## 🎯 What to Test

Once running on device:
1. **Delete app** and reinstall for fresh start
2. **Complete onboarding**:
   - Enter your name and info
   - Select fitness goal
   - Choose activity level
   - Do fitness assessment (20 pushups, etc.)
   - View your personalized plan
3. **Check Profile screen**:
   - See "Your Fitness Profile" section
   - See "Your Workout Plan" section
   - View weekly schedule
4. **Check Home screen**:
   - See "Today's Workout Plan" card

---

## ⚠️ Common Issues

| Error | Solution |
|-------|----------|
| "Profile doesn't include entitlement" | Enable Family Controls in App ID |
| "No matching profile" | Download manual profiles in Xcode Preferences |
| "Device not registered" | Add device UDID to developer portal |
| "Untrusted Developer" | Trust in Settings → General → Device Management |

---

## 🆘 Need Help?

If stuck, check which step failed and refer to the detailed guide:
`MANUAL_SIGNING_SETUP_GUIDE.md`

Or note:
- Step number where stuck: _____
- Error message: _____
- Screenshot: _____

---

**Bundle ID to use**: `com.rcmckain.pushlimit`

**Good luck! You've got this! 💪**

