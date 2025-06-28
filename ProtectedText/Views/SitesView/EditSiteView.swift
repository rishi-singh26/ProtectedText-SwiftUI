//
//  EditSiteView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI

struct EditSiteView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var sitesViewModel: SitesViewModel
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var repeatNewPassword: String = ""
    
    var site: Site
    
    init(site: Site) {
        self.site = site
        _currentPassword = State(wrappedValue: "site.password")
    }

    var body: some View {
#if os(iOS)
        IOSEditAddress()
#elseif os(macOS)
        MacOSEditAddress()
#endif
    }
    
    @ViewBuilder
    func IOSEditAddress() -> some View {
        NavigationView {
            Form {
                Section {
                    TextField("Current Password", text: $currentPassword)
                }
                
                Section {
                    TextField("New Password", text: $newPassword)
                    TextField("Repeat New Password", text: $repeatNewPassword)
                }
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        
                    } label: {
                        Text("Done")
                            .font(.headline)
                    }

                }
//#endif
            }
        }
    }
    
    @ViewBuilder
    func MacOSEditAddress() -> some View {
        VStack {
            HStack {
                Text("Change Password")
                    .font(.title.bold())
                Spacer()
            }
            .padding()
            ScrollView {
                Form {
                    MacCustomSection {
                        HStack {
                            Text("Current Password")
                                .frame(width: 200, alignment: .leading)
                            Spacer()
                            TextField("", text: $currentPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    MacCustomSection {
                        VStack {
                            HStack {
                                Text("New Password")
                                    .frame(width: 200, alignment: .leading)
                                Spacer()
                                TextField("", text: $newPassword)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Repeat New Password")
                                    .frame(width: 200, alignment: .leading)
                                Spacer()
                                TextField("", text: $repeatNewPassword)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                        } label: {
                            Text("Done")
                                .font(.headline)
                        }
                        
                    }
                    //#endif
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SitesViewModel.shared)
}
