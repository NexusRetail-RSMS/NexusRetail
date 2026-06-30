//
//  NewManagerSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

struct NewManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onCreate: ((String, String, String, String, String, String?) async -> Bool)? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    
    @State private var isSaving = false
    
    @State private var selectedCountry = "United States"
    private let countries = ["United States", "United Kingdom", "Canada", "Australia", "India", "Germany", "France", "Japan", "United Arab Emirates", "Singapore"]
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasEmail = !email.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPassword = !password.isEmpty
        return hasFirstName && hasEmail && hasPassword && !isSaving
    }
    
    private func generatePassword() {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        password = String((0..<12).map { _ in chars.randomElement()! })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(RSMSColors.cardBackground)
                                        .overlay {
                                            VStack(spacing: 10) {
                                                Image(systemName: "person.crop.circle.badge.plus")
                                                    .font(.system(size: 34))
                                                    .foregroundStyle(RSMSColors.burgundy)
                                                
                                                Text("Upload Manager Photo")
                                                    .font(.headline)
                                                    .foregroundStyle(RSMSColors.darkBrown)
                                                
                                                Text("Tap to select an image")
                                                    .font(.caption)
                                                    .foregroundStyle(RSMSColors.secondaryText)
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                
                // Manager Details
                Section("Manager Details") {
                    TextField("First Name", text: $firstName)
                        .autocorrectionDisabled()
                    
                    TextField("Last Name", text: $lastName)
                        .autocorrectionDisabled()
                    
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                    .tint(RSMSColors.burgundy)
                }
                
                // Contact
                Section("Contact") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Store Location / Address", text: $address)
                }
                
                // Credentials
                Section("Credentials") {
                    HStack {
                        TextField("Password", text: $password)
                        
                        Button(action: generatePassword) {
                            Text("Generate")
                                .font(RSMSFonts.caption.weight(.bold))
                                .foregroundColor(RSMSColors.burgundy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(RSMSColors.burgundy.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .navigationTitle("Add New Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(RSMSColors.burgundy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                isSaving = true
                                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                let managerName = fullName.isEmpty ? "New Manager" : fullName
                                
                                if let onCreate = onCreate {
                                    let success = await onCreate(email, password, managerName, phone, address, nil)
                                    if success {
                                        dismiss()
                                    }
                                } else {
                                    dismiss()
                                }
                                isSaving = false
                            }
                        }
                        .fontWeight(.bold)
                        .tint(RSMSColors.burgundy)
                        .disabled(!isFormValid)
                    }
                }
            }
        }
    }
}
