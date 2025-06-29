//
//  SitesManager.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation
import SwiftData

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
    @Published var message: String?
    
    @Published var selectedSite: Site? = nil
    @Published var selectedNoteIndex: Int? = nil
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        do {
            self.passwords = try KeychainManager.retrieveKeychainData()
        } catch {
            switch error {
            case KeychainError.itemNotFound:
                break
            default:
                showError(with: error.localizedDescription)
            }
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
            try updateSite(site, with: response)
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
    
    func createSite(_ site: Site, with tabs: [String]) throws {
        modelContext.insert(site)
        try saveChanges()
        siteTabsData[site.id] = tabs
    }
    
    func getSites(withId siteURL: String) throws -> [Site] {
        let fetchDescriptor = FetchDescriptor<Site>(
            predicate: #Predicate { $0.id == siteURL }
        )
        
        let matchingSites = try modelContext.fetch(fetchDescriptor)
        
        return matchingSites
    }
    
    private func updateSite(_ site: Site, with data: SiteData) throws {
        site.expectedDBVersion = data.expectedDBVersion
        site.currentDBVersion = data.currentDBVersion
        site.siteContent = data.eContent
        site.isNew = data.isNew
        
        try saveChanges()
        
        guard let password = passwords[site.id] else { return }
        do {
            let tabs: [String] = try site.decrypt(with: password)
            siteTabsData[site.id] = tabs
        } catch {
            print(error.localizedDescription)
            // Dont show error here, this function runs at app launch
            // If decryption failed, we will attempt decryption again when user selects to view this site
            // show("Error!", with: error.localizedDescription)
        }
    }
    
    private func saveChanges() throws {
        try modelContext.save()
    }
    
    /// Clears any error message
    func clearMessage() {
        self.message = nil
    }
    
    func showError(with message: String) {
        self.message = message
    }
}
