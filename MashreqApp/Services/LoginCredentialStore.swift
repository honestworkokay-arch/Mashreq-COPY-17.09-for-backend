import Foundation
import Security

enum LoginCredentialStoreError: LocalizedError {
    case encodingFailed
    case keychainStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            "The password could not be encoded."
        case .keychainStatus(let status):
            "Secure password storage failed (\(status))."
        }
    }
}

/// Пароль хранится только в системном Keychain и не попадает ни в SwiftData,
/// ни в UserDefaults, ни в логи приложения.
enum LoginCredentialStore {
    private static let service = "com.madina.mashreqdemo.login"
    private static let account = "registered-user-password"

    static func savePassword(_ password: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw LoginCredentialStoreError.encodingFailed
        }

        let lookup = baseQuery
        // Accessibility задаётся при создании. При смене пароля обновляем
        // только секрет, не ослабляя и не пересоздавая существующий item.
        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(lookup as CFDictionary, update as CFDictionary)

        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw LoginCredentialStoreError.keychainStatus(updateStatus)
        }

        var insert = lookup
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let insertStatus = SecItemAdd(insert as CFDictionary, nil)
        guard insertStatus == errSecSuccess else {
            throw LoginCredentialStoreError.keychainStatus(insertStatus)
        }
    }

    static func verify(password: String) throws -> Bool {
        guard let candidate = password.data(using: .utf8) else { return false }

        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess, let stored = result as? Data else {
            throw LoginCredentialStoreError.keychainStatus(status)
        }
        return constantTimeEquals(stored, candidate)
    }

    static func deletePassword() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw LoginCredentialStoreError.keychainStatus(status)
        }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    /// Сравнение без раннего выхода уменьшает утечку информации по времени.
    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for (left, right) in zip(lhs, rhs) {
            difference |= left ^ right
        }
        return difference == 0
    }
}
