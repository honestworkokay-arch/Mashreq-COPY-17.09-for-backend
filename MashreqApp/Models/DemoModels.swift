import Foundation
import UIKit

struct Account: Identifiable, Hashable {
    let id: UUID
    let name: String
    let number: String
    let balance: String

    init(id: UUID = UUID(), name: String, number: String, balance: String) {
        self.id = id
        self.name = name
        self.number = number
        self.balance = balance
    }
}

enum TransactionDirection: String, Codable, CaseIterable, Identifiable {
    case debit = "Debit"
    case credit = "Credit"

    var id: String { rawValue }
}

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case fundTransfer = "Fund transfer"
    case cardPurchase = "Card purchase"
    case accountTransfer = "Account transfer"
    case topUp = "Top up"
    case refund = "Refund"
    case cashWithdrawal = "Cash withdrawal"
    case other = "Other"

    var id: String { rawValue }

    var defaultDirection: TransactionDirection {
        switch self {
        case .topUp, .refund:
            .credit
        default:
            .debit
        }
    }

    var statementTitle: String {
        switch self {
        case .cardPurchase: "Visa Purchase"
        case .accountTransfer: "Acct to Acct transfer"
        default: rawValue
        }
    }
}

/// Унифицированная редактируемая операция. `amountValue` всегда положительный,
/// а направление отдельно определяет списание или зачисление.
struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    var reference: String
    var title: String
    var merchant: String
    var location: String
    var amountValue: Decimal
    var direction: TransactionDirection
    var category: TransactionCategory
    var isProcessing: Bool
    /// Заполнено только у переводов, для которых доступен экран деталей.
    let transferID: UUID?
    /// Для возврата хранит ID исходного списания.
    let relatedTransactionID: UUID?
    var isRefunded: Bool
    let createdAt: Date

    var amount: String {
        let sign = direction == .debit ? "-" : "+"
        return "\(sign) AED \(MoneyText.amount(amountValue))"
    }

    var signedAmount: Decimal {
        direction == .debit ? -amountValue : amountValue
    }

    init(
        id: UUID = UUID(),
        reference: String,
        title: String = "Visa Purchase",
        merchant: String,
        location: String = "Dubai  AE",
        amount: String,
        isProcessing: Bool = true,
        transferID: UUID? = nil,
        category: TransactionCategory = .cardPurchase,
        direction: TransactionDirection? = nil,
        relatedTransactionID: UUID? = nil,
        isRefunded: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.reference = reference
        self.title = title
        self.merchant = merchant
        self.location = location
        amountValue = Self.parseAmount(amount)
        self.direction = direction ?? (amount.contains("-") ? .debit : .credit)
        self.category = category
        self.isProcessing = isProcessing
        self.transferID = transferID
        self.relatedTransactionID = relatedTransactionID
        self.isRefunded = isRefunded
        self.createdAt = createdAt
    }

    init(
        id: UUID = UUID(),
        input: ManagedTransactionInput,
        transferID: UUID? = nil,
        relatedTransactionID: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        reference = input.reference
        title = input.category.statementTitle
        merchant = input.merchant
        location = input.location
        amountValue = input.amount
        direction = input.direction
        category = input.category
        isProcessing = input.isProcessing
        self.transferID = transferID
        self.relatedTransactionID = relatedTransactionID
        isRefunded = false
        self.createdAt = createdAt
    }

    private static func parseAmount(_ value: String) -> Decimal {
        let normalized = value
            .replacingOccurrences(of: ",", with: "")
            .filter { $0.isNumber || $0 == "." }
        return Decimal(string: normalized) ?? 0
    }
}

struct ManagedTransactionInput: Hashable {
    var reference: String
    var category: TransactionCategory
    var direction: TransactionDirection
    var amount: Decimal
    var merchant: String
    var location: String
    var isProcessing: Bool
    var adjustsBalance: Bool
}

/// События банковского журнала уведомлений. Они сохраняются вместе с
/// транзакциями и используются как единый текст для in-app карточки и
/// системного Messages-composer.
struct BankingNotification: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: BankingNotificationKind
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        kind: BankingNotificationKind,
        title: String,
        message: String,
        createdAt: Date = .now,
        isRead: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

enum BankingNotificationKind: String, Codable, Hashable {
    case beneficiaryAdded
    case transferCompleted
    case debit
    case credit

    var shortCode: String {
        switch self {
        case .beneficiaryAdded: "BN"
        case .transferCompleted: "TR"
        case .debit: "DR"
        case .credit: "CR"
        }
    }
}

struct UserProfile: Codable, Hashable {
    var firstName: String
    var lastName: String
    var iban: String
    var accountNumber: String
    var email: String
    var smsPhoneNumber: String
    /// Дополнительные атрибуты счёта опциональны, чтобы старые сохранённые
    /// профили продолжали декодироваться без миграции UserDefaults.
    var accountDetails: UserAccountDetails? = nil

    var fullName: String {
        "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initials: String {
        let parts = [firstName, lastName]
        return parts.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    var maskedSMSPhone: String {
        let digits = smsPhoneNumber.filter(\.isNumber)
        return "xxxxx\(digits.suffix(3))"
    }

    static let demo = UserProfile(
        firstName: "Abdulkadir",
        lastName: "Mursal",
        iban: "AE880330000019101845015",
        accountNumber: "019101845015",
        email: "demo@example.com",
        smsPhoneNumber: "+971 50 000 0679",
        accountDetails: UserAccountDetails(
            nickname: "ABDULKADIR",
            accountType: "Current",
            currency: "AED",
            status: "Active",
            openingDate: Calendar.current.date(from: DateComponents(year: 2023, month: 4, day: 17)),
            relationship: "Single"
        )
    )
}

/// Данные для экрана Your Account Details. Номер счёта и IBAN намеренно
/// остаются в UserProfile как в единственном источнике реквизитов.
struct UserAccountDetails: Codable, Hashable {
    var nickname: String
    var accountType: String
    var currency: String
    var status: String
    var openingDate: Date?
    var relationship: String
}

/// Значения вынесены из View, чтобы экраны формы и review использовали один
/// набор банковских назначений без расхождений и строкового дублирования.
enum TransferPurpose: String, CaseIterable, Identifiable {
    case charitableContributions = "Charitable Contributions"
    case creditCardPayment = "Credit Card Payment"
    case crossBorderPayments = "Cross Border Payments"
    case educationalSupport = "Educational Support"
    case familyExpenses = "Family Expenses"
    case familySupport = "Family Support"
    case loanCharges = "Loan charges"
    case medicalClaimReimbursements = "Medical Claim Reimbursements"
    case monthlyInstallments = "Monthly Installments"
    case ownAccountTransfer = "Own Account Transfer"
    case posMerchantSettlements = "POS Merchant Settlements"
    case pension = "Pension"

    var id: String { rawValue }
}

enum TransferSchedule: String, CaseIterable, Identifiable {
    case immediately = "Immediately"
    case scheduled = "Schedule for later"

    var id: String { rawValue }
}

enum TransferFeePayer: String, CaseIterable, Identifiable {
    case sender = "Sender"
    case shared = "Sender & Receiver"
    case receiver = "Receiver"

    var id: String { rawValue }
}

/// Данные текущего перевода. Экраны review/OTP/success не хранят собственные
/// копии имени, IBAN или суммы — они читают один и тот же draft из AppSession.
struct TransferDraft: Hashable {
    var id = UUID()
    var senderName: String
    var senderAccountName: String
    var senderAccountNumber: String
    var remitterBank: String
    var beneficiaryName: String
    var beneficiaryBank: String
    var beneficiaryBankCountry: String
    var beneficiarySwiftCode: String
    var beneficiaryIBAN: String
    var amount: Decimal
    var purposeOfPayment: String
    var transferType: String
    var exchangeRate: String
    var fxDeal: String
    var intermediaryBank: String
    var noteToBeneficiary: String

    /// Начальные данные принадлежат модели демонстрационного сценария.
    /// После подключения полей ввода они меняются в AppSession, а детали и PDF
    /// автоматически получают актуальные значения без правок в своих View.
    static let demo = TransferDraft(
        senderName: "CU",
        senderAccountName: "NEO Current Account",
        senderAccountNumber: "019101845015",
        remitterBank: "MashreqBank PSC., Dubai, UAE",
        beneficiaryName: "Kozar Elena",
        beneficiaryBank: "AL MARYAH COMMUNITY BANK",
        beneficiaryBankCountry: "UNITED ARAB EMIRATES",
        beneficiarySwiftCode: "E097AEXX",
        beneficiaryIBAN: "AE720970000006523526388",
        amount: Decimal(string: "25.00") ?? 25,
        purposeOfPayment: "Family Support",
        transferType: "Local",
        exchangeRate: "Not Applicable",
        fxDeal: "Not Applied",
        intermediaryBank: "N/A",
        noteToBeneficiary: "N/A"
    )

    /// Чистый draft создаётся перед каждым новым переводом. Данные получателя
    /// заполняются только после выбора сохранённого beneficiary.
    static func empty(profile: UserProfile) -> TransferDraft {
        TransferDraft(
            senderName: profile.fullName,
            senderAccountName: "NEO Current Account",
            senderAccountNumber: profile.accountNumber,
            remitterBank: "MashreqBank PSC., Dubai, UAE",
            beneficiaryName: "",
            beneficiaryBank: "",
            beneficiaryBankCountry: Country.uae.rawValue,
            beneficiarySwiftCode: "",
            beneficiaryIBAN: "",
            amount: 0,
            purposeOfPayment: "",
            transferType: "Local",
            exchangeRate: "Not Applicable",
            fxDeal: "Not Applied",
            intermediaryBank: "N/A",
            noteToBeneficiary: ""
        )
    }
}

/// Зафиксированный снимок завершённого перевода. Он является источником
/// истины для строки истории, деталей операции и электронной квитанции.
struct CompletedTransfer: Identifiable, Codable, Hashable {
    let id: UUID
    let draftID: UUID
    var reference: String
    let createdAt: Date
    let senderName: String
    let senderAccountName: String
    let senderAccountNumber: String
    let remitterBank: String
    let beneficiaryName: String
    let beneficiaryBank: String
    let beneficiaryBankCountry: String
    let beneficiarySwiftCode: String
    let beneficiaryIBAN: String
    var amount: Decimal
    let purposeOfPayment: String
    let transferType: String
    let exchangeRate: String
    let fxDeal: String
    let intermediaryBank: String
    let noteToBeneficiary: String

    var formattedAmount: String {
        MoneyText.amount(amount)
    }

    var detailDate: String {
        Self.detailDateFormatter.string(from: createdAt)
    }

    var maskedSenderAccount: String {
        Self.masked(senderAccountNumber, visibleSuffix: 3)
    }

    var maskedBeneficiaryAccount: String {
        Self.masked(beneficiaryIBAN, visibleSuffix: 3)
    }

    var transaction: Transaction {
        // Полное банковское описание строится из фактических данных перевода,
        // поэтому история не содержит хардкод конкретного получателя.
        let transactionToken = "T_\(id.uuidString.replacingOccurrences(of: "-", with: "").uppercased())"
        let transferDescription = "\(beneficiaryIBAN) - \(beneficiaryName.uppercased()) -/REF/\(purposeOfPayment.uppercased()) - \(transactionToken)"

        return Transaction(
            id: id,
            reference: reference,
            title: "Fund transfer",
            merchant: transferDescription,
            location: "FUND TRANSFER-MOBILE BANKING",
            amount: "- AED \(formattedAmount)",
            isProcessing: false,
            transferID: id,
            category: .fundTransfer,
            direction: .debit,
            createdAt: createdAt
        )
    }

    init(draft: TransferDraft, reference: String, createdAt: Date = .now) {
        id = UUID()
        draftID = draft.id
        self.reference = reference
        self.createdAt = createdAt
        senderName = draft.senderName
        senderAccountName = draft.senderAccountName
        senderAccountNumber = draft.senderAccountNumber
        remitterBank = draft.remitterBank
        beneficiaryName = draft.beneficiaryName
        beneficiaryBank = draft.beneficiaryBank
        beneficiaryBankCountry = draft.beneficiaryBankCountry
        beneficiarySwiftCode = draft.beneficiarySwiftCode
        beneficiaryIBAN = draft.beneficiaryIBAN
        amount = draft.amount
        purposeOfPayment = draft.purposeOfPayment
        transferType = draft.transferType
        exchangeRate = draft.exchangeRate
        fxDeal = draft.fxDeal
        intermediaryBank = draft.intermediaryBank
        noteToBeneficiary = draft.noteToBeneficiary
    }

    private static func masked(_ value: String, visibleSuffix: Int) -> String {
        let normalized = value.filter { $0.isLetter || $0.isNumber }
        let suffix = normalized.suffix(visibleSuffix)
        let hiddenCount = max(4, normalized.count - suffix.count)
        return String(repeating: "X", count: hiddenCount) + suffix
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
}

/// Единое форматирование сумм для всех экранов и PDF.
enum MoneyText {
    static func amount(_ value: Decimal) -> String {
        formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0.00"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()
}

/// Сохранённый получатель. Все поля кодируются в UserDefaults вместе с
/// переводами, поэтому после перезапуска приложения beneficiary не исчезает.
struct Beneficiary: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var nickname: String
    var account: String
    var bank: String
    var swiftCode: String
    var country: Country
    var accountType: String
    var address: String
    var city: String?
    var mobileNumber: String
    var isFavourite: Bool
    /// До этой даты действует четырехчасовой cooling-off период.
    /// Optional сохраняет совместимость с уже записанными UserDefaults.
    var activationAvailableAt: Date?

    var maskedAccount: String {
        let normalized = account.filter { $0.isLetter || $0.isNumber }
        return "***\(normalized.suffix(4))"
    }

    /// В списке Mashreq приоритет имеет nickname (например, "My Wife"),
    /// а полное имя используется, когда nickname не указан.
    var displayName: String {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNickname.isEmpty ? name : trimmedNickname
    }

    /// IBAN отображается печатными группами по четыре символа. Телефонные и
    /// прочие цифровые идентификаторы сохраняют исходное представление.
    var formattedAccount: String {
        let normalized = account.uppercased().filter { $0.isLetter || $0.isNumber }
        guard normalized.contains(where: \.isLetter) else { return account }

        return stride(from: 0, to: normalized.count, by: 4)
            .map { start in
                let startIndex = normalized.index(normalized.startIndex, offsetBy: start)
                let endIndex = normalized.index(startIndex, offsetBy: min(4, normalized.count - start))
                return String(normalized[startIndex..<endIndex])
            }
            .joined(separator: " ")
    }

    init(
        id: UUID = UUID(),
        name: String,
        nickname: String = "",
        account: String,
        bank: String,
        swiftCode: String = "",
        country: Country,
        accountType: String = "INDIVIDUAL",
        address: String = "",
        city: String? = nil,
        mobileNumber: String = "",
        isFavourite: Bool = false,
        activationAvailableAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.account = account
        self.bank = bank
        self.swiftCode = swiftCode
        self.country = country
        self.accountType = accountType
        self.address = address
        self.city = city
        self.mobileNumber = mobileNumber
        self.isFavourite = isFavourite
        self.activationAvailableAt = activationAvailableAt
    }
}

/// Редактируемые поля сценария добавления beneficiary. Это отдельный draft,
/// чтобы незавершённая форма не загрязняла текущий перевод.
struct BeneficiaryDraft: Hashable {
    /// Наличие id означает режим изменения существующего beneficiary.
    /// Благодаря этому изменение IBAN обновляет запись, а не создаёт дубль.
    var editingBeneficiaryID: UUID?
    var country: Country = .uae
    var iban = ""
    var bankName = ""
    var swiftCode = ""
    var accountHolderName = ""
    var accountType = "INDIVIDUAL"
    var fullName = ""
    var nickname = ""
    var address = ""
    var city = ""
    var mobileNumber = ""

    static let empty = BeneficiaryDraft()

    init() {}

    init(beneficiary: Beneficiary) {
        editingBeneficiaryID = beneficiary.id
        country = beneficiary.country
        iban = beneficiary.account
        bankName = beneficiary.bank
        swiftCode = beneficiary.swiftCode
        accountHolderName = beneficiary.name
        accountType = beneficiary.accountType
        fullName = beneficiary.name
        nickname = beneficiary.nickname
        address = beneficiary.address
        city = beneficiary.city ?? ""
        mobileNumber = beneficiary.mobileNumber
    }

    var isEditing: Bool { editingBeneficiaryID != nil }

    var beneficiary: Beneficiary? {
        let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedIBAN = UAEIBANService.normalize(iban)
        guard
            !normalizedName.isEmpty,
            !normalizedIBAN.isEmpty,
            !bankName.isEmpty,
            !swiftCode.isEmpty
        else { return nil }

        return Beneficiary(
            id: editingBeneficiaryID ?? UUID(),
            name: normalizedName,
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            account: normalizedIBAN,
            bank: bankName,
            swiftCode: swiftCode,
            country: country,
            accountType: accountType,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            mobileNumber: mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            // Таймер создается только у новой записи; редактирование не запускает его заново.
            activationAvailableAt: isEditing ? nil : Date().addingTimeInterval(4 * 60 * 60)
        )
    }
}

enum Country: String, Codable, Hashable, CaseIterable {
    case uae = "UNITED ARAB EMIRATES"
    case usa = "UNITED STATES"
    case uk = "UNITED KINGDOM"
    case india = "INDIA"
}

struct UAEBank: Codable, Hashable {
    let code: String
    let name: String
    let bic8: String
}

enum UAEIBANValidationError: LocalizedError, Equatable {
    case empty
    case invalidLength
    case invalidFormat
    case invalidChecksum
    case bankNotFound(String)

    var errorDescription: String? {
        switch self {
        case .empty: "IBAN cannot be empty"
        case .invalidLength: "Enter a 23-character UAE IBAN"
        case .invalidFormat: "IBAN must start with AE followed by 21 digits"
        case .invalidChecksum: "IBAN check digits are invalid"
        case .bankNotFound(let code): "Bank not found for code \(code)"
        }
    }
}

/// UAE IBAN: AE + 2 check digits + 3-digit bank code + 16-digit account.
/// В UI возвращается основной BIC8 без суффикса XXX.
enum UAEIBANService {
    /// Единый справочник из UAE_IBAN_banks_validation.xlsx.
    /// Пустой `code` означает, что запись показывается в выборе банка,
    /// но не может использоваться для автоматического определения по IBAN.
    static let banks: [UAEBank] = {
        guard
            let data = NSDataAsset(name: "UAEIBANBanks")?.data,
            let decoded = try? JSONDecoder().decode([UAEBank].self, from: data)
        else {
            assertionFailure("UAEIBANBanks data asset is missing or invalid")
            return []
        }
        return decoded
    }()

    /// Полный allow-list со вкладки `Allow-list`. Сервисы и обменные дома из
    /// визуального списка остаются доступными для поиска, но не проходят как банк.
    private static let ibanValidationCodes: Set<String> = [
        "001", "003", "004", "007", "008", "009", "011", "012", "015", "016",
        "018", "020", "021", "022", "023", "024", "025", "026", "027", "028",
        "029", "030", "033", "034", "035", "036", "038", "039", "040", "041",
        "042", "043", "044", "045", "046", "047", "049", "050", "051", "052",
        "053", "054", "055", "056", "057", "086", "092", "096", "097", "132"
    ]

    private static let validationOnlyBanks: [UAEBank] = [
        UAEBank(code: "001", name: "CENTRAL BANK OF THE UNITED ARAB EMIRATES", bic8: "CBAUAEAAXXX"),
        UAEBank(code: "027", name: "FIRST GULF BANK", bic8: "FGBMAEAAXXX"),
        UAEBank(code: "033", name: "MASHREQ BANK", bic8: "BOMLAEADXXX")
    ]

    static func normalize(_ value: String) -> String {
        value.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    static func validateAndResolve(_ value: String) -> Result<UAEBank, UAEIBANValidationError> {
        let iban = normalize(value)
        guard !iban.isEmpty else { return .failure(.empty) }
        guard iban.count == 23 else { return .failure(.invalidLength) }
        guard iban.hasPrefix("AE"), iban.dropFirst(2).allSatisfy(\.isNumber) else {
            return .failure(.invalidFormat)
        }
        guard passesMOD97(iban) else { return .failure(.invalidChecksum) }

        let code = String(iban.dropFirst(4).prefix(3))
        guard let bank = banksByCode[code] else { return .failure(.bankNotFound(code)) }
        return .success(bank)
    }

    static func bank(for value: String) -> UAEBank? {
        let iban = normalize(value)
        guard iban.count >= 7 else { return nil }
        return banksByCode[String(iban.dropFirst(4).prefix(3))]
    }

    private static func passesMOD97(_ iban: String) -> Bool {
        let rearranged = iban.dropFirst(4) + iban.prefix(4)
        var remainder = 0
        for character in rearranged {
            if let digit = character.wholeNumberValue {
                remainder = (remainder * 10 + digit) % 97
            } else {
                let value = Int(character.asciiValue ?? 0) - 55
                guard value >= 10, value <= 35 else { return false }
                remainder = (remainder * 100 + value) % 97
            }
        }
        return remainder == 1
    }

    private static let banksByCode: [String: UAEBank] = Dictionary(
        (UAEIBANService.banks + UAEIBANService.validationOnlyBanks)
            .filter { UAEIBANService.ibanValidationCodes.contains($0.code) }
            // Исторические/брендовые дубли (например NBAD/FAB) используют один код.
            .reversed()
            .map { ($0.code, $0) },
        uniquingKeysWith: { current, _ in current }
    )
}

enum DemoData {
    static let accounts = [
        Account(name: "NEO PLUS Savings Account", number: "•••• 7731", balance: "AED 30,000.00"),
        Account(name: "NEO Current Account", number: "12345678912", balance: "AED 10,855.08")
    ]

    static let transactions = [
        Transaction(
            reference: "AB612310024",
            merchant: "DELIVERY HERO TALABAT DUBAI",
            location: "AE",
            amount: "- AED 53.10"
        ),
        Transaction(
            reference: "030POSB262293p0H",
            merchant: "259 0815 653972 QARYAT AL BERI RESORT",
            location: "AED ABU DHABI AED 20 0815",
            amount: "- AED 20.00",
            isProcessing: false
        ),
        Transaction(
            reference: "030POSB26229328T",
            merchant: "259 0815 675608 ADNOC SAMHA REST 887",
            location: "AED ABU DHABI AED 54.62 0815",
            amount: "- AED 54.62",
            isProcessing: false
        ),
        Transaction(
            reference: "033AACT26229A2LH",
            title: "Acct to Acct transfer",
            merchant: "FUND TRANSFER - 019010448550 - CHIMA JOSEPHUGWUTOC-MAE-013583786",
            location: "260816222117 FUND TRANSFER-MOBILE BANKING",
            amount: "- AED 80.00",
            isProcessing: false,
            category: .accountTransfer
        ),
        Transaction(
            reference: "033AACT26229A2VY",
            title: "Acct to Acct transfer",
            merchant: "FUND TRANSFER - 019010448550 - CHIMA JOSEPHUGWUTOC-MAE-013583786",
            location: "260816221950 FUND TRANSFER-MOBILE BANKING",
            amount: "+ AED 25.00",
            isProcessing: false,
            category: .accountTransfer,
            direction: .credit
        )
    ]

}
