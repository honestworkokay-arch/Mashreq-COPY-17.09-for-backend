import Foundation
import SwiftData

/// Единственная локальная запись зарегистрированного владельца приложения.
/// Пароль намеренно отсутствует: секрет хранится отдельно в Apple Keychain.
@Model
final class RegisteredUser {
    var id: UUID
    var firstName: String
    var lastName: String
    var mobileNumber: String
    var email: String
    var iban: String
    var accountNumber: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        mobileNumber: String,
        email: String,
        iban: String,
        accountNumber: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.mobileNumber = mobileNumber
        self.email = email
        self.iban = iban
        self.accountNumber = accountNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(profile: UserProfile) {
        self.init(
            firstName: profile.firstName,
            lastName: profile.lastName,
            mobileNumber: profile.smsPhoneNumber,
            email: profile.email,
            iban: profile.iban,
            accountNumber: profile.accountNumber
        )
    }

    /// Преобразует запись базы в общий профиль, который уже используют
    /// Overview, Account Details, OTP и переводные экраны.
    var userProfile: UserProfile {
        UserProfile(
            firstName: firstName,
            lastName: lastName,
            iban: iban,
            accountNumber: accountNumber,
            email: email,
            smsPhoneNumber: mobileNumber,
            accountDetails: UserAccountDetails(
                nickname: firstName.uppercased(),
                accountType: "Current",
                currency: "AED",
                status: "Active",
                openingDate: createdAt,
                relationship: "Single"
            )
        )
    }

    /// Settings обновляет существующую строку вместо создания копий профиля.
    func update(from profile: UserProfile) {
        firstName = profile.firstName
        lastName = profile.lastName
        mobileNumber = profile.smsPhoneNumber
        email = profile.email
        iban = profile.iban
        accountNumber = profile.accountNumber
        updatedAt = .now
    }
}

enum RegistrationValidation {
    static func normalizedIBAN(_ value: String) -> String {
        value.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    static func accountDigits(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    static func phoneDigits(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    static func profileMessage(
        firstName: String,
        lastName: String,
        mobileNumber: String,
        email: String,
        iban: String,
        accountNumber: String
    ) -> String? {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "First name and last name are required."
        }
        guard phoneDigits(mobileNumber).count >= 7 else {
            return "Enter a valid mobile number."
        }
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            return "Enter a valid email address."
        }
        guard isValidUAEIBAN(iban) else {
            return "Enter a valid UAE IBAN."
        }
        guard (6...20).contains(accountDigits(accountNumber).count) else {
            return "Account number must contain 6–20 digits."
        }
        return nil
    }

    static func isValidUAEIBAN(_ value: String) -> Bool {
        let iban = normalizedIBAN(value)
        guard iban.count == 23, iban.hasPrefix("AE") else { return false }
        guard iban.dropFirst(2).allSatisfy(\.isNumber) else { return false }

        let rearranged = String(iban.dropFirst(4)) + String(iban.prefix(4))
        var remainder = 0
        for character in rearranged {
            let digits: String
            if let number = character.wholeNumberValue {
                digits = String(number)
            } else if let scalar = character.unicodeScalars.first {
                digits = String(Int(scalar.value) - 55)
            } else {
                return false
            }

            for digit in digits {
                guard let number = digit.wholeNumberValue else { return false }
                remainder = (remainder * 10 + number) % 97
            }
        }
        return remainder == 1
    }

    static func passwordMessage(_ password: String, confirmation: String) -> String? {
        guard password.count >= 8 else {
            return "Password must contain at least 8 characters."
        }
        guard password.rangeOfCharacter(from: .letters) != nil,
              password.rangeOfCharacter(from: .decimalDigits) != nil else {
            return "Password must contain letters and numbers."
        }
        guard password == confirmation else {
            return "Passwords do not match."
        }
        return nil
    }
}
