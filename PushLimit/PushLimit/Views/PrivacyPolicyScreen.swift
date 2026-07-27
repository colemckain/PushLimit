import SwiftUI

struct PrivacyPolicyScreen: View {
    private let contactEmail = "richcmckain@gmail.com"
    private let effectiveDate = "July 26, 2026"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                LegalDocumentHeader(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    effectiveDate: effectiveDate,
                    agreementText:
                        "By using PushLimit, you agree to the collection and use of information in accordance with this policy. If you do not agree, please do not use the App."
                )

                LegalDocumentAtAGlanceCard(
                    title: "At a glance",
                    rows: [
                        (icon: "iphone", text: "Works without an account — data can stay on your device only"),
                        (icon: "icloud.fill", text: "Optional cloud backup via Firebase after email verification"),
                        (icon: "nosign", text: "No ads, no data sales, no Firebase Analytics"),
                        (icon: "location.fill", text: "GPS only during active leg runs — stops when you pause or finish")
                    ]
                )

                introductionBlock

                LegalDocumentSection(number: 1, title: "Who we are") {
                    LegalDocumentParagraph(
                        "PushLimit is operated by Apex Applications (\"Company\", \"we\", \"us\", or \"our\"). " +
                        "This Privacy Policy describes how we handle personal information when you use the PushLimit iOS application (the \"App\" or \"Service\")."
                    )
                    LegalDocumentContactRow(email: contactEmail, label: "Privacy inquiries")
                }

                LegalDocumentSection(number: 2, title: "Information we collect") {
                    LegalDocumentSubheading("Information you provide")
                    LegalDocumentBulletList(items: [
                        "Display name (optional during onboarding)",
                        "Email address and password (only if you create an account)",
                        "Profile details such as age (optional), gender, fitness goals, and activity level",
                        "Fitness assessment inputs (e.g., max reps) used to personalize your plan",
                        "Sleep schedule preferences (optional)",
                        "Workout data including exercises, reps, sets, time spent, streaks, XP/levels, weekly goals, and progress history"
                    ])

                    LegalDocumentSubheading("Stored on your device")
                    LegalDocumentBulletList(items: [
                        "Sensitive fitness and profile data is stored in the iOS Keychain (encrypted by the operating system)",
                        "Non-sensitive preferences (theme color, workout timer settings) may use standard app storage"
                    ])

                    LegalDocumentSubheading("Cloud backup (optional)")
                    LegalDocumentParagraph(
                        "If you sign in with a verified email address, we sync a backup to Google Cloud Firestore under your account. " +
                        "Only you can access your document. Firestore security rules require email verification and owner-only access."
                    )
                    firestoreFieldsCard

                    LegalDocumentSubheading("Push notifications (optional)")
                    LegalDocumentParagraph(
                        "If you enable notifications, Apple may provide a device push token for workout or sleep-habit reminders. " +
                        "We do not operate a separate backend server for push tokens."
                    )

                    LegalDocumentSubheading("Location during leg runs (optional)")
                    LegalDocumentParagraph(
                        "If you choose a GPS leg run, PushLimit uses your device location to calculate distance and draw your route on a map. " +
                        "With your permission, location updates continue while a run is active — including when the screen is locked or you switch to another app — so your workout is not interrupted. " +
                        "Location updates stop when you pause or finish the run. We do not track your location when you are not on an active run. " +
                        "Route and distance data stay on your device (and in your optional cloud backup with other workout data). We do not sell location data."
                    )

                    LegalDocumentSubheading("Information we do not collect")
                    LegalDocumentBulletList(items: [
                        "Continuous background location outside of an active leg run",
                        "Photos, camera, microphone, or contacts for advertising or unrelated features",
                        "HealthKit or Apple Health data",
                        "Payment or billing information (no in-app purchases)",
                        "Biometric identifiers (Face ID is not used by this App)"
                    ])
                }

                LegalDocumentSection(number: 3, title: "Third-party services") {
                    LegalDocumentParagraph(
                        "When you create an account and enable cloud backup, PushLimit uses Google Firebase as a service provider:"
                    )
                    firebaseServicesCard
                    LegalDocumentParagraph(
                        "We do not integrate Firebase Analytics, Google Analytics, or advertising SDKs in this App."
                    )
                    LegalDocumentParagraph(
                        "Google processes data on our behalf. See Google's Privacy Policy for details about their processing."
                    )
                    Link("policies.google.com/privacy", destination: URL(string: "https://policies.google.com/privacy")!)
                        .font(.system(size: AppTypography.caption, weight: .semibold))
                    LegalDocumentParagraph(
                        "Firebase may collect limited technical and diagnostic information (device model, OS version, IP address, app instance identifiers) when SDKs communicate with Google's servers."
                    )
                }

                LegalDocumentSection(number: 4, title: "How we use your information") {
                    LegalDocumentBulletList(items: [
                        "Provide workout plans, progress tracking, streaks, levels, and personalized recommendations",
                        "Track optional leg-run distance and route while a run is active (including in the background until you pause or finish)",
                        "Save and restore your data on your device",
                        "Back up and sync data across devices when you use a verified account",
                        "Send optional notifications you enable",
                        "Protect the Service (App Check, security rules, abuse prevention)",
                        "Respond to support requests"
                    ])
                    LegalDocumentNote(text: "We do not use your data for third-party advertising or cross-app tracking.")
                }

                LegalDocumentSection(number: 5, title: "Legal bases") {
                    LegalDocumentParagraph("Depending on your location, we process personal data based on:")
                    LegalDocumentBulletList(items: [
                        "Performance of a contract — to provide the App and account features you request",
                        "Legitimate interests — to secure the Service and improve reliability",
                        "Consent — where required (for example, optional notifications and optional leg-run location tracking)"
                    ])
                }

                LegalDocumentSection(number: 6, title: "How we share information") {
                    LegalDocumentParagraph("We do not sell your personal information.")
                    LegalDocumentParagraph("We may share information only in these limited cases:")
                    LegalDocumentBulletList(items: [
                        "Service providers — Google Firebase, solely to operate authentication and cloud backup",
                        "Legal requirements — if required by law, court order, or to protect rights, safety, or security",
                        "Business transfers — if PushLimit or its assets are acquired, subject to notice where required by law"
                    ])
                    LegalDocumentNote(text: "PushLimit has no public social features — your workout data is not shared with other users through the App.")
                }

                LegalDocumentSection(number: 7, title: "Data retention") {
                    LegalDocumentBulletList(items: [
                        "On your device: Data remains until you delete it or reset the App",
                        "In the cloud: Data is retained in Firestore until you delete it or use the App's reset feature",
                        "Firebase Authentication: Your email and account identifier may remain after a data reset until full account deletion is completed"
                    ])
                    LegalDocumentParagraph(
                        "We retain data only as long as needed for the purposes described in this policy or as required by law."
                    )
                }

                LegalDocumentSection(number: 8, title: "Data security") {
                    LegalDocumentBulletList(items: [
                        "iOS Keychain for sensitive local data",
                        "HTTPS for network communication with Firebase",
                        "Firestore security rules (owner-only, verified-email access)",
                        "Firebase App Check to reduce unauthorized API access",
                        "No sensitive logging in Release builds"
                    ])
                    LegalDocumentParagraph(
                        "No method of transmission or storage is 100% secure. Use the Service at your own risk."
                    )
                }

                LegalDocumentSection(number: 9, title: "Your rights and choices") {
                    LegalDocumentParagraph(
                        "Depending on your location (including California, EU/UK GDPR), you may have the right to access, correct, delete, or port your data, object to or restrict processing, and withdraw consent where applicable."
                    )
                    LegalDocumentBulletList(items: [
                        "In the App: Profile → Data & reset to wipe local data and your Firestore backup (when signed in)",
                        "By email: Contact us for access, correction, or deletion requests"
                    ])
                    LegalDocumentContactRow(email: contactEmail, label: "Exercise your rights")
                }

                LegalDocumentSection(number: 10, title: "Children's privacy") {
                    LegalDocumentParagraph(
                        "PushLimit is not intended for children under 13. We do not knowingly collect personal information from children under 13. " +
                        "If you believe a child has provided us data, contact us and we will take steps to delete it."
                    )
                }

                LegalDocumentSection(number: 11, title: "International transfers") {
                    LegalDocumentParagraph(
                        "Your data may be processed in the United States and other countries where Google/Firebase operates. " +
                        "By using cloud backup, you understand your data may be transferred internationally. " +
                        "Google uses appropriate safeguards as described in their documentation."
                    )
                }

                LegalDocumentSection(number: 12, title: "Changes to this policy") {
                    LegalDocumentParagraph(
                        "We may update this Privacy Policy from time to time. We will post the revised policy in the App with an updated effective date. " +
                        "Material changes may also be communicated in-app or by email where appropriate."
                    )
                }

                LegalDocumentContactFooter(
                    prompt: "Questions about this Privacy Policy or your personal data:",
                    email: contactEmail
                )
            }
            .frame(maxWidth: 600)
            .centerOnIPad(700)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .legalDocumentPage()
    }

    private var introductionBlock: some View {
        LegalDocumentParagraph(
            "This Privacy Policy explains how PushLimit collects, uses, stores, and shares your information. " +
            "We are committed to handling your data responsibly and transparently."
        )
    }

    // MARK: - Tables / cards

    private var firestoreFieldsCard: some View {
        VStack(spacing: 0) {
            LegalDocumentTableRow(field: "userName", description: "Your display name")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "userProfileJson", description: "Goals, activity level, sleep schedule")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "fitnessAssessmentJson", description: "Your fitness assessment")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "workoutPlanJson", description: "Personalized workout plan")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "workoutsJson", description: "Completed workout history")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "levelInfoJson", description: "XP and level progress")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "weeklyGoalsJson / weeklyProgressJson", description: "Weekly targets and completion")
            LegalDocumentDivider()
            LegalDocumentTableRow(field: "schemaVersion / updatedAt", description: "Technical sync metadata")
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var firebaseServicesCard: some View {
        VStack(spacing: 0) {
            LegalDocumentServiceRow(
                name: "Firebase Authentication",
                purpose: "Account sign-in, password reset, and email verification"
            )
            LegalDocumentDivider()
            LegalDocumentServiceRow(
                name: "Cloud Firestore",
                purpose: "Encrypted-at-rest cloud backup under users/{your user ID}"
            )
            LegalDocumentDivider()
            LegalDocumentServiceRow(
                name: "Firebase App Check",
                purpose: "Abuse prevention via App Attest / DeviceCheck"
            )
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyScreen()
    }
}
