//
//  ProtectedTextApp.swift
//  ProtectedText
//
//  Created by Rishi Singh on 26/06/25.
//

import SwiftUI
import SwiftData

@main
struct ProtectedTextApp: App {
    var sharedModelContainer: ModelContainer
    @StateObject private var sitesManager: SitesManager
    @StateObject private var sitesViewModel = SitesViewModel()
    @StateObject private var tabsViewModel = TabsViewModel()
    @StateObject private var appController = AppController()
    
    init() {
        let container: ModelContainer
        do {
            let schema = Schema([Site.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, migrationPlan: SiteMigrationPlan.self, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        self.sharedModelContainer = container
        _sitesManager = StateObject(wrappedValue: SitesManager(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sitesManager)
                .environmentObject(sitesViewModel)
                .environmentObject(tabsViewModel)
                .environmentObject(appController)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Site", action: sitesViewModel.openNewSiteSheet)
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save Selected Site") {
                    Task {
                        let (status, message) = await sitesManager.saveSelectedSite()
                        if !status {
                            if message == KOPResult {
                                sitesManager.showAlert(with: KOPMessage)
                                return
                            }
                            sitesManager.showAlert(with: message)
                        }
                    }
                }
                .disabled(sitesManager.selectedSite == nil)
                .keyboardShortcut("s", modifiers: [.command])
            }
            CommandGroup(after: .saveItem) {
                Button("Close Selected Tab") {
                    sitesManager.selectedTabIndex = nil
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }
            CommandGroup(after: .saveItem) {
                Button("Close Selected Site") {
                    sitesManager.selectedSite = nil
                }
                .keyboardShortcut("w", modifiers: [.command])
            }
        }
    }
}
