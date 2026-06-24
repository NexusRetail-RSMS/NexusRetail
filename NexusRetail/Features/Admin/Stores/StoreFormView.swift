//
//  StoreFormView.swift
//  NexusRetail
//

import SwiftUI

struct StoreFormView: View {
    @Bindable var viewModel: StoresViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var locale: String = "en_IN"
    @State private var currencyCode: String = "INR"
    @State private var timezone: String = "Asia/Kolkata"
    @State private var selectedManagerID: UUID? = nil
    
    @State private var includeRazorpay: Bool = false
    @State private var includeCard: Bool = false
    
    let currencies = ["INR", "USD", "EUR", "AED", "GBP"]
    let locales = ["en_IN", "en_US", "en_GB", "fr_FR", "ar_AE"]
    let timezones = ["Asia/Kolkata", "America/New_York", "Europe/London", "Europe/Paris", "Asia/Dubai"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details")) {
                    TextField("Store Name", text: $name)
                        .accessibilityLabel("Store Name")
                    
                    TextField("Address", text: $address)
                        .accessibilityLabel("Address")
                }
                
                Section(header: Text("Localization")) {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    
                    Picker("Locale", selection: $locale) {
                        ForEach(locales, id: \.self) { Text($0) }
                    }
                    
                    Picker("Timezone", selection: $timezone) {
                        ForEach(timezones, id: \.self) { Text($0) }
                    }
                }
                
                Section(header: Text("Staffing")) {
                    Picker("Manager", selection: $selectedManagerID) {
                        Text("None").tag(UUID?(nil))
                        ForEach(viewModel.managers) { manager in
                            Text(manager.name ?? "Unknown").tag(manager.id as UUID?)
                        }
                    }
                }
                
                Section(header: Text("Payment Terminals")) {
                    Toggle("Razorpay", isOn: $includeRazorpay)
                    Toggle("Card Terminal", isOn: $includeCard)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("New Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.create(
                                name: name,
                                address: address,
                                locale: locale,
                                currencyCode: currencyCode,
                                timezone: timezone,
                                managerID: selectedManagerID,
                                includeRazorpay: includeRazorpay,
                                includeCard: includeCard
                            )
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color.nexusGold)
                    .disabled(viewModel.isLoading || name.isEmpty || address.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                }
            }
        }
    }
}
