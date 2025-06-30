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
        SiteItemTile()
            .swipeActions(edge: .leading) {
                SiteInfoBtn()
            }
            .swipeActions(edge: .trailing) {
                DeleteBtn()
                ArchiveBtn()
            }
            .contextMenu(menuItems: {
                RefreshBtn()
                SiteInfoBtn()
                Divider()
                ArchiveBtn()
                DeleteBtn()
            })
    }
    
    @ViewBuilder
    func SiteItemTile() -> some View {
        HStack {
            Label {
                Text(site.id)
                    .font(.body.bold())
            } icon: {
                Image(systemName: "link")
            }
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
    
    @ViewBuilder
    func SiteInfoBtn() -> some View {
        Button {
            sitesViewModel.showSiteInfoSheet(site: site)
        } label: {
            Label("Site Info", systemImage: "info.square")
        }
        .tint(.yellow)
    }
    
    @ViewBuilder
    func DeleteBtn() -> some View {
        Button(role: .destructive) {
            sitesViewModel.deleteSite(site: site)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
    }
    
    @ViewBuilder
    func ArchiveBtn() -> some View {
        Button {
            Task {
                sitesManager.toggleArchiveStatus(for: site)
            }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(.indigo)
    }
    
    @ViewBuilder
    func RefreshBtn() -> some View {
        Button {
            Task {
                await sitesManager.refreshTabs(for: site)
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise.circle")
        }
    }
}


#Preview {
    ContentView()
            .environmentObject(SitesViewModel.shared)
}
