//
//  UnlockSiteView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 22/07/25.
//

import SwiftUI

struct UnlockSiteView: View {
    @EnvironmentObject private var sitesManager: SitesManager
    @EnvironmentObject private var appController: AppController
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var password: String = ""
    @State private var footerText: String = ""
    @FocusState private var isPassFieldFocused: Bool
    
    var body: some View {
        Group {
#if os(iOS)
            BuildIOSView()
#elseif os(macOS)
            BuildMacOSView()
#endif
        }
        .onAppear {
            isPassFieldFocused = true
        }
    }
    
#if os(macOS)
    @ViewBuilder
    private func BuildMacOSView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Enter Password")
                .font(.headline)
                .padding()
            MacCustomSection(header: "Password is needed to decrypt your site", footer: footerText) {
                BuildPasswordField(style: .roundedBorder)
            }
            .padding(.bottom, 10)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                DoneBtn()
            }
            ToolbarItem(placement: .cancellationAction) {
                CancelBtn()
            }
        }
    }
#endif
    
#if os(iOS)
    @ViewBuilder
    private func BuildIOSView() -> some View {
        NavigationView {
            Form {
                Section {
                    BuildPasswordField(style: .plain)
                } header: {
                    Text("Password is needed to decrypt your site")
                } footer: {
                    Text(footerText)
                }
            }
            .navigationTitle("Enter Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    DoneBtn()
                }
                ToolbarItem(placement: .cancellationAction) {
                    CancelBtn()
                }
            }
        }
    }
#endif
    
    @ViewBuilder
    private func BuildPasswordField<Style: TextFieldStyle>(style: Style) -> some View {
        PasswordField(password: $password, placeholder: "Password", textFieldStyle: style)
            .onSubmit {
                submit()
            }
            .onChange(of: password) { _, _ in
                !footerText.isEmpty ? footerText = "" : nil
            }
    }
    
    @ViewBuilder
    private func DoneBtn() -> some View {
        Button("Done", action: submit)
    }
    
    @ViewBuilder
    private func CancelBtn() -> some View {
        Button("Cancel") {
            dismiss()
        }
    }
    
    private func submit() {
        let status = sitesManager.validateAndUpdatePassword(password: password)
        if status {
            dismiss()
            if DeviceType.isIphone, let site = sitesManager.selectedSite {
                appController.path.append(site)
            }
        } else {
            footerText = "Incorrect password! Please enter correct password."
        }
    }
}

#Preview {
    UnlockSiteView()
}
