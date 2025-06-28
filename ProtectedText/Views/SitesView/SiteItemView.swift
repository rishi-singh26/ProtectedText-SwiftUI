//
//  SiteItemView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI

struct SiteItemView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    
    let site: Site
    
    var body: some View {
        HStack {
            Image(systemName: "tray")
                .foregroundColor(.accentColor)
            HStack {
                Text(site.id)
                Spacer()
                if !site.archived {
                    if sitesManager.loadTracker[site.id] == true {
                        ProgressView()
                            .controlSize(.small)
                    } else if sitesManager.errorTracker[site.id] != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                    } else if let count = sitesManager.siteTabsData[site.id]?.count  {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
            .swipeActions(edge: .leading) {
                Button {
                    sitesViewModel.showSiteInfoSheet(site: site)
                } label: {
                    Label("Address Info", systemImage: "info.square")
                }
                .tint(.yellow)
                Button {
//                    Task {
//                        await addressesController.refreshMessages(for: address)
//                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                .tint(.blue)
                Button {
                    sitesViewModel.showEditSiteSheet(site: site)
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    sitesViewModel.deleteSite(site: site)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                Button {
//                    Task {
//                        await addressesController.toggleAddressStatus(address)
//                    }
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.indigo)
            }
            .contextMenu(menuItems: {
                Button {
//                    Task {
//                        await addressesController.refreshMessages(for: address)
//                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                Button {
                    sitesViewModel.showSiteInfoSheet(site: site)
                } label: {
                    Label("Address Info", systemImage: "info.circle")
                }
                Button {
                    sitesViewModel.showEditSiteSheet(site: site)
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                Divider()
                Button {
//                    Task {
//                        await addressesController.toggleAddressStatus(address)
//                    }
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(role: .destructive) {
                    sitesViewModel.deleteSite(site: site)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            })
    }
}


#Preview {
    ContentView()
            .environmentObject(SitesViewModel.shared)
}
