//
//  SiteData.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation

struct SiteData: Codable {
    let eContent: String
    let isNew: Bool
    let currentDBVersion: Int
    let expectedDBVersion: Int
}
