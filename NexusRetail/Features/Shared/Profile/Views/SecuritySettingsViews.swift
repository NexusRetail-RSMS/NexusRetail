import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme
    
    @Bindable var viewModel: ProfileViewModel
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }
    
    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Current Password", text: $currentPassword)
            }
            
            Section(header: Text("New Password"), footer: Text("Password must be at least 8 characters long.")) {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            }
            
            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || viewModel.isLoading)
                .listRowBackground(isFormValid ? theme.primaryAction : theme.cardBackground)
                .foregroundColor(isFormValid ? .white : .gray)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.groupedBackground)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func save() {
        Task {
            try? await viewModel.changePassword(current: currentPassword, new: newPassword)
            dismiss()
        }
    }
}

struct ChangeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme
    
    @Bindable var viewModel: ProfileViewModel
    
    @State private var newEmail = ""
    
    private var currentEmail: String {
        viewModel.profile?.email ?? ""
    }
    
    private var isFormValid: Bool {
        !newEmail.isEmpty && newEmail.contains("@") && newEmail != currentEmail
    }
    
    var body: some View {
        Form {
            Section(header: Text("Current Email")) {
                Text(currentEmail)
                    .foregroundColor(theme.secondaryText)
            }
            
            Section(header: Text("New Email")) {
                TextField("New Email Address", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section(header: Text("Verification")) {
                Text("A verification link will be sent to the new email address.")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || viewModel.isLoading)
                .listRowBackground(isFormValid ? theme.primaryAction : theme.cardBackground)
                .foregroundColor(isFormValid ? .white : .gray)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.groupedBackground)
        .navigationTitle("Change Email")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func save() {
        Task {
            try? await viewModel.changeEmail(newEmail: newEmail)
            dismiss()
        }
    }
}

struct ChangePhoneView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme
    
    @Bindable var viewModel: ProfileViewModel
    
    @State private var newPhone = ""
    
    private var currentPhone: String {
        viewModel.profile?.phone ?? ""
    }
    
    private var isFormValid: Bool {
        !newPhone.isEmpty && newPhone != currentPhone
    }
    
    var body: some View {
        Form {
            Section(header: Text("Current Phone Number")) {
                Text(currentPhone)
                    .foregroundColor(theme.secondaryText)
            }
            
            Section(header: Text("New Phone Number")) {
                TextField("New Phone Number", text: $newPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }
            
            Section(header: Text("Verification")) {
                Text("An OTP will be sent to this number to verify ownership. (Mocked)")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || viewModel.isLoading)
                .listRowBackground(isFormValid ? theme.primaryAction : theme.cardBackground)
                .foregroundColor(isFormValid ? .white : .gray)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.groupedBackground)
        .navigationTitle("Change Phone")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func save() {
        Task {
            try? await viewModel.changePhone(newPhone: newPhone)
            dismiss()
        }
    }
}
