import SwiftUI

// MARK: - Document chrome

struct LegalDocumentHeader: View {
    let title: String
    let icon: String
    let effectiveDate: String
    let agreementText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.customOrange.opacity(0.22), Color.customOrange.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.customOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: AppTypography.screenTitle, weight: .bold))
                        .foregroundColor(.customLabel)
                    Text("PushLimit · Apex Applications")
                        .font(.system(size: AppTypography.caption, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                }
            }

            HStack(spacing: 8) {
                LegalDocumentMetaBadge(label: "Effective", value: effectiveDate)
                LegalDocumentMetaBadge(label: "Version", value: LegalCopy.policyVersion)
            }

            Text(agreementText)
                .font(.system(size: AppTypography.bodyMedium, weight: .regular))
                .foregroundColor(.customSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.groupInner + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .legalDocumentCard()
    }
}

struct LegalDocumentAtAGlanceCard: View {
    let title: String
    let rows: [(icon: String, text: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "doc.text.fill")
                .font(.system(size: AppTypography.body, weight: .semibold))
                .foregroundColor(.customLabel)

            VStack(spacing: 10) {
                ForEach(rows.indices, id: \.self) { index in
                    LegalDocumentHighlightRow(icon: rows[index].icon, text: rows[index].text)
                }
            }
        }
        .padding(AppSpacing.groupInner + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.customOrange.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous)
                .strokeBorder(Color.customOrange.opacity(0.18), lineWidth: 0.5)
        }
    }
}

struct LegalDocumentContactFooter: View {
    let prompt: String
    let email: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact")
                .font(.system(size: AppTypography.sectionTitle, weight: .semibold))
                .foregroundColor(.customLabel)

            Text(prompt)
                .font(.system(size: AppTypography.bodyMedium, weight: .regular))
                .foregroundColor(.customSecondaryLabel)

            if let url = URL(string: "mailto:\(email)") {
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(email)
                            .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                    }
                    .foregroundColor(.customOrange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.customOrange.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            Text("© \(Calendar.current.component(.year, from: Date())) Apex Applications. All rights reserved.")
                .font(.system(size: AppTypography.captionSmall, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .padding(.top, 4)
        }
        .padding(AppSpacing.groupInner + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .legalDocumentCard()
    }
}

// MARK: - Section building blocks

struct LegalDocumentSection<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.customOrange)
                    .frame(width: 26, height: 26)
                    .background(Color.customOrange.opacity(0.12))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: AppTypography.sectionTitle, weight: .semibold))
                    .foregroundColor(.customLabel)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(.leading, 4)
        }
        .padding(AppSpacing.groupInner + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .legalDocumentCard()
    }
}

struct LegalDocumentParagraph: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: AppTypography.bodyMedium, weight: .regular))
            .foregroundColor(.customLabel)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct LegalDocumentSubheading: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: AppTypography.captionSmall, weight: .bold))
            .foregroundColor(.customSecondaryLabel)
            .tracking(0.6)
            .padding(.top, 4)
    }
}

struct LegalDocumentBulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                        .font(.system(size: AppTypography.bodyMedium, weight: .bold))
                        .foregroundColor(.customOrange)
                    Text(item)
                        .font(.system(size: AppTypography.bodyMedium, weight: .regular))
                        .foregroundColor(.customLabel)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct LegalDocumentNote: View {
    let text: String
    var icon: String = "info.circle.fill"
    var style: NoteStyle = .info

    enum NoteStyle {
        case info
        case warning
    }

    private var accentColor: Color {
        style == .warning ? .orange : .customOrange
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
            Text(text)
                .font(.system(size: AppTypography.caption, weight: .medium))
                .foregroundColor(.customSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LegalDocumentMetaBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.customSecondaryLabel)
                .tracking(0.5)
            Text(value)
                .font(.system(size: AppTypography.caption, weight: .semibold))
                .foregroundColor(.customLabel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LegalDocumentHighlightRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customOrange)
                .frame(width: 20)
            Text(text)
                .font(.system(size: AppTypography.caption, weight: .medium))
                .foregroundColor(.customLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LegalDocumentTableRow: View {
    let field: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(field)
                .font(.system(size: AppTypography.captionSmall, weight: .semibold, design: .monospaced))
                .foregroundColor(.customOrange)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(description)
                .font(.system(size: AppTypography.caption, weight: .regular))
                .foregroundColor(.customLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct LegalDocumentServiceRow: View {
    let name: String
    let purpose: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                .foregroundColor(.customLabel)
            Text(purpose)
                .font(.system(size: AppTypography.caption, weight: .regular))
                .foregroundColor(.customSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct LegalDocumentContactRow: View {
    let email: String
    let label: String

    var body: some View {
        if let url = URL(string: "mailto:\(email)") {
            Link(destination: url) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.system(size: 14, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: AppTypography.captionSmall, weight: .medium))
                            .foregroundColor(.customSecondaryLabel)
                        Text(email)
                            .font(.system(size: AppTypography.bodyMedium, weight: .semibold))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.customOrange)
                .padding(12)
                .background(Color.customOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct LegalDocumentDivider: View {
    var body: some View {
        Divider().opacity(0.35).padding(.leading, 12)
    }
}

// MARK: - Layout helpers

extension View {
    func legalDocumentCard() -> some View {
        background {
            RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppSpacing.groupRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5)
                }
        }
    }

    func legalDocumentPage() -> some View {
        background(Color.customBackground)
            .profileDetailNavigation()
    }
}
