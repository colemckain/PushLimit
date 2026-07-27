import SwiftUI

#if false // Family Controls disabled - set to true when enabled

import FamilyControls

struct AppSelectionView: View {
    @ObservedObject var restrictionService = AppRestrictionService.shared
    @State private var showingAppPicker = false
    @State private var showingAuthorizationAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Workout Unlock")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text("Select apps to lock until your workout is complete")
                    .font(.system(size: 16))
                    .foregroundColor(.customLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            // Status Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: restrictionService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(restrictionService.isAuthorized ? .green : .orange)
                        .font(.system(size: 20))
                    
                    Text(restrictionService.isAuthorized ? "Screen Time Access Granted" : "Screen Time Access Required")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.customLabel)
                    
                    Spacer()
                }
                
                if !restrictionService.isAuthorized {
                    Text("PushLimit needs permission to manage app restrictions. This allows us to lock distracting apps until you complete your workout.")
                        .font(.system(size: 14))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(Color.customBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            
            // App Selection
            if restrictionService.isAuthorized {
                VStack(spacing: 12) {
                    HStack {
                        Text("Selected Apps")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.customLabel)
                        
                        Spacer()
                        
                        Text("\(restrictionService.selectedApps.applicationTokens.count) apps")
                            .font(.system(size: 14))
                            .foregroundColor(.customLabel)
                    }
                    
                    if restrictionService.selectedApps.applicationTokens.isEmpty {
                        Text("No apps selected")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Apps will be locked during workouts")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(Color.customBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if !restrictionService.isAuthorized {
                    Button(action: {
                        Task {
                            await restrictionService.requestAuthorization()
                        }
                    }) {
                        Text("Grant Screen Time Access")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.customOrange)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        showingAppPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Select Apps to Restrict")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.customOrange)
                        .cornerRadius(12)
                    }
                    .familyActivityPicker(isPresented: $showingAppPicker, selection: $restrictionService.selectedApps)
                    .onChange(of: restrictionService.selectedApps) { _, newSelection in
                        restrictionService.saveSelection()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .background(Color.customBackground)
        .alert("Screen Time Access Required", isPresented: $showingAuthorizationAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable Screen Time access in Settings to use this feature.")
        }
    }
}

#Preview {
    AppSelectionView()
}
#else

// Stub view when Family Controls is disabled
struct AppSelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Feature Unavailable")
                .font(.system(size: 24, weight: .bold))
            
            Text("App restrictions require Family Controls capability and manual code signing.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Text("This feature is currently disabled for simulator testing.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#endif
