# 📱 Manual Signing Setup Guide for PushLimit

## Overview
This guide will help you set up manual code signing for PushLimit to enable Device Activity and Family Controls features.

---

## ✅ Prerequisites
- [x] Apple Developer Program membership ($99/year) - **You have this!**
- [ ] Physical iPhone/iPad for testing
- [ ] macOS with Xcode installed

---

## 🎯 Step-by-Step Process

### **Step 1: Create App ID in Apple Developer Portal**

1. **Open your browser** and go to: https://developer.apple.com

2. **Sign in** with your Apple Developer account

3. Navigate to **Certificates, Identifiers & Profiles**
   - URL: https://developer.apple.com/account/resources/identifiers/list

4. Click the **➕ (Plus)** button to add a new identifier

5. Select **App IDs** → Click **Continue**

6. Select **App** (not App Clip) → Click **Continue**

7. **Configure the App ID:**
   ```
   Description: PushLimit
   Bundle ID: Explicit
   Bundle ID String: com.rcmckain.pushlimit
   ```
   ⚠️ **Important**: The Bundle ID must **exactly match** what's in your Xcode project!

8. **Scroll down to Capabilities** and enable these:
   
   **Required for PushLimit:**
   - ✅ **Family Controls** (this is the key one!)
   - ✅ **Push Notifications**
   - ✅ **Time Sensitive Notifications**
   
   **Optional (if you use them):**
   - ✅ **iCloud** (if using CloudKit)
   - ✅ **App Groups** (if needed)

9. Click **Continue** → Review → Click **Register**

10. ✅ **Checkpoint**: You should see "Registration Complete"

---

### **Step 2: Create/Verify Development Certificate**

You might already have one, but let's check:

1. In the same portal, go to **Certificates** section
   - URL: https://developer.apple.com/account/resources/certificates/list

2. Look for **Apple Development** or **iOS Development** certificate
   - If you see one that's **valid** (not expired), **skip to Step 3**
   - If you don't have one or it's expired, continue below

3. **To create a new certificate:**
   - Click **➕ (Plus)** button
   - Select **Apple Development** → Continue
   - Follow the instructions to create a Certificate Signing Request (CSR)
   
   **To create CSR on Mac:**
   ```
   a. Open "Keychain Access" app
   b. Menu: Keychain Access → Certificate Assistant → Request Certificate from Certificate Authority
   c. Enter your email
   d. Select "Saved to disk"
   e. Click Continue
   f. Save the .certSigningRequest file
   ```
   
   - Upload the CSR file
   - Download the certificate
   - **Double-click** the downloaded certificate to install it

4. ✅ **Checkpoint**: You should have a valid development certificate

---

### **Step 3: Register Your Test Device**

1. In the portal, go to **Devices** section
   - URL: https://developer.apple.com/account/resources/devices/list

2. **Get your device UDID:**
   
   **Option A - Using Xcode:**
   ```
   a. Connect your iPhone/iPad to your Mac
   b. Open Xcode
   c. Window → Devices and Simulators
   d. Select your device
   e. Look for "Identifier" - that's your UDID
   f. Right-click → Copy
   ```
   
   **Option B - Using Finder:**
   ```
   a. Connect your iPhone/iPad
   b. Open Finder
   c. Select your device in sidebar
   d. Click on the serial number text - it will change to UDID
   e. Cmd+C to copy
   ```

3. **Register the device:**
   - Click **➕ (Plus)** button
   - Select **iOS, tvOS, watchOS** → Continue
   - Enter:
     ```
     Device Name: My iPhone (or whatever you prefer)
     Device ID (UDID): [paste the UDID you copied]
     ```
   - Click **Continue** → **Register**

4. ✅ **Checkpoint**: Your device should appear in the devices list

---

### **Step 4: Create Provisioning Profile**

1. In the portal, go to **Profiles** section
   - URL: https://developer.apple.com/account/resources/profiles/list

2. Click **➕ (Plus)** button

3. Select **iOS App Development** → Click **Continue**

4. **Select App ID:**
   - Find and select **PushLimit** (com.rcmckain.pushlimit)
   - Click **Continue**

5. **Select Certificate:**
   - Check your development certificate
   - Click **Continue**

6. **Select Devices:**
   - Check the device(s) you want to test on
   - Click **Continue**

7. **Name the profile:**
   ```
   Provisioning Profile Name: PushLimit Development
   ```
   - Click **Generate**

8. **Download the profile:**
   - Click **Download**
   - Save it to your Desktop or Downloads folder
   - The file will be named something like: `PushLimit_Development.mobileprovision`

9. ✅ **Checkpoint**: Profile downloaded successfully

---

### **Step 5: Install Provisioning Profile**

1. **Locate the downloaded file** (usually in Downloads folder)
   - File name: `PushLimit_Development.mobileprovision`

2. **Double-click the file** to install it
   - This will automatically add it to Xcode

3. **Verify installation:**
   ```
   Open Terminal and run:
   open ~/Library/MobileDevice/Provisioning\ Profiles/
   ```
   - You should see your .mobileprovision file there

4. ✅ **Checkpoint**: Profile installed in Xcode

---

### **Step 6: Configure Xcode for Manual Signing**

1. **Open your Xcode project:**
   - File: `/Users/colemckain/Desktop/PushLimit/PushLimit/PushLimit.xcodeproj`

2. **Select the PushLimit target:**
   - In the left sidebar (Project Navigator), click on **PushLimit** (the blue icon at top)
   - In the main area, select the **PushLimit** target (not the project)

3. **Go to Signing & Capabilities tab**

4. **Disable automatic signing:**
   - **UNCHECK** ☐ "Automatically manage signing"

5. **Configure Debug signing:**
   - Under **Signing (Debug)** section:
     ```
     Team: [Select your team name]
     Provisioning Profile: PushLimit Development (or "Download Profile" if needed)
     Signing Certificate: Apple Development: [Your name]
     ```

6. **Configure Release signing (optional for now):**
   - Same as Debug settings
   - Or you can configure this later when you're ready for TestFlight/App Store

7. **Verify capabilities are present:**
   - You should see these capabilities listed:
     - Family Controls
     - Push Notifications
     - Time Sensitive Notifications

8. ✅ **Checkpoint**: No signing errors in Xcode

---

### **Step 7: Build and Test**

1. **Connect your physical iPhone/iPad** to your Mac

2. **Select your device** as the build destination:
   - At the top of Xcode, click the device selector (next to the scheme)
   - Select your connected device (NOT a simulator)

3. **Clean Build Folder:**
   - Menu: Product → Clean Build Folder (Shift+Cmd+K)

4. **Build the project:**
   - Menu: Product → Build (Cmd+B)
   - Wait for build to complete

5. **Run on device:**
   - Menu: Product → Run (Cmd+R)
   - Or click the Play ▶️ button

6. **First time on device:**
   - You might see: "Untrusted Developer"
   - On your iPhone: Settings → General → VPN & Device Management
   - Tap your developer name → Trust

7. ✅ **Success!** App should launch on your device

---

## 🎯 Testing the New Features

Once the app is running on your device, you can test:

### **Onboarding Flow:**
1. Delete the app and reinstall (or clear data)
2. Go through the new 8-step onboarding
3. Complete the fitness assessment
4. See your personalized workout plan

### **Profile Screen:**
1. Navigate to Profile tab
2. See "Your Fitness Profile" section
3. See "Your Workout Plan" section
4. View the weekly schedule
5. Read the "Why these goals?" explanation

### **Home Screen:**
1. Check for "Today's Workout Plan" card
2. See recommended exercises for today
3. Tap "Start Workout" button

---

## 🔧 Troubleshooting

### **"Provisioning profile doesn't include entitlement"**
→ Make sure you enabled **Family Controls** when creating the App ID (Step 1)

### **"No profiles for 'com.rcmckain.pushlimit'"**
→ Go to Xcode → Preferences → Accounts → Download Manual Profiles

### **"Code signing is required"**
→ Make sure you selected your Team in Signing & Capabilities

### **"Unable to install"**
→ Make sure your device UDID is registered and included in the provisioning profile

### **Build succeeds but app won't run on device**
→ Check Settings → General → VPN & Device Management → Trust developer

---

## 📝 Quick Reference

### **Important URLs:**
- Developer Portal: https://developer.apple.com/account
- Certificates: https://developer.apple.com/account/resources/certificates/list
- Identifiers: https://developer.apple.com/account/resources/identifiers/list
- Devices: https://developer.apple.com/account/resources/devices/list
- Profiles: https://developer.apple.com/account/resources/profiles/list

### **Your App Details:**
```
App Name: PushLimit
Bundle ID: com.rcmckain.pushlimit
Team: [Your team name from developer account]
Required Capabilities: Family Controls, Push Notifications
```

---

## ✅ Final Checklist

Before you start:
- [ ] Apple Developer account is active
- [ ] Physical iPhone/iPad available
- [ ] USB cable to connect device

In Apple Developer Portal:
- [ ] App ID created with Family Controls enabled
- [ ] Development certificate created/verified
- [ ] Device registered (UDID added)
- [ ] Provisioning profile created
- [ ] Profile downloaded and installed

In Xcode:
- [ ] Automatic signing disabled
- [ ] Team selected
- [ ] Provisioning profile selected
- [ ] Build succeeds
- [ ] App runs on device

---

## 🎉 Success!

Once everything is set up, you'll be able to:
✅ Test on real device
✅ Use Family Controls/Device Activity features
✅ Test all the new onboarding features
✅ See personalized workout plans
✅ Use app restriction features

The setup is a bit involved, but once it's done, it works smoothly!

---

**Need Help?** If you get stuck at any step, let me know which step number and what error you're seeing!

