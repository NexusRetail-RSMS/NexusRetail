//
//  StoreFormView.swift
//  NexusRetail
//

import SwiftUI
import MapKit

struct StoreFormView: View {
    @Bindable var viewModel: StoresViewModel
    @Environment(\.dismiss) private var dismiss
    
    var editingStore: Store? = nil
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var country: String = ""
    @State private var state: String = ""
    @State private var city: String = ""
    @State private var pinLocation: String = ""
    @State private var pickedCoordinate: CLLocationCoordinate2D? = nil
    @State private var position: MapCameraPosition = .automatic
    @State private var locale: String = "en_IN"
    @State private var currencyCode: String = "INR"
    @State private var timezone: String = "Asia/Kolkata"
    @State private var selectedManagerID: UUID? = nil
    @State private var isActive: Bool = true
    
    @State private var includeRazorpay: Bool = false
    @State private var includeCard: Bool = false
    
    let currencies = ["INR", "USD", "EUR", "AED", "GBP"]
    let locales = ["en_IN", "en_US", "en_GB", "fr_FR", "ar_AE"]
    let timezones = ["Asia/Kolkata", "America/New_York", "Europe/London", "Europe/Paris", "Asia/Dubai"]
    
    init(viewModel: StoresViewModel, editingStore: Store? = nil) {
        self.viewModel = viewModel
        self.editingStore = editingStore
        
        if let store = editingStore {
            _name = State(initialValue: store.name)
            _phone = State(initialValue: store.phone ?? "")
            _pinLocation = State(initialValue: store.address ?? "")
            _locale = State(initialValue: store.locale ?? "en_IN")
            _currencyCode = State(initialValue: store.currencyCode ?? "INR")
            _timezone = State(initialValue: store.timezone ?? "Asia/Kolkata")
            _selectedManagerID = State(initialValue: store.managerID)
            _isActive = State(initialValue: store.status == .active)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if editingStore != nil {
                    Section(header: Text("Store Status").foregroundColor(RSMSColors.primaryText).fontWeight(.semibold)) {
                        Toggle("Store is Active", isOn: $isActive)
                    }
                }

                Section(header: Text("Basic Details").foregroundColor(RSMSColors.primaryText).fontWeight(.semibold)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store Name").font(.caption).foregroundColor(RSMSColors.primaryText)
                        TextField("Enter store name", text: $name)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone Number").font(.caption).foregroundColor(RSMSColors.primaryText)
                        TextField("Enter phone number", text: $phone)
                            .keyboardType(.phonePad)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Address & Location")
                            .font(.caption)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        TextField("Country", text: $country)
                        TextField("State", text: $state)
                        TextField("City", text: $city)
                        TextField("Exact Address / Pin Location", text: $pinLocation)
                        
                        MapReader { proxy in
                            Map(position: $position) {
                                if let coordinate = pickedCoordinate {
                                    Marker("Store Location", coordinate: coordinate)
                                }
                            }
                            .mapControls {
                                MapUserLocationButton()
                                MapCompass()
                                MapScaleView()
                            }
                            .onTapGesture { position in
                                if let coordinate = proxy.convert(position, from: .local) {
                                    pickedCoordinate = coordinate
                                    reverseGeocode(coordinate: coordinate)
                                }
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                        }
                        Text("Tap map to drop a pin and set address.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Localization").foregroundColor(RSMSColors.primaryText).fontWeight(.semibold)) {
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
                
                Section(header: Text("Staffing").foregroundColor(RSMSColors.primaryText).fontWeight(.semibold)) {
                    Picker("Manager", selection: $selectedManagerID) {
                        Text("None").tag(UUID?(nil))
                        ForEach(viewModel.managers) { manager in
                            Text(manager.name ?? "Unknown").tag(manager.id as UUID?)
                        }
                    }
                }
                
                Section(header: Text("Payment Terminals").foregroundColor(RSMSColors.primaryText).fontWeight(.semibold)) {
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
            .scrollContentBackground(.hidden)
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationTitle(editingStore != nil ? "Edit Store" : "New Store")
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
                            var fullAddress = ""
                            if !country.isEmpty { fullAddress += country + ", " }
                            if !state.isEmpty { fullAddress += state + ", " }
                            if !city.isEmpty { fullAddress += city + ", " }
                            fullAddress += pinLocation
                            
                            if let store = editingStore {
                                let success = await viewModel.update(
                                    storeId: store.id,
                                    name: name,
                                    address: fullAddress.trimmingCharacters(in: CharacterSet(charactersIn: ", ")),
                                    phone: phone,
                                    locale: locale,
                                    currencyCode: currencyCode,
                                    timezone: timezone,
                                    managerID: selectedManagerID,
                                    status: isActive ? .active : .archived
                                )
                                if success { dismiss() }
                            } else {
                                let success = await viewModel.create(
                                    name: name,
                                    address: fullAddress.trimmingCharacters(in: CharacterSet(charactersIn: ", ")),
                                    phone: phone,
                                    locale: locale,
                                    currencyCode: currencyCode,
                                    timezone: timezone,
                                    managerID: selectedManagerID,
                                    status: isActive ? .active : .archived,
                                    includeRazorpay: includeRazorpay,
                                    includeCard: includeCard
                                )
                                if success { dismiss() }
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(viewModel.isLoading || name.isEmpty)
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
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var addressString = ""
                if let subThoroughfare = placemark.subThoroughfare { addressString += subThoroughfare + " " }
                if let thoroughfare = placemark.thoroughfare { addressString += thoroughfare + ", " }
                if let locality = placemark.locality { addressString += locality + ", " }
                if let countryStr = placemark.country {
                    if !addressString.isEmpty { addressString += ", " }
                    addressString += countryStr
                }
                
                DispatchQueue.main.async {
                    self.country = placemark.country ?? ""
                    self.state = placemark.administrativeArea ?? ""
                    self.city = placemark.locality ?? ""
                    
                    var exactPin = ""
                    if let subThoroughfare = placemark.subThoroughfare { exactPin += subThoroughfare + " " }
                    if let thoroughfare = placemark.thoroughfare { exactPin += thoroughfare + ", " }
                    if let postalCode = placemark.postalCode { exactPin += postalCode }
                    self.pinLocation = exactPin.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    }
}
