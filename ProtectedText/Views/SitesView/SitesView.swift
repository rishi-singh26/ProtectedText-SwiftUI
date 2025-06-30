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
        Group {
            SitesList()
#if os(iOS)
                .toolbar(content: IOSToolbarBuilder)
#elseif os(macOS)
                .toolbar(content: MacOSToolbarBuilder)
#endif
        }
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
            }
        } message: {
            Text("Are you sure you want to delete this site?\nThis action is irreversible. Ones deleted, the text in this site can not be recovered.")
        }
    }
    
    @ViewBuilder
    func SitesList() -> some View {
        let selectionBinding: Binding<Site?> = Binding {
            sitesManager.selectedSite
        } set: { newVal in
            DispatchQueue.main.async {
                sitesManager.selectedSite = newVal
            }
        }

        Group {
#if os(iOS)
            List(filteredSites) { site in
                NavigationLink {
                    TabsListView(site: site)
                } label: {
                    SiteItemView(site: site)
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
