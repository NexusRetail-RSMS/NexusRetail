//
//  EditEmployeeSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

struct EditEmployeeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var employee: DisplayEmployee
    var onSave: ((DisplayEmployee) -> Void)? = nil
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedRole: UserRole = .salesAssociate
    
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    init(employee: DisplayEmployee, onSave: ((DisplayEmployee) -> Void)? = nil) {
        _employee = State(initialValue: employee)
        self.onSave = onSave
        
        let components = employee.name.components(separatedBy: " ")
        _firstName = State(initialValue: components.first ?? employee.name)
        if components.count > 1 {
            _lastName = State(initialValue: components.dropFirst().joined(separator: " "))
        } else {
            _lastName = State(initialValue: "")
        }
        _email = State(initialValue: employee.email)
        _phone = State(initialValue: employee.phone)
        _selectedRole = State(initialValue: employee.role == "After Sales Associate" ? .afterSales : .salesAssociate)
        _selectedImageData = State(initialValue: employee.imageData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // ── Photo Picker (same as Manager Edit) ──────────────────────────
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
                                } else if let urlString = employee.imageUrl, let url = URL(string: urlString) {
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
                        
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Text(selectedImageData == nil && employee.imageUrl == nil ? "Add Photo" : "Change Photo")
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

                Section(header: Text("Employee Details").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)) {
                    TextField("First Name", text: $firstName)
                        .autocorrectionDisabled()
                    TextField("Last Name", text: $lastName)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Contact Details").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("Role").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)) {
                    roleSelectionRow(role: .salesAssociate, label: "Sales Associate")
                    roleSelectionRow(role: .afterSales, label: "After Sales Associate")
                }
            }
            .navigationTitle("Edit Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))".trimmingCharacters(in: .whitespaces)
                        let roleStr = selectedRole == .afterSales ? "After Sales Associate" : "Sales Associate"
                        
                        var updated = employee
                        if !fullName.isEmpty { updated.name = fullName }
                        updated.email = email
                        updated.phone = phone
                        updated.role = roleStr
                        updated.imageData = selectedImageData
                        
                        onSave?(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
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
}
