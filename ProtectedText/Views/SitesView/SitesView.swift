//
//  SitesView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI

struct SitesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    @EnvironmentObject private var sitesManager: SitesManager
    
    @State private var searchFieldPresented = false
        
    var filteredSites: [Site] {
        if sitesManager.sites.isEmpty {
            return []
        } else if sitesViewModel.searchText.isEmpty {
            return sitesManager.sites
        } else {
            let searchQuery = sitesViewModel.searchText.lowercased()
            return sitesManager.sites.filter { site in
                let siteIdMatch = site.id.lowercased().contains(searchQuery)
                let noteMatch = (sitesManager.siteTabsData[site.id] ?? []).contains { $0.localizedCaseInsensitiveContains(searchQuery) }
                return siteIdMatch || noteMatch
            }
        }
    }
    
    var body: some View {
        SitesList()
#if os(iOS)
            .toolbar(content: IOSToolbarBuilder)
#elseif os(macOS)
            .toolbar(content: MacOSToolbarBuilder)
#endif
            .navigationTitle("Sites")
            .searchable(text: $sitesViewModel.searchText, isPresented: $searchFieldPresented, placement: .sidebar)
            .listStyle(.sidebar)
            .refreshable {
                Task {
                    await sitesManager.fetchDataForAllSites()
                }
            }
            .sheet(isPresented: $sitesViewModel.showNewSiteSheet) {
                AddSiteView()
            }
            .sheet(isPresented: $sitesViewModel.showSiteInfoSheet) {
                SiteInfoView(site: sitesViewModel.selectedSiteForInfoSheet!)
            }
            .sheet(isPresented: $sitesViewModel.showEditSiteSheet) {
                EditSiteView(site: sitesViewModel.selectedSiteForEditSheet!)
            }
            .sheet(isPresented: $sitesViewModel.showSettingsSheet) {
                //            SettingsView()
            }
            .alert("Alert!", isPresented: $sitesViewModel.showDeleteSiteAlert) {
                Button("Cancel", role: .cancel) {
                }
                Button("Delete", role: .destructive) {
                    guard let siteForDeletion = sitesViewModel.selectedSiteForDeletion else { return }
                    Task { await sitesManager.deleteSite(siteForDeletion) }
                    sitesViewModel.selectedSiteForDeletion = nil
                }
            } message: {
                Text("Are you sure you want to delete this site?\nThis action is irreversible. Ones deleted, the text data in this site can not be recovered.")
            }
            .alert("Alert!", isPresented: $sitesViewModel.showRemoveSiteAlert) {
                Button("Cancel", role: .cancel) {
                }
                Button("Remove", role: .destructive) {
                    guard let siteForRemoval = sitesViewModel.selectedSiteForRemoval else { return }
                    Task { await sitesManager.removeSite(siteForRemoval) }
                    sitesViewModel.selectedSiteForRemoval = nil
                }
            } message: {
                Text("Removing a site does not delete it, only removes it from Protected Text application. Password for this site will all so be removed. You can add this site back with the password.\nIf you loose access to the password, you will not be able to access you site!")
            }
            .alert("Alert!", isPresented: $sitesViewModel.showArchiveSiteAlert) {
                Button("Cancel", role: .cancel) {
                }
                Button("Archive", role: .destructive) {
                    guard let siteForArchival = sitesViewModel.selectedSiteForArchival else { return }
                    sitesManager.toggleArchiveStatus(for: siteForArchival)
                }
            } message: {
                Text("Password for this site will be removed from Protected Text. You can add this site back with the password.\nIf you loose access to the password, you will not be able to access you site!")
            }
    }
    
    @ViewBuilder
    func SitesList() -> some View {
        let selectionBinding: Binding<Site?> = Binding {
            sitesManager.selectedSite
        } set: { newVal in
            DispatchQueue.main.async {
                sitesManager.updateSelectedSite(selected: newVal)
            }
        }
        
#if os(iOS)
        if DeviceType.isIphone {
            List(filteredSites) { site in
                SiteItemView(site: site)
            }
            .listStyle(.sidebar)
        } else {
            List(filteredSites, selection: selectionBinding) { site in
                NavigationLink(value: site) {
                    SiteItemView(site: site)
                }
            }
        }
#elseif os(macOS)
        List(filteredSites, selection: selectionBinding) { site in
            NavigationLink(value: site) {
                SiteItemView(site: site)
            }
        }
#endif
    }
    
#if os(iOS)
    @ToolbarContentBuilder
    func IOSToolbarBuilder() -> some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                Button(action: sitesViewModel.openNewSiteSheet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Site")
                    }
                    .fontWeight(.bold)
                }
                Spacer()
                Button(action: {
                    searchFieldPresented = true
                }, label: {
                    Image(systemName: "magnifyingglass")
                })
                Divider().frame(height: 30)
                Button(action: {
                    sitesViewModel.showSettingsSheet = true
                }, label: {
                    Image(systemName: "switch.2")
                })
                Divider().frame(height: 30)
                Menu {
                    Button("Clear Keychain", systemImage: "trash") {
                        KeychainManager.clearKeychain()
                    }
                    Button("Clear SwiftData", systemImage: "swiftdata") {
                        modelContext.container.deleteAllData()
                    }
//                            Picker("Sort Order", selection: $sortOrder) {
//                                Text("Ascending")
//                                .tag(true)
//                                Text("Descending")
//                                .tag(false)
//                            }
//                            .pickerStyle(.inline)
//                            Picker("Sort Games By", selection: $sortBy) {
//                                Text("Name")
//                                    .tag(SortOrder.name)
//                                Text("Score")
//                                    .tag(SortOrder.score)
//                                Text("Game Created Time")
//                                    .tag(SortOrder.createdOn)
//                                Text("Last Played Time")
//                                    .tag(SortOrder.lastPlayedOn)
//                            }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
#endif

#if os(macOS)
    @ToolbarContentBuilder
    func MacOSToolbarBuilder() -> some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("Clear Keychain", systemImage: "trash") {
                    KeychainManager.clearKeychain()
                }
                Button("Clear SwiftData", systemImage: "swiftdata") {
                    modelContext.container.deleteAllData()
                }
//                    Picker("Sort Games By", selection: $sortBy) {
//                        Text("Name")
//                            .tag(SortOrder.name)
//                        Text("Score")
//                            .tag(SortOrder.score)
//                        Text("Game Created Time")
//                            .tag(SortOrder.createdOn)
//                        Text("Last Played Time")
//                            .tag(SortOrder.lastPlayedOn)
//                    }
//                    .pickerStyle(.inline)
//                    Picker("Sort Order", selection: $sortOrder) {
//                        Text("Ascending")
//                            .tag(true)
//                        Text("Descending")
//                            .tag(false)
//                    }
//                    .pickerStyle(.inline)
                Button("Statistics", systemImage: "chart.bar") {
//                        openWindow(id: "statistics")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
#endif
}

#Preview {
    ContentView()
        .environmentObject(SitesViewModel.shared)
}
