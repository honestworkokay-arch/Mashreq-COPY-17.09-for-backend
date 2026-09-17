import SwiftUI
import UIKit

struct PayAndTransferView: View {
    @Environment(AppSession.self) private var session

    /// Три равных столбца повторяют сетку 3 × 2 из референса.
    private let actionColumns = Array(
        repeating: GridItem(.flexible(), spacing: 15),
        count: 3
    )

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                Image("PayHeaderBackground")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: topInset + 96)
                    .clipped()

                Text("Pay and transfer")
                    .font(.mashreq(size: MashreqTextSize.title, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(.top, topInset + 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        LazyVGrid(columns: actionColumns, spacing: 34) {
                            ForEach(PayReferenceAction.allCases) { action in
                                Button { perform(action) } label: {
                                    Image(action.assetName)
                                        .resizable()
                                        .interpolation(.high)
                                        .aspectRatio(448.0 / 548.0, contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .shadow(color: .black.opacity(0.035), radius: 5, y: 2)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(action.accessibilityLabel)
                            }
                        }

                        Text("More actions")
                            .font(.mashreq(size: MashreqTextSize.sectionLarge, weight: .bold))
                            .padding(.top, 28)

                        PayMoreActionRow(
                            assetName: "PayTrackTransfer",
                            title: "Track and manage",
                            subtitle: "Track every transfer you make",
                            action: { session.navigate(to: .trackAndManage) }
                        )
                        .padding(.top, 16)

                        PayMoreActionRow(
                            assetName: "PayManageBeneficiaries",
                            title: "Manage beneficiaries",
                            subtitle: "Add or modify your beneficiaries",
                            action: { session.navigate(to: .manageBeneficiaries) }
                        )

                        PayRemittanceInformationCard()
                            .padding(.top, 10)

                        // Нижнее меню рисуется RootTabView поверх экрана.
                        Color.clear.frame(height: 94)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, topInset + 59)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .accessibilityIdentifier("screen-pay")
    }

    /// Главная плитка оставляет существующий transfer-flow; остальные ведут
    /// в уже реализованные разделы приложения.
    private func perform(_ action: PayReferenceAction) {
        switch action {
        case .sendMoney, .ownAccount:
            session.beginNewTransfer()
        case .instantPayments:
            session.selectedBeneficiaryID = nil
            session.transferDraft = .empty(profile: session.profile)
            session.navigate(to: .recipientDetails)
        case .payBills:
            break
        case .payCreditCard:
            session.navigate(to: .selectCreditCard)
        case .cardlessCash:
            break
        }
    }
}

/// Порядок задан по строкам референса, а не по именам исходных файлов.
private enum PayReferenceAction: String, CaseIterable, Identifiable {
    case sendMoney
    case instantPayments
    case payBills
    case ownAccount
    case cardlessCash
    case payCreditCard

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .sendMoney: "PayActionSendMoney"
        case .instantPayments: "PayActionInstantPayments"
        case .payBills: "PayActionBills"
        case .ownAccount: "PayActionOwnAccount"
        case .cardlessCash: "PayActionCardlessCash"
        case .payCreditCard: "PayActionCreditCard"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .sendMoney: "Send money"
        case .instantPayments: "Instant payments"
        case .payBills: "Pay bills"
        case .ownAccount: "Own account transfer"
        case .cardlessCash: "Cardless cash"
        case .payCreditCard: "Pay credit card"
        }
    }
}

private struct PayMoreActionRow: View {
    let assetName: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(assetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 70, height: 82)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                        .foregroundStyle(MashreqTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)

                    Text(subtitle)
                        .font(.mashreq(size: MashreqTextSize.copy, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 6)

                ChevronGlyph()
                    .stroke(MashreqTheme.ink, lineWidth: 1.7)
                    .frame(width: 9, height: 16)
            }
            .frame(minHeight: 104)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct PayRemittanceInformationCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            InfoGlyph()
                .frame(width: 24, height: 24)

            (
                Text("To know more about our remittance\nservices please ")
                    .foregroundStyle(MashreqTheme.ink)
                + Text("click here.")
                    .foregroundStyle(Color(hex: 0xFF3E31))
                    .fontWeight(.semibold)
                + Text(" Note: You will\nbe redirected to a new tab.")
                    .foregroundStyle(MashreqTheme.ink)
            )
            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(hex: 0xDCDCDC), lineWidth: 1)
        }
    }
}

/// Instant Payments использует один экран с переключаемыми способами ввода,
/// соответствующий Mobile и Bank Acc референсам ORIG_C_04/05.
struct RecipientDetailsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var method: RecipientEntryMethod = .mobile
    @State private var mobileOrContact = ""
    @State private var bankName = ""
    @State private var accountNumber = ""
    @State private var iban = ""
    @State private var recipientName = ""
    @State private var showsExitConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Enter recipient details",
                height: 96,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 17,
                titleFontWeight: .regular,
                onBack: attemptExit
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)

            VStack(spacing: 0) {
                methodTabs

                ScrollView(showsIndicators: false) {
                    Group {
                        switch method {
                        case .mobile:
                            mobileForm
                        case .bankAccount:
                            bankAccountForm
                        case .iban:
                            ibanForm
                        case .wallet, .ipa:
                            identifierForm
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                    Color.clear.frame(height: 104)
                }
            }
            .padding(.top, 95)

            if method != .mobile || !mobileOrContact.isEmpty {
                MashreqPrimaryButton(title: "Proceed") {
                    submitRecipient()
                }
                .disabled(!canProceed)
                .opacity(canProceed ? 1 : 0.25)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(.white)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-recipient-details")
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.discardCurrentTransfer()
                    dismiss()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
    }

    private var methodTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(RecipientEntryMethod.allCases) { option in
                    Button {
                        method = option
                    } label: {
                        VStack(spacing: 12) {
                            Text(option.title)
                                .font(.mashreq(size: 15, weight: option == method ? .medium : .regular))
                                .foregroundStyle(option == method ? MashreqTheme.orangeDeep : Color(hex: 0xE5D6C9))
                                .frame(minWidth: option.width)
                            Rectangle()
                                .fill(option == method ? MashreqTheme.orangeDeep : .clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 58)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var mobileForm: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                SearchGlyph(color: Color(hex: 0xC69367))
                    .frame(width: 24, height: 24)
                TextField("Enter a mobile number or contact name.", text: $mobileOrContact)
                    .font(.mashreq(size: 14, weight: .medium))
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .frame(height: 70)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(MashreqTheme.secondaryInk.opacity(0.55), lineWidth: 1)
            }

            Text("Search for a contact from your contact list below or enter a registered mobile number, for example: XXXXXXX XXX")
                .font(.mashreq(size: 12, weight: .regular))
                .foregroundStyle(MashreqTheme.orangeDeep)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 18) {
                FilterChip("All", selected: true)
                FilterChip("Favourites")
                Spacer()
            }
            .padding(.top, 6)

            Text("In order to proceed, please give permission for Contacts")
                .font(.mashreq(size: 16, weight: .medium))
                .foregroundStyle(MashreqTheme.orangeDeep)
                .multilineTextAlignment(.center)
                .padding(.top, 31)

            Text("PROCEED TO\nSETTINGS")
                .font(.mashreq(size: 17, weight: .regular))
                .foregroundStyle(MashreqTheme.orangeDeep)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
        }
    }

    private var bankAccountForm: some View {
        VStack(spacing: 16) {
            recipientField("Select bank", text: $bankName)
            VStack(alignment: .leading, spacing: 5) {
                recipientField("Enter the bank account number", text: $accountNumber)
                Text("Enter the account number (up to 36 numeric digits)")
                    .font(.mashreq(size: 11, weight: .regular))
            }
            recipientField("Enter the recipient’s name", text: $recipientName)

            recentEmptyState
        }
    }

    private var ibanForm: some View {
        VStack(spacing: 16) {
            recipientField("Enter recipient IBAN", text: $iban)
            recipientField("Enter the recipient’s name", text: $recipientName)
            recentEmptyState
        }
    }

    private var identifierForm: some View {
        VStack(spacing: 16) {
            recipientField(method == .wallet ? "Enter wallet number" : "Enter recipient IPA", text: $accountNumber)
            recipientField("Enter the recipient’s name", text: $recipientName)
            recentEmptyState
        }
    }

    private var recentEmptyState: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                FilterChip("Recent", selected: true)
                FilterChip("Favorites")
                Spacer()
            }

            Image("EmptyBankTransactionsIllustration")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 175, height: 138)
                .padding(.top, 3)

            Text("There is nothing to show here")
                .font(.mashreq(size: 20, weight: .bold))
            Text("Your bank transactions is empty, Do a\nbank transaction now!")
                .font(.mashreq(size: 14, weight: .regular))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
    }

    private func recipientField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.mashreq(size: 14, weight: .regular))
            .padding(.horizontal, 15)
            .frame(height: 66)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(MashreqTheme.secondaryInk.opacity(0.62), lineWidth: 1)
            }
    }

    private var canProceed: Bool {
        switch method {
        case .mobile: !mobileOrContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .bankAccount: !bankName.isEmpty && !accountNumber.isEmpty && !recipientName.isEmpty
        case .iban: !iban.isEmpty && !recipientName.isEmpty
        case .wallet, .ipa: !accountNumber.isEmpty && !recipientName.isEmpty
        }
    }

    private func submitRecipient() {
        guard canProceed else { return }
        session.transferDraft.beneficiaryName = recipientName.isEmpty ? mobileOrContact : recipientName
        session.transferDraft.beneficiaryBank = bankName.isEmpty ? "Instant Payment" : bankName
        session.transferDraft.beneficiaryBankCountry = Country.uae.rawValue
        session.transferDraft.beneficiaryIBAN = iban.isEmpty
            ? (accountNumber.isEmpty ? mobileOrContact : accountNumber)
            : UAEIBANService.normalize(iban)
        session.navigate(to: .confirmRecipient)
    }

    private func attemptExit() {
        let hasProgress = !mobileOrContact.isEmpty || !bankName.isEmpty ||
            !accountNumber.isEmpty || !iban.isEmpty || !recipientName.isEmpty
        if hasProgress {
            showsExitConfirmation = true
        } else {
            dismiss()
        }
    }
}

private enum RecipientEntryMethod: String, CaseIterable, Identifiable {
    case mobile
    case wallet
    case ipa
    case bankAccount
    case iban

    var id: String { rawValue }
    var title: String {
        switch self {
        case .mobile: "Mobile"
        case .wallet: "Wallet"
        case .ipa: "IPA"
        case .bankAccount: "Bank Acc"
        case .iban: "IBAN"
        }
    }
    var width: CGFloat { title == "Bank Acc" ? 86 : 76 }
}

struct ManageBeneficiariesView: View {
    @Environment(AppSession.self) private var session
    @State private var query = ""
    @State private var selectedFilter: BeneficiaryFilter = .all
    @State private var selectedTab: BeneficiaryListTab = .moneyTransfer
    @State private var overlay: BeneficiaryManagementOverlay?

    var filtered: [Beneficiary] {
        guard selectedTab == .moneyTransfer else { return [] }
        return session.beneficiaries.filter { beneficiary in
            let matchesQuery = query.isEmpty
                || beneficiary.name.localizedCaseInsensitiveContains(query)
                || beneficiary.nickname.localizedCaseInsensitiveContains(query)
                || beneficiary.bank.localizedCaseInsensitiveContains(query)
                || beneficiary.account.localizedCaseInsensitiveContains(query)
            let matchesFilter: Bool = switch selectedFilter {
            case .all: true
            case .favourites: beneficiary.isFavourite
            case .international: beneficiary.country != .uae
            case .local: beneficiary.country == .uae
            }
            return matchesQuery && matchesFilter
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(
                title: "Manage beneficiaries",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true
            )
            .zIndex(10)

            VStack(spacing: 0) {
                beneficiaryTabs

                HStack(spacing: 18) {
                    SearchGlyph(color: Color(hex: 0x252733))
                        .frame(width: 24, height: 24)
                    TextField("Search", text: $query)
                        .font(.mashreq(size: MashreqTextSize.label, weight: .light))
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 16)
                .frame(height: 58)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(MashreqTheme.secondaryInk.opacity(0.72), lineWidth: 1)
                }
                .padding(.top, 20)

                HStack(spacing: 8) {
                    ForEach(BeneficiaryFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            BeneficiaryFilterChip(filter: filter, isSelected: selectedFilter == filter)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        Text(selectedFilter.sectionTitle)
                            .font(.mashreq(size: MashreqTextSize.title, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 24)
                            .padding(.bottom, 7)

                        ForEach(filtered) { beneficiary in
                            BeneficiaryRow(
                                beneficiary: beneficiary,
                                onSelect: {
                                    session.selectBeneficiary(beneficiary)
                                    // Для уже сохранённого beneficiary повторный Security tip
                                    // не показывается: пользователь сразу переходит к переводу.
                                    session.navigate(to: .makePayment)
                                },
                                onMore: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        overlay = .actions(beneficiary.id)
                                    }
                                }
                            )
                            if beneficiary.id != filtered.last?.id {
                                Divider()
                            }
                        }

                        if filtered.isEmpty {
                            VStack(spacing: 18) {
                                PersonEmptyGlyph()
                                    .stroke(MashreqTheme.orangeDeep, lineWidth: 1.7)
                                    .frame(width: 54, height: 54)
                                Text("No beneficiaries found")
                                    .font(.mashreq(size: 19, weight: .semibold))
                                Text("Add a beneficiary or change the search filters.")
                                    .font(.mashreq(size: 14, weight: .light))
                                    .foregroundStyle(MashreqTheme.secondaryInk)
                            }
                            .padding(.top, 24)
                        }

                        Color.clear.frame(height: 104)
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, MashreqTheme.horizontalPadding)
            // В референсе вкладки стоят ближе к нижнему краю хедера.
            .padding(.top, 88)

            if overlay == nil, selectedTab == .moneyTransfer {
                VStack {
                    Spacer()
                    MashreqPrimaryButton(title: "Add new beneficiary") {
                        session.startAddingBeneficiary()
                        session.navigate(to: .addBeneficiary)
                    }
                    .padding(.horizontal, MashreqTheme.horizontalPadding)
                    .padding(.vertical, 10)
                    .background(Color.white)
                }
                .zIndex(20)
            }

            if let overlay,
               let beneficiary = session.beneficiaries.first(where: { $0.id == overlay.beneficiaryID }) {
                BeneficiaryOverlayLayer(
                    mode: overlay,
                    beneficiary: beneficiary,
                    dismiss: {
                        withAnimation(.easeIn(duration: 0.16)) { self.overlay = nil }
                    },
                    modify: {
                        self.overlay = nil
                        session.startEditingBeneficiary(beneficiary)
                        session.navigate(to: .addBeneficiary)
                    },
                    requestDelete: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.overlay = .deleteConfirmation(beneficiary.id)
                        }
                    },
                    confirmDelete: {
                        session.deleteBeneficiary(id: beneficiary.id)
                        withAnimation(.easeIn(duration: 0.16)) { self.overlay = nil }
                    },
                    toggleFavourite: {
                        session.toggleFavouriteBeneficiary(id: beneficiary.id)
                        withAnimation(.easeIn(duration: 0.16)) { self.overlay = nil }
                    }
                )
                .zIndex(30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-beneficiaries")
    }

    private var beneficiaryTabs: some View {
        HStack(spacing: 0) {
            ForEach(BeneficiaryListTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 12) {
                        Text(tab.title)
                            .font(.mashreq(size: MashreqTextSize.headline, weight: tab == selectedTab ? .medium : .regular))
                            .foregroundStyle(tab == selectedTab ? MashreqTheme.orangeDeep : Color(hex: 0x34343E))
                            .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(tab == selectedTab ? MashreqTheme.orangeDeep : .clear)
                            .frame(width: 130, height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 58)
    }
}

/// Список выбора для transfer-flow отделён от Manage beneficiaries: здесь нет
/// меню редактирования и Security tip, строка получателя сразу открывает сумму.
struct TransferBeneficiaryPickerView: View {
    @Environment(AppSession.self) private var session
    @State private var query = ""
    @State private var scope: TransferBeneficiaryScope = .all

    private var filteredBeneficiaries: [Beneficiary] {
        session.beneficiaries.filter { beneficiary in
            let matchesQuery = query.isEmpty
                || beneficiary.displayName.localizedCaseInsensitiveContains(query)
                || beneficiary.account.localizedCaseInsensitiveContains(query)
                || beneficiary.bank.localizedCaseInsensitiveContains(query)
            let matchesScope: Bool = switch scope {
            case .all: true
            case .favourites: beneficiary.isFavourite
            case .local: beneficiary.country == .uae
            case .mashreqAccounts: false
            }
            return matchesQuery && matchesScope
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Transferring to",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 18,
                titleFontWeight: .regular
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 15) {
                        SearchGlyph(color: MashreqTheme.secondaryInk)
                            .frame(width: 23, height: 23)
                        TextField("Search your beneficiaries", text: $query)
                            .font(.mashreq(size: 14, weight: .light))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 72)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(MashreqTheme.secondaryInk.opacity(0.72), lineWidth: 1)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(TransferBeneficiaryScope.allCases) { option in
                                Button {
                                    scope = option
                                } label: {
                                    Text(option.title)
                                        .font(.mashreq(size: 12, weight: .regular))
                                        .foregroundStyle(scope == option ? MashreqTheme.orangeDeep : MashreqTheme.secondaryInk)
                                        .padding(.horizontal, 16)
                                        .frame(height: 38)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(scope == option ? MashreqTheme.orangeDeep : MashreqTheme.secondaryInk.opacity(0.55), lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 16)

                    Text(scope.sectionTitle)
                        .font(.mashreq(size: 16, weight: .regular))
                        .padding(.top, 21)
                        .padding(.bottom, 13)

                    LazyVStack(spacing: 0) {
                        ForEach(filteredBeneficiaries) { beneficiary in
                            Button {
                                session.selectBeneficiary(beneficiary)
                                session.navigate(to: .makePayment)
                            } label: {
                                HStack(spacing: 15) {
                                    CountryBadge(country: beneficiary.country)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(beneficiary.displayName)
                                            .font(.mashreq(size: 16, weight: .regular))
                                            .foregroundStyle(MashreqTheme.ink)
                                            .lineLimit(1)
                                        Text("***\(beneficiary.account.suffix(5)) | \(beneficiary.bank)")
                                            .font(.mashreq(size: 12, weight: .light))
                                            .foregroundStyle(MashreqTheme.secondaryInk)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.74)
                                    }

                                    Spacer(minLength: 0)
                                }
                                .frame(minHeight: 82)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .overlay(alignment: .bottom) {
                                Divider().padding(.leading, 61)
                            }
                        }

                        if filteredBeneficiaries.isEmpty {
                            Text(scope.emptyMessage)
                                .font(.mashreq(size: 14, weight: .light))
                                .foregroundStyle(MashreqTheme.secondaryInk)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 46)
                        }

                        Color.clear.frame(height: 100)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 124)
            }

            MashreqPrimaryButton(title: "Add new beneficiary") {
                session.startAddingBeneficiary()
                session.navigate(to: .addBeneficiary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(.white)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-transfer-beneficiary-picker")
    }
}

private enum TransferBeneficiaryScope: String, CaseIterable, Identifiable {
    case all
    case favourites
    case local
    case mashreqAccounts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .favourites: "Favourites"
        case .local: "Local"
        case .mashreqAccounts: "My mashreq acc"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all: "All"
        case .favourites: "Favourites"
        case .local: "Local"
        case .mashreqAccounts: "My Mashreq accounts"
        }
    }

    var emptyMessage: String {
        scopeDescription
    }

    private var scopeDescription: String {
        switch self {
        case .all: "No beneficiaries yet"
        case .favourites: "No favourite beneficiaries"
        case .local: "No local beneficiaries"
        case .mashreqAccounts: "No additional Mashreq accounts"
        }
    }
}

/// Security tip из переданного референса. Экран использует выбранного
/// beneficiary, поэтому имя и телефон никогда не являются статичным макетом.
struct ConfirmRecipientView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var showsExitConfirmation = false

    private var beneficiary: Beneficiary {
        session.selectedBeneficiary
            ?? session.beneficiaryDraft.beneficiary
            ?? Beneficiary(
                name: session.transferDraft.beneficiaryName.isEmpty ? "Beneficiary" : session.transferDraft.beneficiaryName,
                account: session.transferDraft.beneficiaryIBAN,
                bank: session.transferDraft.beneficiaryBank,
                country: .uae,
                mobileNumber: session.transferDraft.beneficiaryIBAN
            )
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Confirm recipient",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 18
            )
            .zIndex(10)

            HStack {
                Spacer()
                Button(action: { showsExitConfirmation = true }) {
                    CloseGlyph(color: .white)
                        .frame(width: 21, height: 21)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
            .padding(.top, 6)
            .padding(.trailing, 10)
            .zIndex(11)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    recipientCard

                    Image("SecurityTipIllustration")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                    Text("We prioritize your security!")
                        .font(.mashreq(size: 22, weight: .semibold))
                        .padding(.top, 12)

                    securityRow(
                        kind: .person,
                        text: "Verify name and mobile number of the recipient."
                    )
                    .padding(.top, 18)

                    securityRow(
                        kind: .payment,
                        text: "Be cautious of scammers asking you to send them money via social media, emails, calls, or text messages."
                    )
                    .padding(.top, 12)

                    Color.clear.frame(height: 176)
                }
                .padding(.horizontal, 22)
                .padding(.top, 86)
            }

            VStack(spacing: 10) {
                Spacer()
                MashreqOutlineButton(title: "Change recipient") {
                    dismiss()
                }
                MashreqPrimaryButton(title: "Confirm and proceed") {
                    session.navigate(to: .makePayment)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 10)
            .background(alignment: .bottom) {
                Color.white.frame(height: 144)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-confirm-recipient")
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.discardCurrentTransfer()
                    session.returnToOverview()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
    }

    private var recipientCard: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().fill(MashreqTheme.orange)
                Text(recipientInitials)
                    .font(.mashreq(size: 17, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(maskedRecipientName)
                    .font(.mashreq(size: 17, weight: .semibold))
                    .lineLimit(1)
                Text(beneficiary.mobileNumber.isEmpty ? beneficiary.account : beneficiary.mobileNumber)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .mashreqCardShadow()
    }

    private func securityRow(kind: ConfirmRecipientGlyph.Kind, text: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                Circle().fill(MashreqTheme.orangeSoft)
                ConfirmRecipientGlyph(kind: kind)
                    .stroke(MashreqTheme.orangeDeep, lineWidth: 1.6)
                    .frame(width: 23, height: 23)
            }
            .frame(width: 48, height: 48)

            Text(text)
                .font(.mashreq(size: 17, weight: .regular))
                .foregroundStyle(MashreqTheme.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recipientInitials: String {
        let parts = beneficiary.name.split(separator: " ")
        return parts.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private var maskedRecipientName: String {
        beneficiary.name.uppercased().split(separator: " ").map { word in
            guard word.count > 4 else { return String(word) }
            return "\(word.prefix(4))*****"
        }.joined(separator: " ")
    }
}

private struct ConfirmRecipientGlyph: Shape {
    enum Kind { case person, payment }
    let kind: Kind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch kind {
        case .person:
            path.addEllipse(in: CGRect(x: rect.midX - 4, y: rect.minY + 1, width: 8, height: 8))
            path.addRoundedRect(
                in: CGRect(x: rect.minX + 4, y: rect.midY, width: rect.width - 8, height: rect.height / 2),
                cornerSize: CGSize(width: 7, height: 7)
            )
        case .payment:
            path.addRoundedRect(
                in: CGRect(x: rect.minX + 2, y: rect.minY + 2, width: rect.width - 7, height: rect.height - 4),
                cornerSize: CGSize(width: 2, height: 2)
            )
            path.move(to: CGPoint(x: rect.minX + 5, y: rect.minY + 8))
            path.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY + 8))
            path.addEllipse(in: CGRect(x: rect.maxX - 10, y: rect.midY - 3, width: 9, height: 9))
        }
        return path
    }
}

struct MakePaymentView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var validationMessage: String?
    @State private var showsExitConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Send Money",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 17,
                titleFontWeight: .medium,
                onBack: attemptExit
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    transferIdentityRow(
                        label: "Transferring from",
                        value: "\(session.transferDraft.senderAccountName) | **** \(session.profile.accountNumber.suffix(4))",
                        detail: "Available balance: AED \(session.formattedAccountBalance)"
                    )

                    Text("↓")
                        .font(.system(size: 27, weight: .ultraLight))
                        .foregroundStyle(Color(hex: 0xD6D7D9))
                        .padding(.leading, 7)
                        .padding(.vertical, 2)

                    transferIdentityRow(
                        label: "Transferring to",
                        value: "\(session.transferDraft.beneficiaryName) | **** \(session.transferDraft.beneficiaryIBAN.suffix(4))",
                        detail: session.transferDraft.beneficiaryBank
                    )

                    HStack(spacing: 16) {
                        UAEFlagView(size: 42)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Enter transfer amount")
                                .font(.mashreq(size: 13, weight: .light))
                                .foregroundStyle(MashreqTheme.secondaryInk)
                            HStack(spacing: 14) {
                                Text("AED")
                                    .font(.mashreq(size: 21, weight: .semibold))
                                TextField("00.00", text: $amount)
                                    .font(.mashreq(size: 28, weight: .semibold))
                                    .keyboardType(.decimalPad)
                            }
                        }
                    }
                    .frame(minHeight: 92)
                    .overlay(alignment: .bottom) { Divider() }

                    Button {
                        session.navigate(to: .purposeOfTransfer)
                    } label: {
                        transferNavigationRow(
                            assetName: "TransferPurposeIcon",
                            title: "Purpose of payment",
                            value: session.transferDraft.purposeOfPayment.isEmpty
                                ? "Select Purpose"
                                : session.transferDraft.purposeOfPayment
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)

                    Button {
                        session.navigate(to: .additionalTransferDetails)
                    } label: {
                        HStack(spacing: 15) {
                            Image("TransferDetailsIcon")
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: 42, height: 42)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Additional transfer details")
                                    .font(.mashreq(size: 16, weight: .semibold))
                                    .foregroundStyle(MashreqTheme.ink)
                                Text("Schedule payment: \(session.transferSchedule.rawValue)")
                                    .font(.mashreq(size: 13, weight: .regular))
                                    .foregroundStyle(MashreqTheme.ink)
                                Text("Paying bank fees: \(session.transferFeePayer.rawValue)")
                                    .font(.mashreq(size: 13, weight: .regular))
                                    .foregroundStyle(MashreqTheme.ink)
                            }

                            Spacer(minLength: 4)
                            ChevronGlyph()
                                .stroke(Color(hex: 0xB8773C), lineWidth: 1.7)
                                .frame(width: 9, height: 16)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) { Divider() }

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                            .foregroundStyle(MashreqTheme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                    }

                    HStack(spacing: 12) {
                        Image("TransferScheduleIcon")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Estimated processing time:")
                                .font(.mashreq(size: 13, weight: .semibold))
                            Text(session.transferSchedule == .immediately ? "Instant" : "Scheduled")
                                .font(.mashreq(size: 13, weight: .regular))
                        }
                    }
                    .padding(.horizontal, 2)
                    .frame(height: 62)

                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 90)
            }

            MashreqPrimaryButton(title: "Review transfer") {
                submit()
            }
            .disabled(!canReview)
            .grayscale(canReview ? 0 : 1)
            .opacity(canReview ? 1 : 0.28)
            .padding(.horizontal, MashreqTheme.horizontalPadding)
            .padding(.vertical, 10)
            .background(Color.white)

            VStack {
                HStack {
                    Spacer()
                    Button(action: attemptExit) {
                        CloseGlyph(color: .white)
                            .frame(width: 21, height: 21)
                            .frame(width: 44, height: 44)
                    }
                }
                Spacer()
            }
            .padding(.top, 6)
            .padding(.trailing, 10)
            .zIndex(11)
        }
        .toolbar(.hidden, for: .navigationBar)
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.discardCurrentTransfer()
                    dismiss()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
        .accessibilityIdentifier("screen-make-payment")
        .onAppear {
            if amount.isEmpty, session.transferDraft.amount > 0 {
                amount = MoneyText.amount(session.transferDraft.amount)
            }
        }
    }

    private func attemptExit() {
        let hasProgress = session.selectedBeneficiaryID != nil ||
            !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !session.transferDraft.purposeOfPayment.isEmpty ||
            session.transferSchedule != .immediately ||
            session.transferFeePayer != .sender || session.includesPaymentNote
        if hasProgress {
            showsExitConfirmation = true
        } else {
            dismiss()
        }
    }

    private func transferIdentityRow(label: String, value: String, detail: String) -> some View {
        HStack(spacing: 16) {
            UAEFlagView(size: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(value)
                    .font(.mashreq(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(detail)
                    .font(.mashreq(size: 12, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            ChevronGlyph()
                .stroke(Color(hex: 0xB8773C), lineWidth: 1.7)
                .frame(width: 9, height: 16)
        }
        .frame(minHeight: 83)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE1E1E1))
                .frame(height: 1)
                .padding(.leading, 57)
        }
    }

    private func transferNavigationRow(assetName: String, title: String, value: String) -> some View {
        HStack(spacing: 15) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(value)
                    .font(.mashreq(size: 15, weight: .semibold))
                    .foregroundStyle(MashreqTheme.ink)
            }
            Spacer()
            ChevronGlyph()
                .stroke(Color(hex: 0xB8773C), lineWidth: 1.7)
                .frame(width: 9, height: 16)
        }
        .frame(height: 72)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE1E1E1))
                .frame(height: 1)
                .padding(.leading, 57)
        }
    }

    private var enteredAmount: Decimal? {
        Decimal(string: amount.replacingOccurrences(of: ",", with: ""))
    }

    private var canReview: Bool {
        guard let enteredAmount, enteredAmount > 0 else { return false }
        return enteredAmount <= session.accountBalance
            && !session.transferDraft.purposeOfPayment.isEmpty
    }

    private func submit() {
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: "")
        guard let value = Decimal(string: normalizedAmount), value > 0 else {
            validationMessage = "Enter a valid transfer amount"
            return
        }
        guard value <= session.accountBalance else {
            validationMessage = "The transfer amount exceeds your available balance"
            return
        }
        let normalizedPurpose = session.transferDraft.purposeOfPayment
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPurpose.isEmpty else {
            validationMessage = "Purpose of payment cannot be empty"
            return
        }

        session.transferDraft.amount = value
        session.transferDraft.purposeOfPayment = normalizedPurpose
        validationMessage = nil
        session.navigate(to: .reviewTransfer)
    }
}

/// Отдельный список назначения платежа повторяет ORIG_C_07 и возвращает
/// выбранное значение в общий transferDraft.
struct PurposeOfTransferView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Purpose of transfer",
                height: 112,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 18,
                titleFontWeight: .regular
            )
            .zIndex(10)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(TransferPurpose.allCases) { purpose in
                        Button {
                            session.transferDraft.purposeOfPayment = purpose.rawValue
                            dismiss()
                        } label: {
                            HStack {
                                Text(purpose.rawValue)
                                    .font(.mashreq(size: 16, weight: .regular))
                                    .foregroundStyle(MashreqTheme.ink)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)

                                if session.transferDraft.purposeOfPayment == purpose.rawValue {
                                    Circle()
                                        .fill(MashreqTheme.orangeDeep)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .frame(minHeight: 64)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { Divider() }
                    }
                }
                .padding(.horizontal, 21)
                .padding(.top, 113)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-purpose-of-transfer")
    }
}

/// Дополнительные параметры вынесены из Send Money в самостоятельный экран.
/// Schedule, fee payer и note сохраняются в AppSession и сразу обновляют summary.
struct AdditionalTransferDetailsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var activeSheet: AdditionalTransferSheet?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Additional transfer details",
                height: 106,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 17,
                titleFontWeight: .regular
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Button { activeSheet = .schedule } label: {
                        additionalRow(
                            assetName: "TransferScheduleIcon",
                            label: "Schedule payment",
                            value: session.transferSchedule.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    Button { activeSheet = .fees } label: {
                        additionalRow(
                            assetName: "TransferFeeIcon",
                            label: "Bank fees to be paid by",
                            value: session.transferFeePayer.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        session.includesPaymentNote.toggle()
                        if !session.includesPaymentNote {
                            session.transferDraft.noteToBeneficiary = ""
                        }
                    } label: {
                        HStack(spacing: 8) {
                            PaymentNoteCheckbox(isChecked: session.includesPaymentNote)
                                .frame(width: 20, height: 20)
                            Text("Have a payment note to beneficiary?")
                                .font(.mashreq(size: 14, weight: .medium))
                                .foregroundStyle(MashreqTheme.ink)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 15)

                    if session.includesPaymentNote {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Payment note to beneficiary (Optional)")
                                .font(.mashreq(size: 12, weight: .light))
                                .foregroundStyle(MashreqTheme.secondaryInk)
                            TextField(
                                "For personal reasons",
                                text: Binding(
                                    get: { session.transferDraft.noteToBeneficiary },
                                    set: { session.transferDraft.noteToBeneficiary = $0 }
                                ),
                                axis: .vertical
                            )
                            .font(.mashreq(size: 15, weight: .regular))
                            .lineLimit(2...3)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .frame(minHeight: 72, alignment: .topLeading)
                        .overlay {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(MashreqTheme.secondaryInk.opacity(0.55), lineWidth: 1)
                        }
                        .padding(.top, 13)
                    }

                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 23)
                .padding(.top, 82)
            }

            MashreqPrimaryButton(title: "Confirm") {
                dismiss()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(.white)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-additional-transfer-details")
        .mashreqEdgeToEdgeBottomSheet(
            item: $activeSheet,
            height: { $0 == .fees ? 304 : 242 }
        ) { sheet in
            AdditionalTransferOptionSheet(sheet: sheet) {
                activeSheet = nil
            }
            .environment(session)
        }
    }

    private func additionalRow(assetName: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(value)
                    .font(.mashreq(size: 15, weight: .medium))
                    .foregroundStyle(MashreqTheme.ink)
            }

            Spacer(minLength: 6)
            DownChevronGlyph()
                .stroke(MashreqTheme.orangeDeep, lineWidth: 1.8)
                .frame(width: 17, height: 9)
        }
        .frame(minHeight: 94)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE1E1E1))
                .frame(height: 1)
                .padding(.leading, 54)
        }
    }
}

private enum AdditionalTransferSheet: String, Identifiable {
    case schedule
    case fees

    var id: String { rawValue }
}

private struct AdditionalTransferOptionSheet: View {
    let sheet: AdditionalTransferSheet
    let onDismiss: () -> Void
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(hex: 0xC9C9C9))
                .frame(width: 48, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 9)

            Image(sheet == .fees ? "TransferFeeIcon" : "TransferScheduleIcon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 46, height: 46)
                .padding(.top, 17)

            Text(sheet == .fees ? "Bank fees to be paid by" : "Schedule payment")
                .font(.mashreq(size: 18, weight: .regular))
                .padding(.top, 15)
                .padding(.bottom, 14)

            if sheet == .fees {
                ForEach(TransferFeePayer.allCases) { payer in
                    optionRow(title: payer.rawValue, selected: session.transferFeePayer == payer) {
                        session.transferFeePayer = payer
                        onDismiss()
                    }
                }
            } else {
                ForEach(TransferSchedule.allCases) { schedule in
                    optionRow(title: schedule.rawValue, selected: session.transferSchedule == schedule) {
                        session.transferSchedule = schedule
                        onDismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white)
    }

    private func optionRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Circle()
                    .fill(MashreqTheme.orangeSoft)
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(sheet == .fees ? "TransferFeeIcon" : "TransferScheduleIcon")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 29, height: 29)
                    }
                Text(title)
                    .font(.mashreq(size: 15, weight: .regular))
                    .foregroundStyle(MashreqTheme.ink)
                Spacer()
                if selected {
                    CheckmarkGlyph()
                        .stroke(MashreqTheme.orangeDeep, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 21, height: 14)
                }
            }
            .frame(height: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PaymentNoteCheckbox: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isChecked ? Color(hex: 0x3E3F42) : .clear)
            RoundedRectangle(cornerRadius: 1.5)
                .stroke(Color(hex: 0x55565A), lineWidth: 1.4)
            if isChecked {
                CheckmarkGlyph()
                    .stroke(.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .padding(4)
            }
        }
    }
}

/// Источник списка — завершённые переводы AppSession. Поэтому поиск, сумма,
/// reference и переход в details всегда показывают данные реальной операции.
struct TrackAndManageView: View {
    @Environment(AppSession.self) private var session
    @State private var query = ""
    @State private var selectedScope: TransferTrackingScope = .processed
    @State private var dateFilter: TransferDateFilter = .all

    private var filteredTransfers: [CompletedTransfer] {
        guard selectedScope == .processed else { return [] }
        return session.completedTransfers.filter { transfer in
            let matchesDate = dateFilter.includes(transfer.createdAt)
            let matchesQuery = query.isEmpty
                || transfer.beneficiaryName.localizedCaseInsensitiveContains(query)
                || transfer.reference.localizedCaseInsensitiveContains(query)
                || transfer.beneficiaryBank.localizedCaseInsensitiveContains(query)
                || transfer.beneficiaryIBAN.localizedCaseInsensitiveContains(query)
            return matchesDate && matchesQuery
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Track and manage",
                height: 111,
                showsBack: true,
                usesReferenceBackground: true
            )
            .zIndex(10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        TextField("Search by transaction details", text: $query)
                            .font(.mashreq(size: MashreqTextSize.copy, weight: .light))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(MashreqTheme.ink)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 61)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(MashreqTheme.secondaryInk, lineWidth: 1)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(TransferTrackingScope.allCases) { scope in
                                Button {
                                    selectedScope = scope
                                } label: {
                                    Text(scope.title)
                                        .font(.mashreq(size: MashreqTextSize.meta, weight: .regular))
                                        .foregroundStyle(selectedScope == scope ? MashreqTheme.orangeDeep : MashreqTheme.secondaryInk)
                                        .padding(.horizontal, 16)
                                        .frame(height: 36)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedScope == scope ? MashreqTheme.orangeDeep : MashreqTheme.secondaryInk, lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 18)

                    HStack {
                        Text("Transactions")
                            .font(.mashreq(size: MashreqTextSize.title, weight: .semibold))
                        Spacer()
                        Menu {
                            ForEach(TransferDateFilter.allCases) { filter in
                                Button {
                                    dateFilter = filter
                                } label: {
                                    Label(filter.title, systemImage: dateFilter == filter ? "checkmark" : "calendar")
                                }
                            }
                        } label: {
                            HStack(spacing: 7) {
                                Image("TransactionFilterCalendar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 23, height: 23)
                                Text("Filter")
                            }
                            .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                            .foregroundStyle(MashreqTheme.orangeDeep)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 25)

                    if filteredTransfers.isEmpty {
                        ContentUnavailableView(
                            selectedScope.emptyTitle,
                            systemImage: "arrow.left.arrow.right.circle",
                            description: Text(selectedScope.emptyDescription)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 54)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredTransfers) { transfer in
                                Button {
                                    session.navigate(to: .transactionDetails(transfer.id))
                                } label: {
                                    TrackTransferRow(transfer: transfer)
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                        .padding(.top, 13)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 128)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-track-and-manage")
    }
}

private enum TransferTrackingScope: String, CaseIterable, Identifiable {
    case processed
    case payLater
    case scheduled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .processed: "All Processed Transactions"
        case .payLater: "Pay Later"
        case .scheduled: "Scheduled"
        }
    }

    var emptyTitle: String {
        switch self {
        case .processed: "No matching transactions"
        case .payLater: "No pay-later transfers"
        case .scheduled: "No scheduled transfers"
        }
    }

    var emptyDescription: String {
        selectedDescription
    }

    private var selectedDescription: String {
        switch self {
        case .processed: "Try another recipient name or reference number."
        case .payLater: "Transfers marked for later will appear here."
        case .scheduled: "Scheduled transfers will appear here."
        }
    }
}

private enum TransferDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case lastSevenDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All dates"
        case .today: "Today"
        case .lastSevenDays: "Last 7 days"
        }
    }

    func includes(_ date: Date, now: Date = .now) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .lastSevenDays:
            guard let threshold = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
            return date >= threshold
        }
    }
}

private struct TrackTransferRow: View {
    let transfer: CompletedTransfer

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(transfer.beneficiaryName)
                    .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                    .foregroundStyle(MashreqTheme.ink)
                    .lineLimit(1)
                Spacer(minLength: 10)
                Text(transfer.detailDate)
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
            }

            HStack(spacing: 7) {
                UAEFlagView(size: 17)
                Text("AED \(transfer.formattedAmount)")
                    .font(.mashreq(size: MashreqTextSize.label, weight: .regular))
                    .foregroundStyle(MashreqTheme.ink)
            }

            HStack {
                Text(transfer.reference)
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(MashreqTheme.orangeDeep)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct ReviewTransferView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var showsExitConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Review transfer",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 17,
                titleFontWeight: .semibold
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    reviewPartyRow(
                        label: "Transferring from",
                        primary: "\(session.transferDraft.senderAccountName) | **** \(session.transferDraft.senderAccountNumber.suffix(4))",
                        secondary: nil
                    )
                    Text("↓")
                        .font(.system(size: 25, weight: .ultraLight))
                        .foregroundStyle(Color(hex: 0xD6D7D9))
                        .padding(.leading, 7)
                        .padding(.vertical, 1)
                    reviewPartyRow(
                        label: "Transferring to",
                        primary: "\(session.transferDraft.beneficiaryName) | **** \(session.transferDraft.beneficiaryIBAN.suffix(4))",
                        secondary: session.transferDraft.beneficiaryBank
                    )
                    reviewAmountRow(
                        label: "Transfer amount",
                        value: "AED \(MoneyText.amount(session.transferDraft.amount))"
                    )
                    reviewAmountRow(
                        label: "Debit amount (Excluding bank fees)",
                        value: "AED \(MoneyText.amount(session.transferDraft.amount))"
                    )
                    reviewIconRow(
                        assetName: "TransferPurposeIcon",
                        label: "Purpose of transfer",
                        value: session.transferDraft.purposeOfPayment
                    )
                    reviewIconRow(
                        assetName: "TransferScheduleIcon",
                        label: "Schedule payment",
                        value: session.transferSchedule == .immediately ? "Pay Immediately" : session.transferSchedule.rawValue
                    )

                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 90)
            }

            MashreqPrimaryButton(title: "Proceed to authentication") {
                session.navigate(to: .transferOTP)
            }
            .padding(.horizontal, MashreqTheme.horizontalPadding)
            .padding(.vertical, 12)
            .background(Color.white)

            VStack {
                HStack {
                    Spacer()
                    Button(action: { showsExitConfirmation = true }) {
                        CloseGlyph(color: .white)
                            .frame(width: 21, height: 21)
                            .frame(width: 44, height: 44)
                    }
                }
                Spacer()
            }
            .padding(.top, 6)
            .padding(.trailing, 10)
            .zIndex(11)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-review-transfer")
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.discardCurrentTransfer()
                    session.returnToOverview()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
    }

    private func reviewPartyRow(label: String, primary: String, secondary: String?) -> some View {
        HStack(spacing: 16) {
            UAEFlagView(size: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(primary)
                    .font(.mashreq(size: 15, weight: .semibold))
                    .foregroundStyle(MashreqTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                if let secondary, !secondary.isEmpty {
                    Text(secondary)
                        .font(.mashreq(size: 12, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 72)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 57) }
    }

    private func reviewAmountRow(label: String, value: String) -> some View {
        HStack(spacing: 16) {
            UAEFlagView(size: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(value)
                    .font(.mashreq(size: 17, weight: .semibold))
                    .foregroundStyle(MashreqTheme.ink)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 72)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 57) }
    }

    private func reviewIconRow(assetName: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
            .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(value)
                    .font(.mashreq(size: 15, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(minHeight: 75)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 57) }
    }
}

/// Экран подтверждения перевода повторяет Mobile OTP из присланного HEIC.
/// Шестая цифра автоматически продолжает существующий transfer-flow.
struct TransferOTPView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var hasSubmitted = false
    @State private var resendSeconds = 60
    @State private var resendCycle = 0
    @State private var showsExitConfirmation = false
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                TransferOTPHeader(
                    topInset: topInset,
                    width: proxy.size.width,
                    onBack: { dismiss() },
                    onClose: { showsExitConfirmation = true }
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Исходная иллюстрация взята из референса без перерисовки.
                        Image("OTPIdentityIllustration")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 205, height: 192)
                            .frame(maxWidth: .infinity)

                        Text("Authentication")
                            .font(.mashreq(size: MashreqTextSize.title, weight: .bold))
                            .foregroundStyle(MashreqTheme.ink)
                            .padding(.top, 12)

                        Text("Please enter the 6 digit code sent to your\nregistered mobile number.")
                            .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .light))
                            .foregroundStyle(MashreqTheme.bodyInk)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 11)

                        HStack(spacing: 14) {
                            PhoneOutlineGlyph()
                                .stroke(MashreqTheme.orange, lineWidth: 1.6)
                                .frame(width: 20, height: 27)

                            Text(session.profile.maskedSMSPhone)
                                .font(.mashreq(size: MashreqTextSize.title, weight: .semibold))
                                .foregroundStyle(MashreqTheme.bodyInk)
                        }
                        .padding(.top, 20)

                        otpBoxes
                            .padding(.top, 29)

                        Text("Haven’t received your OTP?")
                            .font(.mashreq(size: MashreqTextSize.title, weight: .bold))
                            .foregroundStyle(MashreqTheme.orange)
                            .padding(.top, 42)

                        resendStatus
                            .padding(.top, 27)

                        Color.clear.frame(height: 48)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, topInset + 66)
                }
            }
            .ignoresSafeArea(edges: .top)
            // Не даём numberPad сжимать экран и поднимать illustration поверх header.
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-transfer-otp")
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.discardCurrentTransfer()
                    session.returnToOverview()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
        .task(id: resendCycle) {
            // Два состояния: обратный отсчёт и активная кнопка повторной отправки.
            while resendSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                resendSeconds -= 1
            }
        }
    }

    private var otpBoxes: some View {
        let digits = Array(code)

        return ZStack {
            HStack(spacing: 20) {
                ForEach(0..<6, id: \.self) { index in
                    Text(index < digits.count ? String(digits[index]) : "")
                        .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    index == min(digits.count, 5) && isCodeFocused
                                        ? MashreqTheme.orangeDeep
                                        : Color(hex: 0xDEDEDE),
                                    lineWidth: 1.5
                                )
                        }
                }
            }
            .frame(maxWidth: .infinity)

            // Скрытое системное поле поддерживает вставку кода из SMS.
            TextField("One-time code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let sanitized = String(newValue.filter { $0.isNumber }.prefix(6))
                    if sanitized != newValue {
                        code = sanitized
                        return
                    }

                    guard sanitized.count == 6, !hasSubmitted else { return }
                    hasSubmitted = true
                    guard session.completeCurrentTransfer() != nil else {
                        hasSubmitted = false
                        return
                    }
                    session.navigate(to: .transferSuccess)
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { isCodeFocused = true }
    }

    @ViewBuilder
    private var resendStatus: some View {
        if resendSeconds > 0 {
            HStack(spacing: 10) {
                Text("Resend possible in")
                    .foregroundStyle(MashreqTheme.bodyInk)
                Text("\(resendSeconds) sec.")
                    .foregroundStyle(MashreqTheme.orange)
                    .fontWeight(.semibold)
            }
            .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .light))
        } else {
            Button("Resend OTP") {
                code = ""
                hasSubmitted = false
                resendSeconds = 60
                resendCycle += 1
                isCodeFocused = true
            }
            .buttonStyle(.plain)
            .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
            .foregroundStyle(MashreqTheme.orange)
        }
    }
}

private struct TransferOTPHeader: View {
    let topInset: CGFloat
    let width: CGFloat
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Image("ReferenceFlowHeaderBackground")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: width, height: topInset + 58)
                .clipped()

            HStack {
                Button(action: onBack) {
                    Image("ReferenceFlowBack")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text("Send Money")
                    .font(.mashreq(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onClose) {
                    CloseGlyph(color: .white)
                        .frame(width: 21, height: 21)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, topInset + 4)
        }
        .frame(height: topInset + 58)
    }
}

private struct ReviewTransferRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
            Spacer()
            Text(value)
                .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TransferringFromView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(
                title: "Transferring from",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 20,
                titleFontWeight: .semibold
            )
                .zIndex(10)

            VStack(spacing: 24) {
                Button {
                    session.navigate(
                        to: session.selectedBeneficiary == nil
                            ? .selectTransferBeneficiary
                            : .makePayment
                    )
                } label: {
                    HStack(spacing: 15) {
                        UAEFlagView(size: 51)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(accountTitle)
                                .font(.mashreq(size: 18, weight: .regular))
                                .foregroundStyle(MashreqTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("AED \(session.formattedAccountBalance)")
                                .font(.mashreq(size: 20, weight: .regular))
                                .foregroundStyle(MashreqTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.68)
                        }
                        .layoutPriority(1)

                        Spacer(minLength: 4)

                        VStack(alignment: .trailing, spacing: 17) {
                            Text(session.profile.accountNumber)
                                .font(.mashreq(size: 14, weight: .regular))
                                .foregroundStyle(MashreqTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Text("Active")
                                .font(.mashreq(size: 14, weight: .regular))
                                .foregroundStyle(MashreqTheme.success)
                                .padding(.horizontal, 10)
                                .frame(height: 30)
                                .background(MashreqTheme.success.opacity(0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .padding(.horizontal, 21)
                    .frame(height: 132)
                    .background(.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: 0x303030), lineWidth: 1.5)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 23)
            .padding(.top, 105)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-transferring-from")
    }

    private var accountTitle: String {
        let words = session.transferDraft.senderAccountName.split(separator: " ")
        guard words.count >= 3 else { return session.transferDraft.senderAccountName }
        return words.enumerated().map { index, word in
            index == 0 ? word.capitalized : String(word)
        }.joined(separator: "\n")
    }
}

private struct MenuRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 16) {
            ZStack { Circle().fill(MashreqTheme.orangeSoft).frame(width: 44, height: 44); Image(systemName: icon).foregroundStyle(MashreqTheme.orange) }
            Text(title).font(.mashreq(size: 17, weight: .medium))
            Spacer()
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 60) }
    }
}

private struct FilterChip: View {
    let title: String
    var selected = false
    init(_ title: String, selected: Bool = false) { self.title = title; self.selected = selected }
    var body: some View {
        Text(title).font(.mashreq(size: 12, weight: .medium)).foregroundStyle(selected ? MashreqTheme.orange : MashreqTheme.secondaryInk).padding(.horizontal, 13).frame(height: 38).overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? MashreqTheme.orange : MashreqTheme.secondaryInk))
    }
}

private enum BeneficiaryListTab: String, CaseIterable, Identifiable {
    case moneyTransfer
    case billPayment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moneyTransfer: "Money Transfer"
        case .billPayment: "Bill Payment"
        }
    }
}

private enum BeneficiaryFilter: String, CaseIterable, Identifiable {
    case all
    case favourites
    case international
    case local

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .favourites: "Favourites"
        case .international: "International"
        case .local: "Local"
        }
    }

    var sectionTitle: String { title }

    var width: CGFloat {
        switch self {
        case .all: 50
        case .favourites: 88
        case .international: 108
        case .local: 64
        }
    }
}

private struct BeneficiaryFilterChip: View {
    let filter: BeneficiaryFilter
    let isSelected: Bool

    var body: some View {
        Text(filter.title)
            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
            .foregroundStyle(isSelected ? MashreqTheme.orangeDeep : Color(hex: 0x4D4E57))
            .frame(width: filter.width, height: 40)
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        isSelected ? MashreqTheme.orangeDeep : MashreqTheme.secondaryInk.opacity(0.66),
                        lineWidth: 1
                    )
            }
    }
}

private enum BeneficiaryManagementOverlay: Equatable {
    case actions(UUID)
    case deleteConfirmation(UUID)

    var beneficiaryID: UUID {
        switch self {
        case .actions(let id), .deleteConfirmation(let id): id
        }
    }
}

/// Затемнение и нижние панели повторяют два референсных состояния, но действия
/// работают с реальным beneficiary из AppSession.
private struct BeneficiaryOverlayLayer: View {
    let mode: BeneficiaryManagementOverlay
    let beneficiary: Beneficiary
    let dismiss: () -> Void
    let modify: () -> Void
    let requestDelete: () -> Void
    let confirmDelete: () -> Void
    let toggleFavourite: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: dismiss)

            Group {
                switch mode {
                case .actions:
                    BeneficiaryActionsPanel(
                        beneficiary: beneficiary,
                        modify: modify,
                        requestDelete: requestDelete,
                        toggleFavourite: toggleFavourite
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                case .deleteConfirmation:
                    BeneficiaryDeleteConfirmationPanel(
                        beneficiary: beneficiary,
                        cancel: dismiss,
                        confirm: confirmDelete
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAddTraits(.isModal)
    }
}

private struct BeneficiaryActionsPanel: View {
    let beneficiary: Beneficiary
    let modify: () -> Void
    let requestDelete: () -> Void
    let toggleFavourite: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: 0xE5E5E7))
                .frame(width: 54, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 12)

            BeneficiaryActionRow(
                kind: .edit,
                title: "Modify beneficiary",
                action: modify
            )
            BeneficiaryActionRow(
                kind: .delete,
                title: "Delete beneficiary",
                action: requestDelete
            )
            BeneficiaryActionRow(
                kind: .favourite(remove: beneficiary.isFavourite),
                title: beneficiary.isFavourite ? "Remove from favourite" : "Add to favourite",
                action: toggleFavourite
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 17)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
    }
}

private struct BeneficiaryActionRow: View {
    enum Kind { case edit, delete, favourite(remove: Bool) }
    let kind: Kind
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(MashreqTheme.orangeSoft)
                        .frame(width: 48, height: 48)
                    beneficiaryActionGlyph
                }

                Text(title)
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .regular))
                    .foregroundStyle(Color(hex: 0x171925))
                Spacer(minLength: 0)
            }
            .frame(height: 65)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var beneficiaryActionGlyph: some View {
        switch kind {
        case .edit:
            EditGlyph()
                .stroke(MashreqTheme.orangeDeep, lineWidth: 1.8)
                .frame(width: 24, height: 24)
        case .delete:
            TrashGlyph(color: MashreqTheme.orangeDeep)
                .frame(width: 24, height: 27)
        case .favourite(let remove):
            ZStack {
                StarGlyph().stroke(MashreqTheme.orangeDeep, lineWidth: 1.8)
                if remove {
                    Capsule().fill(MashreqTheme.orangeDeep).frame(width: 28, height: 1.8).rotationEffect(.degrees(-45))
                }
            }
            .frame(width: 27, height: 27)
        }
    }
}

private struct BeneficiaryDeleteConfirmationPanel: View {
    let beneficiary: Beneficiary
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WarningGlyph(color: Color(hex: 0xFFAE16))
                .frame(width: 58, height: 52)

            Text("Delete this beneficiary")
                .font(.mashreq(size: MashreqTextSize.displaySmall, weight: .bold))
                .padding(.top, 24)

            Text("Are you sure you want to delete the beneficiary \(beneficiary.displayName)?")
                .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .regular))
                .lineSpacing(7)
                .padding(.top, 25)

            Text("This action is permanent and cannot be undone.")
                .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .regular))
                .lineSpacing(7)
                .padding(.top, 19)

            (
                Text("Note: ").fontWeight(.bold)
                + Text("A cooling-off period applies for new beneficiaries. During this time, you can transfer up to AED 20,000 within first 4 hours.")
            )
            .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .regular))
            .lineSpacing(7)
            .padding(.top, 22)

            Spacer(minLength: 18)

            MashreqOutlineButton(title: "No", action: cancel)
            MashreqPrimaryButton(title: "Yes, proceed") { confirm() }
                .padding(.top, 12)
        }
        .padding(.horizontal, 31)
        .padding(.top, 38)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .frame(height: 636)
        .background(.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
    }
}

private struct TransferInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
            TextField(placeholder, text: $text)
                .font(.mashreq(size: MashreqTextSize.copy, weight: .regular))
                .keyboardType(keyboard)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(height: 64)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(MashreqTheme.secondaryInk.opacity(0.75), lineWidth: 1)
        }
    }
}

private struct BeneficiaryRow: View {
    let beneficiary: Beneficiary
    let onSelect: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    CountryBadge(country: beneficiary.country)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(beneficiary.displayName)
                                .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                            if beneficiary.isFavourite {
                                StarGlyph()
                                    .fill(MashreqTheme.orange)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        Text(beneficiary.formattedAccount)
                            .font(.mashreq(size: MashreqTextSize.copy, weight: .light))
                            .foregroundStyle(Color(hex: 0x62636D))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                if let availableAt = beneficiary.activationAvailableAt {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, Int(availableAt.timeIntervalSince(context.date)))
                        if remaining > 0 {
                            Text(coolingOffLabel(seconds: remaining))
                                .font(.mashreq(size: 10, weight: .medium))
                                .foregroundStyle(MashreqTheme.orangeDeep)
                                .monospacedDigit()
                                .fixedSize()
                                .accessibilityLabel("Cooling-off time remaining \(coolingOffLabel(seconds: remaining))")
                        }
                    }
                }

                Button(action: onMore) {
                    MoreGlyph(color: MashreqTheme.orangeDeep)
                        .frame(width: 8, height: 25)
                        .frame(width: 28, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Manage \(beneficiary.displayName)")
            }
        }
        .frame(minHeight: 78)
    }

    /// Формат 03:59:59 не прыгает по ширине и визуально остается возле меню.
    private func coolingOffLabel(seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

/// Локальные векторные иконки для flow; SF Symbols здесь не используются.
private struct ChevronGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

private struct DownChevronGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

private struct CheckmarkGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

private struct EditGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: CGRect(x: rect.minX, y: rect.minY + 5, width: rect.width - 6, height: rect.height - 5), cornerRadius: 2)
        path.move(to: CGPoint(x: rect.minX + 7, y: rect.maxY - 6))
        path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.minY + 2))
        path.move(to: CGPoint(x: rect.maxX - 5, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 6))
        return path
    }
}

private struct StarGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.44
        var path = Path()
        for index in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * CGFloat.pi / 5
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct MoreGlyph: View {
    let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Circle().fill(color)
            Circle().fill(color)
            Circle().fill(color)
        }
    }
}

private struct WarningGlyph: View {
    let color: Color
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 29, y: 0))
                path.addLine(to: CGPoint(x: 58, y: 52))
                path.addLine(to: CGPoint(x: 0, y: 52))
                path.closeSubpath()
            }
            .fill(color)
            VStack(spacing: 4) {
                Capsule().fill(.white).frame(width: 5, height: 20)
                Circle().fill(.white).frame(width: 5, height: 5)
            }
            .padding(.top, 13)
        }
    }
}

private struct PersonEmptyGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.midX - rect.width * 0.14, y: rect.minY + 4, width: rect.width * 0.28, height: rect.width * 0.28))
        path.addRoundedRect(
            in: CGRect(x: rect.minX + 7, y: rect.midY - 1, width: rect.width - 14, height: rect.height * 0.42),
            cornerSize: CGSize(width: 14, height: 14)
        )
        path.addEllipse(in: rect.insetBy(dx: 1, dy: 1))
        return path
    }
}

struct CountryBadge: View {
    let country: Country
    var body: some View {
        Group {
            if country == .uae {
                UAEFlagView(size: 47)
            } else {
                Circle().fill(MashreqTheme.orangeSoft).frame(width: 47, height: 47).overlay(Text(country == .usa ? "US" : country == .uk ? "UK" : "IN").font(.mashreq(size: 13, weight: .bold)).foregroundStyle(MashreqTheme.orange))
            }
        }
    }
}
