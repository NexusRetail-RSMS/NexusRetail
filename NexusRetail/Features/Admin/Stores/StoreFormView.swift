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
    
    @State private var razorpayConfig = PaymentTerminalConfig(isEnabled: false, status: .notConfigured, environment: .test, credential1: nil, credential2: nil, updatedAt: nil)
    @State private var stripeConfig = PaymentTerminalConfig(isEnabled: false, status: .notConfigured, environment: .test, credential1: nil, credential2: nil, updatedAt: nil)
    @State private var providerToConfigure: PaymentProvider? = nil
    
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
            _country = State(initialValue: store.country ?? "")
            _city = State(initialValue: store.city ?? "")
            if let lat = store.latitude, let lng = store.longitude {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                _pickedCoordinate = State(initialValue: coord)
                _position = State(initialValue: .camera(MapCamera(centerCoordinate: coord, distance: 5000)))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Store Image Placeholder
                Section {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(RSMSColors.cardBackground)
                            .frame(height: 160)
                            .overlay {
                                VStack(spacing: 10) {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 34))
                                        .foregroundStyle(RSMSColors.burgundy)
                                    
                                    Text("Store Image")
                                        .font(.headline)
                                        .foregroundStyle(RSMSColors.darkBrown)
                                    
                                    Text("Visual placeholder")
                                        .font(.caption)
                                        .foregroundStyle(RSMSColors.secondaryText)
                                }
                            }
                    }
                    .listRowInsets(EdgeInsets())
                }
                .listRowInsets(EdgeInsets())
                
                if editingStore != nil {
                    Section("Store Status") {
                        Toggle("Store is Active", isOn: $isActive)
                    }
                }

                Section("Basic Details") {
                    TextField("Store Name", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address & Location") {
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
                
                Section("Localization") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    .tint(RSMSColors.burgundy)
                    
                    Picker("Locale", selection: $locale) {
                        ForEach(locales, id: \.self) { Text($0) }
                    }
                    .tint(RSMSColors.burgundy)
                    
                    Picker("Timezone", selection: $timezone) {
                        ForEach(timezones, id: \.self) { Text($0) }
                    }
                    .tint(RSMSColors.burgundy)
                }
                
                Section("Staffing") {
                    Picker("Manager", selection: $selectedManagerID) {
                        Text("None").tag(UUID?(nil))
                        // Only show managers not already assigned to another store.
                        // When editing, the current store's own manager is always included.
                        ForEach(viewModel.availableManagers(excludingStoreID: editingStore?.id)) { manager in
                            Text(manager.name ?? "Unknown").tag(manager.id as UUID?)
                        }
                    }
                    .tint(RSMSColors.burgundy)

                    if viewModel.availableManagers(excludingStoreID: editingStore?.id).isEmpty
                        && selectedManagerID == nil {
                        Text("All managers are currently assigned to stores.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Payment Gateways"), footer: Text("Configure payment gateways for your store so you can start accepting payments.")) {
                    LocalProviderCard(config: $razorpayConfig, provider: .razorpay) {
                        providerToConfigure = .razorpay
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                    
                    LocalProviderCard(config: $stripeConfig, provider: .card) {
                        providerToConfigure = .card
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(editingStore != nil ? "Edit Store" : "Add New Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(RSMSColors.burgundy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editingStore == nil ? "Save" : "Update") {
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
                                    status: isActive ? .active : .archived,
                                    latitude: pickedCoordinate?.latitude,
                                    longitude: pickedCoordinate?.longitude,
                                    city: city,
                                    country: country
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
                                    razorpayConfig: razorpayConfig,
                                    stripeConfig: stripeConfig,
                                    latitude: pickedCoordinate?.latitude,
                                    longitude: pickedCoordinate?.longitude,
                                    city: city,
                                    country: country
                                )
                                if success != nil { dismiss() }
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .tint(RSMSColors.burgundy)
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
            .sheet(item: $providerToConfigure) { provider in
                if provider == .razorpay {
                    LocalPaymentConfigView(config: $razorpayConfig, provider: .razorpay)
                } else {
                    LocalPaymentConfigView(config: $stripeConfig, provider: .card)
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

struct LocalProviderCard: View {
    @Binding var config: PaymentTerminalConfig
    let provider: PaymentProvider
    let onTapConfigure: () -> Void
    
    var body: some View {
        Button {
            // Only allow config if enabled
            if config.isEnabled {
                onTapConfigure()
            } else {
                config.isEnabled = true
                onTapConfigure()
            }
        } label: {
            VStack(spacing: 0) {
                // Top Row: Icon + Info + Toggle
                HStack(spacing: RSMSSpacing.md) {
                    // Provider icon in a burgundy circle
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.12))
                            .frame(width: 48, height: 48)

                        Image(systemName: provider.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(RSMSColors.burgundy)
                    }

                    // Name + subtitle
                    VStack(alignment: .leading, spacing: 3) {
                        Text(provider.displayName)
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.primaryText)

                        Text(provider.subtitle)
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    // Toggle
                    Toggle("", isOn: $config.isEnabled)
                        .labelsHidden()
                        .tint(RSMSColors.burgundy)
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.md)

                // Divider
                Rectangle()
                    .fill(RSMSColors.divider)
                    .frame(height: 1)
                    .padding(.horizontal, RSMSSpacing.lg)

                // Bottom Row: Status pill + Chevron
                HStack {
                    StatusPill.forPaymentStatus(config.status)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(RSMSColors.secondaryText)
                        .padding(.leading, RSMSSpacing.sm)
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.vertical, RSMSSpacing.md)
            }
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
