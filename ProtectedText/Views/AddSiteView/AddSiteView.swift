//
//  AddSiteView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI

struct AddSiteView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var controller = AddSiteViewModel()
    @EnvironmentObject private var sitesManager: SitesManager

    var body: some View {
        Group {
#if os(iOS)
            IOSAddAddressForm()
#else
            MacOSAddAddressForm()
#endif
        }
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSAddAddressForm() -> some View {
        NavigationView {
            Form {
                
            }
            .navigationTitle("Add Site")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if controller.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                        } label: {
                            Text("Save")
                                .font(.headline)
                        }
                    }
                }
                
            }
            .alert(isPresented: $controller.showErrorAlert) {
                Alert(title: Text("Alert!"), message: Text(controller.errorMessage))
            }
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    private func MacOSAddAddressForm() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Site")
                    .font(.title3.bold())
                Spacer()
                if controller.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding([.top, .horizontal], 25)
            List {
                MacCustomSection {
                    VStack(alignment: .leading) {
                        Text("Enter site URL")
                        HStack {
                            TextField("/yoursite", text: $controller.siteURL)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.send)
                                .onChange(of: controller.siteURL, { _, _ in
                                    controller.resetSiteData()
                                })
                                .onSubmit(submitSite)
                            Button("Go", action: submitSite)
                                .buttonStyle(.borderedProminent)
                                .disabled(controller.siteURL.isEmpty)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .padding(.top)
                
                if let siteData = controller.siteData, !siteData.isNew {
                    MacCustomSection {
                        VStack(alignment: .leading) {
                            Text("This site (**\(controller.siteURL)**) is already occupied.\n\nIf this is your site enter the password used to encrypt this site, or you can try using different site.")
                            PasswordField(password: $controller.password, placeholder: "Password")
                            ShouldSavePasswordToggle(shouldSave: $controller.shouldSavePass)
                                .padding(.vertical, 6)
                            HStack {
                                Spacer()
                                Button("Add Site", action: handleAddSite)
                                    .disabled(controller.password.isEmpty)
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .listRowSeparator(.hidden)
                }
                
                if let siteData = controller.siteData, siteData.isNew {
                    MacCustomSection {
                        VStack(alignment: .leading) {
                            Text("**Great! This site does not exist**.\n\nIn order to take ownership, of this site, create a password.\nIf you forget this password, you will loose access to this site.")
                            PasswordField(password: $controller.password, placeholder: "Password")
                            PasswordField(password: $controller.repeatPassword, placeholder: "Repeat Password")
                            ShouldSavePasswordToggle(shouldSave: $controller.shouldSavePass)
                                .padding(.vertical, 6)
                            HStack {
                                Spacer()
                                Button("Generate Password", action: controller.generateRandomPass)
                                Button("Create Site") {
                                    
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    
                    GroupBox {
                        HStack(alignment: .center) {
                            Image(systemName: "info.square.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .background(RoundedRectangle(cornerRadius: 5).fill(.white))
                            Spacer()
                            Text("Password ones set can be reset only if the origin password is known. If you loose your password, you will loose access to your site.")
                        }
                        .padding(6)
                    }
                    .background(RoundedRectangle(cornerRadius: 5).fill(.yellow.opacity(0.3)))
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .listStyle(.plain)
        }
        .frame(height: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
#endif
    
    private func submitSite() {
        Task {
            do {
                try await controller.handleSubmitSite()
            } catch {
                sitesManager.show("Alert", with: error.localizedDescription)
            }
        }
    }
    
    private func handleAddSite() {
        guard let siteData = controller.siteData else { return }
        do {
            let newSite = Site(
                siteURL: controller.siteURL,
                new: siteData.isNew,
                currentDBVersion: siteData.currentDBVersion,
                expectedDBVersion: siteData.expectedDBVersion,
                siteContent: siteData.eContent,
                createdAt: Date.now
            )

            sitesManager.createSite(newSite, with: controller.password)
            
            if controller.shouldSavePass {
                var updatedPasswords = sitesManager.passwords
                updatedPasswords[controller.siteURL] = controller.password
                try KeychainManager.saveKeychainData(updatedPasswords)
                sitesManager.passwords = updatedPasswords
            }
        } catch {
            sitesManager.show("Error", with: error.localizedDescription)
        }
    }
}

struct ShouldSavePasswordToggle: View {
    @State private var showPopOver: Bool = false
    @Binding var shouldSave: Bool
    
    var body: some View {
        GroupBox {
            HStack {
                Toggle("Save password", isOn: $shouldSave)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                Button("Info") {
                    showPopOver = true
                }
                .popover(isPresented: $showPopOver) {
                    Text("When you enable this option, your password will be securely stored in your device’s Apple Keychain. Access to the stored password is protected by your device's authentication — such as Face ID, Touch ID, or passcode.\n\nYour password never leaves your device, and only you can access it. We use Apple’s security framework to ensure your data is encrypted and protected by user presence verification.\n\nYou can turn this off at any time, and your saved password will be removed from the device.")
                        .padding()
                    
                    Text("Your password will be securely stored in Apple Keychain and protected by Face ID, Touch ID, or your device passcode. It stays on your device and can only be accessed by you.\n\nYou can turn this off at any time, and your saved password will be removed from the device.")
                        .padding()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var showPopover = false
    VStack(spacing: 0) {
        HStack {
            Text("Add Site")
                .font(.title3.bold())
            Spacer()
        }
        .padding([.top, .horizontal], 25)
        List {
            MacCustomSection {
                VStack(alignment: .leading) {
                    Text("Enter site URL")
                    HStack {
                        TextField("/yoursite", text: .constant(""))
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.send)
                        Button {
                            
                        } label: {
                            Text("Go")
                                .padding(.horizontal)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .padding(.top)
                
            MacCustomSection {
                VStack(alignment: .leading) {
                    Text("This site (**\\sitename**) is already occupied. If this is your site enter the password used to encrypt this site, or you can try using different site.")
                    PasswordField(password: .constant(""), placeholder: "Password")
                    GroupBox {
                        HStack {
                            Toggle("Save password", isOn: .constant(false))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            Button("Info") {
                                showPopover = true
                            }
                            .popover(isPresented: $showPopover) {
                                Text("Some more content")
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    HStack {
                        Spacer()
                        Button("Add Site") {
                            
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Text("**Great! This site does not exist**.\n\nIn order to take ownership, of this site, create a password.\nIf you forget this password, you will loose access to this site.")
                    PasswordField(password: .constant(""), placeholder: "Password")
                    PasswordField(password: .constant(""), placeholder: "Repeat Password")
                    HStack {
                        Spacer()
                        Button("Generate Password") {
                            
                        }
                        Button("Create Site") {
                            
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            GroupBox {
                HStack(alignment: .center) {
                    Image(systemName: "info.square.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .background(RoundedRectangle(cornerRadius: 5).fill(.white))
                    Spacer()
                    Text("Password ones set can be reset only if the origin password is known. If you loose your password, you will loose access to your site.")
                }
                .padding(6)
            }
            .background(RoundedRectangle(cornerRadius: 5).fill(.yellow.opacity(0.3)))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .listStyle(.plain)
    }
    .frame(height: 400)
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
            }
        }
    }
}
