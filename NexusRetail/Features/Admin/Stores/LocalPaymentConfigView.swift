//
//  LocalPaymentConfigView.swift
//  NexusRetail
//
//  A lightweight inline configuration sheet for payment gateways used during Store Creation.
//

import SwiftUI

struct LocalPaymentConfigView: View {
    @Binding var config: PaymentTerminalConfig
    let provider: PaymentProvider
    
    @Environment(\.dismiss) private var dismiss
    
    // Temporary states for editing
    @State private var environment: PaymentEnvironment
    @State private var credential1: String
    @State private var credential2: String
    
    init(config: Binding<PaymentTerminalConfig>, provider: PaymentProvider) {
        self._config = config
        self.provider = provider
        
        self._environment = State(initialValue: config.wrappedValue.environment)
        self._credential1 = State(initialValue: config.wrappedValue.credential1 ?? "")
        self._credential2 = State(initialValue: config.wrappedValue.credential2 ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {

                Section(header: Text("Credentials")) {
                    TextField(provider.credential1Label, text: $credential1)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField(provider.credential2Label, text: $credential2)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: save) {
                        Text("Save Configuration")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                    .tint(RSMSColors.burgundy)
                    .disabled(credential1.isEmpty || credential2.isEmpty)
                }
            }
            .navigationTitle("Configure \(provider.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(RSMSColors.burgundy)
                }
            }
        }
    }
    
    private func save() {
        config.environment = environment
        config.credential1 = credential1
        config.credential2 = credential2
        config.status = .configured
        config.isEnabled = true
        dismiss()
    }
}
