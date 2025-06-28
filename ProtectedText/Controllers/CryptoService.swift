//
//  CryptoService.swift
//  ProtectedText
//
//  Created by Rishi Singh on 26/06/25.
//

import Foundation
import CommonCrypto
import CryptoKit

enum CryptoError: Error, LocalizedError {
    case invalidBase64
    case invalidFormat
    case utf8DecodingFailed
    case encryptionFailed
    case decryptionFailed
    case verificationFailed
    case randomBytesFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidBase64:
            return "The provided encrypted data is not valid Base64."
        case .invalidFormat:
            return "The encrypted data format is invalid or not OpenSSL compatible."
        case .utf8DecodingFailed:
            return "Failed to decode decrypted data into UTF-8 string. Please check your password"
        case .encryptionFailed:
            return "Encryption failed due to an internal error."
        case .decryptionFailed:
            return "Decryption failed due to an internal error."
        case .verificationFailed:
            return "Verification of cecrypted data failed. Please check your password"
        case .randomBytesFailed(let status):
            return "Failed to generate secure random bytes. OSStatus: \(status)"
        }
    }
}

class CryptoService {

    static func evpBytesToKey(password: Data, salt: Data, keyLen: Int, ivLen: Int) -> Data {
        var derived = Data()
        var block = Data()

        while derived.count < keyLen + ivLen {
            var hasher = Insecure.MD5()
            hasher.update(data: block)
            hasher.update(data: password)
            hasher.update(data: salt)
            block = Data(hasher.finalize())
            derived.append(block)
        }

        return derived.prefix(keyLen + ivLen)
    }

    static func encryptOpenSSL(plaintext: String, password: String) throws -> String {
        let salt = try randomSalt(length: 8)
        let keyIv = evpBytesToKey(password: password.data(using: .utf8)!, salt: salt, keyLen: 32, ivLen: 16)

        let key = keyIv.prefix(32)
        let iv = keyIv.subdata(in: 32..<48)

        let encrypted = try aesEncrypt(plaintext: plaintext, key: key, iv: iv)
        let prefix = Data("Salted__".utf8) + salt
        let fullData = prefix + encrypted

        return fullData.base64EncodedString()
    }

    static func decryptOpenSSL(base64Encrypted: String, password: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: base64Encrypted) else {
            throw CryptoError.invalidBase64
        }

        let prefix = encryptedData.prefix(8)
        guard String(data: prefix, encoding: .utf8) == "Salted__" else {
            throw CryptoError.invalidFormat
        }

        let salt = encryptedData.subdata(in: 8..<16)
        let cipherText = encryptedData.advanced(by: 16)
        let keyIv = evpBytesToKey(password: password.data(using: .utf8)!, salt: salt, keyLen: 32, ivLen: 16)

        let key = keyIv.prefix(32)
        let iv = keyIv.subdata(in: 32..<48)

        return try aesDecrypt(cipherText: cipherText, key: key, iv: iv)
    }

    static func randomSalt(length: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status != errSecSuccess {
            throw CryptoError.randomBytesFailed(status)
        }
        return Data(bytes)
    }

    static func computeSHA512(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA512.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func aesEncrypt(plaintext: String, key: Data, iv: Data) throws -> Data {
        let data = Data(plaintext.utf8)
        let encrypted = crypt(data: data, key: key, iv: iv, operation: kCCEncrypt)
        guard !encrypted.isEmpty else {
            throw CryptoError.encryptionFailed
        }
        return encrypted
    }

    private static func aesDecrypt(cipherText: Data, key: Data, iv: Data) throws -> String {
        let decryptedData = crypt(data: cipherText, key: key, iv: iv, operation: kCCDecrypt)
        guard !decryptedData.isEmpty else {
            throw CryptoError.decryptionFailed
        }
        guard let result = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.utf8DecodingFailed
        }
        return result
    }

    private static func crypt(data: Data, key: Data, iv: Data, operation: Int) -> Data {
        let keyLength = key.count
        let dataLength = data.count
        var outLength = Int(0)

        var outBytes = [UInt8](repeating: 0, count: dataLength + kCCBlockSizeAES128)
        let result = CCCrypt(CCOperation(operation),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             [UInt8](key), keyLength,
                             [UInt8](iv),
                             [UInt8](data), dataLength,
                             &outBytes, outBytes.count,
                             &outLength)

        guard result == kCCSuccess else {
            return Data()
        }

        return Data(bytes: outBytes, count: outLength)
    }
}
