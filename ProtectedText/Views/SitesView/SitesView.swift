//
//  SitesView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI
import SwiftData

struct SitesView: View {
    @Query(
        filter: #Predicate<Site> { !$0.archived },
        sort: [SortDescriptor(\Site.createdAt, order: .reverse)]
    )
    private var sites: [Site]
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    @EnvironmentObject private var sitesManager: SitesManager
    
    @State private var searchFieldPresented = false
        
    var filteredSites: [Site] {
        if sitesViewModel.searchText.isEmpty {
            return sites
        } else {
            let searchQuery = sitesViewModel.searchText.lowercased()
            return sites.filter { site in
                let siteIdMatch = site.id.lowercased().contains(searchQuery)
                let noteMatch = (sitesManager.siteTabsData[site.id] ?? []).contains { $0.localizedCaseInsensitiveContains(searchQuery) }
                return siteIdMatch || noteMatch
            }
        }
    }
    
    var body: some View {
        Group {
#if os(iOS)
            IOSViewBuilder()
#elseif os(macOS)
            SitesList()
#endif
        }
        .onAppear(perform: {
            Task {
                await sitesManager.fetchNotesForAllSites(sites)
            }
        })
        .navigationTitle("Protected Text")
        .searchable(text: $sitesViewModel.searchText, isPresented: $searchFieldPresented, placement: .sidebar)
        .listStyle(.sidebar)
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
//                Task {
//                    guard let addressForDeletion = addressesViewModel.selectedAddForDeletion else { return }
//                    await addressesController.deleteAddressFromServer(address: addressForDeletion)
//                    addressesViewModel.selectedAddForDeletion = nil
//                }
            }
        } message: {
            Text("Are you sure you want to delete this address? This action is irreversible. Ones deleted, this address and the associated messages can not be restored.")
        }
    }
    
    @ViewBuilder
    func SitesList() -> some View {
        Group {
#if os(iOS)
            List(
                selection: Binding(get: {
                    sitesManager.selectedSite
                }, set: { newVal in
                    DispatchQueue.main.async {
                        sitesManager.selectedSite = newVal
                    }
                })
            ) {
                ForEach(filteredSites) { site in
                    NavigationLink {
                        Text("Notes List")
//                        MessagesView(address: site)
                    } label: {
                        SiteItemView(site: site)
                    }
                }
            }
#elseif os(macOS)
            List(
                selection: Binding(get: {
                    sitesManager.selectedSite
                }, set: { newVal in
                    DispatchQueue.main.async {
                        withAnimation {
                            sitesManager.selectedSite = newVal
                        }
                    }
                })
            ) {
                ForEach(filteredSites) { site in
                    NavigationLink(value: site) {
                        SiteItemView(site: site)
                    }
                }
            }
#endif
        }
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSViewBuilder() -> some View {
        SitesList()
            .toolbar {
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
                            Button("Quick 3x3 Game", systemImage: "3.square") {
        //                        addGame(3)
                            }
                            Button("Quick 4x4 Game", systemImage: "4.alt.square") {
        //                        addGame(4)
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
    }
#endif
}

#Preview {
    ContentView()
        .environmentObject(SitesViewModel.shared)
}
