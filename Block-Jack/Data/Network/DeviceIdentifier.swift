//
//  DeviceIdentifier.swift
//  Block-Jack
//
//  Cihaza özgü kalıcı UUID yönetimi.
//  identifierForVendor app silindiğinde değişir,
//  bu yüzden Keychain'de kalıcı saklıyoruz.
//

import Foundation
import Security
import UIKit

enum DeviceIdentifier {
    
    private static let keychainKey = "com.blockjack.device-id"
    
    /// Kalıcı cihaz UUID'si. Keychain'de yoksa oluşturur ve kaydeder.
    static var deviceID: String {
        if let existing = readFromKeychain() {
            return existing
        }
        
        // Önce identifierForVendor dene
        let newID: String
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            newID = vendorID
        } else {
            newID = UUID().uuidString
        }
        
        saveToKeychain(newID)
        return newID
    }
    
    // MARK: - Keychain Operations
    
    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private static func saveToKeychain(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Önce sil (varsa)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Ekle
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
