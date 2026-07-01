//
//  NewEmployeeSheet.swift
//  NexusRetail
//
//  Sheet to add a new store employee.
//

import SwiftUI
import PhotosUI

struct NewEmployeeSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: ((DisplayEmployee, String) -> Void)? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var password = ""
    @State private var selectedRole: UserRole? = nil

    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasLastName = !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasEmail = !email.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPhone = !phone.trimmingCharacters(in: .whitespaces).isEmpty
        let hasRole = selectedRole != nil
        return hasFirstName && hasLastName && hasEmail && hasPhone && hasRole && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Photo Section ─────────────────────────
                Section {
                    VStack(spacing: RSMSSpacing.sm) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.burgundy.opacity(0.15))
                                    .frame(width: 110, height: 110)
                                    .shadow(color: RSMSColors.burgundy.opacity(0.15), radius: 10, x: 0, y: 4)

                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 52, height: 52)
                                        .foregroundColor(RSMSColors.burgundy)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(RSMSColors.primaryText)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                // ── Basic Info ────────────────────────────
                Section(header: Text("Employee Details").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)) {
                    TextField("First Name", text: $firstName)
                        .autocorrectionDisabled()
                    TextField("Last Name", text: $lastName)
                        .autocorrectionDisabled()
                }

                // ── Contact Info ──────────────────────────
                Section(header: Text("Contact Details").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }

                // ── Role ──────────────────────────────────
                Section(header: Text("Role").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)) {
                    roleSelectionRow(role: .salesAssociate, label: "Sales Associate")
                    roleSelectionRow(role: .afterSales, label: "After Sales Associate")
                }
            }
            .navigationTitle("New Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveEmployee()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            .alert(successAlertTitle, isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successAlertMessage)
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var successAlertTitle: String {
        if selectedRole == .afterSales {
            return "After Sales Associate Created"
        } else {
            return "Sales Associate Created"
        }
    }

    private var successAlertMessage: String {
        return "The password credentials have been sent to their email."
    }

    private func roleSelectionRow(role: UserRole, label: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(RSMSColors.primaryText)
            Spacer()
            Image(systemName: selectedRole == role ? "checkmark.circle.fill" : "circle")
                .foregroundColor(selectedRole == role ? RSMSColors.burgundy : .gray)
                .font(.system(size: 22))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedRole = role
        }
    }

    private func generatePassword() {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        password = String((0..<12).map { _ in chars.randomElement()! })
    }

    private func saveEmployee() async {
        isSaving = true
        generatePassword()
        
        let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
        let roleStr = selectedRole == .afterSales ? "After Sales Associate" : "Sales Associate"
        
        let newEmp = DisplayEmployee(
            id: UUID(),
            name: fullName,
            role: roleStr,
            productsSold: 0,
            revenue: "$0",
            imageUrl: nil,
            phone: phone,
            email: email
        )
        
        // Simulate save / persist
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        if let onCreate = onCreate {
            onCreate(newEmp, password)
        }
        
        isSaving = false
        showSuccessAlert = true
    }
}

#Preview {
    NewEmployeeSheet()
}
