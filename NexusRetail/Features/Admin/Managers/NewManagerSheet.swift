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
                VStack(spacing: 24) {
                    // Profile Photo Picker Placeholder
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
                            Text("Add Photo")
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
                    
                    // Name Form Card
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
                    
                    // Dynamic Attribute Cards
                    VStack(spacing: 16) {
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
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("Country", selection: $selectedCountry) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        .tint(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
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
                            .foregroundColor(isFormValid ? .blue : Color(UIColor.tertiaryLabel))
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
                HStack(spacing: 12) {
                    Button {
                        if let idx = items.wrappedValue.firstIndex(where: { $0.id == item.id }) {
                            items.wrappedValue.remove(at: idx)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // Label picker action
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.label)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .frame(height: 20)
                    
                    TextField(placeholder, text: $item.value)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                
                Divider()
                    .padding(.leading, 48)
            }
            
            Button {
                items.wrappedValue.append(ContactFieldItem(label: defaultLabel, value: ""))
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text(addTitle)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }
}
