import SwiftUI
import UIKit

struct AddBeneficiaryView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var step: AddBeneficiaryStep = .country
    @State private var isCountryPickerPresented = false
    @State private var isBankPickerPresented = false
    @State private var countryQuery = ""
    @State private var bankQuery = ""
    @State private var showsAdditionalDetails = false
    @State private var validationMessage: String?
    @State private var showsExitConfirmation = false

    private var draft: BeneficiaryDraft { session.beneficiaryDraft }
    private let headerHeight: CGFloat = 136

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: isBankPickerPresented
                    ? "Beneficiary Bank Name"
                    : (isCountryPickerPresented
                        ? "Select country"
                        : (draft.isEditing ? "Modify beneficiary" : "Add new beneficiary")),
                height: headerHeight,
                showsBack: !isCountryPickerPresented && !isBankPickerPresented,
                usesReferenceBackground: true,
                onBack: attemptExit,
                content: {
                if !isCountryPickerPresented && !isBankPickerPresented {
                    ProgressLine(progress: step.progress)
                        .padding(.horizontal, 24)
                }
            })
            .zIndex(10)

            if isCountryPickerPresented || isBankPickerPresented {
                countryPickerHeaderActions
                    .zIndex(11)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if isBankPickerPresented {
                        bankPicker
                    } else if isCountryPickerPresented {
                        countryPicker
                    } else if step == .country {
                        countryStep
                    } else if step == .bank {
                        bankStep
                    } else {
                        personalStep
                    }

                    Color.clear.frame(height: step == .personal ? 150 : 48)
                }
                .padding(.horizontal, 24)
                // Отступ измерен по 402 pt Figma-фрейму; progress остается внутри хедера.
                .padding(.top, 90)
            }

            if !isCountryPickerPresented, !isBankPickerPresented, step != .country {
                VStack(spacing: 0) {
                    Spacer()
                    MashreqPrimaryButton(title: step.buttonTitle) {
                        continueFlow()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    .background(Color.white)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.startAddingBeneficiary()
                    dismiss()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
        .accessibilityIdentifier("screen-add-beneficiary")
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("--qa-country-picker") {
                isCountryPickerPresented = true
            }
            if ProcessInfo.processInfo.arguments.contains("--qa-bank-picker") {
                step = .bank
                isBankPickerPresented = true
            }
            if draft.isEditing || !draft.iban.isEmpty {
                step = session.hasTrustedBeneficiary ? .personal : .bank
                if session.beneficiaryDraft.accountHolderName.isEmpty {
                    session.beneficiaryDraft.accountHolderName = draft.fullName
                }
            }
        }
    }

    private var countryStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Beneficiary bank details")
                .font(.mashreq(size: 19, weight: .semibold))

            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    isCountryPickerPresented = true
                }
            } label: {
                HStack(spacing: 17) {
                    CountrySearchGlyph()
                        .frame(width: 27, height: 27)
                    Text("Beneficiary country")
                        .font(.mashreq(size: 17, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                    Spacer()
                    DropdownGlyph()
                        .fill(MashreqTheme.secondaryInk)
                        .frame(width: 13, height: 8)
                }
                .padding(.horizontal, 20)
                .frame(height: 70)
                .contentShape(Rectangle())
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(MashreqTheme.secondaryInk.opacity(0.72), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var countryPickerHeaderActions: some View {
        HStack {
            Button {
                withAnimation(.easeOut(duration: 0.16)) {
                    isCountryPickerPresented = false
                    isBankPickerPresented = false
                }
            } label: {
                Image("ReferenceFlowBack")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.16)) {
                    isCountryPickerPresented = false
                    isBankPickerPresented = false
                }
            } label: {
                CloseGlyph(color: .white)
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close selection")
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
    }

    private var countryPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 15) {
                SearchGlyph(color: MashreqTheme.ink)
                    .frame(width: 25, height: 25)
                TextField("Search country", text: $countryQuery)
                    .font(.mashreq(size: 16, weight: .light))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MashreqTheme.secondaryInk.opacity(0.72), lineWidth: 1)
            }

            Text("Popular countries")
                .font(.mashreq(size: 17, weight: .semibold))
                .padding(.top, 28)

            countryRow(.uae, isEnabled: true)
                .padding(.top, 12)

            Text("All countries (A–Z)")
                .font(.mashreq(size: 17, weight: .semibold))
                .padding(.top, 26)

            ForEach(filteredCountries, id: \.self) { country in
                countryRow(country, isEnabled: country == .uae)
                Divider().padding(.leading, 57)
            }
        }
    }

    private var filteredCountries: [Country] {
        Country.allCases.filter { country in
            countryQuery.isEmpty || country.rawValue.localizedCaseInsensitiveContains(countryQuery)
        }
    }

    private func countryRow(_ country: Country, isEnabled: Bool) -> some View {
        Button {
            guard isEnabled else {
                validationMessage = "Only UNITED ARAB EMIRATES is available in this flow"
                return
            }
            session.beneficiaryDraft.country = .uae
            validationMessage = nil
            withAnimation(.easeOut(duration: 0.18)) {
                isCountryPickerPresented = false
                step = .bank
            }
        } label: {
            HStack(spacing: 16) {
                CountryBadge(country: country)
                    .frame(width: 43, height: 43)
                Text(country.rawValue)
                    .font(.mashreq(size: 16, weight: .semibold))
                    .foregroundStyle(MashreqTheme.ink)
                Spacer()
                if !isEnabled {
                    Text("Unavailable")
                        .font(.mashreq(size: 10, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                }
            }
            .frame(height: 63)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bankStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Beneficiary bank details")
                .font(.mashreq(size: 19, weight: .semibold))

            countryCard.padding(.top, 19)
            ibanField.padding(.top, 18)

            HStack(alignment: .firstTextBaseline) {
                Text(validationMessage ?? "Enter 23 digits")
                    .font(.mashreq(size: 15, weight: .light))
                    .foregroundStyle(
                        validationMessage == nil
                            ? MashreqTheme.secondaryInk
                            : (draft.bankName.isEmpty ? MashreqTheme.error : MashreqTheme.success)
                    )
                Spacer()
                Button("Select bank by name") {
                    withAnimation(.easeOut(duration: 0.18)) { isBankPickerPresented = true }
                }
                .font(.mashreq(size: 13, weight: .medium))
                .foregroundStyle(MashreqTheme.orangeDeep)
            }
            .padding(.top, 9)

            if !draft.bankName.isEmpty {
                resolvedBankCard.padding(.top, 18)
            }

            accountHolderField.padding(.top, 18)
            verificationCard.padding(.top, 17)
        }
    }

    /// Экран выбора банка повторяет референс; данные приходят из одного XLSX-справочника.
    private var bankPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Start typing bank name", text: $bankQuery)
                .font(.mashreq(size: 17, weight: .light))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 17)
                .frame(height: 68)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(MashreqTheme.secondaryInk.opacity(0.72), lineWidth: 1)
                }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredBanks, id: \.self) { bank in
                    Button {
                        selectBank(bank)
                    } label: {
                        Text(bank.name.capitalized)
                            .font(.mashreq(size: 17, weight: .regular))
                            .foregroundStyle(MashreqTheme.bodyInk)
                            .frame(maxWidth: .infinity, minHeight: 61, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.top, 30)
        }
    }

    private var filteredBanks: [UAEBank] {
        guard !bankQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return UAEIBANService.banks
        }
        return UAEIBANService.banks.filter {
            $0.name.localizedCaseInsensitiveContains(bankQuery)
        }
    }

    private func selectBank(_ bank: UAEBank) {
        session.beneficiaryDraft.bankName = bank.name.uppercased()
        session.beneficiaryDraft.swiftCode = bank.bic8
        validationMessage = bank.code.isEmpty
            ? "Enter IBAN to validate this bank"
            : "Selected bank code: \(bank.code)"
        withAnimation(.easeOut(duration: 0.18)) { isBankPickerPresented = false }
    }

    private var personalStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            accountTypeRow("INDIVIDUAL")
            accountTypeRow("COMPANY")
                .padding(.top, 18)

            BeneficiaryInputField(title: "Beneficiary full name", placeholder: "E.g. Mohammed Al Abdul Khan", text: binding(\.fullName))
                .padding(.top, 42)

            BeneficiaryInputField(title: "Beneficiary nick name", placeholder: "Enter beneficiary nick name", text: binding(\.nickname))
                .padding(.top, 18)

            Text("A nickname should be between 2 & 50 characters. Allowed special characters are &, -, _, @, /, ( and )")
                .font(.mashreq(size: 11, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .lineSpacing(2)
                .padding(.top, 8)

            Text("Beneficiary present address")
                .font(.mashreq(size: 18, weight: .semibold))
                .padding(.top, 24)

            countryCard
                .padding(.top, 15)

            BeneficiaryInputField(title: "Beneficiary city", placeholder: "Enter beneficiary city", text: binding(\.city))
                .padding(.top, 17)

            BeneficiaryInputField(title: "Address details", placeholder: "Enter address details", text: binding(\.address))
                .padding(.top, 17)

            Button {
                showsAdditionalDetails.toggle()
            } label: {
                HStack(alignment: .top, spacing: 13) {
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(MashreqTheme.secondaryInk, lineWidth: 1.2)
                        .frame(width: 20, height: 20)
                        .overlay {
                            if showsAdditionalDetails {
                                Text("✓")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(MashreqTheme.orangeDeep)
                            }
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Do you have beneficiary additional details? (Optional)")
                            .font(.mashreq(size: 15, weight: .semibold))
                            .foregroundStyle(MashreqTheme.ink)
                        Text("Sharing additional details will help us process your payments faster.")
                            .font(.mashreq(size: 12, weight: .light))
                            .foregroundStyle(MashreqTheme.secondaryInk)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 18)

            if showsAdditionalDetails {
                BeneficiaryInputField(title: "Mobile number", placeholder: "Enter mobile number", text: binding(\.mobileNumber), keyboard: .phonePad)
                    .padding(.top, 18)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.mashreq(size: MashreqTextSize.copy, weight: .regular))
                    .foregroundStyle(MashreqTheme.error)
                    .padding(.top, 10)
            }
        }
    }

    private func accountTypeRow(_ type: String) -> some View {
        Button {
            session.beneficiaryDraft.accountType = type
        } label: {
            HStack {
                Text(type)
                    .font(.mashreq(size: 18, weight: .regular))
                    .foregroundStyle(MashreqTheme.ink)
                Spacer()
                Circle()
                    .fill(draft.accountType == type ? Color(hex: 0x949696) : Color.clear)
                    .frame(width: 23, height: 23)
                    .overlay {
                        Circle().stroke(Color(hex: 0x949696), lineWidth: 1.5)
                    }
            }
            .padding(.horizontal, 18)
            .frame(height: 70)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(hex: 0x949696), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func attemptExit() {
        let hasProgress = step != .country ||
            !draft.iban.isEmpty || !draft.bankName.isEmpty ||
            !draft.fullName.isEmpty || !draft.nickname.isEmpty ||
            !draft.city.isEmpty || !draft.address.isEmpty
        if hasProgress {
            showsExitConfirmation = true
        } else {
            dismiss()
        }
    }

    private var countryCard: some View {
        HStack(spacing: 16) {
            UAEFlagView(size: 39)
            VStack(alignment: .leading, spacing: 5) {
                Text("Beneficiary country")
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                    .foregroundStyle(MashreqTheme.bodyInk)
                Text("UNITED ARAB EMIRATES")
                    .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    step = .country
                    isCountryPickerPresented = true
                }
            } label: {
                CircleCloseGlyph(color: MashreqTheme.bodyInk)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change beneficiary country")
        }
        .padding(.horizontal, 19)
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(MashreqTheme.bodyInk, lineWidth: 1)
        }
    }

    private var ibanField: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter IBAN")
                    .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                TextField("Enter IBAN", text: ibanBinding)
                    .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Button("Search") {
                resolveIBAN()
            }
            .font(.mashreq(size: MashreqTextSize.label, weight: .medium))
            .foregroundStyle(MashreqTheme.orangeDeep)
        }
        .padding(.horizontal, 14)
        .frame(height: 74)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(MashreqTheme.secondaryInk, lineWidth: 1)
        }
    }

    private var resolvedBankCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.bankName)
                        .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                    Text("Swift code: \(draft.swiftCode)")
                        .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                        .foregroundStyle(MashreqTheme.bodyInk)
                }
                Spacer(minLength: 10)
                Button {
                    session.beneficiaryDraft.iban = ""
                    session.beneficiaryDraft.bankName = ""
                    session.beneficiaryDraft.swiftCode = ""
                    validationMessage = nil
                } label: {
                    TrashGlyph(color: MashreqTheme.orangeDeep)
                        .frame(width: 23, height: 27)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 84)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MashreqTheme.sectionBackground)
    }

    private var accountHolderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account holder name in beneficiary's bank")
                .font(.mashreq(size: 14, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
            Text(maskedAccountHolderName)
                .font(.mashreq(size: 18, weight: .semibold))
                .foregroundStyle(draft.accountHolderName.isEmpty ? Color(hex: 0xBEBFC2) : MashreqTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 14)
        .frame(height: 74)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(MashreqTheme.secondaryInk.opacity(0.7), lineWidth: 1)
        }
    }

    private var maskedAccountHolderName: String {
        guard !draft.accountHolderName.isEmpty else { return "NAME RETURNED BY BANK" }
        return draft.accountHolderName
            .uppercased()
            .split(separator: " ")
            .map { word in
                let visible = word.prefix(min(3, word.count))
                return word.count > 3 ? "\(visible)***" : String(visible)
            }
            .joined(separator: " ")
    }

    private var verificationCard: some View {
        HStack(alignment: .center, spacing: 18) {
            InfoGlyph()
                .frame(width: 31, height: 31)
            (
                Text("The account holder name above is as per the beneficiary's bank records. ")
                + Text("Please verify").fontWeight(.bold)
                + Text(" before proceeding.")
            )
            .font(.mashreq(size: 14, weight: .regular))
            .foregroundStyle(MashreqTheme.ink)
            .lineSpacing(4)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 94)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(MashreqTheme.secondaryInk.opacity(0.7), lineWidth: 1)
        }
    }

    private var ibanBinding: Binding<String> {
        Binding(
            get: { session.beneficiaryDraft.iban },
            set: { newValue in
                session.beneficiaryDraft.iban = String(UAEIBANService.normalize(newValue).prefix(23))
                session.beneficiaryDraft.bankName = ""
                session.beneficiaryDraft.swiftCode = ""
                validationMessage = nil
            }
        )
    }

    private func binding(_ keyPath: WritableKeyPath<BeneficiaryDraft, String>) -> Binding<String> {
        Binding(
            get: { session.beneficiaryDraft[keyPath: keyPath] },
            set: { session.beneficiaryDraft[keyPath: keyPath] = $0 }
        )
    }

    private func resolveIBAN() {
        let normalized = UAEIBANService.normalize(session.beneficiaryDraft.iban)
        session.beneficiaryDraft.iban = normalized

        switch UAEIBANService.validateAndResolve(normalized) {
        case .success(let bank):
            session.beneficiaryDraft.bankName = bank.name
            session.beneficiaryDraft.swiftCode = bank.bic8
            if session.beneficiaryDraft.accountHolderName.isEmpty {
                let knownName = session.beneficiaryDraft.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                session.beneficiaryDraft.accountHolderName = knownName.isEmpty ? "Verified account holder" : knownName
            }
            validationMessage = "IBAN validated"
        case .failure(let error):
            session.beneficiaryDraft.bankName = ""
            session.beneficiaryDraft.swiftCode = ""
            validationMessage = error.localizedDescription
        }
    }

    private func continueFlow() {
        switch step {
        case .country:
            isCountryPickerPresented = true
        case .bank:
            // Выбор из списка не заменяет проверку формата, MOD-97 и кода банка.
            resolveIBAN()
            guard !session.beneficiaryDraft.bankName.isEmpty else { return }
            validationMessage = nil
            session.navigate(to: .beneficiarySecurityTip)
        case .personal:
            let name = draft.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                validationMessage = "Beneficiary full name cannot be empty"
                return
            }
            // Не позволяем случайно сохранить IBAN как имя получателя.
            let normalizedName = UAEIBANService.normalize(name)
            let normalizedIBAN = UAEIBANService.normalize(draft.iban)
            let looksLikeIBAN = normalizedName.count == 23
                && normalizedName.hasPrefix("AE")
                && normalizedName.dropFirst(2).allSatisfy(\.isNumber)
            guard normalizedName != normalizedIBAN, !looksLikeIBAN else {
                validationMessage = "Enter the beneficiary's full name, not the IBAN"
                return
            }

            let nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (2...50).contains(nickname.count) else {
                validationMessage = "Beneficiary nick name must contain between 2 and 50 characters"
                return
            }
            let allowedNicknameCharacters = CharacterSet.alphanumerics
                .union(.whitespaces)
                .union(CharacterSet(charactersIn: "&,-_@/()"))
            guard nickname.unicodeScalars.allSatisfy(allowedNicknameCharacters.contains) else {
                validationMessage = "Beneficiary nick name contains unsupported characters"
                return
            }

            let city = draft.city.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !city.isEmpty else {
                validationMessage = "Beneficiary city cannot be empty"
                return
            }

            session.beneficiaryDraft.fullName = name
            session.beneficiaryDraft.nickname = nickname
            session.beneficiaryDraft.city = city
            validationMessage = nil
            session.navigate(to: .reviewBeneficiary)
        }
    }
}

private enum AddBeneficiaryStep {
    case country
    case bank
    case personal

    var progress: CGFloat {
        switch self {
        case .country, .bank: 0.27
        case .personal: 0.52
        }
    }

    var buttonTitle: String {
        switch self {
        case .country: ""
        case .bank: "Beneficiary personal details"
        case .personal: "Review beneficiary details"
        }
    }
}

/// Векторные глифы повторяют референс и не зависят от набора SF Symbols.
struct SearchGlyph: View {
    var color: Color = MashreqTheme.secondaryInk
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: 2).frame(width: 17, height: 17).offset(x: -3, y: -3)
            Capsule().fill(color).frame(width: 11, height: 2).rotationEffect(.degrees(45)).offset(x: 7, y: 7)
        }
    }
}

private struct CountrySearchGlyph: View {
    var body: some View {
        ZStack {
            Circle().stroke(MashreqTheme.secondaryInk, lineWidth: 1.5).frame(width: 21, height: 21).offset(x: -2, y: -2)
            Ellipse().stroke(MashreqTheme.secondaryInk, lineWidth: 1).frame(width: 9, height: 21).offset(x: -2, y: -2)
            Rectangle().fill(MashreqTheme.secondaryInk).frame(width: 20, height: 1).offset(x: -2, y: -2)
            SearchGlyph().frame(width: 14, height: 14).offset(x: 8, y: 8)
        }
    }
}

private struct DropdownGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CloseGlyph: View {
    let color: Color
    var body: some View {
        ZStack {
            Capsule().fill(color).frame(width: 26, height: 1.7).rotationEffect(.degrees(45))
            Capsule().fill(color).frame(width: 26, height: 1.7).rotationEffect(.degrees(-45))
        }
    }
}

private struct CircleCloseGlyph: View {
    let color: Color
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: 1.4)
            CloseGlyph(color: color).scaleEffect(0.55)
        }
    }
}

struct TrashGlyph: View {
    let color: Color
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2).stroke(color, lineWidth: 2).frame(width: 17, height: 20).offset(y: 6)
            Capsule().fill(color).frame(width: 22, height: 2).offset(y: 4)
            RoundedRectangle(cornerRadius: 1).stroke(color, lineWidth: 2).frame(width: 8, height: 4)
            HStack(spacing: 4) {
                Capsule().fill(color).frame(width: 1.5, height: 13)
                Capsule().fill(color).frame(width: 1.5, height: 13)
            }.offset(y: 10)
        }
    }
}

struct InfoGlyph: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x424246))
            Text("i")
                .font(.system(size: 21, weight: .bold, design: .serif))
                .foregroundStyle(.white)
        }
    }
}

private struct BeneficiaryInputField: View {
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
                .textInputAutocapitalization(keyboard == .phonePad ? .never : .words)
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

/// Шаг 6 add-flow: подтверждение доверия до ввода персональных данных.
struct BeneficiarySecurityTipView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var showsExitConfirmation = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Security tip",
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
                .accessibilityLabel("Close security tip")
            }
            .padding(.top, 6)
            .padding(.trailing, 10)
            .zIndex(11)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    beneficiaryTrustCard

                    Image("SecurityTipIllustration")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 210, height: 210)
                        .frame(maxWidth: .infinity)

                    Text("We prioritize your security!")
                        .font(.mashreq(size: 22, weight: .semibold))
                        .padding(.top, 18)

                    SecurityTipRow(kind: .person, text: "Verify the beneficiary name and bank details before proceeding.")
                        .padding(.top, 24)

                    SecurityTipRow(kind: .payment, text: "Be cautious of scammers asking you to send money via social media, emails, calls, or text messages.")
                        .padding(.top, 18)

                    Color.clear.frame(height: 164)
                }
                .padding(.horizontal, 22)
                .padding(.top, 102)
            }

            VStack(spacing: 10) {
                Spacer()
                MashreqOutlineButton(title: "Change beneficiary") { dismiss() }
                MashreqPrimaryButton(title: "I trust this person") {
                    session.hasTrustedBeneficiary = true
                    session.navigate(to: .addBeneficiary)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 10)
            .background(alignment: .bottom) { Color.white.frame(height: 144) }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-beneficiary-security-tip")
        .mashreqEdgeToEdgeBottomSheet(
            isPresented: $showsExitConfirmation,
            height: UnsavedProgressSheet.referenceHeight
        ) {
            UnsavedProgressSheet(
                onExit: {
                    showsExitConfirmation = false
                    session.startAddingBeneficiary()
                    session.returnToManageBeneficiaries()
                },
                onStay: { showsExitConfirmation = false }
            )
        }
    }

    private var beneficiaryTrustCard: some View {
        let holder = session.beneficiaryDraft.accountHolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = holder.isEmpty ? session.beneficiaryDraft.bankName : holder.uppercased()
        let initial = title.first.map(String.init) ?? "U"

        return HStack(spacing: 15) {
            ZStack {
                Circle().fill(MashreqTheme.orange)
                Text(initial)
                    .font(.mashreq(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.mashreq(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("IBAN ending \(session.beneficiaryDraft.iban.suffix(4))")
                    .font(.mashreq(size: 13, weight: .light))
                    .foregroundStyle(MashreqTheme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 72)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .mashreqCardShadow()
    }
}

private struct SecurityTipRow: View {
    enum Kind { case person, payment }
    let kind: Kind
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle().fill(MashreqTheme.orangeSoft).frame(width: 44, height: 44)
                SecurityTipGlyph(kind: kind)
                    .stroke(MashreqTheme.orangeDeep, lineWidth: 1.6)
                    .frame(width: 23, height: 23)
            }
            Text(text)
                .font(.mashreq(size: 15, weight: .regular))
                .foregroundStyle(MashreqTheme.bodyInk)
                .lineSpacing(4)
        }
    }
}

private struct SecurityTipGlyph: Shape {
    let kind: SecurityTipRow.Kind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch kind {
        case .person:
            path.addEllipse(in: CGRect(x: rect.midX - 4, y: rect.minY + 1, width: 8, height: 8))
            path.addRoundedRect(in: CGRect(x: rect.minX + 4, y: rect.midY, width: rect.width - 8, height: rect.height / 2), cornerSize: CGSize(width: 7, height: 7))
        case .payment:
            path.addRoundedRect(in: CGRect(x: rect.minX + 2, y: rect.minY + 2, width: rect.width - 7, height: rect.height - 4), cornerSize: CGSize(width: 2, height: 2))
            path.move(to: CGPoint(x: rect.minX + 5, y: rect.minY + 8))
            path.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY + 8))
            path.addEllipse(in: CGRect(x: rect.maxX - 10, y: rect.midY - 3, width: 9, height: 9))
        }
        return path
    }
}

struct ReviewBeneficiaryView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ReviewSectionHeader(kind: .bank, title: "Beneficiary bank details")
                    bankDetails

                    ReviewSectionHeader(kind: .person, title: "Beneficiary personal details")
                    personalDetails

                    Color.clear.frame(height: 100)
                }
                .padding(.top, 104)
            }

            MashreqPrimaryButton(title: session.beneficiaryDraft.isEditing ? "Save changes" : "Add beneficiary") {
                if session.beneficiaryDraft.isEditing {
                    if session.saveCurrentBeneficiary() != nil {
                        session.returnToManageBeneficiaries()
                    }
                } else {
                    session.navigate(to: .beneficiaryOTP)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)

            MashreqHeader(
                title: "Review beneficiary details",
                height: 116,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 17,
                titleFontWeight: .semibold,
                content: {
                ProgressLine(progress: 0.76)
                    .padding(.horizontal, 24)
            })
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-review-beneficiary")
    }

    private var bankDetails: some View {
        HStack(alignment: .top, spacing: 18) {
            UAEFlagView(size: 38)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 30) {
                ReviewField(label: "Beneficiary bank country", value: session.beneficiaryDraft.country.rawValue)
                ReviewField(label: "Beneficiary bank name", value: session.beneficiaryDraft.bankName)
                ReviewField(label: "IBAN or Account number", value: session.beneficiaryDraft.iban)
                ReviewField(label: "Swift code", value: session.beneficiaryDraft.swiftCode)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var personalDetails: some View {
        VStack(alignment: .leading, spacing: 32) {
            ReviewField(label: "Beneficiary account type", value: session.beneficiaryDraft.accountType)
            ReviewField(label: "Beneficiary full name", value: session.beneficiaryDraft.fullName)
            ReviewField(label: "Beneficiary nick name", value: session.beneficiaryDraft.nickname)
        }
        .padding(.leading, 70)
        .padding(.trailing, 24)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReviewSectionHeader: View {
    enum Kind { case bank, person }
    let kind: Kind
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MashreqTheme.orangeSoft)
                    .frame(width: 36, height: 36)
                ReviewHeaderGlyph(kind: kind)
                    .stroke(MashreqTheme.orangeDeep, lineWidth: 1.6)
                    .frame(width: 18, height: 18)
            }
            Text(title)
                .font(.mashreq(size: MashreqTextSize.title, weight: .medium))
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
        .background(MashreqTheme.sectionBackground)
    }
}

private struct ReviewHeaderGlyph: Shape {
    let kind: ReviewSectionHeader.Kind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch kind {
        case .person:
            path.addEllipse(in: CGRect(x: rect.midX - 3.5, y: rect.minY + 1, width: 7, height: 7))
            path.addRoundedRect(in: CGRect(x: rect.minX + 3, y: rect.midY, width: rect.width - 6, height: rect.height / 2), cornerSize: CGSize(width: 6, height: 6))
        case .bank:
            path.move(to: CGPoint(x: rect.minX + 1, y: rect.minY + 6))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + 1))
            path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.minY + 6))
            path.closeSubpath()
            for x in stride(from: rect.minX + 4, through: rect.maxX - 4, by: 5) {
                path.move(to: CGPoint(x: x, y: rect.minY + 7))
                path.addLine(to: CGPoint(x: x, y: rect.maxY - 3))
            }
            path.move(to: CGPoint(x: rect.minX + 1, y: rect.maxY - 2))
            path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY - 2))
        }
        return path
    }
}

private struct ReviewField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
            Text(value)
                .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
    }
}

/// Шаг 9 add-flow. Верхняя иллюстрация закреплена и не участвует
/// в изменении высоты layout при появлении цифровой клавиатуры.
struct BeneficiaryAuthenticationView: View {
    @Environment(AppSession.self) private var session
    @State private var code = ""
    @State private var hasSubmitted = false
    @State private var resendSeconds = 60
    @State private var resendCycle = 0
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                MashreqHeader(
                    title: "Add new beneficiary",
                    height: 116,
                    showsBack: true,
                    usesReferenceBackground: true,
                    titleFontSize: 18,
                    content: {
                    ProgressLine(progress: 0.92).padding(.horizontal, 24)
                })
                .zIndex(10)

                VStack(alignment: .leading, spacing: 0) {
                    Image("OTPIdentityIllustration")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 188, height: 176)
                        .frame(maxWidth: .infinity)

                    Text("Authentication")
                        .font(.mashreq(size: 22, weight: .bold))
                        .padding(.top, 12)

                    Text("Please enter the 6 digit code sent to your\nregistered mobile number")
                        .font(.mashreq(size: 17, weight: .light))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 11)

                    HStack(spacing: 14) {
                        PhoneOutlineGlyph()
                            .stroke(MashreqTheme.orangeDeep, lineWidth: 1.6)
                            .frame(width: 20, height: 27)
                        Text(session.profile.maskedSMSPhone)
                            .font(.mashreq(size: 19, weight: .semibold))
                    }
                    .padding(.top, 20)

                    beneficiaryOTPBoxes.padding(.top, 29)

                    Text("Haven’t received your OTP?")
                        .font(.mashreq(size: 19, weight: .bold))
                        .foregroundStyle(MashreqTheme.orange)
                        .padding(.top, 42)

                    resendStatus.padding(.top, 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 128)
            }
            // Клавиатура накрывает нижнюю часть, но не двигает illustration/header.
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-beneficiary-otp")
        .task(id: resendCycle) {
            while resendSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { resendSeconds -= 1 }
            }
        }
    }

    @ViewBuilder
    private var resendStatus: some View {
        if resendSeconds > 0 {
            HStack(spacing: 8) {
                Text("Resend possible in")
                Text("\(resendSeconds) sec.")
                    .foregroundStyle(MashreqTheme.orange)
                    .fontWeight(.semibold)
            }
            .font(.mashreq(size: 16, weight: .light))
        } else {
            Button("Resend OTP") {
                code = ""
                hasSubmitted = false
                resendSeconds = 60
                resendCycle += 1
                isCodeFocused = true
            }
            .buttonStyle(.plain)
            .font(.mashreq(size: 16, weight: .semibold))
            .foregroundStyle(MashreqTheme.orange)
        }
    }

    private var beneficiaryOTPBoxes: some View {
        let digits = Array(code)
        return ZStack {
            HStack(spacing: 14) {
                ForEach(0..<6, id: \.self) { index in
                    Text(index < digits.count ? String(digits[index]) : "")
                        .font(.mashreq(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(index == min(digits.count, 5) && isCodeFocused ? MashreqTheme.orangeDeep : Color(hex: 0xDEDEDE), lineWidth: 1.5)
                        }
                }
            }

            TextField("One-time code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .opacity(0.01)
                .onChange(of: code) { _, value in
                    let sanitized = String(value.filter(\.isNumber).prefix(6))
                    if sanitized != value { code = sanitized; return }
                    guard sanitized.count == 6, !hasSubmitted else { return }
                    hasSubmitted = true
                    if session.saveCurrentBeneficiary() != nil {
                        session.navigate(to: .beneficiarySuccess)
                    } else {
                        hasSubmitted = false
                    }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { isCodeFocused = true }
    }
}

struct PhoneOutlineGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect.insetBy(dx: 2, dy: 1), cornerRadius: 3)
        path.move(to: CGPoint(x: rect.minX + 5, y: rect.maxY - 5))
        path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.maxY - 5))
        return path
    }
}

struct BeneficiarySuccessView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Image("SuccessCheck")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 46, height: 46)
                        .padding(.top, 13)

                    Text("Beneficiary successfully added!")
                        .font(.mashreq(size: MashreqTextSize.section, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.92)
                        .padding(.top, 26)

                    beneficiaryInfo
                        .padding(.top, 24)

                    (
                        Text("You can track your newly added beneficiary status by simply visiting your ")
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                        + Text("Mashreq dashboard > Money Transfer > Manage beneficiary")
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .semibold))
                    )
                    .padding(.top, 12)
                    .lineSpacing(2)

                    Divider().padding(.top, 27)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(MashreqTheme.orangeSoft).frame(width: 36, height: 36)
                            SecurityTipGlyph(kind: .person)
                                .stroke(MashreqTheme.orangeDeep, lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                        }
                        Text("Beneficiary summary")
                            .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                    }
                    .padding(.top, 26)

                    VStack(alignment: .leading, spacing: 34) {
                        ReviewField(label: "Beneficiary full name", value: savedBeneficiary.name)
                        ReviewField(label: "Beneficiary nick name", value: savedBeneficiary.nickname.isEmpty ? savedBeneficiary.name : savedBeneficiary.nickname)
                        ReviewField(label: "IBAN", value: savedBeneficiary.account)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 39)

                    Color.clear.frame(height: 150)
                }
                .padding(.horizontal, 22)
            }

            SuccessButtons(primaryTitle: "Initiate transfer") {
                session.navigate(to: .transferringFrom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
        .accessibilityIdentifier("screen-beneficiary-success")
    }

    private var savedBeneficiary: Beneficiary {
        session.selectedBeneficiary
            ?? session.beneficiaryDraft.beneficiary
            ?? Beneficiary(name: "", account: "", bank: "", country: .uae)
    }

    private var beneficiaryInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            InfoGlyph()
                .frame(width: 19, height: 19)
                .padding(.top, 1)
            Text("For next 4 hours, you can make 2 transfer(s) upto AED 20,000.00 (total) for this beneficiary")
                .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                .foregroundStyle(MashreqTheme.bodyInk)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(MashreqTheme.helpBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct TransferSuccessView: View {
    @Environment(AppSession.self) private var session

    private var transfer: CompletedTransfer {
        session.lastCompletedTransfer
            ?? CompletedTransfer(draft: session.transferDraft, reference: "PENDING")
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Image("TransferSuccessCheckRef")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(.top, 36)

                    HStack(alignment: .top) {
                        Text("Transfer successfully\ninitiated!")
                            .font(.mashreq(size: MashreqTextSize.sectionLarge, weight: .semibold))
                        Spacer()
                        Image("TransferSuccessDownload")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(.top, 8)
                    }
                    .padding(.top, 24)

                    Text("Transaction Reference Number")
                        .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                        .padding(.top, 48)
                    Text(transfer.reference)
                        .font(.mashreq(size: MashreqTextSize.label, weight: .medium))
                        .padding(.top, 5)

                    successParagraph("Your transaction is expected to be credited instantly. Any delay could be due to weekend, public holiday(s) or currency cut-off time.")
                        .padding(.top, 28)
                    successParagraph("You will receive an email confirmation once your transaction has been processed.")
                        .padding(.top, 22)

                    (
                        Text("You can use this reference number for tracking this payment. You can track all your transfers through your ")
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                        + Text("Mashreq dashboard > Money Transfer > Track & Manage transfer.")
                            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .semibold))
                    )
                    .padding(.top, 22)
                    .lineSpacing(2)

                    Divider().padding(.top, 24)

                    Text("Transferring from")
                        .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                        .padding(.top, 26)

                    PanelCard {
                        HStack(spacing: 14) {
                            UAEFlagView(size: 38)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transfer.senderAccountName)
                                    .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                                Text(transfer.maskedSenderAccount)
                                    .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                                    .foregroundStyle(MashreqTheme.secondaryInk)
                            }
                        }
                    }
                    .frame(height: 75)
                    .padding(.top, 14)

                    Text("You have transferred")
                        .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                        .padding(.top, 26)

                    PanelCard {
                        HStack(spacing: 14) {
                            UAEFlagView(size: 38)
                            Text("AED \(transfer.formattedAmount)")
                                .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                        }
                    }
                    .frame(height: 55)
                    .padding(.top, 14)

                    Text("To the beneficiary")
                        .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))
                        .padding(.top, 27)

                    PanelCard {
                        HStack(spacing: 14) {
                            UAEFlagView(size: 38)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transfer.beneficiaryName)
                                    .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                                Text("***\(transfer.beneficiaryIBAN.suffix(4)) | \(transfer.beneficiaryBank)")
                                    .font(.mashreq(size: MashreqTextSize.meta, weight: .light))
                                    .foregroundStyle(MashreqTheme.secondaryInk)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(height: 75)
                    .padding(.top, 14)

                    Color.clear.frame(height: 210)
                }
                .padding(.horizontal, 24)
            }

            SuccessButtons(primaryTitle: "Initiate new transfer") {
                session.prepareRepeatTransfer(from: transfer)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
        .accessibilityIdentifier("screen-transfer-success")
    }

    private func successParagraph(_ value: String) -> some View {
        Text(value)
            .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
            .foregroundStyle(MashreqTheme.bodyInk)
            .lineSpacing(2)
    }
}

private struct SuccessButtons: View {
    let primaryTitle: String
    let primaryAction: () -> Void
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(spacing: 8) {
            MashreqOutlineButton(title: "Back to Overview") {
                session.returnToOverview()
            }
            MashreqPrimaryButton(title: primaryTitle, action: primaryAction)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Color.white)
        .offset(y: 26)
    }
}
