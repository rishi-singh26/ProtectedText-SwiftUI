//
//  PasswordField.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftUI

struct PasswordField<Style: TextFieldStyle>: View {
    @Binding var password: String
    @State private var isPasswordVisible: Bool = false

    var placeholder: String
    var textFieldStyle: Style
    
    var body: some View {
        HStack {
            if isPasswordVisible {
                TextField(placeholder, text: $password)
                    .textFieldStyle(textFieldStyle)
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
            } else {
                SecureField(placeholder, text: $password)
                    .textFieldStyle(textFieldStyle)
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
            }
            
            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    PasswordField(password: .constant(""), placeholder: "Enter password", textFieldStyle: .roundedBorder)
}
