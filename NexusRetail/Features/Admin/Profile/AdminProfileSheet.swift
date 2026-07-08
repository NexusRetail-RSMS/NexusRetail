//
//  AdminProfileSheet.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI
import Supabase

// MARK: - Performance Tier
enum PerformanceTier {
    case gold, silver, bronze, none
    
    var label: String {
        switch self {
        case .gold:   return "Top Performer"
        case .silver: return "Silver Tier"
        case .bronze: return "Bronze Tier"
        case .none:   return ""
        }
    }
    
    var icon: String {
        switch self {
        case .gold:   return "crown.fill"
        case .silver: return "medal.fill"
        case .bronze: return "medal"
        case .none:   return ""
        }
    }
    
    var ringColors: [Color] {
        switch self {
        case .gold:
            return [
                Color(red: 1.0,  green: 0.84, blue: 0.0),
                Color(red: 1.0,  green: 0.65, blue: 0.0),
                Color(red: 1.0,  green: 0.90, blue: 0.4),
                Color(red: 0.85, green: 0.65, blue: 0.13),
                Color(red: 1.0,  green: 0.84, blue: 0.0)
            ]
        case .silver:
            return [
                Color(red: 0.85, green: 0.85, blue: 0.88),
                Color(red: 0.60, green: 0.60, blue: 0.65),
                Color(red: 0.95, green: 0.95, blue: 1.0),
                Color(red: 0.70, green: 0.70, blue: 0.75),
                Color(red: 0.85, green: 0.85, blue: 0.88)
            ]
        case .bronze:
            return [
                Color(red: 0.80, green: 0.50, blue: 0.20),
                Color(red: 0.55, green: 0.27, blue: 0.07),
                Color(red: 0.93, green: 0.64, blue: 0.33),
                Color(red: 0.65, green: 0.37, blue: 0.12),
                Color(red: 0.80, green: 0.50, blue: 0.20)
            ]
        case .none:
            return [Color.gray.opacity(0.3)]
        }
    }
    
    var backgroundGradient: [Color] {
        switch self {
        case .gold:
            return [
                Color(red: 1.0,  green: 0.95, blue: 0.70),
                Color(red: 1.0,  green: 0.88, blue: 0.40),
                Color(red: 0.95, green: 0.78, blue: 0.20)
            ]
        case .silver:
            return [
                Color(red: 0.94, green: 0.94, blue: 0.97),
                Color(red: 0.82, green: 0.82, blue: 0.88),
                Color(red: 0.70, green: 0.70, blue: 0.78)
            ]
        case .bronze:
            return [
                Color(red: 1.0,  green: 0.90, blue: 0.75),
                Color(red: 0.93, green: 0.70, blue: 0.40),
                Color(red: 0.78, green: 0.52, blue: 0.20)
            ]
        case .none:
            return [Color(hex: "F9F8F3")]
        }
    }
    
    var textColor: Color {
        switch self {
        case .gold:   return Color(red: 0.6,  green: 0.45, blue: 0.0)
        case .silver: return Color(red: 0.35, green: 0.35, blue: 0.45)
        case .bronze: return Color(red: 0.50, green: 0.28, blue: 0.06)
        case .none:   return .clear
        }
    }
}

struct AdminProfileSheet: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme
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

    // Performance tier — in production, derive from store revenue ranking
    // Gold = rank 1, Silver = rank 2, Bronze = rank 3
    @State private var performanceTier: PerformanceTier = .gold
    @State private var ringRotation: Double = 0
    
    private var effectivePerformanceTier: PerformanceTier {
        if sessionStore.currentRole == .manager || sessionStore.currentUser?.role == .manager {
            return performanceTier
        }
        return .none
    }

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
                    VStack(spacing: 12) {
                        // Avatar with performance ring
                        ZStack {
                            if effectivePerformanceTier != .none {
                                // Outer rotating shiny ring
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            colors: effectivePerformanceTier.ringColors,
                                            center: .center,
                                            angle: .degrees(ringRotation)
                                        ),
                                        lineWidth: 5
                                    )
                                    .frame(width: 126, height: 126)
                                    .blur(radius: 0.5)
                                    .onAppear {
                                        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                            ringRotation = 360
                                        }
                                    }
                                
                                // Glittery sparkle dots
                                ForEach(0..<8, id: \.self) { i in
                                    sparkleDot(index: i)
                                }
                            }
                            
                            // Gap ring — adapts to dark mode
                            Circle()
                                .stroke(theme.isDarkMode ? Color(hex: "1C1C1C") : Color.white, lineWidth: 4)
                                .frame(width: 118, height: 118)
                            
                            // Profile photo
                            ZStack {
                                Circle()
                                    .fill(theme.isDarkMode
                                          ? Color(hex: "2C0000")
                                          : theme.burgundy.opacity(0.15))
                                    .frame(width: 110, height: 110)

                                if isEditing {
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable().scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                    } else if let urlString = currentImageUrl, let url = URL(string: urlString) {
                                        CachedAsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                        } placeholder: { ProgressView().frame(width: 110, height: 110) }
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable().scaledToFit()
                                            .frame(width: 58, height: 58)
                                            .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                                    }
                                } else {
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable().scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                    } else if let urlString = sessionStore.currentUser?.imageUrl, let url = URL(string: urlString) {
                                        CachedAsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                        } placeholder: { ProgressView().frame(width: 110, height: 110) }
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable().scaledToFit()
                                            .frame(width: 58, height: 58)
                                            .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                                    }
                                }
                            }
                        }
                            
                            // Name
                            if isEditing {
                                editPhotoButton
                            } else {
                                Text(sessionStore.currentUser?.name ?? "Admin User")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.primaryText)
                                
                                // Performance tier badge
                                if effectivePerformanceTier != .none {
                                    tierBadgeView
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                }
                .listRowBackground(
                    // Gradient fills behind the avatar — no more floating dark void
                    LinearGradient(
                        colors: theme.isDarkMode
                            ? [Color(hex: "3D0000"), Color(hex: "1C1007"), Color(hex: "1C1C1C")]
                            : [theme.burgundy.opacity(0.12), theme.cream.opacity(0.6)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .listRowInsets(EdgeInsets())

                if isEditing {
                    // MARK: - EDIT MODE PLATTER (like img2)
                    Section("Admin Details") {
                        TextField("First Name", text: $firstName)
                            .autocorrectionDisabled()
                        TextField("Last Name", text: $lastName)
                            .autocorrectionDisabled()
                       
                        .tint(theme.burgundy)
                    }

                    Section("Contact Details") {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)

                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)

                        TextField("Address", text: $address)
                        
                        Picker("Country", selection: $selectedCountry) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                    }
                } else {
                    // MARK: - VIEW MODE
                    // MARK: - Pill 1: Role · Phone · Email
                    Section {
                        infoRow(icon: "person.badge.shield.checkmark.fill",
                                label: "Role",
                                value: sessionStore.currentRole?.displayName ?? "Admin",
                                valueColor: theme.isDarkMode ? theme.antiqueGold : theme.burgundy)

                        infoRow(icon: "phone.fill",
                                label: "Phone",
                                value: sessionStore.currentUser?.phone ?? "—")

                        infoRow(icon: "envelope.fill",
                                label: "Email",
                                value: sessionStore.currentUser?.email ?? "—")
                    }

                    // MARK: - Pill 2: Address · Country
                    Section {
                        infoRow(icon: "location.fill",
                                label: "Address",
                                value: sessionStore.currentUser?.address ?? "—",
                                multiline: true)

                        infoRow(icon: "globe",
                                label: "Country",
                                value: country(from: sessionStore.currentUser?.address),
                                valueColor: theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                    }


                    // MARK: - Preferences
                    Section("Preferences") {
                        LanguageSettingsButton()
                    }

                    // MARK: - Dark Mode Toggle
                    Section {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(theme.isDarkMode
                                          ? theme.antiqueGold.opacity(0.15)
                                          : theme.burgundy.opacity(0.10))
                                    .frame(width: 32, height: 32)
                                Image(systemName: theme.isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                            }
                            Text("Dark Mode")
                                .font(.system(size: 15))
                                .foregroundColor(theme.primaryText)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { theme.isDarkMode },
                                set: { theme.isDarkMode = $0 }
                            ))
                            .tint(theme.antiqueGold)
                        }
                    } footer: {
                        Text("Switch between midnight black and warm cream themes.")
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryText)
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
                        Button {
                            isEditing = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                        }
                    } else {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        if isSaving {
                            ProgressView()
                        } else {
                            Button {
                                saveChanges()
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isFormValid
                                                     ? (theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                                                     : Color.secondary)
                            }
                            .disabled(!isFormValid)
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                        .font(.system(.body).weight(.semibold))
                        .tint(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
                    }
                }
            }
        }
    }

    // MARK: - Edit Photo Button (extracted to avoid compiler timeout)
    private var editPhotoButton: some View {
        let labelText = (selectedImage == nil && currentImageUrl == nil) ? "Add Photo" : "Change Photo"
        let accentColor = theme.isDarkMode ? theme.antiqueGold : theme.burgundy
        return PhotosPicker(selection: $photoPickerItem, matching: .images) {
            Text(labelText)
                .font(RSMSFonts.subheadline.weight(.medium))
                .foregroundColor(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
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
    }

    // MARK: - Tier Badge (extracted to avoid compiler timeout)
    private var tierBadgeView: some View {
        let bgColors: [Color] = Array(effectivePerformanceTier.ringColors.prefix(3)).map { $0.opacity(0.25) }
        let strokeColors: [Color] = Array(effectivePerformanceTier.ringColors.prefix(3))
        return HStack(spacing: 6) {
            Image(systemName: effectivePerformanceTier.icon)
                .font(.system(size: 11, weight: .bold))
            Text(effectivePerformanceTier.label)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(effectivePerformanceTier.textColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(LinearGradient(colors: bgColors, startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            Capsule()
                .stroke(LinearGradient(colors: strokeColors, startPoint: .leading, endPoint: .trailing), lineWidth: 1.2)
        )
    }

    // MARK: - Sparkle dot helper (extracted to avoid compiler timeout)
    private func sparkleDot(index i: Int) -> some View {
        let angle = Double(i) * 45.0
        let radians = angle * .pi / 180
        let size: CGFloat = i % 2 == 0 ? 5 : 3
        let color = effectivePerformanceTier.ringColors.first ?? .yellow
        let xOffset = cos(radians) * 66
        let yOffset = sin(radians) * 66
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: xOffset, y: yOffset)
            .opacity(0.85)
            .blur(radius: 0.3)
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
                .foregroundColor(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
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
        // Resize image to max 400x400 to prevent timeouts
        let targetSize = CGSize(width: 400, height: 400)
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        guard let data = resizedImage.jpegData(compressionQuality: 0.5) else {
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

            // Prevent saving local file URLs to Supabase if an upload failed or was cached locally
            if let url = uploadedUrl, url.hasPrefix("file://") {
                uploadedUrl = nil
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





