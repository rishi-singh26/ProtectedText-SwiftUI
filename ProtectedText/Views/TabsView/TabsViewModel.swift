//
//  TabsViewModel.swift
//  ProtectedText
//
//  Created by Rishi Singh on 29/06/25.
//

import Foundation

class TabsViewModel: ObservableObject {
    @Published var errorAlertMessage: String? = nil
    @Published var searchText = ""
    
    @Published var selectedTabIndexForDeletion: Int? = nil
    @Published var showTabDeletionConfirmation: Bool = false
    func showTabDeletionConfirmation(index: Int) {
        selectedTabIndexForDeletion = index
        showTabDeletionConfirmation = true
    }
    
    // Tab detail view properties
    @Published var showFileExporter: Bool = false
    @Published var errorAlertMessage2: String? = nil
    
    @Published var selectedTabIndexForDeletion2: Int? = nil
    @Published var showTabDeletionConfirmation2: Bool = false
    func showTabDeletionConfirmation2(index: Int) {
        selectedTabIndexForDeletion2 = index
        showTabDeletionConfirmation2 = true
    }
}
