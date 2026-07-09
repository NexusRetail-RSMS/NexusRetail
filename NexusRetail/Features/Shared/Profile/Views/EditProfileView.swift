import SwiftUI
import _PhotosUI_SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme
    
    @Bindable var viewModel: ProfileViewModel
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var country: String = ""
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    private var hasChanges: Bool {
        guard let profile = viewModel.profile else { return false }
        return firstName != profile.firstName ||
               lastName != profile.lastName ||
               phone != profile.phone ||
               email != profile.email ||
               address != profile.address ||
               country != profile.country ||
               selectedImageData != nil
    }
    
    var body: some View {
        ZStack {
            theme.groupedBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .zIndex(1)
            }
            
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else if let imageUrl = viewModel.profile?.profileImage, let url = URL(string: imageUrl) {
                                            CachedAsyncImage(url: url) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        } else {
                                            ZStack {
                                                theme.cardBackground
                                                Image(systemName: "person.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(24)
                                                    .foregroundColor(theme.primaryAction.opacity(0.5))
                                            }
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(theme.cardBorder, lineWidth: 1))
                                    
                                    ZStack {
                                        Circle()
                                            .fill(theme.primaryAction)
                                            .frame(width: 32, height: 32)
                                            .overlay(Circle().stroke(theme.cardBackground, lineWidth: 3))
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .offset(x: 4, y: 4)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        selectedImageData = data
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                }
                
                Section(header: Text("Contact Details")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                
                Section(header: Text("Location")) {
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)
                    TextField("Country", text: $country)
                        .textContentType(.countryName)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.groupedBackground)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(hasChanges ? theme.primaryAction : .gray)
                .disabled(!hasChanges || viewModel.isLoading)
            }
        }
        .onAppear {
            if let profile = viewModel.profile {
                firstName = profile.firstName
                lastName = profile.lastName
                phone = profile.phone
                email = profile.email
                address = profile.address
                country = profile.country
            }
        }
    }
    
    private func saveChanges() {
        Task {
            if let data = selectedImageData {
                let _ = try? await viewModel.uploadProfileImage(data)
            }
            
            try? await viewModel.updateProfile(
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                email: email,
                address: address,
                country: country
            )
            dismiss()
        }
    }
}
