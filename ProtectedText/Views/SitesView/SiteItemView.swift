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
    @EnvironmentObject private var appController: AppController
    
    let site: Site
    
    var body: some View {
        Group {
#if os(iOS)
            if DeviceType.isIphone {
                Button {
                    let status: Bool = sitesManager.updateSelectedSite(selected: site)
                    if status {
                        if DeviceType.isIphone {
                            appController.path.append(site)
                        } else {
                            appController.path = NavigationPath()
                        }
                    }
                } label: {
                    SiteItemTile()
                }
            } else {
                SiteItemTile()
            }
#elseif os(macOS)
            SiteItemTile()
#endif
        }
        .swipeActions(edge: .leading) {
            SiteInfoBtn()
        }
        .swipeActions(edge: .trailing) {
            DeleteBtn()
            ArchiveBtn()
        }
        .contextMenu(menuItems: {
            RefreshBtn(addTint: false)
            SiteInfoBtn(addTint: false)
            Divider()
            ArchiveBtn(addTint: false)
            DeleteBtn(addTint: false)
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
                } else if sitesManager.passwords[site.id] == nil {
                    Image(systemName: "lock")
                        .controlSize(.small)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
    
    @ViewBuilder
    func SiteInfoBtn(addTint: Bool = true) -> some View {
        Button {
            sitesViewModel.showSiteInfoSheet(site: site)
        } label: {
            Label("Site Info", systemImage: "info.square")
        }
        .tint(addTint ? .yellow : nil)
    }
    
    @ViewBuilder
    func DeleteBtn(addTint: Bool = true) -> some View {
        Button(role: .destructive) {
            sitesViewModel.deleteSite(site: site)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(addTint ? .red : nil)
    }
    
    @ViewBuilder
    func ArchiveBtn(addTint: Bool = true) -> some View {
        Button {
            Task {
                sitesManager.toggleArchiveStatus(for: site)
            }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(addTint ? .indigo : nil)
    }
    
    @ViewBuilder
    func RefreshBtn(addTint: Bool = true) -> some View {
        Button {
            Task {
                await sitesManager.refreshTabs(for: site)
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise.circle")
        }
        .tint(addTint ? .blue : nil)
    }
}


#Preview {
    ContentView()
            .environmentObject(SitesViewModel.shared)
}
