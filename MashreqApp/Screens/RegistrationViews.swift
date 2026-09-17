import SwiftData
import SwiftUI

/// Login всегда остаётся первым экраном. Регистрация открывается только по
/// явному действию пользователя — с Login либо из Settings.
struct LoginRegistrationRootView: View {
    @Query(sort: \RegisteredUser.createdAt) private var registeredUsers: [RegisteredUser]
    @State private var showsRegistration = false

    let session: AppSession

    var body: some View {
        AppRootView(
            session: session,
            canRegister: registeredUsers.isEmpty,
            onRegister: { showsRegistration = true }
        )
        .task(id: registeredUsers.first?.updatedAt) {
            if let user = registeredUsers.first {
                synchronizeSession(with: user)
            }
        }
        .fullScreenCover(isPresented: $showsRegistration) {
            RegistrationView(
                onCancel: { showsRegistration = false },
                onRegistered: { profile in
                    session.saveProfile(profile, balance: session.accountBalance)
                    showsRegistration = false
                }
            )
        }
    }

    private func synchronizeSession(with user: RegisteredUser) {
        guard session.profile != user.userProfile else { return }
        session.saveProfile(user.userProfile, balance: session.accountBalance)
    }
}

private enum RegistrationField: Hashable {
    case firstName
    case lastName
    case mobile
    case email
    case iban
    case accountNumber
    case password
    case confirmation
}

struct RegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: RegistrationField?

    let onCancel: () -> Void
    let onRegistered: (UserProfile) -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var mobileNumber = ""
    @State private var email = ""
    @State private var iban = ""
    @State private var accountNumber = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    intro
                    personalDetails
                    accountDetails
                    loginDetails

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                            .foregroundStyle(MashreqTheme.error)
                            .padding(.top, 18)
                            .accessibilityIdentifier("registration-error")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 126)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            registrationHeader
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            createAccountButton
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
            }
        }
        .tint(MashreqTheme.orangeDeep)
        .preferredColorScheme(.light)
        .accessibilityIdentifier("screen-registration")
    }

    private var registrationHeader: some View {
        MashreqHeader(
            title: "Registration",
            height: 104,
            showsBack: true,
            usesReferenceBackground: true,
            titleFontSize: 18,
            onBack: onCancel
        )
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome to Mashreq")
                .font(.mashreq(size: 24, weight: .bold))
                .foregroundStyle(MashreqTheme.ink)

            Text("Enter your personal and account details to create a secure login on this device.")
                .font(.mashreq(size: MashreqTextSize.copy, weight: .light))
                .foregroundStyle(MashreqTheme.bodyInk)
                .lineSpacing(4)
        }
        .padding(.bottom, 28)
    }

    private var personalDetails: some View {
        registrationSection(title: "Personal details") {
            RegistrationTextField(
                title: "First Name",
                text: $firstName,
                textContentType: .givenName,
                capitalization: .words,
                submitLabel: .next
            )
            .focused($focusedField, equals: .firstName)
            .onSubmit { focusedField = .lastName }

            RegistrationTextField(
                title: "Last Name",
                text: $lastName,
                textContentType: .familyName,
                capitalization: .words,
                submitLabel: .next
            )
            .focused($focusedField, equals: .lastName)
            .onSubmit { focusedField = .mobile }

            RegistrationTextField(
                title: "Mobile number",
                text: $mobileNumber,
                textContentType: .telephoneNumber,
                keyboardType: .phonePad,
                submitLabel: .next
            )
            .focused($focusedField, equals: .mobile)

            RegistrationTextField(
                title: "Email address",
                text: $email,
                textContentType: .emailAddress,
                keyboardType: .emailAddress,
                capitalization: .never,
                submitLabel: .next
            )
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .iban }
        }
    }

    private var accountDetails: some View {
        registrationSection(title: "Account details") {
            RegistrationTextField(
                title: "IBAN",
                text: $iban,
                capitalization: .characters,
                submitLabel: .next
            )
            .focused($focusedField, equals: .iban)
            .onSubmit { focusedField = .accountNumber }

            RegistrationTextField(
                title: "Account number",
                text: $accountNumber,
                keyboardType: .numberPad,
                submitLabel: .next
            )
            .focused($focusedField, equals: .accountNumber)
        }
    }

    private var loginDetails: some View {
        registrationSection(title: "Create login password") {
            RegistrationTextField(
                title: "Password",
                text: $password,
                textContentType: .newPassword,
                capitalization: .never,
                isSecure: true,
                submitLabel: .next
            )
            .focused($focusedField, equals: .password)
            .onSubmit { focusedField = .confirmation }

            RegistrationTextField(
                title: "Confirm password",
                text: $passwordConfirmation,
                textContentType: .newPassword,
                capitalization: .never,
                isSecure: true,
                submitLabel: .done
            )
            .focused($focusedField, equals: .confirmation)
            .onSubmit(createAccount)

            Text("Use at least 8 characters with letters and numbers. Your password is stored in Apple Keychain, not in the profile database.")
                .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .lineSpacing(3)
        }
    }

    private func registrationSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.mashreq(size: MashreqTextSize.section, weight: .bold))
                .foregroundStyle(MashreqTheme.ink)

            content()
        }
        .padding(.bottom, 28)
    }

    private var createAccountButton: some View {
        Button(action: createAccount) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView().tint(.white)
                }
                Text(isSaving ? "Creating account…" : "Create account")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(MashreqTheme.headerGradient)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
        }
        .disabled(isSaving)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.white.shadow(color: .black.opacity(0.08), radius: 8, y: -3))
        .accessibilityIdentifier("registration-create-account")
    }

    private func createAccount() {
        guard !isSaving else { return }
        focusedField = nil
        errorMessage = nil

        if let message = RegistrationValidation.profileMessage(
            firstName: firstName,
            lastName: lastName,
            mobileNumber: mobileNumber,
            email: email,
            iban: iban,
            accountNumber: accountNumber
        ) {
            errorMessage = message
            return
        }
        if let message = RegistrationValidation.passwordMessage(
            password,
            confirmation: passwordConfirmation
        ) {
            errorMessage = message
            return
        }

        isSaving = true
        let user = RegisteredUser(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            mobileNumber: mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            iban: RegistrationValidation.normalizedIBAN(iban),
            accountNumber: RegistrationValidation.accountDigits(accountNumber)
        )

        do {
            try LoginCredentialStore.savePassword(password)
            modelContext.insert(user)
            try modelContext.save()
            onRegistered(user.userProfile)
        } catch {
            modelContext.delete(user)
            try? LoginCredentialStore.deletePassword()
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

private struct RegistrationTextField: View {
    let title: String
    @Binding var text: String
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization? = .sentences
    var isSecure = false
    var submitLabel: SubmitLabel = .next

    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
            }
        }
        .font(.mashreq(size: MashreqTextSize.label, weight: .regular))
        .foregroundStyle(MashreqTheme.ink)
        .textContentType(textContentType)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(capitalization)
        .autocorrectionDisabled()
        .submitLabel(submitLabel)
        .padding(.horizontal, 16)
        .frame(height: 62)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: 0xB9BDC2), lineWidth: 1)
        }
        .accessibilityLabel(title)
    }
}
