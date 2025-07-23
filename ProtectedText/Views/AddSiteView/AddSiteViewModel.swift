//
//  AddSiteViewModel.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation
import SwiftUI

@MainActor
class AddSiteViewModel: ObservableObject {
    @Published var isLoading: Bool = false;
    // MARK: - Address variables
    @Published var siteURL: String = ""
    @Published var siteData: SiteData? = nil
    
    @Published var password: String = ""
    @Published var repeatPassword: String = ""
    @Published var shouldSavePass: Bool = true
    
    var disableAddSiteBtn: Bool {
        siteData == nil || password.isEmpty
    }
    
    var disableCreateSiteBtn: Bool {
        siteData == nil || password.isEmpty || password != repeatPassword || password.count < 6
    }
    
    // Error handlers
    @Published var errorText: String? = nil
    
    func handleSubmitSite() async throws {
        guard !siteURL.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Remove any extra slashes from the start and end of the string (only keep the first one)
            let trimmedInput = siteURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            siteURL = "/" + trimmedInput
            
            let data = try await APIManager.getData(endPoint: siteURL)
            withAnimation {
                siteData = data
            }
            resetPasswords()
        } catch {
            throw error
        }
    }
    
    func generateRandomPass() {
        let randomPass = String.generateRandomString(of: 12, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
        password = randomPass
        repeatPassword = randomPass
    }
    
    func resetSiteData() {
        siteData = nil
        resetPasswords()
    }
    
    private func resetPasswords() {
        password = ""
        repeatPassword = ""
    }
}
