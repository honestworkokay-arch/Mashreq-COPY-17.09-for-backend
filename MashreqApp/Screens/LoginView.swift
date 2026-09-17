import LocalAuthentication
import SwiftUI

struct LoginView: View {
    let onSignIn: () -> Void
    let showsRegistration: Bool
    let onRegister: () -> Void

    @Environment(AppSession.self) private var session
    @State private var isAuthenticating = false
    @State private var authenticationError: String?
    @State private var showsPasswordLogin = false

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                let safeAreaTop = max(geometry.safeAreaInsets.top, 0)
                let safeAreaBottom = max(geometry.safeAreaInsets.bottom, 0)

                VStack(spacing: 0) {
                    referenceHero(
                        width: geometry.size.width,
                        safeAreaTop: safeAreaTop
                    )

                    signInActions(safeAreaBottom: safeAreaBottom)
                }
                .frame(width: geometry.size.width)
                .frame(
                    minHeight: geometry.size.height + safeAreaTop + safeAreaBottom,
                    alignment: .top
                )
                // GeometryReader расположен внутри safe area. Смещаем весь экран
                // к физическому верхнему краю, а referenceHero возвращает нужный
                // отступ содержимому картинки. Общий белый background здесь
                // намеренно отсутствует: он и создавал белую полосу над Face ID.
                .offset(y: -safeAreaTop)
            }
        }
        .background(MashreqTheme.headerGradient.ignoresSafeArea())
        .preferredColorScheme(.light)
        .alert("Face ID", isPresented: faceIDErrorBinding) {
            Button("OK", role: .cancel) { authenticationError = nil }
        } message: {
            Text(authenticationError ?? "Face ID is unavailable.")
        }
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsPasswordLogin,
            height: 390
        ) {
            PasswordLoginSheet(
                isPresented: $showsPasswordLogin,
                onSignIn: onSignIn
            )
        }
        .accessibilityIdentifier("screen-login-face-id")
    }

    /// Используется точный UAE hero из присланного референса. Status bar
    /// исходного снимка вырезается геометрией, поэтому поверх него остаётся
    /// только настоящий системный status bar устройства.
    private func referenceHero(width: CGFloat, safeAreaTop: CGFloat) -> some View {
        let sourceWidth: CGFloat = 588
        let sourceHeight: CGFloat = 1280
        let cropTop: CGFloat = 80
        let cropBottom: CGFloat = 770
        let scale = width / sourceWidth
        let sourceRenderedHeight = sourceHeight * scale
        let cropHeight = (cropBottom - cropTop) * scale
        let heroHeight = safeAreaTop + cropHeight

        return VStack(spacing: 0) {
            Color.clear.frame(height: safeAreaTop)

            ZStack(alignment: .top) {
                Image("LoginUAEReferenceScreen")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: width, height: sourceRenderedHeight)
                    .offset(y: -cropTop * scale)
            }
            .frame(width: width, height: cropHeight, alignment: .top)
            .clipped()
        }
        .frame(width: width, height: heroHeight)
        .background(MashreqTheme.headerGradient)
        .clipped()
        .accessibilityHidden(true)
    }

    private func signInActions(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Welcome back, \(session.profile.firstName)")
                    .font(.mashreq(size: 20, weight: .light))
                    .foregroundStyle(MashreqTheme.bodyInk)
                Spacer()
            }
            .padding(.top, 39)

            Button(action: authenticateWithFaceID) {
                HStack(spacing: 13) {
                    Image("LoginFaceIDIcon")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 26, height: 26)

                    Text("Sign in with Face ID")
                        .font(.mashreq(size: 16, weight: .regular))
                        .tracking(0.2)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(MashreqTheme.headerGradient)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
            }
            .disabled(isAuthenticating)
            .opacity(isAuthenticating ? 0.82 : 1)
            .padding(.top, 18)
            .accessibilityIdentifier("sign-in-with-face-id")

            // Компактные ссылки сохраняют прежнюю геометрию Login: основной
            // акцент остаётся только на Face ID, регистрация не подменяет экран.
            HStack(spacing: 12) {
                Button("Use password") {
                    showsPasswordLogin = true
                }
                .accessibilityIdentifier("sign-in-with-password")

                if showsRegistration {
                    Spacer(minLength: 12)

                    Text("New to Mashreq?")
                        .foregroundStyle(MashreqTheme.secondaryInk)

                    Button("Register", action: onRegister)
                        .accessibilityIdentifier("open-registration")
                }
            }
            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .semibold))
            .foregroundStyle(MashreqTheme.orangeDeep)
            .padding(.top, 14)

            Spacer(minLength: 22)

            HStack(spacing: 0) {
                LoginQuickAction(assetName: "LoginSendMoneyIcon", title: "Send\nmoney")
                LoginQuickAction(assetName: "LoginQuickBalanceIcon", title: "Quick\nbalance")
                LoginQuickAction(assetName: "OverviewHeaderChatExact", title: "Chat\nwith us")
                LoginQuickAction(assetName: "LoginSecurityIcon", title: "Security")
            }
            // Home indicator не перекрывает подписи на iPhone 17 Pro.
            .padding(.bottom, max(18, safeAreaBottom + 10))
        }
        .padding(.horizontal, 32)
        .frame(maxHeight: .infinity)
        .background(Color.white)
    }

    /// LAContext показывает штатную системную анимацию Face ID iPhone.
    /// Никакая собственная имитация поверх экрана больше не используется.
    private func authenticateWithFaceID() {
        guard !isAuthenticating else { return }

        let context = LAContext()
        context.localizedFallbackTitle = ""
        context.localizedCancelTitle = "Cancel"

        var availabilityError: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &availabilityError
        ) else {
            authenticationError = availabilityError?.localizedDescription
                ?? "Face ID is not configured on this device."
            return
        }

        isAuthenticating = true

        Task { @MainActor in
            do {
                let authenticated = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Sign in to your Mashreq account"
                )

                isAuthenticating = false
                if authenticated {
                    onSignIn()
                }
            } catch {
                isAuthenticating = false

                // Отмена пользователем не превращается в лишнее предупреждение.
                let code = (error as? LAError)?.code
                if code != .userCancel && code != .systemCancel && code != .appCancel {
                    authenticationError = error.localizedDescription
                }
            }
        }
    }

    private var faceIDErrorBinding: Binding<Bool> {
        Binding(
            get: { authenticationError != nil },
            set: { if !$0 { authenticationError = nil } }
        )
    }
}

private struct PasswordLoginSheet: View {
    @Binding var isPresented: Bool
    let onSignIn: () -> Void

    @FocusState private var isPasswordFocused: Bool
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(hex: 0xD6D6D8))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Enter login password")
                        .font(.mashreq(size: MashreqTextSize.section, weight: .bold))
                        .foregroundStyle(MashreqTheme.ink)
                    Text("Use the password created during registration.")
                        .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MashreqTheme.bodyInk)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Close")
            }
            .padding(.top, 24)

            SecureField("Password", text: $password)
                .font(.mashreq(size: MashreqTextSize.label, weight: .regular))
                .textContentType(.password)
                .submitLabel(.go)
                .focused($isPasswordFocused)
                .onSubmit(verifyPassword)
                .padding(.horizontal, 16)
                .frame(height: 62)
                .background(Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(errorMessage == nil ? Color(hex: 0xB9BDC2) : MashreqTheme.error, lineWidth: 1)
                }
                .padding(.top, 24)
                .accessibilityIdentifier("login-password-field")

            if let errorMessage {
                Text(errorMessage)
                    .font(.mashreq(size: MashreqTextSize.caption, weight: .regular))
                    .foregroundStyle(MashreqTheme.error)
                    .padding(.top, 9)
            }

            Spacer(minLength: 18)

            Button(action: verifyPassword) {
                Text("Sign in")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(MashreqTheme.headerGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .disabled(password.isEmpty)
            .opacity(password.isEmpty ? 0.48 : 1)
            .accessibilityIdentifier("login-password-submit")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .background(Color.white)
        .onAppear { isPasswordFocused = true }
    }

    private func verifyPassword() {
        guard !password.isEmpty else { return }
        errorMessage = nil

        do {
            guard try LoginCredentialStore.verify(password: password) else {
                errorMessage = "Incorrect password. Please try again."
                return
            }
            isPresented = false
            password = ""
            onSignIn()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct LoginQuickAction: View {
    let assetName: String
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 34, height: 34)

            Text(title)
                .font(.mashreq(size: 13, weight: .light))
                .foregroundStyle(MashreqTheme.bodyInk)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
    }
}
