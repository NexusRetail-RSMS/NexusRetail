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
                VStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color(red: 70/255, green: 65/255, blue: 95/255))
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
                                .frame(width: 55, height: 55)
                                .foregroundColor(.white)
                                .offset(y: 6)
                                .clipShape(Circle())
                        }
                    }
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)

                    // Full name on one line
                    Text(manager.name)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 10)
                .background(Color(UIColor.systemGroupedBackground))

                // ── Contact Info ────────────────────────────────────────
                DetailSection(title: "CONTACT") {
                    if !manager.phone.isEmpty {
                        DetailRow(icon: "phone.fill", iconColor: .green, label: manager.phone)
                    }
                    if !manager.phone.isEmpty && (!manager.email.isEmpty || !manager.address.isEmpty) {
                        Divider().padding(.horizontal, 7)
                    }
                    if !manager.email.isEmpty {
                        DetailRow(icon: "envelope.fill", iconColor: .blue, label: manager.email)
                    }
                    if !manager.email.isEmpty && !manager.address.isEmpty {
                        Divider().padding(.horizontal, 7)
                    }
                    if !manager.address.isEmpty {
                        DetailRow(icon: "mappin.circle.fill", iconColor: .red, label: manager.address)
                    }
                    if manager.phone.isEmpty && manager.email.isEmpty && manager.address.isEmpty {
                        DetailRow(icon: "info.circle.fill", iconColor: .gray, label: "No contact info available")
                    }
                }

                // ── Store ───────────────────────────────────────────────
                DetailSection(title: "STORE") {
                    DetailRow(
                        icon: "building.2.fill",
                        iconColor: Color(red: 1.0, green: 0.60, blue: 0.0),
                        label: manager.storeName.isEmpty ? "Not Assigned" : manager.storeName,
                        isSecondary: manager.storeName.isEmpty
                    )
                }

                // ── Stats ───────────────────────────────────────────────
                DetailSection(title: "PERFORMANCE") {
                    // Revenue
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 22))
                            .frame(width: 32)
                        Text("Revenue")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(manager.revenue.isEmpty ? "$0" : manager.revenue)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)

                    Divider().padding(.horizontal, 7)

                    // Products sold
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 22))
                            .frame(width: 32)
                        Text("Products Sold")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(manager.productsSold)")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
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
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(manager.performanceScore)%")
                                .font(.body.weight(.bold))
                                .foregroundColor(performanceColor(for: manager.performanceScore))
                        }
                        .padding(.horizontal, 16)

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(UIColor.systemGray5))
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
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .padding(.top, 12)
                }

                Spacer(minLength: 32)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
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
                    .foregroundColor(.blue)
                }
            }

            // Edit button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditPresented = true
                } label: {
                    Text("Edit")
                        .font(.body)
                        .foregroundColor(.blue)
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
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(24)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 4)
    }
}

private struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    var isSecondary: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 22))
                .frame(width: 32)

            Text(label)
                .foregroundColor(isSecondary ? .secondary : .primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
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
                VStack(spacing: 24) {

                    // ── Photo Picker ──────────────────────────────────
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 70/255, green: 65/255, blue: 95/255))
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
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(.white)
                                        .offset(y: 8)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Text(selectedImageData == nil ? "Add Photo" : "Change Photo")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color(UIColor.secondarySystemFill))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)

                        Divider()
                            .padding(.horizontal, 7)

                        TextField("Last name", text: $lastName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(24)

                    // ── Contact Fields ────────────────────────────────
                    VStack(spacing: 16) {
                        contactField(icon: "phone.fill", iconColor: .green, placeholder: "Phone", text: $phone)
                        contactField(icon: "envelope.fill", iconColor: .blue, placeholder: "Email", text: $email)
                        contactField(icon: "mappin.circle.fill", iconColor: .red, placeholder: "Address", text: $address)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Edit Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
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
                            .foregroundColor(isFormValid ? .blue : Color(UIColor.tertiaryLabel))
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    @ViewBuilder
    private func contactField(icon: String, iconColor: Color, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 28)

            TextField(placeholder, text: text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }
}
