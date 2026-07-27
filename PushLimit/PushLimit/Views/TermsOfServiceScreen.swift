import SwiftUI

struct TermsOfServiceScreen: View {
    private let contactEmail = "richcmckain@gmail.com"
    private let effectiveDate = "July 07, 2026"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                LegalDocumentHeader(
                    title: "Terms of Service",
                    icon: "doc.text.fill",
                    effectiveDate: effectiveDate,
                    agreementText:
                        "Please read these Terms carefully before using PushLimit. By accessing or using the App, you agree to be bound by these Terms and our Privacy Policy. If you do not agree, do not use the App."
                )

                LegalDocumentAtAGlanceCard(
                    title: "Key points",
                    rows: [
                        (icon: "person.fill.checkmark", text: "Personal, non-commercial use only — you must be 13 or older"),
                        (icon: "heart.text.square.fill", text: "Not medical advice — consult a physician before exercising"),
                        (icon: "exclamationmark.triangle.fill", text: "You assume the risks of physical activity when using the App"),
                        (icon: "lock.shield.fill", text: "Optional accounts may sync data via Firebase cloud backup")
                    ]
                )

                LegalDocumentParagraph(
                    "These Terms of Service (\"Terms\") govern your use of the PushLimit iOS application (the \"App\" or \"Service\") operated by Apex Applications."
                )

                LegalDocumentSection(number: 1, title: "Acceptance of terms") {
                    LegalDocumentParagraph(
                        "By creating an account, completing onboarding, or using PushLimit, you confirm that you have read, understood, and agree to these Terms and our Privacy Policy."
                    )
                }

                LegalDocumentSection(number: 2, title: "Eligibility") {
                    LegalDocumentParagraph(
                        "PushLimit is intended for users 13 years of age or older. By using the App, you represent that you meet this requirement."
                    )
                    LegalDocumentParagraph(
                        "If you are under 18, you should use PushLimit only with permission from a parent or legal guardian."
                    )
                }

                LegalDocumentSection(number: 3, title: "Health & fitness disclaimer") {
                    LegalDocumentNote(
                        text: "PushLimit is a general fitness tool, not a medical device and not a substitute for professional medical advice, diagnosis, or treatment.",
                        icon: "cross.case.fill",
                        style: .warning
                    )
                    LegalDocumentBulletList(items: [
                        "Consult a physician or qualified healthcare provider before starting a new exercise program, especially if you are pregnant, have a medical condition, injury, or cardiovascular concerns",
                        "You are solely responsible for determining whether any workout is appropriate for your fitness level and health status",
                        "Stop exercising immediately if you experience pain, dizziness, shortness of breath, chest discomfort, or any unusual symptoms",
                        "PushLimit does not guarantee specific fitness, weight loss, strength, or health outcomes",
                        "Workout recommendations are estimates based on information you provide and may not be suitable for everyone"
                    ])
                    LegalDocumentNote(
                        text: "You voluntarily assume all risks associated with physical exercise and use of this App, including risk of injury. To the fullest extent permitted by law, PushLimit and its operators are not liable for injuries or health issues arising from your use of the App.",
                        icon: "exclamationmark.shield.fill",
                        style: .warning
                    )
                }

                LegalDocumentSection(number: 4, title: "Use of the app") {
                    LegalDocumentParagraph(
                        "You may use PushLimit only for lawful personal, non-commercial purposes. You agree not to:"
                    )
                    LegalDocumentBulletList(items: [
                        "Misuse, reverse engineer, or interfere with the App or its services",
                        "Attempt unauthorized access to accounts, servers, or data",
                        "Upload malicious content or use the App in a way that harms others"
                    ])
                }

                LegalDocumentSection(number: 5, title: "User content & data") {
                    LegalDocumentParagraph(
                        "You are responsible for information you provide, such as profile details and workout history. You must not submit false, misleading, or unlawful content."
                    )
                    LegalDocumentParagraph(
                        "Your use of the App is also governed by our Privacy Policy, which explains how we collect, store, and process your data."
                    )
                }

                LegalDocumentSection(number: 6, title: "Accounts & cloud backup") {
                    LegalDocumentParagraph(
                        "Optional account features may sync your data to cloud services such as Google Firebase. You are responsible for maintaining the security of your login credentials."
                    )
                    LegalDocumentParagraph(
                        "We may suspend or terminate access for violations of these Terms or conduct that harms the Service or other users."
                    )
                }

                LegalDocumentSection(number: 7, title: "Intellectual property") {
                    LegalDocumentParagraph(
                        "All content, features, branding, and functionality in PushLimit are owned by PushLimit, Apex Applications, or licensors and are protected by applicable intellectual property laws."
                    )
                    LegalDocumentParagraph(
                        "You may not copy, modify, distribute, or create derivative works from App content without prior written permission."
                    )
                }

                LegalDocumentSection(number: 8, title: "Disclaimer of warranties") {
                    LegalDocumentParagraph(
                        "PushLimit is provided \"as is\" and \"as available\" without warranties of any kind, whether express or implied, including merchantability, fitness for a particular purpose, accuracy of workout recommendations, or uninterrupted operation."
                    )
                }

                LegalDocumentSection(number: 9, title: "Limitation of liability") {
                    LegalDocumentParagraph(
                        "To the fullest extent permitted by law, PushLimit, Apex Applications, and their officers, employees, and affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or for personal injury, lost profits, or data loss arising from your use of the App — even if we have been advised of the possibility of such damages."
                    )
                    LegalDocumentParagraph(
                        "Some jurisdictions do not allow certain limitations; in those cases, our liability is limited to the maximum extent permitted by law."
                    )
                }

                LegalDocumentSection(number: 10, title: "Changes to terms") {
                    LegalDocumentParagraph(
                        "We may update these Terms from time to time. Material changes will be posted in the App with an updated effective date. Continued use after changes constitutes acceptance of the revised Terms."
                    )
                }

                LegalDocumentContactFooter(
                    prompt: "Questions about these Terms of Service:",
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
}

#Preview {
    NavigationStack {
        TermsOfServiceScreen()
    }
}
