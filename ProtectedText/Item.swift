//
//  Item.swift
//  ProtectedText
//
//  Created by Rishi Singh on 26/06/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
