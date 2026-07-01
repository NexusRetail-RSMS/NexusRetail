//
//  NewManagerSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

struct NewManagerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onCreate: ((String, String, String, String, String, String, String, UIImage?) async -> Bool)? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var storeName = ""
    @State private var storeAddress = ""

    @State private var isSaving = false
    @State private var showSuccessAlert = false

    @State private var selectedCountry = "United States"
    private let countries = ["United States", "United Kingdom", "Canada", "Australia", "India", "Germany", "France", "Japan", "United Arab Emirates", "Singapore"]

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var stores: [Store] = []
    
    private var pickerStoreNames: [String] {
        var names = stores.map { $0.name }
        if !storeName.isEmpty && !names.contains(storeName) {
            names.insert(storeName, at: 0)
        }
        return names
    }
    
    private var pickerCountries: [String] {
        var list = countries
        if !selectedCountry.isEmpty && !list.contains(selectedCountry) {
            list.append(selectedCountry)
        }
        return list
    }

    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasEmail = !email.trimmingCharacters(in: .whitespaces).isEmpty
        return hasFirstName && hasEmail && !isSaving
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
                    Picker("Store Name", selection: $storeName) {
                        ForEach(pickerStoreNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .tint(RSMSColors.burgundy)

                    TextField("Store Address", text: $storeAddress, axis: .vertical)

                    Picker("Country", selection: $selectedCountry) {
                        ForEach(pickerCountries, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                    .tint(RSMSColors.burgundy)
                }
            }
            .navigationTitle("Add New Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(RSMSColors.burgundy)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                isSaving = true
                                generatePassword()
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
                                        selectedImage
                                    )
                                    if success {
                                        isSaving = false
                                        showSuccessAlert = true
                                    } else {
                                        isSaving = false
                                    }
                                } else {
                                    dismiss()
                                }
                            }
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isFormValid ? RSMSColors.burgundy : Color.secondary)
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .task {
                do {
                    self.stores = try await StoreRepository().fetchStores()
                    // Set default selection to first store if currently empty
                    if let firstStore = self.stores.first, storeName.isEmpty {
                        self.storeName = firstStore.name
                        // Also auto-populate address and country for the default store
                        if let addr = firstStore.address {
                            self.storeAddress = addr
                        }
                        if let cntry = firstStore.country, !cntry.isEmpty {
                            self.selectedCountry = cntry
                        }
                    }
                } catch {
                    print("Failed to fetch stores: \(error)")
                }
            }
            .onChange(of: storeName) { _, newStoreName in
                if let matchedStore = stores.first(where: { $0.name == newStoreName }) {
                    if let addr = matchedStore.address {
                        self.storeAddress = addr
                    }
                    if let cntry = matchedStore.country, !cntry.isEmpty {
                        self.selectedCountry = cntry
                    }
                }
            }
            .alert("Manager Created", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("The manager account has been created. The username and password have been sent to the manager's registered email.")
            }
        }
    }
}
