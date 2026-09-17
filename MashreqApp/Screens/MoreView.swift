import SwiftUI

struct MoreView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(title: "More", height: 205)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Button { session.navigate(to: .settings) } label: {
                        PanelCard {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(MashreqTheme.orangeSoft)
                                    .frame(width: 50, height: 50)
                                    .overlay {
                                        Text(session.profile.initials)
                                            .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                                            .foregroundStyle(MashreqTheme.orange)
                                    }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(session.profile.fullName)
                                        .font(.mashreq(size: 17, weight: .bold))
                                        .foregroundStyle(MashreqTheme.ink)
                                    Text("Profile, account & transactions")
                                        .font(.mashreq(size: 13))
                                        .foregroundStyle(MashreqTheme.secondaryInk)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(MashreqTheme.ink)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    MashreqOutlineButton(title: "Apply for a new product  +") { }
                    Text("Card services").font(.mashreq(size: 21, weight: .bold))
                    MoreRow(icon: "creditcard.and.123", title: "Card control")
                    MoreRow(icon: "percent", title: "Instant Cash")
                    MoreRow(icon: "creditcard", title: "Apply for a supplementary credit card")
                    Text("Other services").font(.mashreq(size: 21, weight: .bold)).padding(.top, 8)
                    Button { session.navigate(to: .settings) } label: {
                        MoreRow(icon: "gearshape", title: "Settings & transaction control")
                    }
                    .buttonStyle(.plain)
                    MoreRow(icon: "banknote", title: "Cardless cash")
                    Button { session.navigate(to: .eStatementRequest) } label: {
                        MoreRow(icon: "leaf", title: "E-statements")
                    }
                    .buttonStyle(.plain)
                    Button("Sign out") { session.signOut() }.foregroundStyle(MashreqTheme.error).padding(.vertical, 14)
                    Color.clear.frame(height: 92)
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 145)
            }
        }
        .accessibilityIdentifier("screen-more")
    }
}

private struct MoreRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack { Circle().fill(MashreqTheme.orangeSoft).frame(width: 44, height: 44); Image(systemName: icon).foregroundStyle(MashreqTheme.orange) }
            Text(title).font(.mashreq(size: 16))
            Spacer()
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 58).offset(y: 7) }
    }
}
