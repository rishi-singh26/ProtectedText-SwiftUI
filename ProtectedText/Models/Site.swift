//
//  Site.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftData
import Foundation

enum SiteSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Site.self]
    }
    
    @Model
    class Site: Identifiable, Codable {
        var id: String = ""
        var isNew: Bool = true
        var currentDBVersion: Int = 0
        var expectedDBVersion: Int = 0
        /// Encrypted site content
        var siteContent: String = ""
        var archived: Bool = false
        var createdAt: Date = Date.now
        
        @Transient
        var siteURL: String { id }
        
        init(
            siteURL: String,
            new: Bool,
            currentDBVersion: Int,
            expectedDBVersion: Int,
            siteContent: String,
        ) {
            self.id = siteURL
            self.isNew = new
            self.currentDBVersion = currentDBVersion
            self.expectedDBVersion = expectedDBVersion
            self.siteContent = siteContent
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, new, currentDBVersion, expectedDBVersion, siteContent, archived, createdAt
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            isNew = try container.decode(Bool.self, forKey: .new)
            currentDBVersion = try container.decode(Int.self, forKey: .currentDBVersion)
            expectedDBVersion = try container.decode(Int.self, forKey: .expectedDBVersion)
            siteContent = try container.decode(String.self, forKey: .siteContent)
            archived = try container.decode(Bool.self, forKey: .archived)
            
            if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
               let date = createdAtString.toDate() {
                createdAt = date
            } else {
                createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.now
            }
        }
            
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(isNew, forKey: .new)
            try container.encode(currentDBVersion, forKey: .currentDBVersion)
            try container.encode(expectedDBVersion, forKey: .expectedDBVersion)
            try container.encode(siteContent, forKey: .siteContent)
            try container.encode(archived, forKey: .archived)
            
            // Format dates as ISO8601 strings
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        }
    }
}

typealias Site = SiteSchemaV1.Site


// MARK: - Crypto functions
extension Site {
    /// Returns decrypted string along with tab seperator hash
    func decrypt(with password: String) throws -> String {
        // If encrypted site content is empty, no use decrypting it, return the empty string
        guard !siteContent.isEmpty else { return siteContent }
        // attempt decryption
        var decryptedData = try CryptoService.decryptOpenSSL(
            base64Encrypted: siteContent,
            password: password
        )
        // verify decrypted data
        let siteURlHash = CryptoService.computeSHA512(id)
        guard decryptedData.hasSuffix(siteURlHash) else {
            throw CryptoError.verificationFailed
        }
        // remove siteURLHash from decrypted data
        decryptedData.removeLast(siteURlHash.count)
        // data with tab seperator
        return decryptedData
    }
    
    /// Returns an arry of tabs
    func decrypt(with password: String) throws -> [String] {
        let decryptedWithSeperator: String = try decrypt(with: password)
        // omittingEmptySubsequences is set to false, when decryptedwith seperator is empty string, it will return array with emppty [""]
        // if you want [] empty array, set it to true
        return decryptedWithSeperator.split(separator: KTabSeperatorHash, omittingEmptySubsequences: false).map { String($0) }
    }
    
    /// returns (eContent, currentHashContent, initHashContent)
    func encrypt(with password: String, and tabs: [String]) throws -> (String, String) {
        let allContent = tabs.joined(separator: KTabSeperatorHash)
        let newHashContent = Site.computeSHA(content: allContent, password: password, dbVersion: expectedDBVersion)
        let siteURlHash = CryptoService.computeSHA512(id)
        let eContent = try CryptoService.encryptOpenSSL(plaintext: allContent + siteURlHash, password: password) // encrypt(content + siteHash)
        return (eContent, newHashContent)
    }
    
    static func computeSHA(content: String, password: String, dbVersion: Int) -> String {
        if dbVersion == 1 {
            return CryptoService.computeSHA512(content)
        } else if dbVersion == 2 {
            return CryptoService.computeSHA512(content + CryptoService.computeSHA512(password)) + "2"
        } else {
            return ""
        }
    }
}

// MARK: - API functions
extension Site {
    func save(with password: String, and tabs: [String]) async throws -> (SaveDataResponse, String) {
        let (encrypted, currentHash) = try encrypt(with: password, and: tabs)
        let tabsWithSeperator: String = try decrypt(with: password)
        let initHash = Site.computeSHA(content: isNew ? "" : tabsWithSeperator, password: isNew ? "" : password, dbVersion: currentDBVersion)
        // Save the data into protectedtext.com server
        let result = try await APIManager.saveData(
            endPoint: id,
            initHashContent: initHash,
            currentHashContent: currentHash,
            encryptedContent: encrypted
        )
        
        return (result, encrypted)
    }
    
    func delete(with password: String) async throws -> DeleteSiteResponse {
        let tabsWithSeperator: String = try decrypt(with: password)
        let initHash = Site.computeSHA(content: isNew ? "" : tabsWithSeperator, password: isNew ? "" : password, dbVersion: currentDBVersion)
        // Delete the site from protectedtext.com server
        let result = try await APIManager.deleteData(
            endPoint: id,
            initHashContent: initHash
        )
        
        return result
    }
}
