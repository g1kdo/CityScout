import Foundation
import Security

class KeychainService {

    // Define the unique identifiers for your partner session key
    private static let service = Bundle.main.bundleIdentifier ?? "com.yourapp.PartnerAuth"
    private static let sessionKeyAccount = "PartnerSessionKey"
    private static let emailAccount = "PartnerEmail"

    // MARK: - Generic Save/Update Function

    /// Saves or updates a data item in the Keychain.
    private static func save(key: String, account: String) -> OSStatus {
        guard let data = key.data(using: .utf8) else { return errSecInvalidData }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        var status = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            // Item already exists, update it
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        case errSecItemNotFound:
            // Item not found, add it
            let newItem: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // Access control
            ]
            status = SecItemAdd(newItem as CFDictionary, nil)
        default:
            break
        }
        
        // Print useful debug info if needed
        if status != errSecSuccess {
            print("Keychain Save Error: \(SecCopyErrorMessageString(status, nil) ?? "Unknown Error")")
        }
        
        return status
    }

    // MARK: - Generic Retrieve Function

    /// Retrieves a data item from the Keychain.
    private static func retrieve(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            return nil
        }

        guard let data = item as? Data, let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    // MARK: - Partner-Specific Public Methods

    // --- Session Key ---
    static func savePartnerSessionKey(_ key: String) {
        _ = save(key: key, account: sessionKeyAccount)
    }

    static func retrievePartnerSessionKey() -> String? {
        return retrieve(account: sessionKeyAccount)
    }

    // --- Partner Email (Needed for Re-sign-in) ---
    static func savePartnerEmail(_ email: String) {
        // Save the email too, as signIn requires both email and password (the session key)
        _ = save(key: email, account: emailAccount)
    }

    static func retrievePartnerEmail() -> String? {
        return retrieve(account: emailAccount)
    }
    
    // --- Clear All Partner Credentials ---
    static func clearPartnerCredentials() {
        let queryKey: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKeyAccount
        ]
        SecItemDelete(queryKey as CFDictionary)

        let queryEmail: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailAccount
        ]
        SecItemDelete(queryEmail as CFDictionary)
    }
}