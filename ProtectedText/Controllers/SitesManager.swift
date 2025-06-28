//
//  SitesManager.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class SitesManager: ObservableObject {
    // SwiftData modelContainer and modelContext
    private var modelContext: ModelContext
    
    @Published var loadTracker: [String: Bool] = [:] // siteURL: Bool
    @Published var errorTracker: [String: String] = [:] // siteURL: Error message
    @Published var siteTabsData: [String: [String]] = [:] // siteURL: tab data
    
    // Passwords retrived from keystore
    @Published var passwords: [String: String] = [:]
    
    // For showing error or success message to user
    @Published var title: String = "Alert"
    @Published var message: String?
    
    @Published var selectedSite: Site? = nil
    @Published var selectedNoteIndex: Int? = nil
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        do {
            self.passwords = try KeychainManager.retrieveKeychainData()
        } catch {
            show("Error", with: error.localizedDescription)
        }
    }
    
    func fetchNotesForAllSites(_ sites: [Site]) async {
        defer { loadTracker = [:] }
        guard !sites.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for site in sites {
                let id = site.id
                loadTracker[id] = true
                
                group.addTask {
                    await self.fetchNotes(for: site)
                }
            }
        }
    }
    
    func fetchNotes(for site: Site) async {
        do {
            let response = try await APIManager.getData(endPoint: site.id)
            self.loadTracker.removeValue(forKey: site.id)
            self.errorTracker.removeValue(forKey: site.id)
            updateSite(site, with: response)
        } catch {
            self.loadTracker.removeValue(forKey: site.id)
            self.errorTracker[site.id] = error.localizedDescription
        }
    }
    
    func refreshNotes(for site: Site) async {
        self.loadTracker[site.id] = true
        self.errorTracker.removeValue(forKey: site.id)
        await fetchNotes(for: site)
    }
    
    func createSite(_ site: Site, with password: String) {
        modelContext.insert(site)
        saveChanges()
        
        do {
            let tabs = try site.decrypt(with: password)
            siteTabsData[site.id] = tabs
        } catch {
            show("Error!", with: error.localizedDescription)
        }
    }
    
    private func updateSite(_ site: Site, with data: SiteData) {
        site.expectedDBVersion = data.expectedDBVersion
        site.currentDBVersion = data.currentDBVersion
        site.siteContent = data.eContent
        site.isNew = data.isNew
        
        saveChanges()
        
        guard let password = passwords[site.id] else { return }
        do {
            let tabs = try site.decrypt(with: password)
            siteTabsData[site.id] = tabs
        } catch {
            // Dont show error here, this function runs at app launch
            // If decryption failed, we will attempt decryption again when user selects to view this site
            // show("Error!", with: error.localizedDescription)
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            self.show("Alert", with: error.localizedDescription)
        }
    }
    
    /// Clears any error message
    func clearMessage() {
        self.message = nil
        self.title = "Alert"
    }
    
    func show(_ title: String, with message: String) {
        self.title = title
        self.message = message
    }
}
