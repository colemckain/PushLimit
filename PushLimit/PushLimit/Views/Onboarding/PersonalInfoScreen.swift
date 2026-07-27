import SwiftUI

struct PersonalInfoScreen: View {
    @Binding var userName: String
    @Binding var age: String
    @Binding var selectedGender: UserProfile.Gender
    let onContinue: () -> Void
    let themeColor: Color

    @FocusState private var focusedField: Field?
    @State private var nameError: String?
    @State private var ageError: String?

    enum Field {
        case name
        case age
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 12)

                VStack(spacing: 12) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 52))
                        .foregroundColor(themeColor)

                    Text("Tell Us About Yourself")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.customLabel)
                        .multilineTextAlignment(.center)

                    Text("Fill in each section, then continue with the arrow below.")
                        .font(.system(size: 15))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("Stored on device; sign in syncs plan & workout history.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 24) {
                    nameSection
                    ageSection
                    genderSection
                }
                .padding(.horizontal, 20)
                .onboardingScrollBottomInset()
            }
        }
        .background(Color.customBackground)
        .onboardingForwardAction(step: 2, action: validateAndContinue)
        .onChange(of: userName) { _, _ in
            nameError = nil
        }
        .onChange(of: age) { _, _ in
            ageError = nil
        }
        .onChange(of: focusedField) { _, newFocus in
            guard newFocus == nil else { return }
            if !isAgeSectionSatisfied {
                ageError = "Enter a valid age (13–120), or leave it blank."
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .foregroundColor(themeColor)
                .fontWeight(.semibold)
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's your name?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.customLabel)

            TextField("Enter your name", text: $userName)
                .font(.system(size: 18))
                .foregroundColor(.customLabel)
                .padding(16)
                .background(Color.customSecondaryBackground)
                .cornerRadius(12)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit {
                    if isNameValid {
                        focusedField = .age
                    }
                }

            if let nameError {
                Text(nameError)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.leading, 4)
            }
        }
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age (optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.customLabel)

            TextField("Enter your age", text: $age)
                .font(.system(size: 18))
                .foregroundColor(.customLabel)
                .keyboardType(.numberPad)
                .padding(16)
                .background(Color.customSecondaryBackground)
                .cornerRadius(12)
                .focused($focusedField, equals: .age)
                .onChange(of: age) { oldValue, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        age = filtered
                    }
                    if filtered.count > 3 {
                        age = String(filtered.prefix(3))
                    }
                    if isAgeSectionSatisfied, isNameValid, focusedField == .age {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            if focusedField == .age {
                                focusedField = nil
                            }
                        }
                    }
                }

            Text("We use your age to customize your workout intensity")
                .font(.system(size: 12))
                .foregroundColor(.customSecondaryLabel)
                .padding(.leading, 4)

            if let ageError {
                Text(ageError)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.leading, 4)
            }
        }
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gender (optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.customLabel)

            VStack(spacing: 8) {
                ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                    GenderOptionButton(
                        gender: gender,
                        isSelected: selectedGender == gender,
                        themeColor: themeColor,
                        action: {
                            focusedField = nil
                            selectedGender = gender
                        }
                    )
                }
            }

            Text("This information is private and helps us personalize your experience")
                .font(.system(size: 12))
                .foregroundColor(.customSecondaryLabel)
                .padding(.leading, 4)
        }
    }

    private var trimmedName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNameValid: Bool {
        !trimmedName.isEmpty
    }

    private var isAgeSectionSatisfied: Bool {
        let ageTrim = age.trimmingCharacters(in: .whitespacesAndNewlines)
        if ageTrim.isEmpty { return true }
        guard let v = Int(ageTrim), (13...120).contains(v) else { return false }
        return true
    }

    private var canProceedPersonalInfo: Bool {
        guard isNameValid else { return false }
        return isAgeSectionSatisfied
    }

    private func validateAndContinue() {
        nameError = nil
        ageError = nil

        guard canProceedPersonalInfo else {
            if trimmedName.isEmpty {
                nameError = "Please enter your name."
            } else if !isAgeSectionSatisfied {
                ageError = "Enter a valid age (13–120), or leave it blank."
            }
            return
        }

        focusedField = nil
        onContinue()
    }
}

// MARK: - Gender Option Button
struct GenderOptionButton: View {
    let gender: UserProfile.Gender
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: gender.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? themeColor : .customLabel)
                    .frame(width: 28)

                Text(gender.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? themeColor : .customLabel)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeColor)
                }
            }
            .padding(16)
            .background(isSelected ? themeColor.opacity(0.1) : Color.customSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PersonalInfoScreen(
        userName: .constant(""),
        age: .constant(""),
        selectedGender: .constant(.preferNotToSay),
        onContinue: {},
        themeColor: .customOrange
    )
}
