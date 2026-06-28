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

    init(manager: DisplayManager) {
        _manager = State(initialValue: manager)
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

                        if let data = manager.photoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
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
                        DetailRow(icon: "phone.fill", iconColor: RSMSColors.success, label: manager.phone)
                    }
                    if !manager.phone.isEmpty && (!manager.email.isEmpty || !manager.address.isEmpty) {
                        Divider().padding(.horizontal, 7)
                    }
                    if !manager.email.isEmpty {
                        DetailRow(icon: "envelope.fill", iconColor: RSMSColors.burgundy, label: manager.email)
                    }
                    if !manager.email.isEmpty && !manager.address.isEmpty {
                        Divider().padding(.horizontal, 7)
                    }
                    if !manager.address.isEmpty {
                        DetailRow(icon: "mappin.circle.fill", iconColor: RSMSColors.error, label: manager.address)
                    }
                    if manager.phone.isEmpty && manager.email.isEmpty && manager.address.isEmpty {
                        DetailRow(icon: "info.circle.fill", iconColor: RSMSColors.secondaryText, label: "No contact info available")
                    }
                }

                // ── Store ───────────────────────────────────────────────
                DetailSection(title: "STORE") {
                    DetailRow(
                        icon: "building.2.fill",
                        iconColor: RSMSColors.warning,
                        label: manager.storeName.isEmpty ? "Not Assigned" : manager.storeName,
                        isSecondary: manager.storeName.isEmpty
                    )
                }

                // ── Stats ───────────────────────────────────────────────
                DetailSection(title: "PERFORMANCE") {
                    // Revenue
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(RSMSColors.success)
                            .font(.system(size: 22))
                            .frame(width: 32)
                        Text("Revenue")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Text(manager.revenue.isEmpty ? "$0" : manager.revenue)
                            .font(RSMSFonts.body.weight(.semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.vertical, 11)

                    Divider().padding(.horizontal, 7)

                    // Products sold
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(RSMSColors.burgundy)
                            .font(.system(size: 22))
                            .frame(width: 32)
                        Text("Products Sold")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Text("\(manager.productsSold)")
                            .font(RSMSFonts.body.weight(.semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.vertical, 11)

                    Divider().padding(.horizontal, 7)

                    // Performance score with progress bar
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(performanceColor(for: manager.performanceScore))
                                .font(.system(size: 22))
                                .frame(width: 32)
                            Text("Performance Score")
                                .font(RSMSFonts.body)
                                .foregroundColor(RSMSColors.primaryText)
                            Spacer()
                            Text("\(manager.performanceScore)%")
                                .font(RSMSFonts.body.weight(.bold))
                                .foregroundColor(performanceColor(for: manager.performanceScore))
                        }
                        .padding(.horizontal, RSMSSpacing.lg)

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(RSMSColors.cardBorder)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(performanceColor(for: manager.performanceScore))
                                    .frame(
                                        width: geo.size.width * CGFloat(manager.performanceScore) / 100.0,
                                        height: 8
                                    )
                                    .animation(.easeInOut(duration: 0.6), value: manager.performanceScore)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, RSMSSpacing.md)
                    }
                    .padding(.top, RSMSSpacing.md)
                }

                Spacer(minLength: RSMSSpacing.xxxl)
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            // Back button
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
            }

            // Edit button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditPresented = true
                } label: {
                    Text("Edit")
                        .font(RSMSFonts.body)
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
        .sheet(isPresented: $isEditPresented) {
            EditManagerSheet(manager: $manager)
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
                .font(RSMSFonts.caption.weight(.semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .padding(.horizontal, RSMSSpacing.xl)
                .padding(.top, RSMSSpacing.md)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(RSMSColors.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .padding(.bottom, RSMSSpacing.xs)
    }
}

private struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    var isSecondary: Bool = false

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 22))
                .frame(width: 32)

            Text(label)
                .font(RSMSFonts.body)
                .foregroundColor(isSecondary ? RSMSColors.secondaryText : RSMSColors.primaryText)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, 11)
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
    @State private var address: String
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data?

    init(manager: Binding<DisplayManager>) {
        _manager = manager
        let m = manager.wrappedValue
        let parts = m.name.components(separatedBy: " ")
        _firstName = State(initialValue: parts.first ?? "")
        _lastName  = State(initialValue: parts.dropFirst().joined(separator: " "))
        _phone     = State(initialValue: m.phone)
        _email     = State(initialValue: m.email)
        _address   = State(initialValue: m.address)
        _selectedImageData = State(initialValue: m.photoData)
    }

    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPhone = !phone.trimmingCharacters(in: .whitespaces).isEmpty
        return hasFirstName && hasPhone
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RSMSSpacing.xxl) {

                    // ── Photo Picker ──────────────────────────────────
                    VStack(spacing: RSMSSpacing.md) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.burgundy.opacity(0.15))
                                    .frame(width: 120, height: 120)

                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(RSMSColors.burgundy)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Text(selectedImageData == nil ? "Add Photo" : "Change Photo")
                                .font(RSMSFonts.subheadline.weight(.medium))
                                .foregroundColor(RSMSColors.primaryText)
                                .padding(.horizontal, RSMSSpacing.lg)
                                .padding(.vertical, 6)
                                .background(RSMSColors.burgundy.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, RSMSSpacing.md)
                    .onChange(of: photoPickerItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }

                    // ── Name ──────────────────────────────────────────
                    VStack(spacing: 0) {
                        TextField("First name", text: $firstName)
                            .font(RSMSFonts.body)
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.vertical, 11)

                        Divider()
                            .padding(.horizontal, 7)

                        TextField("Last name", text: $lastName)
                            .font(RSMSFonts.body)
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.vertical, 11)
                    }
                    .background(RSMSColors.cardBackground)
                    .cornerRadius(RSMSRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSRadius.large)
                            .stroke(RSMSColors.cardBorder, lineWidth: 1)
                    )

                    // ── Contact Fields ────────────────────────────────
                    VStack(spacing: RSMSSpacing.lg) {
                        contactField(icon: "phone.fill", iconColor: RSMSColors.success, placeholder: "Phone", text: $phone)
                        contactField(icon: "envelope.fill", iconColor: RSMSColors.burgundy, placeholder: "Email", text: $email)
                        contactField(icon: "mappin.circle.fill", iconColor: RSMSColors.error, placeholder: "Address", text: $address)
                    }
                }
                .padding()
            }
            .background(RSMSColors.background.ignoresSafeArea())
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
                    Button {
                        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                        manager.name    = fullName.isEmpty ? manager.name : fullName
                        manager.phone   = phone
                        manager.email   = email
                        manager.address = address
                        if let data = selectedImageData {
                            manager.photoData = data
                        }
                        // Persist to shared store
                        ManagersStore.shared.update(manager: manager)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isFormValid ? RSMSColors.burgundy : RSMSColors.disabled)
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    @ViewBuilder
    private func contactField(icon: String, iconColor: Color, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: RSMSSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 28)

            TextField(placeholder, text: text)
                .font(RSMSFonts.body)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, 11)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
}
