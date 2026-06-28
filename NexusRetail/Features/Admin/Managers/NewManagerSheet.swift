//
//  NewManagerSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

struct ContactFieldItem: Identifiable {
    let id = UUID()
    var label: String
    var value: String
}

struct NewManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    
    @State private var phones: [ContactFieldItem] = [ContactFieldItem(label: "mobile", value: "")]
    @State private var emails: [ContactFieldItem] = []
    @State private var addresses: [ContactFieldItem] = []
    
    @State private var selectedCountry = "United States"
    private let countries = ["United States", "United Kingdom", "Canada", "Australia", "India", "Germany", "France", "Japan", "United Arab Emirates", "Singapore"]
    
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPhone = phones.contains { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        return hasFirstName && hasPhone
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RSMSSpacing.xxl) {
                    // Profile Photo Picker Placeholder
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
                            Text("Add Photo")
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
                    
                    // Name Form Card
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
                    
                    // Dynamic Attribute Cards
                    VStack(spacing: RSMSSpacing.lg) {
                        dynamicAttributeSection(
                            items: $phones,
                            defaultLabel: "mobile",
                            placeholder: "Phone",
                            addTitle: "add phone"
                        )
                        
                        dynamicAttributeSection(
                            items: $emails,
                            defaultLabel: "home",
                            placeholder: "Email",
                            addTitle: "add email"
                        )
                        
                        dynamicAttributeSection(
                            items: $addresses,
                            defaultLabel: "work",
                            placeholder: "Address",
                            addTitle: "add address"
                        )
                    }
                    
                    // Country Card
                    HStack {
                        Text("Country")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Picker("Country", selection: $selectedCountry) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        .tint(RSMSColors.burgundy)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.vertical, RSMSSpacing.xs)
                    .background(RSMSColors.cardBackground)
                    .cornerRadius(RSMSRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSRadius.large)
                            .stroke(RSMSColors.cardBorder, lineWidth: 1)
                    )
                }
                .padding()
            }
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationTitle("New Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                        let managerName = fullName.isEmpty ? "New Manager" : fullName
                        let store = addresses.first(where: { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty })?.value ?? ""
                        
                        let newManager = DisplayManager(
                            name: managerName,
                            storeName: store.isEmpty ? "Nexus Retail Store" : store,
                            country: selectedCountry,
                            performanceScore: 0,
                            revenue: "$0",
                            photoData: selectedImageData,
                            phone: phones.first(where: { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty })?.value ?? "",
                            email: emails.first(where: { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty })?.value ?? "",
                            address: store,
                            productsSold: 0,
                            createdAt: Date()
                        )
                        ManagersStore.shared.add(manager: newManager)
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
    
    private func dynamicAttributeSection(
        items: Binding<[ContactFieldItem]>,
        defaultLabel: String,
        placeholder: String,
        addTitle: String
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { $item in
                HStack(spacing: RSMSSpacing.md) {
                    Button {
                        if let idx = items.wrappedValue.firstIndex(where: { $0.id == item.id }) {
                            items.wrappedValue.remove(at: idx)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(RSMSColors.error)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // Label picker action
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.label)
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.burgundy)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .frame(height: 20)
                    
                    TextField(placeholder, text: $item.value)
                        .font(RSMSFonts.body)
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.vertical, 11)
                
                Divider()
                    .padding(.leading, 48)
            }
            
            Button {
                items.wrappedValue.append(ContactFieldItem(label: defaultLabel, value: ""))
            } label: {
                HStack(spacing: RSMSSpacing.md) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(RSMSColors.success)
                        .font(.title3)
                    
                    Text(addTitle)
                        .font(RSMSFonts.body)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
}
