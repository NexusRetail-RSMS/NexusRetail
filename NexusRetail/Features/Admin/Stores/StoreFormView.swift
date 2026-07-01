import SwiftUI
import MapKit
import PhotosUI

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
    @State private var position: MapCameraPosition
    @State private var locale: String = "en_IN"
    @State private var currencyCode: String = "INR"
    @State private var timezone: String = "Asia/Kolkata"
    @State private var selectedManagerID: UUID? = nil
    @State private var isActive: Bool = true
    @State private var includeRazorpay: Bool = false
    @State private var includeCard: Bool = false
    @State private var isShowingManagerPicker = false
    @State private var geocodeTask: Task<Void, Never>? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @FocusState private var focusedField: Field?

    private enum Field {
        case pin, city, state, country, phone, name
    }

    private var currencies: [String] { CountryLocalizationLookup.currencies }
    private var locales: [String] { CountryLocalizationLookup.locales }
    private var timezones: [String] { CountryLocalizationLookup.timezones }

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
            } else {
                _position = State(initialValue: .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 22.3511, longitude: 78.6677), distance: 3_000_000)))
            }
        } else {
            _position = State(initialValue: .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 22.3511, longitude: 78.6677), distance: 3_000_000)))
        }
    }

    private var selectedManager: DisplayManager? {
        guard let id = selectedManagerID else { return nil }
        return viewModel.managers.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: RSMSSpacing.xl) {
                    imageHero

                    if editingStore != nil {
                        statusCard
                    }

                    FormSectionCard(title: "Basic Details") {
                        PremiumTextField(icon: "building.2.fill", placeholder: "Store Name", text: $name)
                            .focused($focusedField, equals: .name)
                        FormDivider()
                        PremiumTextField(icon: "phone.fill", placeholder: "Phone Number", text: $phone, keyboardType: .phonePad)
                            .focused($focusedField, equals: .phone)
                    }

                    FormSectionCard(title: "Address & Location") {
                        PremiumTextField(icon: "mappin.and.ellipse", placeholder: "Exact Address / Pin Location", text: $pinLocation)
                            .focused($focusedField, equals: .pin)
                            .onChange(of: pinLocation) { _, _ in scheduleGeocode() }
                        FormDivider()
                        PremiumTextField(icon: "building.columns.fill", placeholder: "City", text: $city)
                            .focused($focusedField, equals: .city)
                            .onChange(of: city) { _, _ in scheduleGeocode() }
                        FormDivider()
                        PremiumTextField(icon: "map.fill", placeholder: "State", text: $state)
                            .focused($focusedField, equals: .state)
                            .onChange(of: state) { _, _ in scheduleGeocode() }
                        FormDivider()
                        PremiumTextField(icon: "flag.fill", placeholder: "Country", text: $country)
                            .focused($focusedField, equals: .country)
                            .onChange(of: country) { _, _ in
                                scheduleGeocode()
                                applyAutoLocalization()
                            }

                        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
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
                                .onTapGesture { tapPosition in
                                    if let coordinate = proxy.convert(tapPosition, from: .local) {
                                        pickedCoordinate = coordinate
                                        withAnimation { position = .camera(MapCamera(centerCoordinate: coordinate, distance: 5000)) }
                                        reverseGeocode(coordinate: coordinate)
                                    }
                                }
                                .frame(height: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(RSMSColors.cardBorder, lineWidth: 1)
                                )
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 10.5))
                                Text("Type an address above, or tap the map to drop a pin")
                                    .font(.system(size: 11.5))
                            }
                            .foregroundColor(RSMSColors.secondaryText)
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.vertical, RSMSSpacing.md)
                    }

                    if editingStore != nil {
                        FormSectionCard(title: "Manager") {
                            Button {
                                isShowingManagerPicker = true
                            } label: {
                                HStack(spacing: RSMSSpacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(RSMSColors.burgundy.opacity(0.12))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: selectedManager == nil ? "person.badge.plus" : "person.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(RSMSColors.burgundy)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Manager")
                                            .font(.system(size: 11.5, weight: .medium))
                                            .foregroundColor(RSMSColors.secondaryText)
                                        Text(selectedManager?.name ?? "None assigned")
                                            .font(.system(size: 14.5, weight: .medium))
                                            .foregroundColor(selectedManager == nil ? RSMSColors.secondaryText : RSMSColors.primaryText)
                                    }

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                                }
                                .padding(.horizontal, RSMSSpacing.lg)
                                .padding(.vertical, RSMSSpacing.md)
                            }
                            .buttonStyle(.plain)

                            if viewModel.availableManagers(excludingStoreID: editingStore?.id).isEmpty && selectedManagerID == nil {
                                FormDivider()
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 12))
                                    Text("All managers are currently assigned to stores")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(RSMSColors.secondaryText)
                                .padding(.horizontal, RSMSSpacing.lg)
                                .padding(.bottom, RSMSSpacing.md)
                            }
                        }
                    }

                    FormSectionCard(title: "Payment Terminals") {
                        PremiumToggleRow(icon: "creditcard.fill", title: "Razorpay", isOn: $includeRazorpay)
                        FormDivider()
                        PremiumToggleRow(icon: "wave.3.right.circle.fill", title: "Card Terminal", isOn: $includeCard)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(RSMSColors.error)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(RSMSColors.error)
                        }
                        .padding(RSMSSpacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RSMSColors.error.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSRadius.large)
                                .stroke(RSMSColors.error.opacity(0.2), lineWidth: 1)
                        )
                    }

                    saveButton
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.xxxxl)
            }
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationTitle(editingStore != nil ? "Edit Store" : "Add New Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(RSMSColors.burgundy)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .tint(RSMSColors.burgundy)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(RSMSColors.burgundy)
                        Text("Saving…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                }
            }
            .sheet(isPresented: $isShowingManagerPicker) {
                ManagerPickerSheet(
                    managers: viewModel.availableManagers(excludingStoreID: editingStore?.id),
                    selectedManagerID: $selectedManagerID
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }

    private var imageHero: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottom) {
                Group {
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else if let urlString = editingStore?.imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            imagePlaceholder
                        }
                    } else {
                        imagePlaceholder
                    }
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 70)

                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Tap to update photo")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.bottom, 12)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [RSMSColors.burgundy.opacity(0.10), RSMSColors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(RSMSColors.burgundy)
                }
                Text("Store Image")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
            }
        }
    }

    private var statusCard: some View {
        FormSectionCard(title: "Store Status") {
            HStack(spacing: RSMSSpacing.md) {
                ZStack {
                    Circle()
                        .fill((isActive ? RSMSColors.success : RSMSColors.secondaryText).opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isActive ? RSMSColors.success : RSMSColors.secondaryText)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Store is Active")
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundColor(RSMSColors.primaryText)
                    Text(isActive ? "Visible and operational" : "Archived and hidden")
                        .font(.system(size: 11.5))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                Spacer()
                Toggle("", isOn: $isActive)
                    .labelsHidden()
                    .tint(RSMSColors.burgundy)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.vertical, RSMSSpacing.md)
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                let fullAddress = [pinLocation, city, state, country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")

                if let store = editingStore {
                    let success = await viewModel.update(
                        storeId: store.id,
                        name: name,
                        address: fullAddress,
                        phone: phone,
                        locale: locale,
                        currencyCode: currencyCode,
                        timezone: timezone,
                        managerID: selectedManagerID,
                        status: isActive ? .active : .archived,
                        latitude: pickedCoordinate?.latitude,
                        longitude: pickedCoordinate?.longitude,
                        city: city,
                        country: country,
                        imageData: selectedImageData
                    )
                    if success { dismiss() }
                } else {
                    let success = await viewModel.create(
                        name: name,
                        address: fullAddress,
                        phone: phone,
                        locale: locale,
                        currencyCode: currencyCode,
                        timezone: timezone,
                        managerID: selectedManagerID,
                        status: isActive ? .active : .archived,
                        includeRazorpay: includeRazorpay,
                        includeCard: includeCard,
                        latitude: pickedCoordinate?.latitude,
                        longitude: pickedCoordinate?.longitude,
                        city: city,
                        country: country,
                        imageData: selectedImageData
                    )
                    if success { dismiss() }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: editingStore != nil ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text(editingStore != nil ? "Update Store" : "Create Store")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: RSMSColors.burgundy.opacity(0.30), radius: 14, x: 0, y: 8)
            .opacity(name.isEmpty || viewModel.isLoading ? 0.5 : 1)
        }
        .buttonStyle(PremiumPressStyle())
        .disabled(viewModel.isLoading || name.isEmpty)
        .padding(.top, RSMSSpacing.sm)
    }

    private func applyAutoLocalization() {
        guard let match = CountryLocalizationLookup.match(for: country) else { return }
        locale = match.locale
        currencyCode = match.currencyCode
        timezone = match.timezone
    }

    private func scheduleGeocode() {
        geocodeTask?.cancel()
        geocodeTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            await forwardGeocode()
        }
    }

    private func forwardGeocode() async {
        let query = [pinLocation, city, state, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        guard !query.isEmpty else { return }

        if query.trimmingCharacters(in: .whitespaces).count < 3 { return }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            guard !Task.isCancelled, let coordinate = placemarks.first?.location?.coordinate else { return }
            await MainActor.run {
                pickedCoordinate = coordinate
                withAnimation {
                    position = .camera(MapCamera(centerCoordinate: coordinate, distance: pinLocation.isEmpty ? 400_000 : 5000))
                }
            }
        } catch {
            if let match = CountryLocalizationLookup.match(for: country), pinLocation.isEmpty, city.isEmpty, state.isEmpty {
                await MainActor.run {
                    withAnimation {
                        position = .camera(MapCamera(centerCoordinate: match.coordinate, distance: 3_000_000))
                    }
                }
            }
        }
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.country = placemark.country ?? self.country
                    self.state = placemark.administrativeArea ?? self.state
                    self.city = placemark.locality ?? self.city

                    var exactPin = ""
                    if let subThoroughfare = placemark.subThoroughfare { exactPin += subThoroughfare + " " }
                    if let thoroughfare = placemark.thoroughfare { exactPin += thoroughfare + ", " }
                    if let postalCode = placemark.postalCode { exactPin += postalCode }
                    self.pinLocation = exactPin.trimmingCharacters(in: .whitespacesAndNewlines)

                    self.applyAutoLocalization()
                }
            }
        }
    }
}

private struct FormSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(RSMSColors.burgundy)
                    .frame(width: 3, height: 16)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.md)

            VStack(spacing: 0) {
                content()
            }
        }
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
    }
}

private struct FormDivider: View {
    var body: some View {
        Rectangle()
            .fill(RSMSColors.divider)
            .frame(height: 0.5)
            .padding(.leading, RSMSSpacing.lg + 38 + RSMSSpacing.md)
    }
}

private struct PremiumTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        LinearGradient(
                            colors: [RSMSColors.burgundy.opacity(0.12), RSMSColors.burgundy.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.burgundy)
            }

            TextField(placeholder, text: $text)
                .font(.system(size: 14.5, weight: .medium))
                .foregroundColor(RSMSColors.primaryText)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(keyboardType == .phonePad)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, RSMSSpacing.md)
    }
}

private struct PremiumMenuRow: View {
    let icon: String
    let title: String
    let value: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        } label: {
            HStack(spacing: RSMSSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(
                            LinearGradient(
                                colors: [RSMSColors.burgundy.opacity(0.12), RSMSColors.burgundy.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(RSMSColors.burgundy)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                    Text(value)
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundColor(RSMSColors.primaryText)
                }

                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.vertical, RSMSSpacing.md)
        }
        .tint(RSMSColors.primaryText)
    }
}

private struct PremiumToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        LinearGradient(
                            colors: [RSMSColors.burgundy.opacity(0.12), RSMSColors.burgundy.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.burgundy)
            }

            Text(title)
                .font(.system(size: 14.5, weight: .medium))
                .foregroundColor(RSMSColors.primaryText)

            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(RSMSColors.burgundy)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, RSMSSpacing.md)
    }
}

private struct ManagerPickerSheet: View {
    let managers: [DisplayManager]
    @Binding var selectedManagerID: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [DisplayManager] {
        if searchText.isEmpty { return managers }
        return managers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: RSMSSpacing.md) {
                    Button {
                        selectedManagerID = nil
                        dismiss()
                    } label: {
                        HStack(spacing: RSMSSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.background)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                            .foregroundColor(RSMSColors.cardBorder)
                                    )
                                Image(systemName: "xmark")
                                    .font(.system(size: 14))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            Text("None")
                                .font(.system(size: 14.5, weight: .medium))
                                .foregroundColor(RSMSColors.primaryText)
                            Spacer()
                            if selectedManagerID == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                        }
                        .padding(RSMSSpacing.md)
                        .background(RSMSColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSRadius.large)
                                .stroke(RSMSColors.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    if filtered.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 34))
                                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                            Text("No available managers")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ForEach(filtered) { manager in
                            Button {
                                selectedManagerID = manager.id
                                dismiss()
                            } label: {
                                HStack(spacing: RSMSSpacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(RSMSColors.burgundy.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        if let urlString = manager.imageUrl, let url = URL(string: urlString) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(Circle())
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(RSMSColors.burgundy)
                                            }
                                        } else {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(RSMSColors.burgundy)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(manager.name)
                                            .font(.system(size: 14.5, weight: .medium))
                                            .foregroundColor(RSMSColors.primaryText)
                                        HStack(spacing: 4) {
                                            Text(flagEmoji(for: manager.country))
                                                .font(.system(size: 12))
                                            Text(manager.country)
                                                .font(.system(size: 12))
                                                .foregroundColor(RSMSColors.secondaryText)
                                        }
                                    }

                                    Spacer()
                                    if selectedManagerID == manager.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(RSMSColors.burgundy)
                                    }
                                }
                                .padding(RSMSSpacing.md)
                                .background(RSMSColors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
                                .overlay(
                                    RoundedRectangle(cornerRadius: RSMSRadius.large)
                                        .stroke(RSMSColors.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(RSMSSpacing.lg)
            }
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationTitle("Select Manager")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search managers")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(RSMSColors.burgundy)
                }
            }
        }
    }
}
