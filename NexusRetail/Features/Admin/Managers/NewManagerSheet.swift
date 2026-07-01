//
//  NewManagerSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

struct NewManagerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onCreate: ((String, String, String, String, String, String, String, String?) async -> Bool)? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var storeName = ""
    @State private var storeAddress = ""

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
                // ── Photo Section (img2 style) ─────────────────────────
                Section {
                    VStack(spacing: RSMSSpacing.sm) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "3B3060"), Color(hex: "2A2048")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 110, height: 110)

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
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Pill-shaped Add Photo button
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(RSMSColors.primaryText)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RSMSSpacing.sm)
                }
                .listRowBackground(Color.clear)
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }

                // ── Personal Info (single grouped pill) ───────────────
                Section("Manager Details") {
                    TextField("First Name", text: $firstName)
                        .autocorrectionDisabled()

                    TextField("Last Name", text: $lastName)
                        .autocorrectionDisabled()

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                // ── Store Details ──────────────────────────────────────
                Section("Store Details") {
                    TextField("Store Name", text: $storeName)
                        .autocorrectionDisabled()

                    TextField("Store Address", text: $storeAddress)

                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                    .tint(RSMSColors.burgundy)
                }

                // ── Credentials ────────────────────────────────────────
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
                                    let success = await onCreate(
                                        email,
                                        password,
                                        managerName,
                                        phone,
                                        storeName,
                                        storeAddress,
                                        selectedCountry,
                                        nil
                                    )
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
