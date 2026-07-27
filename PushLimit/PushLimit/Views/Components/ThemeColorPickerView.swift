import SwiftUI

struct ThemeColorPickerView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Choose Theme Color")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.customLabel)
                
                Text("Select a color to customize your app highlights")
                    .font(.system(size: 16))
                    .foregroundColor(.customSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Color Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(WorkoutViewModel.availableThemeColors, id: \.self) { color in
                    ThemeColorOptionView(
                        color: color,
                        isSelected: colorsMatch(color, workoutViewModel.themeColor),
                        onTap: {
                            workoutViewModel.updateThemeColor(color)
                            dismiss()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.customBackground)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.customSecondaryLabel)
            }
        }
    }
    
    // Helper function to compare colors
    private func colorsMatch(_ color1: Color, _ color2: Color) -> Bool {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        // Compare with small tolerance for floating point
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01
    }
}

struct ThemeColorOptionView: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 70, height: 70)
                    .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 4)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    NavigationView {
        ThemeColorPickerView(workoutViewModel: WorkoutViewModel())
    }
}

