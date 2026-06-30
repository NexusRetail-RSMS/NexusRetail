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
    @State private var newPassword = ""
    @State private var showDeleteAlert = false

    var onResetPassword: ((String) async -> Bool)?
    var onDelete: (() -> Void)?
    var onUpdate: ((DisplayManager) async -> Void)?

    init(manager: DisplayManager, onResetPassword: ((String) async -> Bool)? = nil, onDelete: (() -> Void)? = nil, onUpdate: ((DisplayManager) async -> Void)? = nil) {
        _manager = State(initialValue: manager)
        self.onResetPassword = onResetPassword
        self.onDelete = onDelete
        self.onUpdate = onUpdate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────────────────
                VStack(spacing: RSMSSpacing.md) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.15))
                            .frame(width: 100, height: 100)

                        if let urlString = manager.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }
                    .shadow(color: RSMSColors.burgundy.opacity(0.15), radius: 10, x: 0, y: 4)

                    // Full name on one line
                    Text(manager.name)
                        .font(RSMSFonts.title)
                        .foregroundColor(RSMSColors.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, RSMSSpacing.xxl)
                .padding(.bottom, RSMSSpacing.md)
                .background(RSMSColors.background)

                // ── Contact Info ────────────────────────────────────────
                DetailSection(title: "CONTACT") {
                    if !manager.phone.isEmpty {
                        ManagerProfileDetailRow(icon: "phone.fill", iconColor: RSMSColors.success, label: manager.phone)
                    }
                    if !manager.phone.isEmpty && (!manager.email.isEmpty || !manager.address.isEmpty) {
                        Divider().padding(.leading, 58)
                    }
                    if !manager.email.isEmpty {
                        ManagerProfileDetailRow(icon: "envelope.fill", iconColor: RSMSColors.burgundy, label: manager.email)
                    }
                    if !manager.email.isEmpty && !manager.address.isEmpty {
                        Divider().padding(.leading, 58)
                    }
                    if !manager.address.isEmpty {
                        ManagerProfileDetailRow(icon: "location.fill", iconColor: RSMSColors.error, label: manager.address)
                    }
                    if manager.phone.isEmpty && manager.email.isEmpty && manager.address.isEmpty {
                        ManagerProfileDetailRow(icon: "info.circle.fill", iconColor: RSMSColors.secondaryText, label: "No contact info available")
                    }
                }

                // ── Store ───────────────────────────────────────────────
                DetailSection(title: "STORE") {
                    ManagerProfileDetailRow(
                        icon: "building.2.fill",
                        iconColor: RSMSColors.warning,
                        label: manager.storeName.isEmpty ? "Not Assigned" : manager.storeName,
                        isSecondary: manager.storeName.isEmpty
                    )
                }
                .padding(.bottom, 0)

                // ── Stats ───────────────────────────────────────────────
                DetailSection(title: "PERFORMANCE") {
                    // Revenue
                    HStack(spacing: 14) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(RSMSColors.success)
                            .frame(width: 32, height: 32)
                        Text("Revenue")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Text(manager.revenue.isEmpty ? "$0" : manager.revenue)
                            .font(RSMSFonts.body.weight(.semibold))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .frame(minHeight: 48)

                    Divider().padding(.leading, 58)

                    // Products sold
                    HStack(spacing: 14) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 32, height: 32)
                        Text("Products Sold")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Text("\(manager.productsSold)")
                            .font(RSMSFonts.body.weight(.semibold))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .frame(minHeight: 48)
                }

                if onResetPassword != nil {
                    VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                        Text("ACCOUNT")
                            .font(RSMSFonts.caption.weight(.semibold))
                            .foregroundColor(RSMSColors.secondaryText)
                            .padding(.horizontal, RSMSSpacing.xl)

                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 14) {
                                Text("Reset Credentials")
                                    .font(RSMSFonts.body)
                                    .foregroundColor(RSMSColors.primaryText)
                                Spacer()
                                Image(systemName: "key.fill")
                                    .foregroundColor(RSMSColors.warning)
                            }
                            .padding(.horizontal, RSMSSpacing.lg)
                            .frame(minHeight: 48)
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                    }
                    .padding(.top, RSMSSpacing.md)
                }

                if onDelete != nil {
                    VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(RSMSColors.error)
                                    .frame(width: 32, height: 32)
                                Text("Delete Manager")
                                    .font(RSMSFonts.body.weight(.semibold))
                                    .foregroundColor(RSMSColors.error)
                                Spacer()
                            }
                            .padding(.horizontal, RSMSSpacing.lg)
                            .frame(minHeight: 48)
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                    }
                    .padding(.top, RSMSSpacing.sm)
                }

                Spacer(minLength: RSMSSpacing.xxxl)
            }
        }
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
            EditManagerSheet(manager: $manager, onSave: { updatedManager in
                await onUpdate?(updatedManager)
            })
        }
        .alert("Reset Password", isPresented: $showResetAlert) {
            TextField("New Password", text: $newPassword)
            Button("Cancel", role: .cancel) {
                newPassword = ""
            }
            Button("Reset") {
                Task {
                    isResettingPassword = true
                    if let onResetPassword = onResetPassword {
                        _ = await onResetPassword(newPassword)
                    }
                    isResettingPassword = false
                    newPassword = ""
                }
            }
            .disabled(newPassword.isEmpty)
        } message: {
            Text("Enter a new password for this manager.")
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
}

// MARK: - Reusable Detail Components

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .padding(.horizontal, RSMSSpacing.xl)
                .padding(.top, RSMSSpacing.md)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .padding(.bottom, RSMSSpacing.xs)
    }
}

private struct ManagerProfileDetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    var isSecondary: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)

            Text(label)
                .font(RSMSFonts.body)
                .foregroundColor(isSecondary ? RSMSColors.secondaryText : RSMSColors.primaryText)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .frame(minHeight: 48)
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

    private let countries = ["United States", "United Kingdom", "Canada", "Australia", "India", "Germany", "France", "Japan", "United Arab Emirates", "Singapore"]

    var onSave: ((DisplayManager) async -> Void)? = nil

    init(manager: Binding<DisplayManager>, onSave: ((DisplayManager) async -> Void)? = nil) {
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
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "3B3060"), Color(hex: "2A2048")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 110, height: 110)

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
                                        .foregroundColor(.white)
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
                            .foregroundColor(RSMSColors.success)
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
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(RSMSColors.warning)
                            .frame(width: 20)
                        TextField("Store Name", text: $storeName)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(RSMSColors.error)
                            .frame(width: 20)
                        TextField("Store Address", text: $storeAddress)
                    }
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries, id: \.self) { country in
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
                                await onSave?(manager)
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
        }
    }
}
