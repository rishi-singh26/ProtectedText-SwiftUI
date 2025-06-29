//
//  SiteData.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation

struct SiteData: Codable {
    var eContent: String
    var isNew: Bool
    var currentDBVersion: Int
    var expectedDBVersion: Int
}
