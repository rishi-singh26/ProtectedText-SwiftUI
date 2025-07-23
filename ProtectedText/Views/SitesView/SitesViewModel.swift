//
//  SitesViewModel.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import Foundation

class SitesViewModel: ObservableObject {
    static let shared = SitesViewModel()
    
    @Published var searchText = ""
    @Published var showNewSiteSheet = false
    
    @Published var showDeleteSiteAlert = false
    @Published var selectedSiteForDeletion: Site?
    func deleteSite(site: Site) {
        selectedSiteForDeletion = site
        showDeleteSiteAlert = true
    }
    
    @Published var showRemoveSiteAlert = false
    @Published var selectedSiteForRemoval: Site?
    func removeSite(site: Site) {
        selectedSiteForRemoval = site
        showRemoveSiteAlert = true
    }
    
    @Published var showArchiveSiteAlert = false
    @Published var selectedSiteForArchival: Site?
    func archiveSite(site: Site) {
        selectedSiteForArchival = site
        showArchiveSiteAlert = true
    }

    @Published var errorAlertMessage = ""
    
    @Published var showSiteInfoSheet = false
    @Published var selectedSiteForInfoSheet: Site?
    func showSiteInfoSheet(site: Site) {
        selectedSiteForInfoSheet = site
        showSiteInfoSheet = true
    }
    
    @Published var showEditSiteSheet = false
    @Published var selectedSiteForEditSheet: Site?
    func showEditSiteSheet(site: Site) {
        selectedSiteForEditSheet = site
        showEditSiteSheet = true
    }
    
    @Published var showSettingsSheet = false
        
    func openNewSiteSheet() {
        showNewSiteSheet = true
    }
}
