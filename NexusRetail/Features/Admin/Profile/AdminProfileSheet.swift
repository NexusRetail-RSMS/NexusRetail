//
//  AdminProfileSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI
import Supabase

struct AdminProfileSheet: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    // Edit states
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var selectedCountry = "United States"
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var currentImageUrl: String? = nil

    private let countries = [
        "United States", "United Kingdom", "Canada", "Australia",
        "India", "Germany", "France", "Japan", "United Arab Emirates",
        "Singapore"
    ]

    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasEmail = !email.trimmingCharacters(in: .whitespaces).isEmpty
        return hasFirstName && hasEmail && !isSaving
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Avatar Header Section
                Section {
                    VStack(spacing: 14) {
                        if isEditing {
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(RSMSColors.burgundy.opacity(0.15))
                                        .frame(width: 110, height: 110)

                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                    } else if let urlString = currentImageUrl, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
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
                                            .frame(width: 58, height: 58)
                                            .foregroundColor(RSMSColors.burgundy)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .onChange(of: photoPickerItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            self.selectedImageData = data
                                            self.selectedImage = uiImage
                                        }
                                    }
                                }
                            }


                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                Text(selectedImage == nil && currentImageUrl == nil ? "Add Photo" : "Change Photo")
                                    .font(RSMSFonts.subheadline.weight(.medium))
                                    .foregroundColor(RSMSColors.primaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(RSMSColors.burgundy.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.burgundy.opacity(0.15))
                                    .frame(width: 110, height: 110)

                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                } else if let urlString = sessionStore.currentUser?.imageUrl, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
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
                                        .frame(width: 58, height: 58)
                                        .foregroundColor(RSMSColors.burgundy)
                                }
                            }
                            Text(sessionStore.currentUser?.name ?? "Admin User")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if isEditing {
                    // MARK: - EDIT MODE PLATTER (like img2)
                    Section("Manager Details") {
                        TextField("First Name", text: $firstName)
                            .autocorrectionDisabled()
                        TextField("Last Name", text: $lastName)
                            .autocorrectionDisabled()
                        Picker("Country", selection: $selectedCountry) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        .tint(RSMSColors.burgundy)
                    }

                    Section("Contact") {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)

                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)

                        TextField("Store Location / Address", text: $address)
                    }
                } else {
                    // MARK: - VIEW MODE
                    // MARK: - Pill 1: Role · Phone · Email
                    Section {
                        infoRow(icon: "person.badge.shield.checkmark.fill",
                                label: "Role",
                                value: sessionStore.currentRole?.displayName ?? "Admin",
                                valueColor: RSMSColors.burgundy)

                        infoRow(icon: "phone.fill",
                                label: "Phone",
                                value: sessionStore.currentUser?.phone ?? "—")

                        infoRow(icon: "envelope.fill",
                                label: "Email",
                                value: sessionStore.currentUser?.email ?? "—")
                    }

                    // MARK: - Pill 2: Address · Country
                    Section {
                        infoRow(icon: "mappin.and.ellipse",
                                label: "Address",
                                value: sessionStore.currentUser?.address ?? "—",
                                multiline: true)

                        infoRow(icon: "globe",
                                label: "Country",
                                value: country(from: sessionStore.currentUser?.address),
                                valueColor: RSMSColors.burgundy)
                    }

                    // MARK: - Payment Configuration
                    Section {
                        NavigationLink(destination: AdminStorePaymentSelectorView()) {
                            Label {
                                Text("Payment Configuration")
                            } icon: {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                        }
                    }

                    // MARK: - Sign Out
                    Section {
                        Button(role: .destructive) {
                            Task {
                                dismiss()
                                try? await sessionStore.signOut()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .accessibilityHint("Signs you out of your account and returns to the login screen")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .alert("Error Saving Profile", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        // Cancel → xmark icon (IMG5)
                        Button {
                            isEditing = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    } else {
                        // Dismiss sheet (non-edit mode)
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        if isSaving {
                            ProgressView()
                        } else {
                            // Save → checkmark icon (IMG5)
                            Button {
                                saveChanges()
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isFormValid ? RSMSColors.burgundy : Color.secondary)
                            }
                            .disabled(!isFormValid)
                        }
                    } else {
                        // Edit button on right (non-edit mode)
                        Button("Edit") {
                            startEditing()
                        }
                        .font(.system(.body).weight(.semibold))
                        .tint(RSMSColors.burgundy)
                    }
                }
            }
        }
    }

    // MARK: - Native Info Row
    @ViewBuilder
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .secondary,
        multiline: Bool = false
    ) -> some View {
        HStack(alignment: multiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(RSMSColors.burgundy)
                .frame(width: 20)

            Text(label)

            Spacer()

            Text(value)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(multiline ? 3 : 1)
        }
    }

    private func startEditing() {
        let name = sessionStore.currentUser?.name ?? ""
        let parts = name.components(separatedBy: " ")
        firstName = parts.first ?? ""
        lastName = parts.dropFirst().joined(separator: " ")
        phone = sessionStore.currentUser?.phone ?? ""
        email = sessionStore.currentUser?.email ?? ""

        let rawAddress = sessionStore.currentUser?.address ?? ""
        let derivedCountry = country(from: rawAddress)
        selectedCountry = countries.contains(derivedCountry) ? derivedCountry : "United States"

        if !rawAddress.isEmpty, rawAddress.hasSuffix(derivedCountry) {
            let index = rawAddress.index(rawAddress.endIndex, offsetBy: -derivedCountry.count)
            let prefix = String(rawAddress[..<index]).trimmingCharacters(in: .whitespaces)
            if prefix.hasSuffix(",") {
                address = String(prefix.dropLast()).trimmingCharacters(in: .whitespaces)
            } else {
                address = prefix
            }
        } else {
            address = rawAddress
        }

        currentImageUrl = sessionStore.currentUser?.imageUrl
        selectedImageData = nil
        selectedImage = nil
        photoPickerItem = nil
        isEditing = true
    }

    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        let path = "profiles/\(UUID().uuidString).jpg"
        let fileOptions = FileOptions(contentType: "image/jpeg")
        try await SupabaseManager.shared.client.storage
            .from("product-images")
            .upload(path, data: data, options: fileOptions)

        let url = try SupabaseManager.shared.client.storage
            .from("product-images")
            .getPublicURL(path: path)
        return url.absoluteString
    }

    private func saveChanges() {
        guard let user = sessionStore.currentUser else { return }

        // Compute new profile fields immediately
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        let finalAddress: String
        if !address.isEmpty {
            finalAddress = "\(address), \(selectedCountry)"
        } else {
            finalAddress = selectedCountry
        }

        // Cache selected photo locally to document/cache directory immediately
        var localImageUrl = user.imageUrl
        if let data = selectedImageData {
            localImageUrl = saveImageLocally(data)
        }

        // 1. Instantly update UI text values locally so the user sees the updates without lag
        let temporaryUser = AppUser(
            id: user.id,
            name: fullName,
            email: email,
            role: user.role,
            storeID: user.storeID,
            isActive: user.isActive,
            phone: phone,
            address: finalAddress,
            imageUrl: localImageUrl // display local cache path immediately
        )
        sessionStore.currentUser = temporaryUser
        isEditing = false

        // 2. Run image upload and database updates in a background task
        let pickedImage = selectedImage
        let originalImageUrl = currentImageUrl

        Task(priority: .background) {
            var uploadedUrl = originalImageUrl

            if let image = pickedImage {
                do {
                    uploadedUrl = try await uploadImage(image)
                } catch {
                    print("Failed to upload profile photo in background: \(error)")
                }
            }

            let updateData: [String: String?] = [
                "name": fullName,
                "phone": phone,
                "email": email,
                "address": finalAddress,
                "image_url": uploadedUrl
            ]

            do {
                try await SupabaseManager.shared.client
                    .from("app_user")
                    .update(updateData)
                    .eq("id", value: user.id.uuidString)
                    .execute()

                // 3. Finalize local state on MainActor with the permanent remote image URL
                await MainActor.run {
                    let finalUser = AppUser(
                        id: user.id,
                        name: fullName,
                        email: email,
                        role: user.role,
                        storeID: user.storeID,
                        isActive: user.isActive,
                        phone: phone,
                        address: finalAddress,
                        imageUrl: uploadedUrl
                    )
                    sessionStore.currentUser = finalUser
                    // Clear selectedImage reference so we display the uploaded URL
                    self.selectedImage = nil
                }
            } catch {
                print("Failed to save background profile changes: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func getLocalAvatarURL() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("profile_avatar_temp.jpg")
    }

    private func saveImageLocally(_ data: Data) -> String? {
        let url = getLocalAvatarURL()
        do {
            try data.write(to: url)
            return url.absoluteString
        } catch {
            print("Failed to write image locally: \(error)")
            return nil
        }
    }

    /// Extracts the country from the last comma-separated component of the address.
    private func country(from address: String?) -> String {
        guard let address = address, !address.isEmpty else { return "—" }
        let components = address.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return components.last ?? "—"
    }
}





// MARK: - Store Selector for Payment Configuration
struct AdminStorePaymentSelectorView: View {
    @State private var stores: [Store] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            Group {
                if isLoading {
                    ProgressView("Loading stores...")
                        .tint(RSMSColors.burgundy)
                        .frame(maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: RSMSSpacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(RSMSColors.error)
                        Text(error)
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else if stores.isEmpty {
                    VStack(spacing: RSMSSpacing.md) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 64))
                            .foregroundColor(RSMSColors.burgundy)
                        Text("No Stores Found")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(stores) { store in
                            NavigationLink(destination: PaymentConfigurationView(isAdmin: true, storeID: store.id)) {
                                HStack(spacing: 12) {
                                    Image(systemName: store.isWarehouse == true ? "shippingbox.fill" : "building.2.fill")
                                        .foregroundColor(RSMSColors.burgundy)
                                        .font(.system(size: 18))
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(store.name)
                                            .font(RSMSFonts.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(RSMSColors.primaryText)
                                        if let address = store.address {
                                            Text(address)
                                                .font(RSMSFonts.caption)
                                                .foregroundColor(RSMSColors.secondaryText)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Select Store")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStores()
        }
    }
    
    private func loadStores() async {
        isLoading = true
        errorMessage = nil
        do {
            self.stores = try await StoreRepository().fetchStores()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
