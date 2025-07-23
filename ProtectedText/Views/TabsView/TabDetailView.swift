//
//  TabDetailView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 30/06/25.
//

import SwiftUI

struct TabDetailView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var tabsViewModel: TabsViewModel
    
    var body: some View {
        Group {
            if let selectedSite = sitesManager.selectedSite, let selectedTabIndex = sitesManager.selectedTabIndex, sitesManager.siteTabsData[selectedSite.id] != nil {
                TabEditorView(site: selectedSite, tabIndex: selectedTabIndex)
            } else {
                Text("No Data")
            }
        }
#if os(macOS)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button {
                        tabsViewModel.showFileExporter = true
                    } label: {
                        Label("Save to file", systemImage: "square.and.arrow.down")
                    }
                    .help("Save tab content into a .txt file")
                    
                    ShareLink(item: (sitesManager.siteTabsData[sitesManager.selectedSite?.id ?? ""] ?? []).item(at: sitesManager.selectedTabIndex ?? 0) ?? "")
                        .help("Share tab content")
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(sitesManager.selectedSite == nil || sitesManager.selectedTabIndex == nil)
                
                if let selectedSite = sitesManager.selectedSite, sitesManager.selectedTabIndex != nil {
                    Text(sitesManager.saveTracker == selectedSite.id ? "Saving..." : sitesManager.changeTracker.contains(selectedSite.id) ? "Not Saved" : "Saved")
                        .foregroundStyle(.gray)
                        .help("Tab status")
                }
            }
        }
#endif
    }
}

struct TabEditorView: View {
    var site: Site
    var tabIndex: Int
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sitesManager: SitesManager
    @EnvironmentObject var tabsViewModel: TabsViewModel
    
    @FocusState private var isFocused: Bool
    
    var tabContentBinding: Binding<String> {
        Binding {
            sitesManager.siteTabsData[site.id]?.item(at: tabIndex) ?? ""
        } set: { newVal in
            var tabsData = sitesManager.siteTabsData
            tabsData[site.id]![tabIndex] = newVal
            sitesManager.siteTabsData = tabsData
            sitesManager.changeTracker.insert(site.id)
        }
    }
    
    var body: some View {
        TextEditor(text: tabContentBinding)
            .font(.system(.body, design: .monospaced))
            .focused($isFocused)
            .navigationTitle(tabContentBinding.wrappedValue.getTabTitle(length: 10))
#if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
#elseif os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    if sitesManager.saveTracker == site.id {
                        ProgressView()
                            .controlSize(.small)
                    }
                    if isFocused {
                        Button("Done") {
                            isFocused = false
                            Task {
                                handleSiteSaveResult(result: await sitesManager.saveSite(site))
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarTitleMenu {
                    Button {
                        tabsViewModel.showFileExporter = true
                    } label: {
                        Label("Save to file", systemImage: "square.and.arrow.down")
                    }
                    .help("Save tab content into a .txt file")
                    ShareLink(item: tabContentBinding.wrappedValue)
                        .help("Share tab content")
                    Divider()
                    Button(role: .destructive) {
                        tabsViewModel.showTabDeletionConfirmation2(index: tabIndex)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .help("Delete tab")
                }
            }
            .confirmationDialog(
                "Are you sure you want to delete this tab?",
                isPresented: $tabsViewModel.showTabDeletionConfirmation2,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: deleteTab)
            }
            .alert("Alert!", isPresented: .constant(tabsViewModel.errorAlertMessage2 != nil)) {
                Button("Ok", role: .cancel) {
                    tabsViewModel.errorAlertMessage2 = nil
                }
            } message: {
                Text(tabsViewModel.errorAlertMessage2 ?? "")
            }
#endif
            .fileExporter(
                isPresented: $tabsViewModel.showFileExporter,
                document: TextFileDocument(text: tabContentBinding.wrappedValue),
                contentType: .plainText,
                defaultFilename: "\(tabContentBinding.wrappedValue.getTabTitle(length: 10)).txt"
            ) { result in
                print(result)
            }
    }
    
    private func deleteTab() {
        tabsViewModel.selectedTabIndexForDeletion2 = nil
        Task {
            handleSiteSaveResult(result: await sitesManager.deleteTab(at: tabIndex, from: site))
        }
    }
    
    private func handleSiteSaveResult(result: (Bool, String)) {
        let (status, message) = result
        guard !status else { return }
        
        if message == KOPResult {
            tabsViewModel.errorAlertMessage2 = KOPMessage
            return
        }
        tabsViewModel.errorAlertMessage2 = message
    }
}
