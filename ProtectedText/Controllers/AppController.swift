//
//  AppController.swift
//  ProtectedText
//
//  Created by Rishi Singh on 21/07/25.
//

import SwiftUI

class AppController: ObservableObject {
    static let shared = AppController()
    
    /// Used for navigation on iOS only
    @Published var path = NavigationPath()
}
