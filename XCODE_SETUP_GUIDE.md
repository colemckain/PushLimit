# Xcode Project Configuration Guide for App Store Submission

## 🎯 Current Configuration Status

✅ **Bundle Identifier**: `rcmckain.tech.PushLimit`  
✅ **Development Team**: `8WU84H5ZHB`  
✅ **Code Signing**: Automatic signing enabled  
✅ **Push Notifications**: Entitlements configured  
✅ **iOS Deployment Target**: 18.5  

## 📋 Step-by-Step Configuration

### 1. Open Xcode Project
```bash
open PushLimit/PushLimit.xcodeproj
```

### 2. Configure Bundle Identifier

1. **Select the project** in the navigator (top-level "PushLimit")
2. **Select the "PushLimit" target**
3. **Go to "Signing & Capabilities" tab**
4. **Update Bundle Identifier** (if needed):
   - Current: `rcmckain.tech.PushLimit`
   - Recommended: `com.yourcompany.pushlimit` or keep current

### 3. Configure Apple Developer Team

1. **In "Signing & Capabilities" tab**:
   - **Team**: Select your Apple Developer Team
   - **Automatically manage signing**: ✅ Enabled
   - **Provisioning Profile**: Should be auto-generated

### 4. Enable Push Notifications Capability

1. **In "Signing & Capabilities" tab**:
   - Click **"+ Capability"** button
   - Search for **"Push Notifications"**
   - Click **"Push Notifications"** to add it

2. **Verify Entitlements**:
   - The `PushLimit.entitlements` file should show:
     - `aps-environment` = `development`
     - `com.apple.developer.usernotifications.time-sensitive` = `true`

### 5. Configure App Store Build Settings

1. **Select "Any iOS Device"** as the target device
2. **Product → Archive** to create an App Store build
3. **Use Xcode Organizer** to upload to App Store Connect

### 6. Apple Developer Portal Setup

1. **Create App ID**:
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Certificates, Identifiers & Profiles → Identifiers
   - Create new App ID with your bundle identifier
   - Enable Push Notifications capability

2. **Generate Push Certificates**:
   - Create APNs Development Certificate
   - Create APNs Production Certificate
   - Download and install certificates

3. **Create Provisioning Profiles**:
   - Development profile for testing
   - App Store profile for distribution

### 7. App Store Connect Setup

1. **Create App Record**:
   - Go to [App Store Connect](https://appstoreconnect.apple.com/)
   - My Apps → "+" → New App
   - Fill in app information:
     - **Name**: PushLimit
     - **Bundle ID**: Select your App ID
     - **SKU**: Unique identifier (e.g., "pushlimit2024")
     - **User Access**: Full Access

2. **Configure App Information**:
   - **App Information**: Basic details
   - **Pricing and Availability**: Set pricing
   - **App Review Information**: Contact details
   - **Version Information**: Screenshots and metadata

## 🔧 Advanced Configuration

### Environment-Specific Entitlements

The project includes two entitlements files:
- `PushLimit.entitlements` - Development (aps-environment: development)
- `PushLimit_Production.entitlements` - Production (aps-environment: production)

### Build Configurations

- **Debug**: Uses development entitlements
- **Release**: Uses production entitlements (for App Store)

### Push Notification Server Setup

1. **Update NetworkService.swift**:
   ```swift
   // In AppConstants.swift, update the API base URL
   static let baseURL = "https://your-server.com/api"
   ```

2. **Configure Server**:
   - Upload APNs certificates to your server
   - Implement push notification sending logic
   - Update `sendDeviceTokenToServer` method in `PushNotificationService.swift`

## 🚨 Important Notes

### Bundle Identifier Requirements
- Must be unique across the App Store
- Format: `com.company.appname` (recommended)
- Cannot be changed after App Store submission

### Team ID Verification
- Current Team ID: `8WU84H5ZHB`
- Verify this matches your Apple Developer account
- Ensure you have the correct role (Admin or App Manager)

### Push Notifications
- Requires Apple Developer Program membership ($99/year)
- Certificates expire annually
- Test thoroughly on physical devices

### App Store Review
- Ensure all privacy descriptions are accurate
- Test push notifications thoroughly
- Follow Apple's App Store Review Guidelines

## 🧪 Testing Checklist

- [ ] App builds successfully for "Any iOS Device"
- [ ] Push notifications work on physical device
- [ ] App launches without crashes
- [ ] All features work as expected
- [ ] Privacy descriptions are accurate
- [ ] App icons display correctly
- [ ] Launch screen appears properly

## 📞 Support

If you encounter issues:
1. Check Apple Developer documentation
2. Verify certificates and provisioning profiles
3. Test on physical devices
4. Review Xcode build logs for errors

## 🔄 Next Steps

After configuration:
1. **Test the app** thoroughly on physical devices
2. **Create App Store screenshots** and metadata
3. **Submit for App Store review**
4. **Monitor review status** in App Store Connect 