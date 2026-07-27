import SwiftUI

struct StatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: isIPad ? 12 : 8) {
            Text(label)
                .responsiveFont(.subheadline, weight: .bold)
                .foregroundColor(.customLabel)
            
            Text(value)
                .responsiveFont(.title2, weight: .bold)
                .foregroundColor(.customLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(isIPad ? 24 : 16)
        .background(Color.customBackground)
        .responsiveCornerRadius(12)
        .customShadow()
    }
}

#Preview {
    StatCard(label: "Total Reps", value: "25")
        .padding()
} 