////
////  NewClientSheet.swift
////  NexusRetail
////
////  Modal form for creating a new clienteling record with consent gate.
////
//
//import SwiftUI
//
//struct NewClientSheet: View {
//    var viewModel: ClientelingViewModel
//    @Environment(\.dismiss) private var dismiss
//
//    @State private var name        = ""
//    @State private var phone       = ""
//    @State private var preferences = ""
//    @State private var hasConsent  = true
//
//    private var canSave: Bool {
//        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
//        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
//        hasConsent
//    }
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Consented Details") {
//                    TextField("Name", text: $name)
//                        .textContentType(.name)
//                    TextField("Phone Number", text: $phone)
//                        .textContentType(.telephoneNumber)
//                        .keyboardType(.phonePad)
//                    TextField("Style Preferences", text: $preferences, axis: .vertical)
//                        .lineLimit(3...5)
//                }
//
//                Section {
//                    Toggle("Client consent received", isOn: $hasConsent)
//                        .tint(RSMSColors.burgundy)
//                } footer: {
//                    Text("Consent is required before saving client details.")
//                }
//            }
//            .navigationTitle("New Client")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Save") {
//                        viewModel.addClient(name: name, phone: phone, preferences: preferences)
//                        dismiss()
//                    }
//                    .bold()
//                    .disabled(!canSave)
//                }
//            }
//        }
//        .presentationDetents([.medium, .large])
//    }
//}
