//
//  ManagerDetailView.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

// MARK: - Manager Detail View

struct ManagerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    // We keep a local copy so edits reflect immediately
    @State private var manager: DisplayManager
    @State private var isEditPresented = false
    
    @State private var isResettingPassword = false
    @State private var showResetAlert = false
    @State private var showResetSuccessAlert = false
    @State private var newPassword = ""
    @State private var showDeleteAlert = false
    
    var onResetPassword: ((String) async -> Bool)?
    var onDelete: (() -> Void)?
    var onUpdate: ((DisplayManager, UIImage?) async -> Void)?

    init(manager: DisplayManager, onResetPassword: ((String) async -> Bool)? = nil, onDelete: (() -> Void)? = nil, onUpdate: ((DisplayManager, UIImage?) async -> Void)? = nil) {
        _manager = State(initialValue: manager)
        self.onResetPassword = onResetPassword
        self.onDelete = onDelete
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        List {
            // MARK: - Avatar Header Section
            Section {
                VStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.15))
                            .frame(width: 110, height: 110)
                        
                        if let urlString = manager.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 110, height: 110)
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58)
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }
                    .shadow(color: RSMSColors.burgundy.opacity(0.15), radius: 10, x: 0, y: 4)
                    
                    // Full name on one line
                    Text(manager.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Contact Info
            Section(header: Text("Manager Information")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .textCase(.none)
            ) {
                infoRow(icon: "person.badge.shield.checkmark.fill",
                        label: "Role",
                        value: "Manager",
                        valueColor: RSMSColors.burgundy)
                
                if !manager.phone.isEmpty {
                    infoRow(icon: "phone.fill",
                            label: "Phone",
                            value: manager.phone)
                }
                
                if !manager.email.isEmpty {
                    infoRow(icon: "envelope.fill",
                            label: "Email",
                            value: manager.email)
                }
            }
            
            // MARK: - Store
            Section(header: Text("Store Information")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .textCase(.none)
            ) {
                infoRow(icon: "building.2.fill",
                        label: "Store",
                        value: manager.storeName.isEmpty ? "Not Assigned" : manager.storeName,
                        valueColor: manager.storeName.isEmpty ? RSMSColors.secondaryText : RSMSColors.primaryText)
                
                if !manager.address.isEmpty {
                    infoRow(icon: "location.fill",
                            label: "Address",
                            value: manager.address,
                            multiline: true)
                }
                
                if !manager.country.isEmpty {
                    infoRow(icon: "globe",
                            label: "Country",
                            value: manager.country,
                            valueColor: RSMSColors.burgundy)
                }
            }
            
            // // MARK: - Performance
            // Section(header: Text("Performance")
            //     .font(.system(size: 17, weight: .semibold))
            //     .foregroundColor(RSMSColors.secondaryText)
            //     .textCase(.none)
            // ) {
            //     infoRow(icon: "dollarsign.circle.fill",
            //             label: "Revenue",
            //             value: manager.revenue.isEmpty ? "$0" : manager.revenue)
                
            //     infoRow(icon: "shippingbox.fill",
            //             label: "Products Sold",
            //             value: "\(manager.productsSold)")
            // }
            
            // MARK: - Account
            if onResetPassword != nil {
                Section(header: Text("Account")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
                    .textCase(.none)
                ) {
                    Button {
                        Task {
                            isResettingPassword = true
                            let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
                            let generatedPassword = String((0..<12).map { _ in chars.randomElement()! })
                            if let onResetPassword = onResetPassword {
                                _ = await onResetPassword(generatedPassword)
                            }
                            isResettingPassword = false
                            showResetSuccessAlert = true
                        }
                    } label: {
                        HStack {
                            Text("Reset Credentials")
                                .font(RSMSFonts.body)
                                .foregroundColor(RSMSColors.primaryText)
                            Spacer()
                            Image(systemName: "key.fill")
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }
                }
            }
            
            // MARK: - Delete Manager
            if onDelete != nil {
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Manager")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            // Dismiss (xmark) on LEFT — IMG4
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            
            // Edit button on RIGHT
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditPresented = true
                } label: {
                    Text("Edit")
                        .font(.system(.body, design: .default).weight(.semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
        .sheet(isPresented: $isEditPresented) {
            EditManagerSheet(manager: $manager, onSave: { updatedManager, newImage in
                await onUpdate?(updatedManager, newImage)
            })
        }
        .alert("Credentials Reset", isPresented: $showResetSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("A link to reset credentials has been sent to the manager's registered email.")
        }
        .alert("Delete Manager", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let onDelete = onDelete {
                    onDelete()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this manager? This action cannot be undone and will revoke their access.")
        }
    }
    
    // MARK: - Native Info Row
    @ViewBuilder
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .secondary,
        multiline: Bool = false
    ) -> some View {
        HStack(alignment: multiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(RSMSColors.burgundy)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(multiline ? 3 : 1)
        }
    }
}

// MARK: - Edit Manager Sheet

struct EditManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var manager: DisplayManager
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var email: String
    @State private var storeName: String
    @State private var storeAddress: String
    @State private var selectedCountry: String
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data?
    @State private var isSaving = false
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
    
    private let countries = ["United States", "United Kingdom", "Canada", "Australia", "India", "Germany", "France", "Japan", "United Arab Emirates", "Singapore"]
    var onSave: ((DisplayManager, UIImage?) async -> Void)? = nil

    init(manager: Binding<DisplayManager>, onSave: ((DisplayManager, UIImage?) async -> Void)? = nil) {
        _manager = manager
        let m = manager.wrappedValue
        let parts = m.name.components(separatedBy: " ")
        _firstName       = State(initialValue: parts.first ?? "")
        _lastName        = State(initialValue: parts.dropFirst().joined(separator: " "))
        _phone           = State(initialValue: m.phone)
        _email           = State(initialValue: m.email)
        _storeName       = State(initialValue: m.storeName)
        _storeAddress    = State(initialValue: m.address)
        _selectedCountry = State(initialValue: m.country.isEmpty ? "United States" : m.country)
        self.onSave = onSave
    }
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // ── Photo Picker (img2 style) ──────────────────────────
                Section {
                    VStack(spacing: RSMSSpacing.sm) {
                                                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.burgundy.opacity(0.15))
                                    .frame(width: 110, height: 110)
                                    .shadow(color: RSMSColors.burgundy.opacity(0.15), radius: 10, x: 0, y: 4)
                                
                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                } else if let urlString = manager.imageUrl,
                                          let url = URL(string: urlString) {
                                    AsyncImage(url: url) { img in
                                        img.resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 110, height: 110)
                                    }
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
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Text(selectedImageData == nil ? "Add Photo" : "Change Photo")
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
                    .padding(.vertical, RSMSSpacing.xs)
                }
                .listRowBackground(Color.clear)
                .onChange(of: photoPickerItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }
                
                // ── Manager Details (single grouped pill) ─────────────
                Section("Manager Details") {
                    TextField("First Name", text: $firstName)
                        .autocorrectionDisabled()
                    TextField("Last Name", text: $lastName)
                        .autocorrectionDisabled()
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 20)
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                    }
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 20)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                // ── Store Details ──────────────────────────────────────
                Section("Store Details") {
                    Picker(selection: $storeName) {
                        ForEach(pickerStoreNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(RSMSColors.burgundy)
                                .frame(width: 20)
                            Text("Store Name")
                        }
                    }
                    .tint(RSMSColors.burgundy)
                    HStack(alignment: .top) {
                        Image(systemName: "location.fill")
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 20)
                            .padding(.top, 8)
                        TextField("Store Address", text: $storeAddress, axis: .vertical)
                    }
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(pickerCountries, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                    .tint(RSMSColors.burgundy)
                }
            }
            .navigationTitle("Edit Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                isSaving = true
                                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                manager.name      = fullName.isEmpty ? manager.name : fullName
                                manager.phone     = phone
                                manager.email     = email
                                manager.storeName = storeName
                                manager.address   = storeAddress
                                manager.country   = selectedCountry
                                let newImage = selectedImageData != nil ? UIImage(data: selectedImageData!) : nil
                                await onSave?(manager, newImage)
                                isSaving = false
                                dismiss()
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
        }
    }
}

