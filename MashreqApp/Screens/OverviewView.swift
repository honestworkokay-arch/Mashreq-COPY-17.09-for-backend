import SwiftUI

struct OverviewView: View {
    @Environment(AppSession.self) private var session
    @State private var loadStage = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isEditingQuickActions = false

    private let scrollCoordinateSpace = "overview-scroll"
    private let overviewHeaderTravel: CGFloat = 306

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            // Большой Overview header уходит вверх вместе с контентом.
            // Раньше он был неподвижным слоем ZStack и поэтому не мог скрыться.
            overviewHeader
                .offset(y: -min(scrollOffset, overviewHeaderTravel))
                .allowsHitTesting(scrollOffset < 150)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    MashreqScrollOffsetReader(coordinateSpace: scrollCoordinateSpace)

                    if loadStage == 0 {
                        DashboardSkeleton()
                            .padding(.top, 163)
                    } else {
                        overviewContent
                            .padding(.top, 163)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Color.clear.frame(height: 105)
                }
                .padding(.horizontal, 24)
            }
            .mashreqTrackScrollOffset(
                $scrollOffset,
                coordinateSpace: scrollCoordinateSpace
            )
        }
        .task {
            // Последовательность появления измерена по присланному видео.
            guard loadStage == 0 else { return }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.32)) { loadStage = 1 }
            try? await Task.sleep(for: .milliseconds(1_050))
            withAnimation(.easeOut(duration: 0.26)) { loadStage = 2 }
            try? await Task.sleep(for: .milliseconds(1_550))
            withAnimation(.easeOut(duration: 0.26)) { loadStage = 3 }
        }
        .accessibilityIdentifier("screen-overview")
    }

    private var overviewContent: some View {
        VStack(spacing: 0) {
            accountSummary

            ZStack(alignment: .trailing) {
                VStack(spacing: 0) {
                    Button { session.navigate(to: .accountDetails) } label: {
                        accountRow
                    }
                    .buttonStyle(.plain)

                    addMoneyBar
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .mashreqCardShadow()

                Image("OverviewNextAccountPeek")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: 15, height: 62)
                    .clipped()
                    .offset(x: 24, y: -9)
            }
            .padding(.top, 8)

            HStack(spacing: 14) {
                Capsule().fill(MashreqTheme.orange).frame(width: 33, height: 7)
                Circle().fill(MashreqTheme.line).frame(width: 7, height: 7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 9)
            .padding(.top, 16)

            if loadStage >= 2 {
                Button { session.selectTab(.pay) } label: {
                    Image("OverviewBanner")
                        .resizable()
                        .interpolation(.high)
                        // Баннер используется целиком в исходном соотношении 745 × 271.
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(745.0 / 271.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .padding(.top, 56)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if loadStage >= 3 {
                quickActions
                    .padding(.top, 42)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                moneyInsights
                    .padding(.top, 42)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var overviewHeader: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                Image("OverviewHeaderGradient")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 306)
                    .clipped()
            }
                .frame(height: 306)
                // Точную дугу сохраняем нативной маской, а цвет берём из Фото 1.
                .mask(MashreqHeaderShape())
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 26) {
                HStack(alignment: .top, spacing: 0) {
                    Image("OverviewNeoLockup")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 59, height: 57)
                        .padding(.leading, 12)
                        .offset(y: -9)

                    Spacer()

                    Button {
                        // После открытия SMS/чата unread-индикатор исчезает.
                        withAnimation(.easeOut(duration: 0.18)) {
                            session.markSupportMessageRead()
                        }
                        session.navigate(to: .virtualAssistant)
                    } label: {
                        overviewHeaderIcon(
                            assetName: session.supportMessageState == .unread
                                ? "OverviewHeaderChatUnread"
                                : "OverviewHeaderChatExact",
                            width: 41,
                            height: 43,
                            yOffset: 9
                        )
                    }
                    .frame(width: 48, height: 50)
                    .accessibilityLabel(
                        session.supportMessageState == .unread
                            ? "Chat, unread message"
                            : "Chat"
                    )

                    Button { session.navigate(to: .notifications) } label: {
                        overviewHeaderIcon(
                            assetName: "OverviewHeaderNotificationsExact",
                            width: 48,
                            height: 50,
                            yOffset: 3
                        )
                    }
                    .frame(width: 48, height: 50)
                    .accessibilityLabel(
                        session.unreadBankingNotificationCount > 0
                            ? "Notifications, \(session.unreadBankingNotificationCount) unread"
                            : "Notifications"
                    )

                    Button { session.selectTab(.more) } label: {
                        overviewHeaderIcon(
                            assetName: "OverviewHeaderProfileExact",
                            width: 41,
                            height: 43,
                            yOffset: 9
                        )
                    }
                    .frame(width: 48, height: 50)
                    .accessibilityLabel("Profile")
                }
                .padding(.leading, 23)
                .padding(.trailing, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        OverviewChip(title: "Accounts", width: 98, selected: true)
                        OverviewChip(title: "Wealth", width: 82, selected: false)
                        OverviewChip(title: "Cards", width: 75, selected: false)
                        OverviewChip(title: "Loans", width: 77, selected: false)
                    }
                    .padding(.horizontal, 24)
                }
            }
            // На iPhone 17 Pro содержимое начинается ниже Dynamic Island.
            // 83 pt совпадают с измеренным положением иконок и вкладок референса.
            .padding(.top, 83)
        }
        .frame(height: 164)
    }

    /// PNG уже содержит точный белый контейнер, оранжевый знак, обводку и тень.
    private func overviewHeaderIcon(
        assetName: String,
        width: CGFloat,
        height: CGFloat,
        yOffset: CGFloat
    ) -> some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .offset(y: yOffset)
            .contentShape(Rectangle())
    }

    private var accountSummary: some View {
        Button { session.navigate(to: .accounts) } label: {
            // Внутренняя сетка измерена по двум компактным Overview-референсам:
            // заголовок расположен ниже, а строки балансов собраны плотнее.
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Text("1 Account")
                            .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                        Image("OverviewEye")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 25, height: 20)
                    }
                    .offset(y: 3)
                    Spacer()
                    Text("View all")
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .semibold))
                        .foregroundStyle(MashreqTheme.orangeDeep)
                }
                .frame(height: 20, alignment: .top)

                Color.clear.frame(height: 11)

                HStack(alignment: .firstTextBaseline) {
                    Text("Available Balance")
                        .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                    Spacer()
                    DirhamAmount(
                        value: session.formattedAccountBalance,
                        size: 19,
                        weight: .semibold,
                        fractionSize: 12
                    )
                        .offset(y: 3)
                }
                .frame(height: 27, alignment: .top)

                HStack(alignment: .firstTextBaseline) {
                    Text("Current Balance")
                        .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                    Spacer()
                    DirhamAmount(
                        value: session.formattedAccountBalance,
                        size: 14,
                        weight: .semibold,
                        fractionSize: 10
                    )
                        .offset(y: 1)
                }
                .frame(height: 22, alignment: .top)
            }
            .foregroundStyle(MashreqTheme.ink)
            .padding(.leading, 20)
            .padding(.trailing, 17)
            .padding(.top, 13)
            .frame(maxWidth: .infinity)
            .frame(height: 102, alignment: .top)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .mashreqCardShadow()
        }
        .buttonStyle(.plain)
    }

    private var accountRow: some View {
        HStack(spacing: 12) {
            UAEFlagView(size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text("NEO Current Account")
                    .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
                DirhamAmount(value: session.formattedAccountBalance, size: 19, weight: .semibold)
            }

            Spacer()

            Text(session.profile.accountNumber)
                .font(.mashreq(size: MashreqTextSize.micro, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 13)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 79)
        .background(Color.white)
    }

    private var addMoneyBar: some View {
        Button { session.selectTab(.pay) } label: {
            Image("OverviewAddMoneyBar")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .aspectRatio(2082.0 / 229.0, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Money")
    }

    private var quickActions: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Quick actions")
                    .font(.mashreq(size: MashreqTextSize.headline, weight: .semibold))

                Spacer()

                Button(isEditingQuickActions ? "Done" : "Edit") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditingQuickActions.toggle()
                    }
                }
                .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                .foregroundStyle(MashreqTheme.orangeDeep)
            }

            HStack(alignment: .top, spacing: 0) {
                OverviewQuickActionButton(
                    firstLine: "Pay cards",
                    assetName: "OverviewQuickPayCards",
                    isEditing: isEditingQuickActions
                ) {
                    session.navigate(to: .cards)
                }

                OverviewQuickActionButton(
                    firstLine: "Cardless",
                    secondLine: "cash",
                    assetName: "OverviewQuickCardlessCash",
                    isEditing: isEditingQuickActions
                ) {
                    session.selectTab(.pay)
                }

                OverviewQuickActionButton(
                    firstLine: "E-",
                    secondLine: "statement",
                    assetName: "OverviewQuickEStatement",
                    isEditing: isEditingQuickActions
                ) {
                    session.navigate(to: .eStatementRequest)
                }

                OverviewQuickActionButton(
                    firstLine: "Block and",
                    secondLine: "replace",
                    assetName: "OverviewQuickBlockReplace",
                    isEditing: isEditingQuickActions
                ) {
                    session.navigate(to: .cardDetails)
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 120, alignment: .top)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .mashreqCardShadow()
            .overlay {
                if isEditingQuickActions {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(MashreqTheme.orange.opacity(0.55), lineWidth: 1)
                }
            }
        }
    }

    private var moneyInsights: some View {
        VStack(spacing: 14) {
            HStack(spacing: 9) {
                Text("Money insights")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                Text("BETA")
                    .font(.mashreq(size: MashreqTextSize.caption, weight: .regular))
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(MashreqTheme.line))
                Spacer()
                Text("View all")
                    .font(.mashreq(size: MashreqTextSize.meta, weight: .semibold))
                    .foregroundStyle(MashreqTheme.orangeDeep)
            }

            Button(action: {}) {
                Image("OverviewMoneyInsightsCard")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1396.0 / 483.0, contentMode: .fit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take control of your finances. Track and manage in one place")
        }
    }
}

private struct OverviewQuickActionButton: View {
    let firstLine: String
    var secondLine: String? = nil
    let assetName: String
    let isEditing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(assetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 47, height: 47)

                VStack(spacing: 0) {
                    Text(firstLine)
                    if let secondLine {
                        Text(secondLine)
                    }
                }
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                .foregroundStyle(MashreqTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(height: 36, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isEditing ? 0.97 : 1)
            .opacity(isEditing ? 0.88 : 1)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel([firstLine, secondLine].compactMap { $0 }.joined(separator: " "))
    }
}

private struct DashboardSkeleton: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xF3F3F4)).frame(height: 102)
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xF3F3F4)).frame(height: 116)
        }
        .redacted(reason: .placeholder)
    }
}

private struct OverviewChip: View {
    let title: String
    let width: CGFloat
    let selected: Bool

    var body: some View {
        Text(title)
            .font(.mashreq(size: MashreqTextSize.meta, weight: .semibold))
            .foregroundStyle(selected ? MashreqTheme.orangeDeep : Color.white)
            .frame(width: width, height: 42)
            .background(selected ? Color.white : Color.white.opacity(0.26))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: selected ? .black.opacity(0.12) : .clear, radius: 6, y: 3)
    }
}

struct DirhamAmount: View {
    let value: String
    let size: CGFloat
    let weight: MashreqFontWeight
    var fractionSize: CGFloat? = nil

    /// Разделяем сумму только когда экран явно запросил уменьшенные копейки.
    /// Остальные вызовы продолжают отображать исходную строку без изменений.
    private var decimalParts: (whole: String, fraction: String)? {
        guard
            fractionSize != nil,
            let separator = value.lastIndex(of: "."),
            separator < value.index(before: value.endIndex)
        else {
            return nil
        }

        return (
            String(value[..<separator]),
            String(value[value.index(after: separator)...])
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image("WioDirhamSymbol")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * 0.78, height: size * 0.70)

            if let decimalParts, let fractionSize {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(decimalParts.whole)
                        .font(.mashreq(size: size, weight: weight))
                    Text(".\(decimalParts.fraction)")
                        .font(.mashreq(size: fractionSize, weight: weight))
                }
            } else {
                Text(value)
                    .font(.mashreq(size: size, weight: weight))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("AED \(value)")
    }
}
