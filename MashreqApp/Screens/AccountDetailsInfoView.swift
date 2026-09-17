import SwiftUI
import UIKit

/// Экран реквизитов текущего счёта. Все копируемые значения берутся из
/// AppSession, поэтому экран, PDF и переводы не расходятся по номеру или IBAN.
struct YourAccountDetailsView: View {
    @Environment(AppSession.self) private var session
    @State private var copiedField: CopiedAccountField?

    private var details: UserAccountDetails {
        session.profile.accountDetails ?? UserAccountDetails(
            nickname: session.profile.firstName.uppercased(),
            accountType: "Current",
            currency: "AED",
            status: "Active",
            openingDate: nil,
            relationship: "Single"
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    tabs

                    Divider()
                        .padding(.top, 25)

                    nicknameSection
                        .padding(.top, 18)

                    Divider()
                        .padding(.top, 22)

                    VStack(alignment: .leading, spacing: 28) {
                        detailRow(label: "Account Type", value: details.accountType)
                        detailRow(label: "Account Currency", value: details.currency)
                        detailRow(
                            label: "Status",
                            value: details.status,
                            valueColor: Color(hex: 0x19A64A)
                        )
                        detailRow(label: "Opening Date", value: formattedOpeningDate)
                        detailRow(label: "Relationship", value: details.relationship)
                        copyableRow(
                            label: "Account Number",
                            value: session.profile.accountNumber,
                            field: .accountNumber
                        )
                        copyableRow(
                            label: "IBAN",
                            value: session.profile.iban,
                            field: .iban
                        )
                    }
                    .padding(.top, 26)

                    MashreqOutlineButton(
                        title: copiedField == .allDetails
                            ? "Account details copied"
                            : "Copy all account details"
                    ) {
                        copy(allAccountDetails, field: .allDetails)
                    }
                    .padding(.horizontal, 42)
                    .padding(.top, 30)
                    .padding(.bottom, 42)
                }
                .padding(.horizontal, 24)
                .padding(.top, 150)
            }

            MashreqHeader(
                title: "Your Account Details",
                height: 128,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 18,
                titleFontWeight: .medium
            )
            .zIndex(10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-your-account-details")
    }

    /// В референсе это один tab-strip; неактивные вкладки сохранены визуально,
    /// но не подменяют запрошенный экран фиктивными данными.
    private var tabs: some View {
        HStack(alignment: .top, spacing: 0) {
            tabLabel("Account\nDetails", isSelected: true)
            tabLabel("Facilities", isSelected: false)
            tabLabel("Balances", isSelected: false)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabLabel(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.mashreq(size: 17, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? MashreqTheme.orangeDeep : MashreqTheme.secondaryInk)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity)
            .frame(height: 67, alignment: .top)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(MashreqTheme.orangeDeep)
                        .frame(width: 76, height: 2)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var nicknameSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Nickname")
                    .font(.mashreq(size: 15, weight: .regular))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                Text(details.nickname)
                    .font(.mashreq(size: 18, weight: .semibold))
                    .foregroundStyle(MashreqTheme.orangeDeep)
            }

            Spacer()

            // В референсе справа стоит фирменная edit-иконка. Здесь оставлена
            // текстовая команда, чтобы не заменять её несоответствующим SF Symbol.
            Text("Edit")
                .font(.mashreq(size: 13, weight: .medium))
                .foregroundStyle(MashreqTheme.orangeDeep)
        }
    }

    private func detailRow(
        label: String,
        value: String,
        valueColor: Color = MashreqTheme.ink
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.mashreq(size: 15, weight: .regular))
                .foregroundStyle(MashreqTheme.secondaryInk)
            Text(value)
                .font(.mashreq(size: 18, weight: .semibold))
                .foregroundStyle(valueColor)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func copyableRow(
        label: String,
        value: String,
        field: CopiedAccountField
    ) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            detailRow(label: label, value: value)

            Button(copiedField == field ? "Copied" : "Copy") {
                copy(value, field: field)
            }
            .font(.mashreq(size: 16, weight: .semibold))
            .foregroundStyle(MashreqTheme.orangeDeep)
            .buttonStyle(.plain)
            .padding(.bottom, 1)
            .accessibilityLabel("Copy \(label)")
        }
    }

    private var formattedOpeningDate: String {
        guard let openingDate = details.openingDate else { return "Not available" }
        return openingDate.formatted(
            Date.FormatStyle()
                .day(.defaultDigits)
                .month(.abbreviated)
                .year(.defaultDigits)
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }

    private var allAccountDetails: String {
        [
            "Account holder: \(session.profile.fullName)",
            "Nickname: \(details.nickname)",
            "Account type: \(details.accountType)",
            "Currency: \(details.currency)",
            "Status: \(details.status)",
            "Opening date: \(formattedOpeningDate)",
            "Relationship: \(details.relationship)",
            "Account number: \(session.profile.accountNumber)",
            "IBAN: \(session.profile.iban)"
        ].joined(separator: "\n")
    }

    private func copy(_ value: String, field: CopiedAccountField) {
        UIPasteboard.general.string = value
        copiedField = field

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if copiedField == field {
                copiedField = nil
            }
        }
    }
}

private enum CopiedAccountField: Equatable {
    case accountNumber
    case iban
    case allDetails
}
