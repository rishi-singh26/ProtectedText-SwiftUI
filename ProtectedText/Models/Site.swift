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
            createdAt: Date,
        ) {
            self.id = siteURL
            self.isNew = new
            self.currentDBVersion = currentDBVersion
            self.expectedDBVersion = expectedDBVersion
            self.siteContent = siteContent
            self.createdAt = createdAt
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
        
        func decrypt(with password: String) throws -> [String] {
            do {
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
                
                // remove metadata
                decryptedData.removeLast(siteURlHash.count)
                
                // retrive tab data
                let tabSeperator = "-- tab separator --"
                let tabSeperatorHash = CryptoService.computeSHA512(tabSeperator)
                return decryptedData.split(separator: tabSeperatorHash).map { String($0) }
            } catch {
                throw error
            }
        }
    }
}

typealias Site = SiteSchemaV1.Site
