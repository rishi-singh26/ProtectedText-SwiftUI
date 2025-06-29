//
//  SiteInfoView.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI

struct SiteInfoView: View {
    @Environment(\.dismiss) var dismiss
    let site: Site
    
    @State private var isPasswordBlurred = true
    
    var body: some View {
#if os(iOS)
        IOSAddressInfo()
#elseif os(macOS)
        MacOSAddressInfo()
#endif
    }
    
    #if os(iOS)
    @ViewBuilder
    func IOSAddressInfo() -> some View {
        NavigationView {
            List {
            }
            .navigationTitle(site.id)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: """
                              Login using the details below at \(APIManager.baseURL) website.
                              Site: \(APIManager.baseURL)\(site.id)
                              Password: \("site.password")
                              """)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                    }
                }
            }
        }
    }
    #endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSAddressInfo() -> some View {
        VStack {
            HStack {
                Text(site.id)
                    .font(.title.bold())
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem {
                ShareLink(item: """
                          Login using the details below at \(APIManager.baseURL) website.
                          Site: \(APIManager.baseURL)\(site.id)
                          Password: \("site.password")
                          """)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                }
            }
        }
    }
#endif
}

#Preview {
    ContentView()
        .environmentObject(SitesViewModel.shared)
}
