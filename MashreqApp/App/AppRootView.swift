import Observation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case pay = "Pay"
    case help = "Rewards"
    case more = "Services"

    var id: String { rawValue }

    func assetName(isActive: Bool) -> String {
        switch self {
        case .overview: isActive ? "OverviewNavOverviewActive" : "OverviewNavOverview"
        case .pay: isActive ? "OverviewNavPayActive" : "OverviewNavPay"
        case .help: isActive ? "OverviewNavRewardsActive" : "OverviewNavRewards"
        case .more: isActive ? "OverviewNavServicesActive" : "OverviewNavServices"
        }
    }
}

enum AppRoute: Hashable {
    case accounts
    case accountDetails
    case yourAccountDetails
    case eStatementRequest
    case cards
    case cardDetails
    case selectCreditCard
    case manageBeneficiaries
    case trackAndManage
    case confirmRecipient
    case recipientDetails
    case selectTransferBeneficiary
    case makePayment
    case purposeOfTransfer
    case additionalTransferDetails
    case reviewTransfer
    case transferOTP
    case addBeneficiary
    case beneficiarySecurityTip
    case reviewBeneficiary
    case beneficiaryOTP
    case beneficiarySuccess
    case transferringFrom
    case transferSuccess
    case transactionDetails(UUID)
    case settings
    case notifications
    case virtualAssistant
}

enum SupportMessageState {
    case unread
    case read
}

@MainActor
@Observable
final class AppSession {
    /// Один controller принадлежит root-session и используется всеми экранами.
    let loadingController = GlobalLoadingController()
    var isAuthenticated = false
    var selectedTab: AppTab = .overview
    var path: [AppRoute] = []
    // В эталонном Overview чат показан без индикатора; unread включается при новом сообщении.
    var supportMessageState: SupportMessageState = .read
    /// Текущий баланс и завершённые переводы принадлежат AppSession, поэтому
    /// Overview, Account details и Transactions обновляются одновременно.
    var accountBalance: Decimal = Decimal(string: "125.23") ?? 125.23
    var completedTransfers: [CompletedTransfer] = []
    var managedTransactions: [Transaction] = DemoData.transactions
    var bankingNotifications: [BankingNotification] = []
    var profile: UserProfile = .demo
    var beneficiaries: [Beneficiary] = []
    var beneficiaryDraft: BeneficiaryDraft = .empty
    /// Подтверждение Security tip живёт только внутри текущего add-flow.
    var hasTrustedBeneficiary = false
    var selectedBeneficiaryID: UUID?
    var transferDraft: TransferDraft = .empty(profile: .demo)
    /// Настройки перевода живут на уровне сессии, поэтому отдельные экраны
    /// Purpose и Additional details изменяют один общий черновик процесса.
    var transferSchedule: TransferSchedule = .immediately
    var transferFeePayer: TransferFeePayer = .sender
    var includesPaymentNote = false
    var lastCompletedTransferID: UUID?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        restoreAppState()
        synchronizeCurrentSender()

        // Аргумент QA позволяет запускать любой экран напрямую для точного сравнения.
        guard let marker = arguments.firstIndex(of: "--qa-screen"), arguments.indices.contains(marker + 1) else { return }
        isAuthenticated = true
        applyQAScreen(arguments[marker + 1])
    }

    var formattedAccountBalance: String {
        MoneyText.amount(accountBalance)
    }

    /// Новые списания отображаются первыми, затем идут исходные demo-операции.
    var transactions: [Transaction] {
        managedTransactions
    }

    var lastCompletedTransfer: CompletedTransfer? {
        guard let lastCompletedTransferID else { return completedTransfers.first }
        return completedTransfers.first { $0.id == lastCompletedTransferID }
    }

    var unreadBankingNotificationCount: Int {
        bankingNotifications.lazy.filter { !$0.isRead }.count
    }

    func completedTransfer(id: UUID) -> CompletedTransfer? {
        completedTransfers.first { $0.id == id }
    }

    var selectedBeneficiary: Beneficiary? {
        guard let selectedBeneficiaryID else { return nil }
        return beneficiaries.first { $0.id == selectedBeneficiaryID }
    }

    /// Очищает только незавершённую форму. Уже сохранённые beneficiaries и
    /// история переводов остаются без изменений.
    func startAddingBeneficiary() {
        beneficiaryDraft = .empty
        hasTrustedBeneficiary = false
    }

    /// Подготавливает общий add/edit-flow уже заполненными данными выбранного
    /// beneficiary. Экран редактирования не хранит собственную копию модели.
    func startEditingBeneficiary(_ beneficiary: Beneficiary) {
        beneficiaryDraft = BeneficiaryDraft(beneficiary: beneficiary)
        hasTrustedBeneficiary = true
    }

    /// Новый transfer-flow всегда начинает с выбора счёта и получателя, а не
    /// повторно использует незаметно beneficiary из предыдущей операции.
    func beginNewTransfer() {
        discardCurrentTransfer()
        navigate(to: .transferringFrom)
    }

    /// Удаляет только незавершённый перевод, не затрагивая историю.
    func discardCurrentTransfer() {
        selectedBeneficiaryID = nil
        transferDraft = .empty(profile: profile)
        transferSchedule = .immediately
        transferFeePayer = .sender
        includesPaymentNote = false
    }

    /// Создаёт или обновляет beneficiary по IBAN, сохраняет его и сразу
    /// подготавливает новый перевод с выбранным получателем.
    @discardableResult
    func saveCurrentBeneficiary() -> Beneficiary? {
        guard var beneficiary = beneficiaryDraft.beneficiary else { return nil }

        let existingIndex = beneficiaryDraft.editingBeneficiaryID.flatMap { editingID in
            beneficiaries.firstIndex { $0.id == editingID }
        } ?? beneficiaries.firstIndex(where: {
            UAEIBANService.normalize($0.account) == UAEIBANService.normalize(beneficiary.account)
        })
        let isNewBeneficiary = existingIndex == nil
        if let existingIndex {
            beneficiary = Beneficiary(
                id: beneficiaries[existingIndex].id,
                name: beneficiary.name,
                nickname: beneficiary.nickname,
                account: beneficiary.account,
                bank: beneficiary.bank,
                swiftCode: beneficiary.swiftCode,
                country: beneficiary.country,
                accountType: beneficiary.accountType,
                address: beneficiary.address,
                city: beneficiary.city,
                mobileNumber: beneficiary.mobileNumber,
                isFavourite: beneficiaries[existingIndex].isFavourite,
                activationAvailableAt: beneficiaries[existingIndex].activationAvailableAt
            )
            beneficiaries[existingIndex] = beneficiary
        } else {
            beneficiaries.insert(beneficiary, at: 0)
        }

        selectBeneficiary(beneficiary)
        hasTrustedBeneficiary = false
        if isNewBeneficiary {
            enqueueNotification(
                kind: .beneficiaryAdded,
                title: "Beneficiary added",
                message: "\(beneficiary.nickname) was added successfully. The beneficiary will be available for transfers after the 4-hour activation period."
            )
        }
        persistAppState()
        return beneficiary
    }

    /// Переключает избранное в единственном persisted-источнике.
    func toggleFavouriteBeneficiary(id: UUID) {
        guard let index = beneficiaries.firstIndex(where: { $0.id == id }) else { return }
        beneficiaries[index].isFavourite.toggle()
        persistAppState()
    }

    /// Удаляет beneficiary и очищает незавершённый перевод, если он ссылался
    /// именно на удалённую запись. Завершённые транзакции остаются снимками.
    func deleteBeneficiary(id: UUID) {
        guard beneficiaries.contains(where: { $0.id == id }) else { return }
        beneficiaries.removeAll { $0.id == id }

        if selectedBeneficiaryID == id {
            selectedBeneficiaryID = nil
            transferDraft = .empty(profile: profile)
        }
        if beneficiaryDraft.editingBeneficiaryID == id {
            beneficiaryDraft = .empty
        }
        persistAppState()
    }

    /// После сохранения изменений возвращает существующий Manage-экран без
    /// добавления его дубликата в NavigationStack.
    func returnToManageBeneficiaries() {
        loadingController.performNavigation { [weak self] in
            guard let self else { return }
            if let manageIndex = path.lastIndex(of: .manageBeneficiaries) {
                path = Array(path.prefix(through: manageIndex))
            } else {
                path.append(.manageBeneficiaries)
            }
        }
    }

    /// Выбранный beneficiary становится единственным источником данных для
    /// Payment details, Review, Success, history, details и PDF.
    func selectBeneficiary(_ beneficiary: Beneficiary) {
        selectedBeneficiaryID = beneficiary.id
        transferDraft = TransferDraft(
            senderName: profile.fullName,
            senderAccountName: "NEO Current Account",
            senderAccountNumber: profile.accountNumber,
            remitterBank: "MashreqBank PSC., Dubai, UAE",
            beneficiaryName: beneficiary.name,
            beneficiaryBank: beneficiary.bank,
            beneficiaryBankCountry: beneficiary.country.rawValue,
            beneficiarySwiftCode: beneficiary.swiftCode,
            beneficiaryIBAN: UAEIBANService.normalize(beneficiary.account),
            amount: 0,
            purposeOfPayment: "",
            transferType: "Local",
            exchangeRate: "Not Applicable",
            fxDeal: "Not Applied",
            intermediaryBank: "N/A",
            noteToBeneficiary: ""
        )
        transferSchedule = .immediately
        transferFeePayer = .sender
        includesPaymentNote = false
    }

    /// Вызывается ровно один раз после корректного OTP. Повторное появление
    /// success-экрана не создаёт дубль и не списывает баланс повторно.
    @discardableResult
    func completeCurrentTransfer() -> CompletedTransfer? {
        if let existing = completedTransfers.first(where: { $0.draftID == transferDraft.id }) {
            lastCompletedTransferID = existing.id
            return existing
        }

        guard transferDraft.amount > 0, transferDraft.amount <= accountBalance else {
            return nil
        }

        let transfer = CompletedTransfer(
            draft: transferDraft,
            reference: Self.makeReference()
        )
        accountBalance -= transfer.amount
        completedTransfers.insert(transfer, at: 0)
        managedTransactions.insert(transfer.transaction, at: 0)
        lastCompletedTransferID = transfer.id
        enqueueNotification(
            kind: .transferCompleted,
            title: "Transfer completed",
            message: "AED \(MoneyText.amount(transfer.amount)) was transferred to \(transfer.beneficiaryName). Reference: \(transfer.reference)."
        )
        persistAppState()
        return transfer
    }

    /// Сохраняет профиль, контакты и реквизиты текущего счёта одним действием.
    /// Исторические переводы не переписываются: их реквизиты остаются снимком
    /// состояния на момент операции.
    func saveProfile(_ newProfile: UserProfile, balance: Decimal) {
        profile = newProfile
        profile.iban = Self.normalizedIBAN(newProfile.iban)
        profile.accountNumber = newProfile.accountNumber.filter(\.isNumber)
        accountBalance = max(0, balance)
        synchronizeCurrentSender()
        persistAppState()
    }

    /// Добавляет ручную операцию и при необходимости сразу отражает её на
    /// балансе. Возвращает false, если списание сделало бы баланс отрицательным.
    @discardableResult
    func addTransaction(_ input: ManagedTransactionInput) -> Bool {
        let transaction = Transaction(input: input)
        if input.adjustsBalance {
            guard canApplyBalanceDelta(transaction.signedAmount) else { return false }
            accountBalance += transaction.signedAmount
        }
        managedTransactions.insert(transaction, at: 0)
        enqueueTransactionNotification(for: transaction)
        persistAppState()
        return true
    }

    /// Редактирует reference/type/amount и текст операции. Для перевода также
    /// синхронизирует reference и сумму с Payment details и PDF-квитанцией.
    @discardableResult
    func updateTransaction(id: UUID, input: ManagedTransactionInput) -> Bool {
        guard let index = managedTransactions.firstIndex(where: { $0.id == id }) else { return false }
        let previous = managedTransactions[index]
        var updated = Transaction(
            id: previous.id,
            input: input,
            transferID: previous.transferID,
            relatedTransactionID: previous.relatedTransactionID,
            createdAt: previous.createdAt
        )
        updated.isRefunded = previous.isRefunded

        if input.adjustsBalance {
            let delta = updated.signedAmount - previous.signedAmount
            guard canApplyBalanceDelta(delta) else { return false }
            accountBalance += delta
        }

        managedTransactions[index] = updated
        if let transferID = updated.transferID,
           let transferIndex = completedTransfers.firstIndex(where: { $0.id == transferID }) {
            completedTransfers[transferIndex].reference = updated.reference
            completedTransfers[transferIndex].amount = updated.amountValue
        }
        persistAppState()
        return true
    }

    /// Возврат не стирает исходное списание: создаётся отдельная credit-запись,
    /// исходная операция помечается возвращённой, баланс увеличивается.
    @discardableResult
    func refundTransaction(id: UUID) -> Bool {
        guard
            let index = managedTransactions.firstIndex(where: { $0.id == id }),
            managedTransactions[index].direction == .debit,
            !managedTransactions[index].isRefunded
        else { return false }

        let source = managedTransactions[index]
        let refundInput = ManagedTransactionInput(
            reference: Self.makeManualReference(prefix: "RFD"),
            category: .refund,
            direction: .credit,
            amount: source.amountValue,
            merchant: source.merchant,
            location: "REFUND OF \(source.reference)",
            isProcessing: false,
            adjustsBalance: true
        )
        let refund = Transaction(input: refundInput, relatedTransactionID: source.id)

        managedTransactions[index].isRefunded = true
        managedTransactions.insert(refund, at: 0)
        accountBalance += source.amountValue
        enqueueTransactionNotification(for: refund)
        persistAppState()
        return true
    }

    /// Удаляет только запись из истории без неявного пересчёта баланса.
    /// Признак выполненного возврата сохраняется, чтобы удаление refund-строки
    /// не позволило повторно зачислить ту же сумму.
    func deleteTransaction(id: UUID) {
        guard let transaction = managedTransactions.first(where: { $0.id == id }) else { return }

        managedTransactions.removeAll { $0.id == id }
        if let transferID = transaction.transferID {
            completedTransfers.removeAll { $0.id == transferID }
            if lastCompletedTransferID == transferID {
                lastCompletedTransferID = completedTransfers.first?.id
            }
        }
        persistAppState()
    }

    /// Новый draft получает новый id, поэтому повторный перевод будет новой
    /// операцией, но сохранит выбранного получателя и назначение платежа.
    func prepareRepeatTransfer(from transfer: CompletedTransfer) {
        if let beneficiary = beneficiaries.first(where: {
            UAEIBANService.normalize($0.account) == UAEIBANService.normalize(transfer.beneficiaryIBAN)
        }) {
            selectedBeneficiaryID = beneficiary.id
        }
        transferDraft = TransferDraft(
            senderName: transfer.senderName,
            senderAccountName: transfer.senderAccountName,
            senderAccountNumber: transfer.senderAccountNumber,
            remitterBank: transfer.remitterBank,
            beneficiaryName: transfer.beneficiaryName,
            beneficiaryBank: transfer.beneficiaryBank,
            beneficiaryBankCountry: transfer.beneficiaryBankCountry,
            beneficiarySwiftCode: transfer.beneficiarySwiftCode,
            beneficiaryIBAN: transfer.beneficiaryIBAN,
            amount: transfer.amount,
            purposeOfPayment: transfer.purposeOfPayment,
            transferType: transfer.transferType,
            exchangeRate: transfer.exchangeRate,
            fxDeal: transfer.fxDeal,
            intermediaryBank: transfer.intermediaryBank,
            noteToBeneficiary: transfer.noteToBeneficiary
        )
        loadingController.performNavigation { [weak self] in
            self?.selectedTab = .pay
            self?.path = [.transferringFrom]
        }
    }

    /// Все пользовательские переходы между root-tabs используют тот же global loader.
    func selectTab(_ tab: AppTab) {
        guard tab != selectedTab else { return }
        loadingController.performNavigation { [weak self] in
            withAnimation(.easeOut(duration: 1.30)) {
                self?.selectedTab = tab
            }
        }
    }

    func returnToOverview() {
        loadingController.performNavigation { [weak self] in
            self?.selectedTab = .overview
            self?.path.removeAll()
        }
    }

    func signIn() {
        loadingController.performNavigation { [weak self] in
            guard let self else { return }
            withAnimation(.easeOut(duration: 1.30)) {
                self.isAuthenticated = true
                self.selectedTab = .overview
            }
        }
    }

    func signOut() {
        path.removeAll()
        selectedTab = .overview
        supportMessageState = .read
        isAuthenticated = false
    }

    func markSupportMessageUnread() {
        supportMessageState = .unread
    }

    func markSupportMessageRead() {
        supportMessageState = .read
    }

    func navigate(to route: AppRoute) {
        loadingController.performNavigation { [weak self] in
            self?.path.append(route)
        }
    }

    private func applyQAScreen(_ name: String) {
        switch name {
        case "login": isAuthenticated = false
        case "overview": selectedTab = .overview
        case "accounts": path = [.accounts]
        case "account-detail": path = [.accountDetails]
        case "your-account-details": path = [.yourAccountDetails]
        case "e-statement": path = [.eStatementRequest]
        case "cards": path = [.cards]
        case "card-detail": path = [.cardDetails]
        case "select-card": path = [.selectCreditCard]
        case "pay": selectedTab = .pay
        case "beneficiaries":
            ensureQABeneficiaryDraft()
            path = [.manageBeneficiaries]
        case "track-and-manage":
            _ = ensureQATransfer()
            path = [.trackAndManage]
        case "confirm-recipient":
            ensureQABeneficiaryDraft()
            path = [.confirmRecipient]
        case "recipient-details": path = [.recipientDetails]
        case "select-transfer-beneficiary":
            ensureQABeneficiaryDraft()
            path = [.selectTransferBeneficiary]
        case "make-payment":
            ensureQABeneficiaryDraft()
            path = [.makePayment]
        case "purpose-of-transfer":
            ensureQABeneficiaryDraft()
            path = [.purposeOfTransfer]
        case "additional-transfer-details":
            ensureQABeneficiaryDraft()
            path = [.additionalTransferDetails]
        case "review-transfer":
            ensureQABeneficiaryDraft()
            path = [.reviewTransfer]
        case "transfer-otp":
            ensureQABeneficiaryDraft()
            path = [.transferOTP]
        case "add-beneficiary": path = [.addBeneficiary]
        case "add-beneficiary-bank":
            ensureQABeneficiaryDraft()
            path = [.addBeneficiary]
        case "add-beneficiary-personal":
            ensureQABeneficiaryDraft()
            hasTrustedBeneficiary = true
            path = [.addBeneficiary]
        case "beneficiary-security-tip":
            ensureQABeneficiaryDraft()
            path = [.beneficiarySecurityTip]
        case "review-beneficiary":
            ensureQABeneficiaryDraft()
            path = [.reviewBeneficiary]
        case "beneficiary-otp":
            ensureQABeneficiaryDraft()
            path = [.beneficiaryOTP]
        case "beneficiary-success":
            ensureQABeneficiaryDraft()
            path = [.beneficiarySuccess]
        case "transferring-from": path = [.transferringFrom]
        case "transfer-success":
            _ = ensureQATransfer()
            path = [.transferSuccess]
        case "transaction-details":
            let transfer = ensureQATransfer()
            path = [.transactionDetails(transfer.id)]
        case "settings": path = [.settings]
        case "notifications": path = [.notifications]
        case "help": selectedTab = .help
        case "chat": path = [.virtualAssistant]
        case "more": selectedTab = .more
        default: selectedTab = .overview
        }
    }

    private func ensureQATransfer() -> CompletedTransfer {
        if transferDraft.beneficiaryName.isEmpty {
            transferDraft = .demo
            synchronizeCurrentSender()
        }
        if let transfer = lastCompletedTransfer {
            return transfer
        }

        let transfer = CompletedTransfer(
            draft: transferDraft,
            reference: "MLC2811251839993",
            createdAt: Date()
        )
        completedTransfers = [transfer]
        if !managedTransactions.contains(where: { $0.id == transfer.id }) {
            managedTransactions.insert(transfer.transaction, at: 0)
        }
        lastCompletedTransferID = transfer.id
        return transfer
    }

    /// Данные только для прямых QA-запусков. Обычный пользовательский flow
    /// всегда получает эти значения из формы и сохранённого beneficiary.
    private func ensureQABeneficiaryDraft() {
        guard beneficiaryDraft.fullName.isEmpty else { return }

        let sample = TransferDraft.demo
        beneficiaryDraft.country = .uae
        beneficiaryDraft.iban = "AE560260001015840517601"
        beneficiaryDraft.bankName = "EMIRATES NBD BANK PJSC"
        beneficiaryDraft.swiftCode = "EBILAEAD"
        beneficiaryDraft.accountType = "INDIVIDUAL"
        beneficiaryDraft.fullName = sample.beneficiaryName
        beneficiaryDraft.nickname = sample.beneficiaryName
        beneficiaryDraft.address = "Dubai, UAE"
        beneficiaryDraft.mobileNumber = "+971 50 000 0000"

        if let beneficiary = beneficiaryDraft.beneficiary {
            if !beneficiaries.contains(where: { $0.account == beneficiary.account }) {
                beneficiaries.insert(beneficiary, at: 0)
            }
            if let stored = beneficiaries.first(where: { $0.account == beneficiary.account }) {
                selectBeneficiary(stored)
            }
        }

        transferDraft.amount = sample.amount
        transferDraft.purposeOfPayment = sample.purposeOfPayment
        transferDraft.noteToBeneficiary = sample.noteToBeneficiary
    }

    private func restoreAppState() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.transferStorageKey),
            let snapshot = try? JSONDecoder().decode(AppStateSnapshot.self, from: data)
        else { return }

        accountBalance = snapshot.accountBalance
        completedTransfers = snapshot.completedTransfers
        profile = snapshot.profile ?? .demo
        let storedTransactions = snapshot.managedTransactions ?? DemoData.transactions
        var storedByTransferID: [UUID: Transaction] = [:]
        for transaction in storedTransactions {
            if let transferID = transaction.transferID {
                storedByTransferID[transferID] = transaction
            }
        }
        let refreshedTransfers = completedTransfers.map { transfer in
            var transaction = transfer.transaction
            transaction.isRefunded = storedByTransferID[transfer.id]?.isRefunded ?? false
            return transaction
        }
        let completedIDs = Set(completedTransfers.map(\.id))
        let transactionsWithoutCompletedSnapshot = storedTransactions.filter { transaction in
            guard let transferID = transaction.transferID else { return true }
            return !completedIDs.contains(transferID)
        }
        managedTransactions = refreshedTransfers + transactionsWithoutCompletedSnapshot
        beneficiaries = snapshot.beneficiaries ?? []
        bankingNotifications = snapshot.bankingNotifications ?? []
        selectedBeneficiaryID = snapshot.selectedBeneficiaryID
        lastCompletedTransferID = completedTransfers.first?.id
    }

    private func persistAppState() {
        let snapshot = AppStateSnapshot(
            accountBalance: accountBalance,
            completedTransfers: completedTransfers,
            managedTransactions: managedTransactions,
            profile: profile,
            beneficiaries: beneficiaries,
            bankingNotifications: bankingNotifications,
            selectedBeneficiaryID: selectedBeneficiaryID
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.transferStorageKey)
    }

    private func synchronizeCurrentSender() {
        transferDraft.senderName = profile.fullName
        transferDraft.senderAccountNumber = profile.accountNumber
    }

    private func canApplyBalanceDelta(_ delta: Decimal) -> Bool {
        accountBalance + delta >= 0
    }

    /// Отмечает центр уведомлений прочитанным при открытии, но не удаляет
    /// историю банковских событий.
    func markBankingNotificationsRead() {
        var didChange = false
        for index in bankingNotifications.indices where !bankingNotifications[index].isRead {
            bankingNotifications[index].isRead = true
            didChange = true
        }
        if didChange { persistAppState() }
    }

    private func enqueueTransactionNotification(for transaction: Transaction) {
        let ending = String(profile.accountNumber.suffix(4))
        if transaction.direction == .credit {
            let isTopUp = transaction.category == .topUp
            enqueueNotification(
                kind: .credit,
                title: isTopUp ? "Account topped up" : "Credit received",
                message: "AED \(MoneyText.amount(transaction.amountValue)) was credited to account ending \(ending). Reference: \(transaction.reference)."
            )
        } else {
            enqueueNotification(
                kind: .debit,
                title: "Account debited",
                message: "AED \(MoneyText.amount(transaction.amountValue)) was debited from account ending \(ending). Reference: \(transaction.reference)."
            )
        }
    }

    private func enqueueNotification(
        kind: BankingNotificationKind,
        title: String,
        message: String
    ) {
        bankingNotifications.insert(
            BankingNotification(kind: kind, title: title, message: message),
            at: 0
        )
    }

    private static func normalizedIBAN(_ value: String) -> String {
        value.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func makeManualReference(prefix: String, date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "ddMMyyHHmmss"
        return prefix + formatter.string(from: date)
    }

    private static func makeReference(date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // 3 + 10 + 3 = 16 знаков, как в референсном MLC-номере.
        formatter.dateFormat = "ddMMyyHHmm"
        let suffix = String(format: "%03d", Int.random(in: 0...999))
        return "MLC\(formatter.string(from: date))\(suffix)"
    }

    private static let transferStorageKey = "mashreq.completed-transfer-state.v1"
}

private struct AppStateSnapshot: Codable {
    let accountBalance: Decimal
    let completedTransfers: [CompletedTransfer]
    let managedTransactions: [Transaction]?
    let profile: UserProfile?
    let beneficiaries: [Beneficiary]?
    let bankingNotifications: [BankingNotification]?
    let selectedBeneficiaryID: UUID?
}

struct AppRootView: View {
    @Bindable var session: AppSession
    var canRegister = true
    var onRegister: () -> Void = {}

    var body: some View {
        ZStack {
            Group {
                if session.isAuthenticated {
                    NavigationStack(path: $session.path) {
                        RootTabView(session: session)
                            .onAppear {
                                session.loadingController.destinationDidAppear()
                            }
                            .navigationDestination(for: AppRoute.self, destination: destination)
                    }
                } else {
                    LoginView(
                        onSignIn: { session.signIn() },
                        showsRegistration: canRegister,
                        onRegister: onRegister
                    )
                }
            }

            if session.loadingController.isPresented {
                GlobalLoadingOverlay()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: session.loadingController.isPresented)
        .environment(session)
        .environment(session.loadingController)
#if DEBUG
        .task {
            if ProcessInfo.processInfo.arguments.contains("--qa-loading-overlay") {
                session.loadingController.presentForQualityAssurance()
            }
        }
#endif
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        Group {
            switch route {
            case .accounts: AccountsListView()
            case .accountDetails: AccountDetailsView()
            case .yourAccountDetails: YourAccountDetailsView()
            case .eStatementRequest: EStatementRequestView()
            case .cards: CardsListView()
            case .cardDetails: CardDetailsView()
            case .selectCreditCard: SelectCreditCardView()
            case .manageBeneficiaries: ManageBeneficiariesView()
            case .trackAndManage: TrackAndManageView()
            case .confirmRecipient: ConfirmRecipientView()
            case .recipientDetails: RecipientDetailsView()
            case .selectTransferBeneficiary: TransferBeneficiaryPickerView()
            case .makePayment: MakePaymentView()
            case .purposeOfTransfer: PurposeOfTransferView()
            case .additionalTransferDetails: AdditionalTransferDetailsView()
            case .reviewTransfer: ReviewTransferView()
            case .transferOTP: TransferOTPView()
            case .addBeneficiary: AddBeneficiaryView()
            case .beneficiarySecurityTip: BeneficiarySecurityTipView()
            case .reviewBeneficiary: ReviewBeneficiaryView()
            case .beneficiaryOTP: BeneficiaryAuthenticationView()
            case .beneficiarySuccess: BeneficiarySuccessView()
            case .transferringFrom: TransferringFromView()
            case .transferSuccess: TransferSuccessView()
            case .transactionDetails(let id): TransactionDetailsView(transferID: id)
            case .settings: SettingsView(onRegister: onRegister)
            case .notifications: NotificationsView()
            case .virtualAssistant: VirtualAssistantView()
            }
        }
        .onAppear {
            session.loadingController.destinationDidAppear()
        }
    }
}

struct RootTabView: View {
    @Bindable var session: AppSession

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch session.selectedTab {
                case .overview: OverviewView()
                case .pay: PayAndTransferView()
                case .help: HelpView()
                case .more: MoreView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MashreqBottomBar(
                selection: Binding(
                    get: { session.selectedTab },
                    set: { session.selectTab($0) }
                )
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: session.selectedTab) { _, _ in
            // Tab destination уже заменён SwiftUI; теперь можно завершить loader.
            session.loadingController.destinationDidAppear()
        }
    }
}
