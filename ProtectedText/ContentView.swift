//
//  ContentView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 26/06/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    @EnvironmentObject private var appController: AppController

    var body: some View {
        Group {
#if os(iOS)
            if DeviceType.isIphone {
                IPhoneNavigtionBuilder()
            } else {
                IPadNavigationBuilder()
            }
#elseif os(macOS)
            MacOSViewBuilder()
#endif
        }
        .alert("Alert!", isPresented: .constant(sitesManager.alertMessage != nil)) {
            Button("Ok") {
                sitesManager.clearAlert()
            }
        } message: {
            Text(sitesManager.alertMessage ?? "")
        }
        .sheet(isPresented: $sitesManager.showPasswordInput) {
            UnlockSiteView()
        }
    }
    
#if os(macOS)
    @ViewBuilder
    private func MacOSViewBuilder() -> some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                SitesView()
                NewSiteBtn()
            }
            .navigationSplitViewColumnWidth(min: 195, ideal: 195, max: 340)
        } content: {
            TabsView()
                .navigationSplitViewColumnWidth(min: 290, ideal: 290, max: 400)
        } detail: {
            TabDetailView()
                .navigationSplitViewColumnWidth(min: 440, ideal: 440)
        }
    }
#endif
}

// MARK: - Navigation View Builders
extension ContentView {
#if os(iOS)
    @ViewBuilder
    private func IPhoneNavigtionBuilder() -> some View {
        NavigationStack(path: $appController.path) {
            SitesView()
                .navigationDestination(for: Site.self, destination: handleAddressNavigation)
                .navigationDestination(for: String.self, destination: handleMessageNavigation)
        }
    }
    
    @ViewBuilder
    private func IPadNavigationBuilder() -> some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            SitesView()
        } detail: {
            NavigationStack(path: $appController.path) {
                TabsView()
                    .navigationDestination(for: String.self, destination: handleMessageNavigation)
            }
        }
    }
    
    private func handleAddressNavigation(site: Site) -> some View {
        TabsView()
    }
    
    private func handleMessageNavigation(tabData: String) -> some View {
        TabDetailView()
    }
    
#elseif os(macOS)
    @ViewBuilder
    private func MacNavigationBuilder() -> some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                SitesView()
                NewSiteBtn()
            }
            .navigationSplitViewColumnWidth(min: 195, ideal: 195, max: 340)
        } content: {
            TabsView()
                .navigationSplitViewColumnWidth(min: 290, ideal: 290, max: 400)
        } detail: {
            TabDetailView()
                .navigationSplitViewColumnWidth(min: 440, ideal: 440)
        }
    }
#endif
}

#if os(macOS)
private struct NewSiteBtn: View {
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack {
            Button(action: sitesViewModel.openNewSiteSheet, label: {
                HStack(alignment: .center, spacing: 2) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.primary)
                    Text("New Site")
                        .foregroundStyle(.primary)
                        .padding(.leading, 4)
                        .lineLimit(1)
                }
                .foregroundStyle(isHovering ? Color.primary : Color.gray)
                .onHover(perform: { value in
                    isHovering = value
                })
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            })
            .buttonStyle(.plain)
            .keyboardShortcut(.init("n", modifiers: [.command, .shift]))
            
            Spacer()
        }
    }
}
#endif

#Preview {
    ContentView()
        .environmentObject(SitesViewModel.shared)
        .modelContainer(for: Site.self, inMemory: true)
}
