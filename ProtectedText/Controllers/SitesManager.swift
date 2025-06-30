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
    
    @Published var sites: [Site] = []
    @Published var archivedSites: [Site] = []
    
    @Published var loadTracker: [String: Bool] = [:] // siteURL: Bool
    @Published var saveTracker: String = "" // siteURL
    @Published var errorTracker: [String: String] = [:] // siteURL: Error message
    @Published var siteTabsData: [String: [String]] = [:] // siteURL: tab data
    
    // Passwords retrived from keystore
    @Published var passwords: [String: String] = [:]
    
    // For showing error or success message to user
    @Published var alertMessage: String?
    
    // selected site will only be used for macOS app
    @Published var selectedSite: Site? = nil {
        willSet {
            selectedTabIndex = nil // reset tab selection on site selection change
//            if let site = newValue {
//                Task {
//                    await refreshTabs(for: site)
//                }
//            }
        }
    }
    // selected tab index will only be used for macOS app
    @Published var selectedTabIndex: Int? = nil
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        do {
            self.passwords = try KeychainManager.retrieveKeychainData()
            fetchSites()
        } catch {
            switch error {
            case KeychainError.itemNotFound, KeychainError.authenticationFailed:
                fetchSites()
                break
            default:
                showAlert(with: error.localizedDescription)
            }
        }
    }
    
    func fetchSites() {
        Task {
            do {
                // Fetch active sites
                let descriptor = FetchDescriptor<Site>(
                    predicate: #Predicate<Site> { !$0.archived },
                    sortBy: [SortDescriptor(\Site.createdAt, order: .reverse)]
                )
                sites = try modelContext.fetch(descriptor)
                
                // Fetch archived sites
                let archivedDescriptor = FetchDescriptor<Site>(
                    predicate: #Predicate<Site> { $0.archived },
                    sortBy: [SortDescriptor(\Site.createdAt, order: .reverse)]
                )
                archivedSites = try modelContext.fetch(archivedDescriptor)
                
                self.clearAlert()
                
                /// Fetch tabs for each site
                 await self.fetchDataForAllSites()
            } catch {
                self.showAlert(with: error.localizedDescription)
                print("Error fetching addresses: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchDataForAllSites() async {
        defer { loadTracker = [:] }
        guard !sites.isEmpty else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for site in sites {
                let id = site.id
                loadTracker[id] = true

                group.addTask {
                    await self.fetchTabs(for: site)
                }
            }
        }
    }
    
    func fetchTabs(for site: Site) async {
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
    
    func refreshTabs(for site: Site) async {
        self.loadTracker[site.id] = true
        self.errorTracker.removeValue(forKey: site.id)
        await fetchTabs(for: site)
    }
    
    func createSite(_ site: Site, with tabs: [String]) throws {
        modelContext.insert(site)
        fetchSites()
        siteTabsData[site.id] = tabs
        try saveChanges()
    }
    
    func deleteSite(_ site: Site) async {
        do {
            guard let password = passwords[site.id] else { return }
            let result = try await site.delete(with: password)
            if (result.status.lowercased() == "success") {
                modelContext.delete(site)
                fetchSites()
                siteTabsData.removeValue(forKey: site.id)
                passwords.removeValue(forKey: site.id)
                errorTracker.removeValue(forKey: site.id)
                loadTracker.removeValue(forKey: site.id)
                try saveChanges()
            } else {
                alertMessage = "Failed to delete site.\nIf this problem cotinues, please try deleting this site from [protectedtext.com\(site.id)](https://www.protectedtext.com\(site.id)"
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }
    
    func toggleArchiveStatus(for site: Site) {
        do {
            site.archived = !site.archived
            try saveChanges()
            fetchSites()
        } catch {
            errorTracker[site.id] = error.localizedDescription
            alertMessage = error.localizedDescription
        }
    }
    
    func addTab(to site: Site) async -> (Bool, String) {
        // Create a copy of siteTabsData
        var siteTabsDataCopy = siteTabsData
        
        // Early exit if data not available
        guard var tabs = siteTabsDataCopy[site.id] else { return (false, "Site tabs not available. Something wend wrong!") }
        
        // Add tab to copyied data
        tabs.append("")
        siteTabsDataCopy[site.id] = tabs
        
        // Save updated tabs to server
        let (status, message) = await saveSite(site, with: tabs)
        if status {
            // Update the siteTabsData ones saved successfully on server
            siteTabsData = siteTabsDataCopy
        }
        return (status, message)
    }
    
    func deleteSelectedTab() async -> (Bool, String) {
        // Early exit if no selected site or tab index
        guard let site = selectedSite else { return (false, "No site selected, please select a site.") }
        guard let selectedTabIndex = selectedTabIndex else { return (false, "Tab not selected. Please select a tab.") }
        return await deleteTab(at: selectedTabIndex, from: site)
    }
    
    func deleteTabFromSelectedSite(at index: Int) async -> (Bool, String) {
        // Early exit if no selected site or tab index
        guard let site = selectedSite else { return (false, "No site selected, please select a site.") }
        return await deleteTab(at: index, from: site)
    }
    
    func deleteTab(at index: Int, from site: Site) async -> (Bool, String) {
        // Create a copy of siteTabsData
        var siteTabsDataCopy = siteTabsData
        
        // Early exit if data not available
        guard var tabs = siteTabsDataCopy[site.id] else { return (false, "Site tabs not available. Something wend wrong!") }
        guard tabs.isValidIndex(index) else { return (false, "Selected tab not available. Something went wrong!") }
        
        // Remove tab from copyied data
        if tabs.count == 1 {
            tabs = [""] // when deleting last tab, only remove tab data
        } else {
            tabs.remove(at: index)
        }
        siteTabsDataCopy[site.id] = tabs
        
        // Save updated tabs to server
        let (status, message) = await saveSite(site, with: tabs)
        if status {
            // Update the siteTabsData ones saved successfully on server
            siteTabsData = siteTabsDataCopy
            // reset selectedTabIndex for the deleted tab
            self.selectedTabIndex = [index, index + 1, index - 1].first(where: { tabs.isValidIndex($0) }) ?? 0
        }
        return (status, message)
    }
    
    func saveSelectedSite() async -> (Bool, String) {
        guard let selectedSite = selectedSite else { return (false, "No site selected, please select a site") }
        return await saveSite(selectedSite)
    }
    
    func saveSite(_ site: Site) async -> (Bool, String) {
        guard let siteTabs = siteTabsData[site.id] else { return (false, "Site tabs not available. Something wend wrong!") }
        return await saveSite(site, with: siteTabs)
    }
    
    private func saveSite(_ site: Site, with tabs: [String]) async -> (Bool, String) {
        do {
            guard let password = passwords[site.id] else { return (false, "Site password not found") }
            
            saveTracker = site.id
            defer { saveTracker = "" }
            
            let (result, eContent) = try await site.save(with: password, and: tabs)
            
            if (result.status.lowercased() == "success") {
                site.isNew = false
                site.siteContent = eContent
                try saveChanges()
                return (true, "Site saved")
            }
            else if let message = result.message { // special messages from server
                return (false, message)
            }
            else if let expectedDBVersion = result.expectedDBVersion, site.expectedDBVersion < expectedDBVersion { // special messages from server
                // This will only happen for very old sites, very rare case
                site.expectedDBVersion = expectedDBVersion;
                try saveChanges()
                return await saveSite(site, with: tabs) // retry with newer version
            }
            else {
                return (false, KOPResult)
                // text was changed in the meantime, show dialog to reload data and show changes
            }
        } catch {
            return (false, error.localizedDescription)
        }
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
    func clearAlert() {
        self.alertMessage = nil
    }
    
    func showAlert(with message: String) {
        self.alertMessage = message
    }
}
