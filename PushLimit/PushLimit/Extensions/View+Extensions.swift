import SwiftUI

extension View {
    
    // MARK: - Corner Radius
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    // MARK: - Shadow
    func customShadow(color: Color = .black, radius: CGFloat = 4, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self.shadow(color: color.opacity(0.1), radius: radius, x: x, y: y)
    }
    
    // MARK: - Loading State
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
    }
    
    // MARK: - Error Alert
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(
            "Error",
            isPresented: .constant(error.wrappedValue != nil),
            presenting: localizedAlertError
        ) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
    
    // MARK: - Hide Keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Conditional Modifier
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // MARK: - iPad Responsive Design
    
    /// Responsive padding that adapts to device size
    func responsivePadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        let padding = length ?? (isIPad ? 32 : 16)
        return self.padding(edges, padding)
    }
    
    /// Responsive horizontal padding
    func responsiveHorizontalPadding(_ length: CGFloat? = nil) -> some View {
        let padding = length ?? (isIPad ? 40 : 20)
        return self.padding(.horizontal, padding)
    }
    
    /// Responsive font size that scales with device
    func responsiveFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        let scaleFactor: CGFloat = isIPad ? 1.3 : 1.0
        let uiFontStyle: UIFont.TextStyle
        switch style {
        case .largeTitle: uiFontStyle = .largeTitle
        case .title: uiFontStyle = .title1
        case .title2: uiFontStyle = .title2
        case .title3: uiFontStyle = .title3
        case .headline: uiFontStyle = .headline
        case .subheadline: uiFontStyle = .subheadline
        case .body: uiFontStyle = .body
        case .callout: uiFontStyle = .callout
        case .footnote: uiFontStyle = .footnote
        case .caption: uiFontStyle = .caption1
        case .caption2: uiFontStyle = .caption2
        default: uiFontStyle = .body
        }
        return self.font(.system(size: UIFont.preferredFont(forTextStyle: uiFontStyle).pointSize * scaleFactor, weight: weight))
    }
    
    /// Responsive corner radius
    func responsiveCornerRadius(_ radius: CGFloat) -> some View {
        let adjustedRadius = isIPad ? radius * 1.2 : radius
        return self.cornerRadius(adjustedRadius)
    }
    
    /// Responsive spacing for VStack/HStack
    func responsiveSpacing(_ spacing: CGFloat) -> some View {
        return self
    }
    
    /// Maximum width constraint for iPad
    func maxWidthForIPad(_ maxWidth: CGFloat = 600) -> some View {
        self.frame(maxWidth: isIPad ? maxWidth : .infinity)
            .if(isIPad) { view in
                view.frame(maxWidth: .infinity)
            }
    }
    
    /// Center content on iPad with max width
    func centerOnIPad(_ maxWidth: CGFloat = 600) -> some View {
        self.maxWidthForIPad(maxWidth)
            .if(isIPad) { view in
                HStack {
                    Spacer()
                    view
                    Spacer()
                }
            }
    }
    
    /// Responsive grid columns for iPad
    func responsiveGridColumns(_ columns: [GridItem]) -> some View {
        return self
    }
}

// MARK: - Device Detection
extension View {
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Localized Alert Error
struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
} 