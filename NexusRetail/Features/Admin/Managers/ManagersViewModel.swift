import SwiftUI
import Supabase

@Observable
class ManagersViewModel {
    var managers: [DisplayManager] = []
    var isLoading = false
    var errorMessage: String? = nil

    func loadManagers() async {
        isLoading = true
        errorMessage = nil

        do {
            let stats: [ManagerStatsRPC] = try await SupabaseManager.shared.client
                .rpc("get_manager_stats")
                .execute()
                .value
            
            // Fetch isActive statuses from app_user table
            struct UserStatus: Decodable {
                let id: UUID
                let is_active: Bool?
                enum CodingKeys: String, CodingKey {
                    case id
                    case is_active
                }
            }
            let statuses: [UserStatus] = try await SupabaseManager.shared.client
                .from("app_user")
                .select("id, is_active")
                .execute()
                .value
            let statusMap = Dictionary(uniqueKeysWithValues: statuses.map { ($0.id, $0.is_active ?? true) })

            self.managers = stats.map { stat in
                let revString = formatIndianCurrency(stat.revenue ?? 0)
                
                // Parse date
                var parsedDate = Date()
                if let dateStr = stat.createdAt {
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = isoFormatter.date(from: dateStr) {
                        parsedDate = date
                    } else {
                        let isoFormatter2 = ISO8601DateFormatter()
                        if let date = isoFormatter2.date(from: dateStr) {
                            parsedDate = date
                        }
                    }
                }
                
                return DisplayManager(
                    id: stat.id,
                    name: stat.name ?? "Unknown",
                    storeName: stat.storeName ?? "Unassigned",
                    country: stat.country ?? "Unassigned",
                    performanceScore: stat.performanceScore ?? 0,
                    revenue: revString,
                    imageUrl: stat.imageUrl,
                    phone: stat.phone ?? "",
                    email: stat.email ?? "",
                    address: stat.address ?? "",
                    productsSold: stat.productsSold ?? 0,
                    createdAt: parsedDate,
                    isActive: statusMap[stat.id] ?? true
                )
            }
            // Sort by performance score descending
            self.managers.sort { $0.performanceScore > $1.performanceScore }
        } catch {
            print("Error loading managers: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createManager(email: String, password: String, name: String, phone: String, storeName: String, address: String, country: String, image: UIImage?) async -> String? {
        isLoading = true
        errorMessage = nil
        do {
            var uploadedUrl = ""
            if let img = image {
                do {
                    uploadedUrl = try await uploadImage(img)
                } catch {
                    print("Image upload failed: \(error)")
                }
            }
            struct Params: Encodable {
                let manager_email: String
                let manager_password: String
                let manager_name: String
                let manager_phone: String
                let manager_address: String
                let manager_image_url: String
            }

            let finalAddress = address.isEmpty ? country : "\(address), \(country)"

            let params = Params(
                manager_email: email,
                manager_password: password,
                manager_name: name,
                manager_phone: phone,
                manager_address: finalAddress,
                manager_image_url: uploadedUrl
            )

            try await SupabaseManager.shared.client
                .rpc("create_manager", params: params)
                .execute()

            // Fetch the newly created manager's ID to assign the store
            struct IDResponse: Decodable { let id: UUID }
            let idResponse: [IDResponse] = try await SupabaseManager.shared.client
                .from("app_user")
                .select("id")
                .eq("email", value: email)
                .execute()
                .value
            
            if let newUserId = idResponse.first?.id {
                if !storeName.isEmpty && storeName != "Not Assigned" && storeName != "Unassigned" {
                    struct StoreManagerUpdate: Encodable { let manager_id: UUID? }
                    try? await SupabaseManager.shared.client
                        .from("store")
                        .update(StoreManagerUpdate(manager_id: newUserId))
                        .eq("name", value: storeName)
                        .execute()
                }
            }

            // Dispatch a raw email with the generated password via Resend
            await sendResendEmail(to: email, password: password)

            await loadManagers()
            return nil
        } catch {
            print("Error creating manager: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return error.localizedDescription
        }
    }

    func updateManager(_ manager: DisplayManager, newImage: UIImage? = nil) async -> String? {
        isLoading = true
        errorMessage = nil
        do {
            let finalAddress = manager.address.isEmpty ? manager.country : (manager.address.hasSuffix(manager.country) ? manager.address : "\(manager.address), \(manager.country)")

            var updateData: [String: String?] = [
                "name": manager.name,
                "phone": manager.phone,
                "email": manager.email,
                "address": finalAddress
            ]
            
            if let img = newImage {
                do {
                    let uploadedUrl = try await uploadImage(img)
                    updateData["image_url"] = uploadedUrl
                } catch {
                    print("Image upload failed during update: \(error)")
                }
            }
            
            try await SupabaseManager.shared.client
                .from("app_user")
                .update(updateData)
                .eq("id", value: manager.id)
                .execute()

            // Update store assignment. The DB trigger enforces one-store-per-manager
            // (assigning a manager to a store auto-detaches + archives any store they
            // previously managed) and archives stores left without a manager.
            struct StoreManagerUpdate: Encodable { let manager_id: UUID? }
            let hasStore = !manager.storeName.isEmpty && manager.storeName != "Not Assigned" && manager.storeName != "Unassigned"
            if hasStore {
                // Assign to the chosen store; trigger handles detaching/archiving the old one.
                try? await SupabaseManager.shared.client
                    .from("store")
                    .update(StoreManagerUpdate(manager_id: manager.id))
                    .eq("name", value: manager.storeName)
                    .execute()
            } else {
                // Unassigned: remove this manager from whatever store they held (trigger archives it).
                try? await SupabaseManager.shared.client
                    .from("store")
                    .update(StoreManagerUpdate(manager_id: nil))
                    .eq("manager_id", value: manager.id)
                    .execute()
            }

            // Refresh local list so changes appear immediately
            await loadManagers()
            return nil
        } catch {
            print("Error updating manager: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return error.localizedDescription
        }
    }

    func resetPassword(for managerId: UUID, email: String, newPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            struct Params: Encodable {
                let manager_id: UUID
                let new_password: String
            }
            let params = Params(manager_id: managerId, new_password: newPassword)
            
            try await SupabaseManager.shared.client
                .rpc("reset_manager_password", params: params)
                .execute()
                
            await sendResendEmail(to: email, password: newPassword)
                
            isLoading = false
            return true
        } catch {
            print("Error resetting password: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func deleteManager(id: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            struct UpdateUser: Encodable { let is_active: Bool }
            try await SupabaseManager.shared.client
                .from("app_user")
                .update(UpdateUser(is_active: false))
                .eq("id", value: id)
                .execute()
                
            struct StoreManagerUpdate: Encodable { let manager_id: UUID? }
            try? await SupabaseManager.shared.client
                .from("store")
                .update(StoreManagerUpdate(manager_id: nil))
                .eq("manager_id", value: id)
                .execute()
                
            await loadManagers()
            return true
        } catch {
            print("Error deleting manager: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Resend Email Integration
    
    private func sendResendEmail(to email: String, password: String) async {
        // IMPORTANT: Replace this with your actual Resend API Key from resend.com
        let resendApiKey = "re_3ot8yx3s_BDYPp6FcxJXDcFsSXU6bGW7t"
        
        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(resendApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let htmlBody = """
        <h2>Welcome to Nexus Retail!</h2>
        <p>An admin has created a manager account for you.</p>
        <p><b>Login ID:</b> \(email)</p>
        <p><b>Password:</b> \(password)</p>
        <p><i>Please log in and change your password as soon as possible for security purposes.</i></p>
        """
        
        let payload: [String: Any] = [
            // Resend requires a verified domain to send from. 'onboarding@resend.dev' works for testing if you verify your domain or email in the Resend dashboard.
            "from": "Nexus Admin <admin@updates.nexusretail.tech>",
            "to": [email],
            "subject": "Your Manager Account Details",
            "html": htmlBody
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 300 {
                print("Failed to send Resend email. Status: \(httpRes.statusCode)")
                print(String(data: data, encoding: .utf8) ?? "")
            } else {
                print("Successfully dispatched custom email via Resend to \(email)!")
            }
        } catch {
            print("Network error sending Resend email: \(error)")
        }
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
}
