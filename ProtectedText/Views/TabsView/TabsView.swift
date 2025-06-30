//
//  TabsView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 29/06/25.
//

import SwiftUI

#if os(macOS)
struct TabsView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var tabsViewModel: TabsViewModel
    
    var body: some View {
        Group {
            if let selectedSite = sitesManager.selectedSite {
                TabsListView(site: selectedSite)
            } else {
                Text("")
            }
        }
        .toolbar(content: MacOSToolbarBuilder)
    }
    
    @ToolbarContentBuilder
    func MacOSToolbarBuilder() -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                guard let site = sitesManager.selectedSite else { return }
                Task {
                    await sitesManager.refreshTabs(for: site)
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise.circle")
            }
            .disabled(sitesManager.selectedSite == nil)
            .help(
                sitesManager.selectedSite == nil
                    ? "Refresh selected site"
                    : "Refresh \(sitesManager.selectedSite!.id)"
            )
            
            Button(role: .destructive) {
                guard let selectedTabIndex = sitesManager.selectedTabIndex else { return }
                tabsViewModel.showTabDeletionConfirmation(index: selectedTabIndex)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(sitesManager.selectedSite == nil || sitesManager.selectedTabIndex == nil)
            .help("Delete selected tab")
            
            Button(action: addTab) {
                Label("Add Tab", systemImage: "square.and.pencil")
            }
            .disabled(sitesManager.selectedSite == nil)
            .help(
                sitesManager.selectedSite == nil
                    ? "Add tab"
                    : "Add tab to \(sitesManager.selectedSite!.id)"
            )
        }
    }
    
    func addTab() {
        guard let site = sitesManager.selectedSite else { return }
        Task {
            let (status, message) = await sitesManager.addTab(to: site)
            guard !status else { return }
            
            if message == KOPResult {
                tabsViewModel.errorAlertMessage = KOPMessage
                return
            }
            tabsViewModel.errorAlertMessage = message
        }
    }
}
#endif

struct TabsListView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var tabsViewModel: TabsViewModel
    
    var site: Site
    
    var tabs: [String] {
        let tabs = sitesManager.siteTabsData[site.id] ?? []
        if tabsViewModel.searchText.isEmpty {
            return tabs
        } else {
            let searchQuery = tabsViewModel.searchText.lowercased()
            return tabs.filter { tab in
                tab.lowercased().contains(searchQuery)
            }
        }
    }
    
    var body: some View {
        Group {
            if (tabs).isEmpty {
                Text("")
            } else {
                TabsList()
#if os(iOS)
                    .listStyle(.sidebar)
#elseif os(macOS)
                    .listStyle(.inset)
#endif
                    .refreshable {
                        Task { await sitesManager.refreshTabs(for: site) }
                    }
            }
        }
        .alert("Alert!", isPresented: $tabsViewModel.showTabDeletionConfirmation) {
            Button("Cancel", role: .cancel) {
                tabsViewModel.selectedTabIndexForDeletion = nil
            }
            Button("Delete", role: .destructive, action: deleteOneTab)
        } message: {
            Text(KTabDelMessage)
        }
        .alert("Alert!", isPresented: .constant(tabsViewModel.errorAlertMessage != nil)) {
            Button("Ok", role: .cancel) {
                tabsViewModel.errorAlertMessage = nil
            }
        } message: {
            Text(tabsViewModel.errorAlertMessage ?? "")
        }
        .searchable(text: $tabsViewModel.searchText)
        .navigationTitle(site.id)
#if os(iOS)
        .toolbar(content: {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .center) {
                    Button("Site Information", systemImage: "info.circle") {
//                        print(site.siteContent)
                    }
                    .help("Site information")
                    Spacer()
                    if sitesManager.saveTracker == site.id {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Text("\(tabs.count) Tab\(tabs.count < 2 ? "" : "s")")
                        .font(.footnote)
                    Spacer()
                    Button("Add Tab", systemImage: "square.and.pencil") {
                        Task {
                            handleSiteSaveResult(result: await sitesManager.addTab(to: site))
                        }
                    }
                    .help("Add tab to \(site.id)")
                }
            }
        })
#endif
    }
    
    @ViewBuilder
    func TabsList() -> some View {
        let selectionBinding: Binding<Int?> = Binding {
            sitesManager.selectedTabIndex
        } set: { newVal in
            DispatchQueue.main.async {
                sitesManager.selectedTabIndex = newVal
            }
        }

        Group {
#if os(iOS)
            List(Array(tabs.enumerated()), id: \.offset) { index, tab in
                NavigationLink {
                    TabEditorView(site: site, tabIndex: index)
                } label: {
                    TabItemView(tab: tab, index: index)
                }
            }
#elseif os(macOS)
            List(Array(tabs.enumerated()), id: \.offset, selection: selectionBinding) { index, tab in
                NavigationLink(value: index) {
                    TabItemView(tab: tab, index: index)
                }
            }
#endif
        }
    }
    
    private func deleteOneTab() {
        guard let index = tabsViewModel.selectedTabIndexForDeletion else {
            tabsViewModel.errorAlertMessage = "Tab index not available. Something wehn wrong!"
            return
        }
        tabsViewModel.selectedTabIndexForDeletion = nil
        Task {
            handleSiteSaveResult(result: await sitesManager.deleteTab(at: index, from: site))
        }
    }
    
    private func handleSiteSaveResult(result: (Bool, String)) {
        let (status, message) = result
        guard !status else { return }
        
        if message == KOPResult {
            tabsViewModel.errorAlertMessage = KOPMessage
            return
        }
        tabsViewModel.errorAlertMessage = message
    }
}

#Preview {
    Text("Hello, World!")
}
