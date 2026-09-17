import SwiftUI

struct LoginView: View {
    let onSignIn: () -> Void

    @State private var phase: LoginPhase = .publicLanding
    @State private var isScanningFace = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                hero(width: geometry.size.width)

                switch phase {
                case .publicLanding:
                    publicActions
                case .faceID:
                    faceIDActions
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background(Color.white)
        }
        .background(Color.white.ignoresSafeArea())
        .accessibilityIdentifier(phase == .publicLanding ? "screen-login-public" : "screen-login-face-id")
    }

    @ViewBuilder
    private func hero(width: CGFloat) -> some View {
        let sourceSize = phase == .publicLanding
            ? CGSize(width: 585, height: 738)
            : CGSize(width: 384, height: 506)
        let measuredTrim: CGFloat = phase == .faceID ? 14 : 0
        let height = width * sourceSize.height / sourceSize.width - measuredTrim

        Image(phase == .publicLanding ? "LoginPublicHero" : "LoginFaceHero")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
            .accessibilityHidden(true)
    }

    private var publicActions: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Button {
                withAnimation(.easeOut(duration: 0.24)) {
                    phase = .faceID
                }
            } label: {
                Text("Sign in")
                    .font(.mashreq(size: MashreqTextSize.title, weight: .bold))
                    .foregroundStyle(MashreqTheme.orangeDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(MashreqTheme.orangeDeep, lineWidth: 1.5)
                    }
            }
            .accessibilityIdentifier("sign-in")

            Button(action: {}) {
                Text("Become a customer")
                    .font(.mashreq(size: MashreqTextSize.title, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(MashreqTheme.headerGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .shadow(color: .black.opacity(0.13), radius: 5, y: 3)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
        .frame(maxHeight: .infinity)
    }

    private var faceIDActions: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Welcome back, Rizvan")
                    .font(.mashreq(size: MashreqTextSize.title, weight: .regular))
                    .foregroundStyle(MashreqTheme.ink)
                Spacer()
            }
            .padding(.top, 22)

            Button(action: authenticateWithFaceID) {
                HStack(spacing: 12) {
                    Image(systemName: "faceid")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(MashreqTheme.faceIDGreen)
                        .symbolEffect(.pulse, isActive: isScanningFace)

                    Text(isScanningFace ? "Recognizing Face ID" : "Sign in with Face ID")
                        .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .bold))
                        .tracking(0.4)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: MashreqTheme.buttonHeight)
                .background(MashreqTheme.headerGradient)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
            }
            .disabled(isScanningFace)
            .padding(.top, 14)
            .accessibilityIdentifier("sign-in-with-face-id")

            Spacer(minLength: 18)

            HStack(spacing: 0) {
                LoginQuickAction(icon: "arrow.left.arrow.right", title: "Send\nmoney")
                LoginQuickAction(icon: "eye", title: "Quick\nbalance")
                LoginQuickAction(icon: "lock.shield", title: "Security")
            }
            .padding(.bottom, 0)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
    }

    private func authenticateWithFaceID() {
        guard !isScanningFace else { return }
        isScanningFace = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(780))
            onSignIn()
        }
    }
}

private enum LoginPhase {
    case publicLanding
    case faceID
}

private struct LoginQuickAction: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(MashreqTheme.orangeDeep)
                .frame(height: 25)

            Text(title)
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                .foregroundStyle(MashreqTheme.bodyInk)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
    }
}
