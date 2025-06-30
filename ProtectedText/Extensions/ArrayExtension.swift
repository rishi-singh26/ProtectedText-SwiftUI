//
//  ArrayExtension.swift
//  ProtectedText
//
//  Created by Rishi Singh on 30/06/25.
//

import Foundation

extension Array {
    // Method to safely check if an index is valid
    func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && index < self.count
    }
    
    // Method to safely access an item at a given index
    func item(at index: Int) -> Element? {
        guard isValidIndex(index) else {
            return nil
        }
        return self[index]
    }
    
    @discardableResult
    mutating func safeRemove(at index: Int) -> Bool {
        guard isValidIndex(index) else {
            return false
        }
        
        // Safely remove the item at the valid index and return it
        self.remove(at: index)
        return true
    }
}
