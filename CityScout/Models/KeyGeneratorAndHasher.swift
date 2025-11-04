//
//  KeyGeneratorAndHasher.swift
//  CityScout
//
//  Created by Umuco Auca on 04/11/2025.
//

import Foundation
import CryptoKit


struct KeyGeneratorAndHasher {
    
    // Recommended length for a highly secure session key
    private static let keyLength = 32
    
    /// Generates a cryptographically strong random secret key.
    /// - Returns: A 32-character secure secret string.
    static func generateSecretKey() -> String {
        // Define the comprehensive character set
        let allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-="
        
        // Use a secure random data generator
        var data = Data(count: keyLength)
        
        // Use the SecureRandom API to fill the data with random bytes
        // In a production iOS app, use SecRandomCopyBytes
        let status = SecRandomCopyBytes(kSecRandomDefault, keyLength, data.withUnsafeMutableBytes { $0.baseAddress! })
        
        guard status == errSecSuccess else {
            // Fallback for simulation, but failure should halt activation in production
            return UUID().uuidString + UUID().uuidString
        }

        // Map the random bytes to the allowed characters
        let charArray = Array(allowedCharacters)
        let key = data.map { byte in
            let index = Int(byte) % charArray.count
            return charArray[index]
        }
        
        return String(key)
    }

    /// Generates a unique salt and computes the hash of the secret key.
    ///
    /// - Parameter secretKey: The plain-text secret key (to be stored in Keychain/Secure Storage).
    /// - Returns: A tuple containing the base64-encoded salt and the hash string.
    static func hashSecretKey(_ secretKey: String) -> (salt: String, hash: String)? {
        // 1. Generate a unique, random salt (using SHA256 for a short, unique value in this simulation)
        let saltData = Data(SHA256.hash(data: UUID().uuidString.data(using: .utf8)!))
        let saltString = saltData.base64EncodedString()
        
        // 2. Hash the key with the salt (Simulated Hashing - should be Argon2/bcrypt)
        guard let keyData = (secretKey + saltString).data(using: .utf8) else { return nil }
        // Hashing the combined key and salt using SHA256
        let hash = SHA256.hash(data: keyData)
        // Convert the hash digest to a hexadecimal string for storage
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        return (salt: saltString, hash: hashString)
    }
}
