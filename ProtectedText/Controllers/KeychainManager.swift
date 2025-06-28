//
//  KeychainManager.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation
import Security
import LocalAuthentication
import SwiftUI

enum KeychainError: Error, LocalizedError {
    case encodingError
    case decodingError
    case authenticationFailed(OSStatus)
    case itemNotFound
    case unexpectedData
    case accessControlCreationFailed
    case saveFailed(OSStatus)
    case unknown(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Failed to encode data."
        case .decodingError:
            return "Failed to decode data from Keychain."
        case .authenticationFailed(let status):
            return "Authentication failed with status: \(status)."
        case .itemNotFound:
            return "No item found in Keychain."
        case .unexpectedData:
            return "Unexpected data format."
        case .accessControlCreationFailed:
            return "Could not create access control object."
        case .saveFailed(let status):
            return "Failed to save data to Keychain with status: \(status)."
        case .unknown(let status):
            return "An unknown Keychain error occurred: \(status)."
        }
    }
}

class KeychainManager: ObservableObject {
    static private let service = "in.rishisingh.ProtectedText.sitepasswords"
    static private let account = "secureSitepasswords"

    // MARK: - Public Update Function
    static func updateKeyStoreData(withSecurity requireAuth: Bool = true) throws {
        do {
            let currentData = try retrieveKeychainData(useAuthentication: requireAuth)
            guard !currentData.isEmpty else { return }
            
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            try saveKeychainData(currentData, requireAuthentication: requireAuth)
        } catch {
            throw error
        }
    }

    // MARK: - Retrieval
    static func retrieveKeychainData(useAuthentication: Bool = true) throws -> [String: String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        if useAuthentication {
            let context = LAContext()
            context.localizedReason = "Authenticate to access secure data"
            query[kSecUseAuthenticationContext as String] = context
        }

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            } else {
                throw KeychainError.authenticationFailed(status)
            }
        }

        guard let data = item as? Data else {
            throw KeychainError.unexpectedData
        }

        do {
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            throw KeychainError.decodingError
        }
    }

    // MARK: - Save Data
    static func saveKeychainData(_ dict: [String: String], requireAuthentication: Bool = true) throws {
        guard let data = try? JSONEncoder().encode(dict) else {
            throw KeychainError.encodingError
        }

        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        if requireAuthentication {
            guard let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, nil) else {
                throw KeychainError.accessControlCreationFailed
            }
            attributes[kSecAttrAccessControl as String] = accessControl
        } else {
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - App Lifecycle

//    private func observeAppLifecycle() {
//        let center = NotificationCenter.default
//
//        #if os(iOS)
//        center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
//            Task { @MainActor in
//                self.showPrivacyOverlay = false
//                self.authenticateAndLoad()
//            }
//        }
//
//        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
//            Task { @MainActor in
//                self.data.removeAll()
//                self.showPrivacyOverlay = true
//            }
//        }
//        #elseif os(macOS)
//        center.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
//            Task { @MainActor in
//                self.showPrivacyOverlay = false
//                self.authenticateAndLoad()
//            }
//        }
//
//        center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
//            Task { @MainActor in
//                self.data.removeAll()
//                self.showPrivacyOverlay = true
//            }
//        }
//        #endif
//    }
//
//
//    func authenticateAndLoad() {
//        retrieveKeychainData { result in
//            self.data = result ?? [:]
//        }
//    }
}
