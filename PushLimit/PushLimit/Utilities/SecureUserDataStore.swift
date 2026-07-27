import Foundation
import Security

/// Stores sensitive fitness / profile payloads in the iOS Keychain instead of UserDefaults.
enum SecureUserDataStore {
    private static let service = "com.rcmckain.pushlimit.user-data"

    enum StoreError: Error {
        case encodingFailed
        case unhandled(OSStatus)
    }

    static func set(_ data: Data, forKey account: String) throws {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(baseQuery as CFDictionary)

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StoreError.unhandled(status)
        }
    }

    static func data(forKey account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    static func setString(_ string: String, forKey account: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw StoreError.encodingFailed
        }
        try set(data, forKey: account)
    }

    static func string(forKey account: String) -> String? {
        guard let data = data(forKey: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(forKey account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func removeAll(forKeys accounts: [String]) {
        accounts.forEach { remove(forKey: $0) }
    }
}
