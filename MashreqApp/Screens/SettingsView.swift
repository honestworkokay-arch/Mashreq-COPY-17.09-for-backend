import SwiftData
import SwiftUI

/// Локальная панель управления демонстрационными данными приложения.
/// Все изменения сохраняются через AppSession и сразу видны на остальных экранах.
struct SettingsView: View {
    var onRegister: () -> Void = {}

    @Environment(AppSession.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RegisteredUser.createdAt) private var registeredUsers: [RegisteredUser]

    @State private var profileDraft = UserProfile.demo
    @State private var balanceText = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var passwordConfirmation = ""
    @State private var editorRoute: TransactionEditorRoute?
    @State private var pendingDeletion: Transaction?
    @State private var statusMessage: String?
    @State private var validationMessage: String?
    @State private var passwordStatusMessage: String?
    @State private var passwordValidationMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            MashreqTheme.canvas.ignoresSafeArea()

            Form {
                profileOverviewSection
                profileSection
                accountSection
                saveSection
                passwordSection
                transactionActionsSection
                transactionsSection
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MashreqTheme.canvas)
            // Form уже учитывает safe area; здесь нужен только зазор под
            // нижней границей фирменного header, а не его полная высота.
            .padding(.top, 32)
            .scrollDismissesKeyboard(.interactively)

            MashreqHeader(
                title: "Settings",
                height: 101,
                showsBack: true,
                usesReferenceBackground: true
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .tint(MashreqTheme.orangeDeep)
        .onAppear(perform: loadCurrentValues)
        .onChange(of: registeredUsers.first?.updatedAt) { _, _ in
            loadCurrentValues()
        }
        .fullScreenCover(item: $editorRoute, onDismiss: refreshBalance) { route in
            NavigationStack {
                TransactionEditorView(route: route)
            }
            .environment(session)
        }
        .confirmationDialog(
            "Delete transaction?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let transaction = pendingDeletion else { return }
                session.deleteTransaction(id: transaction.id)
                pendingDeletion = nil
                statusMessage = "Transaction deleted. Balance was not changed."
            }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("The history record will be removed. Use Refund when the balance must be credited back.")
        }
        .accessibilityIdentifier("screen-settings")
    }

    /// Яркая карточка делает зарегистрированный профиль заметным сразу после
    /// открытия Settings. Если регистрации ещё нет — отсюда открывается тот же flow.
    private var profileOverviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(MashreqTheme.headerGradient)
                            .frame(width: 62, height: 62)

                        Text(profileInitials)
                            .font(.mashreq(size: 19, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(registeredUsers.isEmpty ? "Complete your registration" : profileDisplayName)
                            .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .bold))
                            .foregroundStyle(MashreqTheme.ink)

                        Text(registeredUsers.isEmpty ? "Add your contact and account details" : profileDraft.email)
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                            .foregroundStyle(MashreqTheme.secondaryInk)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: registeredUsers.isEmpty ? "person.crop.circle.badge.plus" : "checkmark.seal.fill")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(MashreqTheme.orangeDeep)
                }

                if registeredUsers.isEmpty {
                    Button(action: onRegister) {
                        Text("Register now")
                            .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(MashreqTheme.headerGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings-open-registration")
                } else {
                    HStack(spacing: 8) {
                        SettingsStatusPill(icon: "person.text.rectangle", title: "Profile saved")
                        SettingsStatusPill(icon: "lock.shield", title: "Password protected")
                    }
                }
            }
            .padding(18)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(MashreqTheme.orangeDeep.opacity(0.32), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var profileSection: some View {
        Section {
            SettingsEditableRow(
                icon: "person",
                title: "First name",
                text: $profileDraft.firstName,
                textContentType: .givenName,
                capitalization: .words
            )
            SettingsEditableRow(
                icon: "person",
                title: "Last name",
                text: $profileDraft.lastName,
                textContentType: .familyName,
                capitalization: .words
            )
            SettingsEditableRow(
                icon: "envelope",
                title: "Email address",
                text: $profileDraft.email,
                textContentType: .emailAddress,
                keyboardType: .emailAddress,
                capitalization: .never
            )
            SettingsEditableRow(
                icon: "iphone",
                title: "Mobile number",
                text: $profileDraft.smsPhoneNumber,
                textContentType: .telephoneNumber,
                keyboardType: .phonePad
            )
        } header: {
            Text("Personal & contact details")
        } footer: {
            Text("The SMS number is used to mask the recipient on the OTP screen.")
        }
    }

    private var accountSection: some View {
        Section {
            SettingsEditableRow(
                icon: "building.columns",
                title: "UAE IBAN",
                text: $profileDraft.iban,
                capitalization: .characters
            )
            SettingsEditableRow(
                icon: "number",
                title: "Account number",
                text: $profileDraft.accountNumber,
                keyboardType: .numberPad
            )
            SettingsEditableRow(
                icon: "banknote",
                title: "Balance (AED)",
                text: $balanceText,
                keyboardType: .decimalPad
            )
        } header: {
            Text("Current account")
        } footer: {
            Text("IBAN must contain 23 characters, start with AE and pass MOD-97 validation.")
        }
    }

    private var saveSection: some View {
        Section {
            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.circle")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                    .foregroundStyle(MashreqTheme.error)
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                    .foregroundStyle(MashreqTheme.success)
            }

            Button(action: saveProfileAndAccount) {
                Text("Save profile and account")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MashreqTheme.headerGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .listRowBackground(Color.clear)
    }

    private var passwordSection: some View {
        Section {
            SettingsEditableRow(
                icon: "lock",
                title: "Current password",
                text: $currentPassword,
                textContentType: .password,
                capitalization: .never,
                isSecure: true
            )
            SettingsEditableRow(
                icon: "key",
                title: "New password",
                text: $newPassword,
                textContentType: .newPassword,
                capitalization: .never,
                isSecure: true
            )
            SettingsEditableRow(
                icon: "checkmark.shield",
                title: "Confirm new password",
                text: $passwordConfirmation,
                textContentType: .newPassword,
                capitalization: .never,
                isSecure: true
            )

            if let passwordValidationMessage {
                Label(passwordValidationMessage, systemImage: "exclamationmark.circle")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                    .foregroundStyle(MashreqTheme.error)
            }

            if let passwordStatusMessage {
                Label(passwordStatusMessage, systemImage: "checkmark.shield.fill")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                    .foregroundStyle(MashreqTheme.success)
            }

            Button(action: updatePassword) {
                Text("Update login password")
                    .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                    .foregroundStyle(MashreqTheme.orangeDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(MashreqTheme.orangeDeep, lineWidth: 1.2)
                    }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Login security")
        } footer: {
            Text("The password is stored in Apple Keychain and never written to the profile database.")
        }
    }

    private var transactionActionsSection: some View {
        Section("Transaction management") {
            Button {
                editorRoute = .add(.other)
            } label: {
                Label("Add transaction", systemImage: "plus.circle")
            }

            Button {
                editorRoute = .add(.topUp)
            } label: {
                Label("Add money / top up", systemImage: "arrow.down.circle")
            }
        }
    }

    @ViewBuilder
    private var transactionsSection: some View {
        Section {
            if session.transactions.isEmpty {
                ContentUnavailableView(
                    "No transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Create the first transaction above.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(session.transactions) { transaction in
                    SettingsTransactionRow(
                        transaction: transaction,
                        editAction: { editorRoute = .edit(transaction) },
                        refundAction: { refund(transaction) },
                        deleteAction: { pendingDeletion = transaction }
                    )
                }
            }
        } header: {
            Text("All transactions · \(session.transactions.count)")
        } footer: {
            Text("Editing can reconcile the balance. Deleting only removes history; Refund creates a separate credit operation.")
        }
    }

    private func loadCurrentValues() {
        profileDraft = registeredUsers.first?.userProfile ?? session.profile
        balanceText = MoneyText.amount(session.accountBalance)
    }

    private var profileDisplayName: String {
        let fullName = "\(profileDraft.firstName) \(profileDraft.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? "Mashreq customer" : fullName
    }

    private var profileInitials: String {
        let first = profileDraft.firstName.first.map { String($0) } ?? "M"
        let last = profileDraft.lastName.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }

    private func refreshBalance() {
        balanceText = MoneyText.amount(session.accountBalance)
    }

    private func saveProfileAndAccount() {
        validationMessage = nil
        statusMessage = nil

        let normalizedIBAN = RegistrationValidation.normalizedIBAN(profileDraft.iban)
        let accountDigits = RegistrationValidation.accountDigits(profileDraft.accountNumber)
        let normalizedAmount = balanceText.replacingOccurrences(of: ",", with: "")

        if let message = RegistrationValidation.profileMessage(
            firstName: profileDraft.firstName,
            lastName: profileDraft.lastName,
            mobileNumber: profileDraft.smsPhoneNumber,
            email: profileDraft.email,
            iban: normalizedIBAN,
            accountNumber: accountDigits
        ) {
            validationMessage = message
            return
        }
        guard let balance = Decimal(string: normalizedAmount), balance >= 0 else {
            validationMessage = "Balance must be zero or greater."
            return
        }

        profileDraft.firstName = profileDraft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileDraft.lastName = profileDraft.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileDraft.smsPhoneNumber = profileDraft.smsPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        profileDraft.email = profileDraft.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        profileDraft.iban = normalizedIBAN
        profileDraft.accountNumber = accountDigits

        guard let registeredUser = registeredUsers.first else {
            validationMessage = "Registered profile was not found. Complete registration first."
            return
        }

        registeredUser.update(from: profileDraft)
        do {
            try modelContext.save()
        } catch {
            validationMessage = "The profile database could not be updated: \(error.localizedDescription)"
            return
        }

        session.saveProfile(profileDraft, balance: balance)
        balanceText = MoneyText.amount(session.accountBalance)
        statusMessage = "Profile, contacts and account saved to the database."
    }

    private func updatePassword() {
        passwordValidationMessage = nil
        passwordStatusMessage = nil

        guard !currentPassword.isEmpty else {
            passwordValidationMessage = "Enter your current password."
            return
        }
        if let message = RegistrationValidation.passwordMessage(
            newPassword,
            confirmation: passwordConfirmation
        ) {
            passwordValidationMessage = message
            return
        }

        do {
            guard try LoginCredentialStore.verify(password: currentPassword) else {
                passwordValidationMessage = "Current password is incorrect."
                return
            }
            try LoginCredentialStore.savePassword(newPassword)
            currentPassword = ""
            newPassword = ""
            passwordConfirmation = ""
            passwordStatusMessage = "Login password updated securely."
        } catch {
            passwordValidationMessage = error.localizedDescription
        }
    }

    private func refund(_ transaction: Transaction) {
        statusMessage = nil
        validationMessage = nil
        if session.refundTransaction(id: transaction.id) {
            balanceText = MoneyText.amount(session.accountBalance)
            statusMessage = "Refund added and balance credited."
        } else {
            validationMessage = transaction.direction == .credit
                ? "Only debit transactions can be refunded."
                : "This transaction has already been refunded."
        }
    }
}

/// Единый визуальный ряд Settings: иконка, подпись и редактируемое значение.
/// Благодаря ему изменения профиля заметны, но остаются в стиле Mashreq.
private struct SettingsEditableRow: View {
    let icon: String
    let title: String
    @Binding var text: String
    var textContentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization? = .sentences
    var isSecure = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MashreqTheme.orangeSoft)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(MashreqTheme.orangeDeep)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)

                Group {
                    if isSecure {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                    }
                }
                .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                .foregroundStyle(MashreqTheme.ink)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }
}

private struct SettingsStatusPill: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.mashreq(size: MashreqTextSize.nano, weight: .semibold))
            .foregroundStyle(MashreqTheme.orangeDeep)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(MashreqTheme.orangeSoft)
            .clipShape(Capsule())
    }
}

private struct SettingsTransactionRow: View {
    let transaction: Transaction
    let editAction: () -> Void
    let refundAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.direction == .credit ? Color.green.opacity(0.12) : MashreqTheme.orangeSoft)
                    .frame(width: 38, height: 38)
                Image(systemName: transaction.direction == .credit ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(transaction.direction == .credit ? MashreqTheme.success : MashreqTheme.orangeDeep)
            }

            Button(action: editAction) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(transaction.category.rawValue)
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .semibold))
                            .foregroundStyle(MashreqTheme.ink)
                        if transaction.isRefunded {
                            Text("REFUNDED")
                                .font(.mashreq(size: MashreqTextSize.nano, weight: .semibold))
                                .foregroundStyle(MashreqTheme.success)
                        }
                    }
                    Text(transaction.reference)
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .regular))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                        .lineLimit(1)
                    Text(transaction.merchant)
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                        .foregroundStyle(MashreqTheme.bodyInk)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .trailing, spacing: 6) {
                Text(transaction.amount)
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .semibold))
                    .foregroundStyle(transaction.direction == .credit ? MashreqTheme.success : MashreqTheme.ink)

                Menu {
                    Button("Edit", systemImage: "pencil", action: editAction)
                    Button("Refund", systemImage: "arrow.uturn.backward", action: refundAction)
                        .disabled(transaction.direction == .credit || transaction.isRefunded)
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive, action: deleteAction)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(MashreqTheme.orangeDeep)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private enum TransactionEditorRoute: Identifiable {
    case add(TransactionCategory)
    case edit(Transaction)

    var id: String {
        switch self {
        case .add(let category): "add-\(category.rawValue)"
        case .edit(let transaction): transaction.id.uuidString
        }
    }
}

private struct TransactionEditorView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    private let transactionID: UUID?
    @State private var draft: TransactionFormDraft
    @State private var errorMessage: String?

    init(route: TransactionEditorRoute) {
        switch route {
        case .add(let category):
            transactionID = nil
            _draft = State(initialValue: TransactionFormDraft(category: category))
        case .edit(let transaction):
            transactionID = transaction.id
            _draft = State(initialValue: TransactionFormDraft(transaction: transaction))
        }
    }

    var body: some View {
        Form {
            Section("Core fields") {
                TextField("Reference number", text: $draft.reference)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Picker("Transaction type", selection: $draft.category) {
                    ForEach(TransactionCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }

                Picker("Direction", selection: $draft.direction) {
                    ForEach(TransactionDirection.allCases) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("AED")
                        .foregroundStyle(MashreqTheme.secondaryInk)
                    TextField("Amount", text: $draft.amount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Description") {
                TextField("Recipient / merchant", text: $draft.merchant, axis: .vertical)
                    .lineLimit(1...3)
                TextField("Details / location", text: $draft.location, axis: .vertical)
                    .lineLimit(1...3)
                Toggle("Processing", isOn: $draft.isProcessing)
            }

            Section {
                Toggle("Reconcile account balance", isOn: $draft.adjustsBalance)
            } footer: {
                Text(transactionID == nil
                     ? "Debit subtracts the amount; credit and top up add it."
                     : "When enabled, the balance changes only by the difference between the old and new transaction.")
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(MashreqTheme.error)
                }
            }
        }
        .navigationTitle(transactionID == nil ? "Add transaction" : "Edit transaction")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .tint(MashreqTheme.orangeDeep)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .fontWeight(.semibold)
            }
        }
        .onChange(of: draft.category) { _, category in
            draft.direction = category.defaultDirection
        }
    }

    private func save() {
        errorMessage = nil
        let normalizedReference = draft.reference
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = draft.amount.replacingOccurrences(of: ",", with: "")

        guard !normalizedReference.isEmpty else {
            errorMessage = "Reference number is required."
            return
        }
        guard let amount = Decimal(string: normalizedAmount), amount > 0 else {
            errorMessage = "Amount must be greater than zero."
            return
        }
        guard !draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Recipient or merchant is required."
            return
        }

        let input = ManagedTransactionInput(
            reference: normalizedReference,
            category: draft.category,
            direction: draft.direction,
            amount: amount,
            merchant: draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines),
            isProcessing: draft.isProcessing,
            adjustsBalance: draft.adjustsBalance
        )

        let didSave: Bool
        if let transactionID {
            didSave = session.updateTransaction(id: transactionID, input: input)
        } else {
            didSave = session.addTransaction(input)
        }

        guard didSave else {
            errorMessage = "The debit would make the account balance negative."
            return
        }
        dismiss()
    }
}

private struct TransactionFormDraft {
    var reference: String
    var category: TransactionCategory
    var direction: TransactionDirection
    var amount: String
    var merchant: String
    var location: String
    var isProcessing: Bool
    var adjustsBalance: Bool

    init(category: TransactionCategory) {
        reference = ManualReference.make(prefix: category == .topUp ? "TOP" : "MAN")
        self.category = category
        direction = category.defaultDirection
        amount = ""
        merchant = category == .topUp ? "ACCOUNT TOP UP" : ""
        location = "MOBILE BANKING"
        isProcessing = false
        adjustsBalance = true
    }

    init(transaction: Transaction) {
        reference = transaction.reference
        category = transaction.category
        direction = transaction.direction
        amount = MoneyText.amount(transaction.amountValue)
        merchant = transaction.merchant
        location = transaction.location
        isProcessing = transaction.isProcessing
        adjustsBalance = true
    }
}

private enum ManualReference {
    static func make(prefix: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "ddMMyyHHmmss"
        return prefix + formatter.string(from: .now)
    }
}
