//
//  TabItemView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 30/06/25.
//

import SwiftUI

struct TabItemView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var tabsViewModel: TabsViewModel
    @EnvironmentObject private var appController: AppController
    
    var tab: String
    var index: Int
    
    var body: some View {
        Group {
#if os(iOS)
            Button {
                sitesManager.selectedTabIndex = index
                appController.path.append(tab)
            } label: {
                TabTileBuilder()
            }
            .buttonStyle(.plain)
#elseif os(macOS)
            TabTileBuilder()
#endif
        }
        .swipeActions(edge: .trailing) {
            DeleteBtnBuilder()
        }
        .contextMenu(menuItems: {
            DeleteBtnBuilder()
        })
    }
    
    @ViewBuilder
    private func TabTileBuilder() -> some View {
        Text(tab.getTabTitle())
            .lineLimit(2)
    }
    
    @ViewBuilder
    private func DeleteBtnBuilder() -> some View {
        Button(role: .destructive) {
            tabsViewModel.showTabDeletionConfirmation(index: index)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        .help("Delete")
    }
}

#Preview {
    Text("Hello World!")
}
