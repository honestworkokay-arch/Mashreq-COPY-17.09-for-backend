import SwiftUI

struct OverviewView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            overviewHeader

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    accountSummary

                    Button { session.navigate(to: .accountDetails) } label: {
                        accountRow
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    addMoneyBar
                        .padding(.top, 1)

                    HStack(spacing: 14) {
                        Capsule()
                            .fill(MashreqTheme.orange)
                            .frame(width: 33, height: 7)
                        Circle()
                            .fill(MashreqTheme.line)
                            .frame(width: 7, height: 7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 9)
                    .padding(.top, 16)

                    Button { session.selectedTab = .pay } label: {
                        Image("EverydayCashback")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(341.0 / 125.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 47)

                    SectionTitle(title: "Quick actions", actionTitle: "Edit") {}
                        .padding(.top, 42)

                    HStack(spacing: 8) {
                        ActionIcon(systemName: "creditcard", title: "Cards")
                        ActionIcon(systemName: "banknote", title: "Pay bills")
                        ActionIcon(systemName: "leaf", title: "E-Statements")
                        ActionIcon(systemName: "ellipsis", title: "More")
                    }
                    .padding(.top, 12)

                    Color.clear.frame(height: 105)
                }
                .padding(.horizontal, 24)
                .padding(.top, 168)
            }
        }
        .accessibilityIdentifier("screen-overview")
    }

    private var overviewHeader: some View {
        ZStack(alignment: .top) {
            MashreqHeaderShape()
                .fill(MashreqTheme.headerGradient)
                .frame(height: 310)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 30) {
                HStack(spacing: 12) {
                    Image("AlIslamiNEO")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 116, height: 67)
                        .accessibilityLabel("Al Islami NEO")

                    Spacer()

                    Button { session.navigate(to: .notifications) } label: {
                        ZStack(alignment: .topTrailing) {
                            Circle().fill(Color.white).frame(width: 42, height: 42)
                            Image(systemName: "bell")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(MashreqTheme.orangeDeep)
                                .frame(width: 42, height: 42)
                            Text("5")
                                .font(.mashreq(size: MashreqTextSize.nano, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(width: 17, height: 17)
                                .background(Color(hex: 0xD84D3C))
                                .clipShape(Circle())
                                .offset(x: 2, y: -4)
                        }
                    }
                    .accessibilityLabel("Notifications")

                    Circle()
                        .fill(Color.white)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Text("RK")
                                .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                                .foregroundStyle(MashreqTheme.orangeDeep)
                        }
                }
                .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        OverviewChip(title: "Accounts", selected: true)
                        OverviewChip(title: "Wealth", selected: false)
                        OverviewChip(title: "Finances", selected: false)
                        OverviewChip(title: "Deposits", selected: false)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 8)
        }
        .frame(height: 310)
    }

    private var accountSummary: some View {
        Button { session.navigate(to: .accounts) } label: {
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Text("1 Account")
                            .font(.mashreq(size: MashreqTextSize.title, weight: .semibold))
                        Image(systemName: "eye")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(MashreqTheme.secondaryInk)
                    }
                    Spacer()
                    Text("View all")
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .semibold))
                        .foregroundStyle(MashreqTheme.orangeDeep)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("Available Balance")
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                    Spacer()
                    DirhamAmount(value: "6,072.38", size: 22, weight: .semibold)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("Current Balance")
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                    Spacer()
                    DirhamAmount(value: "6,072.38", size: 14, weight: .medium)
                }
            }
            .foregroundStyle(MashreqTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .frame(height: 106)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .mashreqCardShadow()
        }
        .buttonStyle(.plain)
    }

    private var accountRow: some View {
        HStack(spacing: 13) {
            UAEFlagView(size: 42)

            VStack(alignment: .leading, spacing: 8) {
                Text("Rizvan")
                    .font(.mashreq(size: MashreqTextSize.label, weight: .medium))
                DirhamAmount(value: "6,072.38", size: 20, weight: .semibold)
            }

            Spacer()

            Text("019120159667")
                .font(.mashreq(size: MashreqTextSize.micro, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .mashreqCardShadow()
    }

    private var addMoneyBar: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Text("Add Money")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.white)
                    .frame(width: 28, height: 28)
                    .background(MashreqTheme.orange)
                    .clipShape(Circle())
            }
            .foregroundStyle(MashreqTheme.orangeDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color(hex: 0xFFF0E8))
            .overlay(alignment: .top) { Divider().opacity(0.7) }
        }
    }
}

private struct OverviewChip: View {
    let title: String
    let selected: Bool

    var body: some View {
        Text(title)
            .font(.mashreq(size: MashreqTextSize.meta, weight: selected ? .semibold : .medium))
            .foregroundStyle(selected ? MashreqTheme.orangeDeep : Color.white)
            .padding(.horizontal, 20)
            .frame(height: 46)
            .background(selected ? Color.white : Color.white.opacity(0.26))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct DirhamAmount: View {
    let value: String
    let size: CGFloat
    let weight: MashreqFontWeight

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image("DirhamMark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * 0.83, height: size * 0.86)
            Text(value)
                .font(.mashreq(size: size, weight: weight))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("AED \(value)")
    }
}
