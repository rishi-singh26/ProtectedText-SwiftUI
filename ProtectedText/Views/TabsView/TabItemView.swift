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
    
    var tab: String
    var index: Int
    
    var body: some View {
        Text(tab.getTabTitle())
            .lineLimit(2)
            .swipeActions(edge: .trailing) {
                DeleteBtnBuilder()
            }
            .contextMenu(menuItems: {
                DeleteBtnBuilder()
            })
    }
    
    @ViewBuilder
    func DeleteBtnBuilder() -> some View {
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
