//
//  ContentView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 26/06/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    
    @State private var siteURL = ""
    @State private var password = ""

    var body: some View {
        Group {
#if os(iOS)
            NavigationView {
                SitesView()
            }
#elseif os(macOS)
            MacOSViewBuilder()
#endif
        }
        .alert("Alert!", isPresented: .constant(sitesManager.message != nil)) {
            Button("Ok") {
                sitesManager.clearMessage()
            }
        } message: {
            Text(sitesManager.message ?? "")
        }
    }
    
#if os(macOS)
    @ViewBuilder
    func MacOSViewBuilder() -> some View {
        NavigationSplitView {
            VStack {
                NewSiteBtn()
                SitesView()
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 240, max: 340)
            .toolbar(content: MacOSToolbarBuilder)
        } content: {
            Group {
                if let _ = sitesManager.selectedSite {
                    Text("Notes List")
                } else {
                    Text("Please select a site to view notes")
                }
            }
        } detail: {
            Text("Select an item")
            TextField("site", text: $siteURL)
            TextField("password", text: $password)
            Button("Print data") {
                Task {
                    do {
                        let data = try await APIManager.getData(endPoint: siteURL)
                        print(data.currentDBVersion)
                        print(data.expectedDBVersion)
                        let decrypted = try CryptoService.decryptOpenSSL(base64Encrypted: data.eContent, password: password)
                        print(decrypted)
                        print(CryptoService.computeSHA512(siteURL))
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    func MacOSToolbarBuilder() -> some ToolbarContent {
        ToolbarItem {
            HStack(spacing: 0) {
                Button {
//                    openWindow(id: "newGame")
                } label: {
                    Label("Settings", systemImage: "gear")
                }
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
    }
#endif
}

#if os(macOS)
struct NewSiteBtn: View {
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    
    var body: some View {
        Button(action: sitesViewModel.openNewSiteSheet, label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("Add Site")
                        .foregroundStyle(.primary)
                        .padding(.leading, 4)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(6)
            }
        })
        .padding(.horizontal)
        .padding(.vertical, 5)
        .buttonStyle(.plain)
        .keyboardShortcut(.init("n", modifiers: [.command, .shift]))
    }
}
#endif

#Preview {
    ContentView()
        .environmentObject(SitesViewModel.shared)
        .modelContainer(for: Site.self, inMemory: true)
}
