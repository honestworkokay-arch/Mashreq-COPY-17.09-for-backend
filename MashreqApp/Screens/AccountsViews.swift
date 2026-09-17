import SwiftUI

struct AccountsListView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0

    private let scrollCoordinateSpace = "accounts-list-scroll"

    /// Геометрия измерена по присланному референсу 588 x 1280 и переведена
    /// в logical points iPhone 17 Pro. Все заметные размеры экрана собраны
    /// здесь, чтобы дальнейшая калибровка не превращалась в набор offset.
    private enum Layout {
        static let expandedHeaderHeight: CGFloat = 148
        static let horizontalInset: CGFloat = 24.5
        static let contentTopInset: CGFloat = 37
        static let summaryHeight: CGFloat = 114
        static let summaryToAccountGap: CGFloat = 36
        static let accountHeight: CGFloat = 86
        static let accountSpacing: CGFloat = 16
        static let accountToPromoGap: CGFloat = 32
        static let promoHeight: CGFloat = 84
        static let cardRadius: CGFloat = 5
    }

    /// Пока приложение хранит один редактируемый текущий счёт. Имя владельца
    /// намеренно не используется как название продукта: в референсе это
    /// именно тип счёта, а номер и баланс берутся из AppSession.
    private var displayedAccounts: [DisplayedAccount] {
        [
            DisplayedAccount(
                id: "current-account",
                title: "Current Account",
                number: session.profile.accountNumber,
                balance: session.formattedAccountBalance
            )
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            let safeAreaTop = max(proxy.safeAreaInsets.top, 0)
            let compactMotionHeight = AccountHeaderMotion.layoutHeight(
                visibleHeight: AccountHeaderMotion.compactVisibleHeight,
                safeAreaTop: safeAreaTop
            )
            let compactFrameHeight = AccountHeaderMotion.compactVisibleHeight
            let collapseDistance = max(1, Layout.expandedHeaderHeight - compactMotionHeight)
            let collapseProgress = AccountHeaderMotion.collapseProgress(
                scrollOffset: scrollOffset,
                collapseDistance: collapseDistance
            )

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                MashreqHeader(
                    title: "My Accounts",
                    height: Layout.expandedHeaderHeight,
                    showsBack: true,
                    usesReferenceBackground: true
                )
                .offset(y: -min(scrollOffset, collapseDistance))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        MashreqScrollOffsetReader(coordinateSpace: scrollCoordinateSpace)

                        accountsSummary

                        VStack(spacing: Layout.accountSpacing) {
                            ForEach(displayedAccounts) { account in
                                accountCard(account)
                            }
                        }
                        .padding(.top, Layout.summaryToAccountGap - 16)

                        openAccountCard
                            .padding(.top, Layout.accountToPromoGap - 16)
                    }
                    .padding(.horizontal, Layout.horizontalInset)
                    // Вместе с safe area, 1-pt scroll marker и spacing это
                    // ставит верх summary-card на измеренный y ≈ 117 pt.
                    .padding(.top, Layout.contentTopInset)
                    .padding(.bottom, 32)
                }
                .mashreqTrackScrollOffset(
                    $scrollOffset,
                    coordinateSpace: scrollCoordinateSpace
                )

                accountsCompactHeader(
                    height: compactFrameHeight,
                    collapseProgress: collapseProgress
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-accounts")
    }

    private var accountsSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(displayedAccounts.count) \(displayedAccounts.count == 1 ? "Account" : "Accounts")")
                .font(.mashreq(size: MashreqTextSize.headline, weight: .semibold))

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                BalanceSummary(
                    label: "Available Balance",
                    amount: session.formattedAccountBalance,
                    large: true
                )
                BalanceSummary(
                    label: "Current Balance",
                    amount: session.formattedAccountBalance
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Layout.summaryHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius))
        .mashreqCardShadow()
    }

    private func accountCard(_ account: DisplayedAccount) -> some View {
        Button { session.navigate(to: .accountDetails) } label: {
            HStack(alignment: .top, spacing: 14) {
                UAEFlagView(size: 42)

                VStack(alignment: .leading, spacing: 5) {
                    Text(account.title)
                        .font(.mashreq(size: MashreqTextSize.label, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    DirhamAmount(
                        value: account.balance,
                        size: 19,
                        weight: .semibold,
                        fractionSize: 12
                    )
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(account.number)
                    .font(.mashreq(size: MashreqTextSize.micro, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Layout.accountHeight)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius))
            .mashreqCardShadow()
        }
        .buttonStyle(.plain)
        .foregroundStyle(MashreqTheme.ink)
        .accessibilityHint("Opens account details")
    }

    private var openAccountCard: some View {
        HStack(spacing: 0) {
            // Точная фотография вырезана из предоставленного референса;
            // вместо неё не используется generic/system placeholder.
            Image("OpenAccountReference")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: 52, height: Layout.promoHeight)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text("Open an account")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                    .lineLimit(1)

                Text("Instantly in multiple currencies")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.leading, 14)

            Spacer(minLength: 4)

            // Фирменный raster-chevron: тот же исходный back-asset,
            // развёрнутый вправо. SF Symbols на экране My Accounts нет.
            Image("ReferenceFlowBack")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .colorMultiply(MashreqTheme.ink)
                .rotationEffect(.degrees(180))
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Layout.promoHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius))
        .mashreqCardShadow()
    }

    private func accountsCompactHeader(
        height: CGFloat,
        collapseProgress: CGFloat
    ) -> some View {
        let revealProgress = (collapseProgress - AccountHeaderMotion.compactRevealStart)
            / (1 - AccountHeaderMotion.compactRevealStart)
        let opacity = AccountHeaderMotion.smoothStep(revealProgress)

        return ZStack(alignment: .top) {
            Image("AccountCompactHeader")
                .resizable(resizingMode: .stretch)
                .interpolation(.high)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .ignoresSafeArea(edges: .top)

            HStack {
                Button { dismiss() } label: {
                    Image("TransactionBack")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")

                Spacer()

                Text("My Accounts")
                    .font(.mashreq(size: MashreqTextSize.label, weight: .medium))
                    .foregroundStyle(Color.white)

                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
        }
        .frame(height: height)
        .opacity(opacity)
        .allowsHitTesting(opacity > 0.5)
        .zIndex(30)
    }
}

private struct DisplayedAccount: Identifiable {
    let id: String
    let title: String
    let number: String
    let balance: String
}

private struct BalanceSummary: View {
    let label: String
    let amount: String
    var large = false

    var body: some View {
        HStack {
            Text(label)
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
            Spacer()
            DirhamAmount(
                value: amount,
                size: large ? 20 : 14,
                weight: large ? .semibold : .medium,
                fractionSize: large ? 13 : 11
            )
        }
    }
}

/// Три визуальных состояния хедера из видео-референса.
private enum AccountHeaderPhase {
    case expanded
    case transitioning
    case compact

    var accessibilityValue: String {
        switch self {
        case .expanded: "expanded"
        case .transitioning: "transitioning"
        case .compact: "compact"
        }
    }
}

/// Все измеренные параметры перехода собраны здесь, чтобы их можно было
/// калибровать без поиска случайных offset/padding по экрану.
private enum AccountHeaderMotion {
    /// Контрольная высота для расчёта дистанции и скорости схлопывания.
    /// Оставляем 400 pt, чтобы не менять уже настроенную механику скролла.
    static let expandedVisibleHeight: CGFloat = 400
    /// Фактическая высота блока с балансом и картой до панели действий.
    /// Отделена от motion-высоты: так визуальная композиция совпадает с
    /// референсом, а порог и скорость скрытия остаются прежними.
    static let expandedContentVisibleHeight: CGFloat = 362
    /// Измеренная высота именно оранжевого фона в раскрытом состоянии.
    /// 433 pt дают нижнюю границу около y = 536 px на референсе 591 × 1280.
    static let expandedBackgroundVisibleHeight: CGFloat = 433
    /// Высота закреплённого хедера, включая status bar.
    static let compactVisibleHeight: CGFloat = 113
    /// Панель действий слегка перекрывает нижнюю волну, как в видео.
    static let actionPanelOverlap: CGFloat = 12
    /// Компактный PNG проявляется только в последней части схлопывания.
    static let compactRevealStart: CGFloat = 0.72

    static func layoutHeight(visibleHeight: CGFloat, safeAreaTop: CGFloat) -> CGFloat {
        max(44, visibleHeight - safeAreaTop)
    }

    /// Нормализованный прогресс интерактивного перехода: 0 — раскрыт,
    /// 1 — закреплённый compact header. Скорость задаёт сам ScrollView.
    static func collapseProgress(
        scrollOffset: CGFloat,
        collapseDistance: CGFloat
    ) -> CGFloat {
        min(max(scrollOffset / max(1, collapseDistance), 0), 1)
    }

    /// Фон уменьшается строго тем же прогрессом, которым движется контент.
    /// Линейная интерполяция соответствует покадровому движению из видео;
    /// инерцию и easing добавляет нативный ScrollView во время жеста.
    static func visibleHeight(
        expandedHeight: CGFloat,
        compactHeight: CGFloat,
        progress: CGFloat
    ) -> CGFloat {
        expandedHeight - ((expandedHeight - compactHeight) * progress)
    }

    static func smoothStep(_ value: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }
}

struct AccountDetailsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0

    private let scrollCoordinateSpace = "account-details-scroll"

    var body: some View {
        GeometryReader { proxy in
            let safeAreaTop = max(proxy.safeAreaInsets.top, 0)
            let expandedHeight = AccountHeaderMotion.layoutHeight(
                visibleHeight: AccountHeaderMotion.expandedVisibleHeight,
                safeAreaTop: safeAreaTop
            )
            let expandedBackgroundHeight = AccountHeaderMotion.layoutHeight(
                visibleHeight: AccountHeaderMotion.expandedBackgroundVisibleHeight,
                safeAreaTop: safeAreaTop
            )
            let expandedContentHeight = AccountHeaderMotion.layoutHeight(
                visibleHeight: AccountHeaderMotion.expandedContentVisibleHeight,
                safeAreaTop: safeAreaTop
            )
            let compactMotionHeight = AccountHeaderMotion.layoutHeight(
                visibleHeight: AccountHeaderMotion.compactVisibleHeight,
                safeAreaTop: safeAreaTop
            )
            // Фон compact-state должен включать safe area и строку навигации.
            // Раньше из 113 pt повторно вычитался safeAreaTop, поэтому фон
            // заканчивался под Dynamic Island, а заголовок ложился на контент.
            let compactFrameHeight = AccountHeaderMotion.compactVisibleHeight
            let collapseDistance = max(1, expandedHeight - compactMotionHeight)
            // Один и тот же прогресс управляет фоном, compact-state и фазой.
            // Это устраняет рассинхронизацию с Фото 2, где контент уже ушёл,
            // а оранжевый фон ошибочно оставался почти раскрытым.
            let collapseProgress = AccountHeaderMotion.collapseProgress(
                scrollOffset: scrollOffset,
                collapseDistance: collapseDistance
            )
            let visibleHeaderHeight = AccountHeaderMotion.visibleHeight(
                expandedHeight: expandedBackgroundHeight,
                compactHeight: compactFrameHeight,
                progress: collapseProgress
            )
            let phase = headerPhase(for: collapseProgress)

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                // Новый accountgradient.png остаётся фоном раскрытого состояния.
                Image("AccountHeaderGradient")
                    .resizable(resizingMode: .stretch)
                    .interpolation(.high)
                    .frame(maxWidth: .infinity)
                    .frame(height: visibleHeaderHeight)
                    .clipped()
                    .ignoresSafeArea(edges: .top)
                    .accessibilityHidden(true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        MashreqScrollOffsetReader(coordinateSpace: scrollCoordinateSpace)

                        // Баланс и карта принадлежат контенту ScrollView: поэтому
                        // они уходят вверх, пока строка заголовка остаётся на месте.
                        expandedHeaderContent
                            .frame(height: expandedContentHeight)

                        accountActionPanel
                            .padding(.horizontal, 22)
                            .padding(.top, -AccountHeaderMotion.actionPanelOverlap)

                        HighSpendCard()
                            .padding(.horizontal, 22)
                            .padding(.top, 16)

                        AccountAddMoneyBar()
                            .padding(.horizontal, 22)
                            .padding(.top, 47)

                        applePayRow
                            .padding(.top, 23)

                        transactions
                            .padding(.horizontal, 22)
                            .padding(.top, 22)
                    }
                    .padding(.bottom, 30)
                }
                // Без отдельной time-based анимации: прогресс точно следует
                // пальцу и инерции системного ScrollView, как в референсе.
                .mashreqTrackScrollOffset(
                    $scrollOffset,
                    coordinateSpace: scrollCoordinateSpace
                )

                compactHeaderBackground(
                    height: compactFrameHeight,
                    collapseProgress: collapseProgress
                )

                persistentHeaderNavigation
                    .accessibilityValue(phase.accessibilityValue)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-account-details")
    }

    private func headerPhase(for progress: CGFloat) -> AccountHeaderPhase {
        if progress <= 0.001 { return .expanded }
        if progress >= 0.999 { return .compact }
        return .transitioning
    }

    private func compactHeaderBackground(
        height: CGFloat,
        collapseProgress: CGFloat
    ) -> some View {
        let revealProgress = (collapseProgress - AccountHeaderMotion.compactRevealStart)
            / (1 - AccountHeaderMotion.compactRevealStart)
        let opacity = AccountHeaderMotion.smoothStep(revealProgress)

        return Image("AccountCompactHeader")
            .resizable(resizingMode: .stretch)
            .interpolation(.high)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .ignoresSafeArea(edges: .top)
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .zIndex(20)
    }

    /// Единственная закреплённая строка: в видео Back и название счёта
    /// остаются в одной координате во всех фазах.
    private var persistentHeaderNavigation: some View {
        HStack {
            Button { dismiss() } label: {
                Image("TransactionBack")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("NEO Current Account")
                .font(.mashreq(size: MashreqTextSize.label, weight: .medium))
                .foregroundStyle(Color.white)

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .zIndex(30)
    }

    private var expandedHeaderContent: some View {
        VStack(spacing: 0) {
            // На референсе баланс начинается примерно на 27 pt выше текущего
            // результата, при этом закреплённая строка навигации не двигается.
            Color.clear.frame(height: 53)

            Text("Total Available Balance")
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                .foregroundStyle(Color.white)

            HStack(spacing: 6) {
                Text("AED")
                Text(session.formattedAccountBalance)
                    .font(.mashreq(size: MashreqTextSize.displaySmall, weight: .bold))
            }
            .font(.mashreq(size: MashreqTextSize.title, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.top, 4)

            HStack(spacing: 3) {
                Text("Current Balance")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                Text("AED \(session.formattedAccountBalance)")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.top, 4)

            Image("AccountCardHero")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                // Исходник содержит тонкую чёрную рамку по внешнему краю.
                // Слот больше видимой карты на 2 pt с каждой стороны:
                // после маски остаётся референсный размер 224 × 136 pt.
                .frame(width: 228, height: 140)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .inset(by: 2)
                )
                .padding(.top, 16)
                .accessibilityLabel("Mashreq NEO debit card")

            Spacer(minLength: 0)
        }
    }

    private var accountActionPanel: some View {
        HStack(alignment: .top, spacing: 4) {
            Button { session.navigate(to: .yourAccountDetails) } label: {
                ReferenceActionIcon(assetName: "AccountActionDetails", title: "Account &\nCard Details")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens account details")
            ReferenceActionIcon(assetName: "AccountActionCardControl", title: "Card\nControl")
            Button { session.navigate(to: .eStatementRequest) } label: {
                ReferenceActionIcon(assetName: "AccountActionEStatements", title: "E-Statements")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens e-statement request")
            ReferenceActionIcon(
                assetName: "AccountActionMoreOptions",
                title: "More\nOptions",
                preservesExplicitLineBreaks: true
            )
        }
        .padding(.horizontal, 6)
        // В референсе иконки начинаются примерно через 8 pt от верхнего края,
        // а подписи получают место для двух строк без сжатия и обрезки.
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 97, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .mashreqCardShadow()
    }

    private var applePayRow: some View {
        HStack(spacing: 14) {
            Image("TransactionApplePay")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 47, height: 29)

            Divider().frame(height: 31)

            Text("Added to Apple Wallet")
                .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
    }

    private var transactions: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Transactions")
                    .font(.mashreq(size: MashreqTextSize.headline, weight: .semibold))
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image("TransactionFilterCalendar")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Filter")
                            .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                    }
                    .foregroundStyle(MashreqTheme.orangeDeep)
                }
            }

            HStack(spacing: 8) {
                Image("TransactionDateCalendar")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(session.completedTransfers.first?.detailDate ?? "17th August 2026")
                    .font(.mashreq(size: MashreqTextSize.copy, weight: .light))
            }
            .foregroundStyle(MashreqTheme.secondaryInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)

            ForEach(session.transactions) { transaction in
                if let transferID = transaction.transferID {
                    Button {
                        session.navigate(to: .transactionDetails(transferID))
                    } label: {
                        TransactionRow(transaction: transaction)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(MashreqTheme.ink)
                    .accessibilityHint("Opens transaction details")
                } else {
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

private struct HighSpendCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    Circle().fill(MashreqTheme.orangeDeep).frame(width: 6, height: 6)
                    Text("14 Aug 2026")
                        .font(.mashreq(size: MashreqTextSize.micro, weight: .regular))
                }

                Text("High Spend at New\nMerchant")
                    .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                    .padding(.top, 8)

                Text("Check out your recent high\nvalue transaction from a new\nmerchant!")
                    .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                    .foregroundStyle(MashreqTheme.bodyInk)
                    .lineSpacing(1)
                    .padding(.top, 8)

                Text("Check it out!")
                    .font(.mashreq(size: MashreqTextSize.meta, weight: .semibold))
                    .foregroundStyle(MashreqTheme.orangeDeep)
                    .padding(.top, 18)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 0) {
                Text("BID CITY AUTO\nSERVICES")
                    .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                    .multilineTextAlignment(.trailing)

                Divider().padding(.vertical, 12)

                Text("AED 1,650.00")
                    .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                Text("12 Aug 2026")
                    .font(.mashreq(size: MashreqTextSize.micro, weight: .light))
            }
            .padding(.top, 16)
            .frame(width: 124, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(MashreqTheme.line, lineWidth: 0.7)
        }
    }
}

private struct AccountAddMoneyBar: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Text("Add Money")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                Image("OverviewAddMoneyPlus")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 29, height: 29)
            }
            .foregroundStyle(MashreqTheme.orangeDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: 0xFFF0E8))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(hex: 0xF2D4C6), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
        }
    }
}
