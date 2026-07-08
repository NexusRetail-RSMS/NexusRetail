//
//  StaffViewModel.swift
//  NexusRetail
//

import SwiftUI
import Supabase

struct StaffStatsRPC: Decodable {
    let id: UUID
    let name: String?
    let email: String?
    let role: String?
    let phone: String?
    let imageUrl: String?
    let productsSold: Int?
    let revenue: Double?
    let storeId: UUID?
    let customerAttraction: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case phone
        case imageUrl = "image_url"
        case productsSold = "products_sold"
        case revenue
        case storeId = "store_id"
        case customerAttraction = "customer_attraction"
    }
}

@Observable
class StaffViewModel {
    var employees: [DisplayEmployee] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    private let localCacheKey = "nexus_local_staff_cache_v2"
    private let deletedIDsKey = "nexus_local_staff_deleted_ids_v1"
    private var lastStoreID: UUID?

    private var deletedIDs: Set<UUID> {
        get {
            guard let data = UserDefaults.standard.data(forKey: deletedIDsKey),
                  let set = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
                return []
            }
            return set
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: deletedIDsKey)
            }
        }
    }

    init() {
        self.employees = loadFromCache()
    }

    private func saveToCache() {
        if let data = try? JSONEncoder().encode(employees) {
            UserDefaults.standard.set(data, forKey: localCacheKey)
        }
    }

    private func loadFromCache() -> [DisplayEmployee] {
        guard let data = UserDefaults.standard.data(forKey: localCacheKey),
              let decoded = try? JSONDecoder().decode([DisplayEmployee].self, from: data) else {
            return []
        }
        return decoded
    }

    func loadStaff() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: [StaffStatsRPC] = try await SupabaseManager.shared.client
                .rpc("get_staff_stats")
                .execute()
                .value
            

            let deleted = self.deletedIDs
            
            let remoteEmployees = response.compactMap { stat -> DisplayEmployee? in
                guard !deleted.contains(stat.id) else { return nil }
                if let managerStore = currentStoreID, stat.storeId != managerStore { return nil }
                guard let role = stat.role?.lowercased(), !role.contains("manager"), !role.contains("admin") else { return nil }
                
                let isAfterSales = role == "after_sales" || role.contains("after")
                let roleStr = isAfterSales ? "After Sales Associate" : "Sales Associate"
                let revVal = stat.revenue ?? 0
                let revStr = formatIndianCurrency(revVal)
                
                let existing = self.employees.first { emp in
                    emp.id == stat.id || (!emp.email.isEmpty && emp.email == stat.email)
                }
                let finalImageUrl = stat.imageUrl ?? existing?.imageUrl
                let finalImageData = existing?.imageData
                
                return DisplayEmployee(
                    id: stat.id,
                    name: stat.name ?? "Staff Member",
                    role: roleStr,
                    productsSold: stat.productsSold ?? 0,
                    revenue: revStr,
                    imageUrl: finalImageUrl,
                    phone: stat.phone ?? "",
                    email: stat.email ?? "",
                    imageData: finalImageData,
                    storeId: stat.storeId,
                    customerAttraction: stat.customerAttraction ?? 0
                )
            }
            
            self.employees = remoteEmployees
            saveToCache()
        } catch {
            print("Error loading staff: \(error)")
        }
        isLoading = false
    }
    
    func deleteEmployee(id: UUID) async -> Bool {
        // Optimistically hide from the in-memory list for a responsive UI, but do
        // NOT persist to deletedIDs yet — otherwise a failed server delete would
        // filter the still-live employee out of every future load permanently.
        await MainActor.run {
            self.employees.removeAll { $0.id == id }
            self.saveToCache()
        }

        var deleted = false
        do {
            struct Params: Encodable { let staff_id: UUID }
            try await SupabaseManager.shared.client
                .rpc("delete_staff", params: Params(staff_id: id))
                .execute()
            deleted = true
        } catch {
            print("delete_staff RPC failed: \(error)")
        }

        if !deleted {
            do {
                struct Params: Encodable { let manager_id: UUID }
                try await SupabaseManager.shared.client
                    .rpc("delete_manager", params: Params(manager_id: id))
                    .execute()
                deleted = true
            } catch {
                print("delete_manager RPC failed: \(error)")
            }
        }

        if !deleted {
            do {
                try await SupabaseManager.shared.client
                    .from("app_user")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .execute()
                deleted = true
            } catch {
                print("Direct app_user delete failed: \(error)")
            }
        }

        // Only record the tombstone once the server has actually deleted the row.
        if deleted {
            await MainActor.run {
                var currentDeleted = self.deletedIDs
                currentDeleted.insert(id)
                self.deletedIDs = currentDeleted
            }
        }

        // Reload either way: on success this confirms removal, on failure it
        // brings the still-live employee back into the list.
        await loadStaff(storeID: nil)
        return deleted
    }
    
    func addEmployee(_ employee: DisplayEmployee, password: String) async -> String? {
        let roleVal = employee.role == "After Sales Associate" ? "after_sales" : "sales_associate"
        
        do {
            var uploadedUrl: String? = nil
            if let data = employee.imageData {
                do {
                    uploadedUrl = try await uploadStaffImage(data: data)
                } catch {
                    print("Image upload failed for new staff: \(error)")
                }
            }
            
            struct Params: Encodable {
                let staff_email: String
                let staff_password: String
                let staff_name: String
                let staff_phone: String
                let staff_role: String
            }
            
            let params = Params(
                staff_email: employee.email,
                staff_password: password,
                staff_name: employee.name,
                staff_phone: employee.phone,
                staff_role: roleVal
            )
            
            var persisted = false
            var lastFailure: Error? = nil
            do {
                try await SupabaseManager.shared.client
                    .rpc("create_staff", params: params)
                    .execute()
                persisted = true
            } catch {
                lastFailure = error
                print("create_staff RPC failed: \(error). Attempting direct table insert fallback...")
            }

            if !persisted {
                do {
                    struct DirectStaffInsert: Encodable {
                        let id: UUID
                        let email: String
                        let name: String
                        let role: String
                        let phone: String
                        let image_url: String?
                    }
                    let insertRecord = DirectStaffInsert(
                        id: employee.id,
                        email: employee.email,
                        name: employee.name,
                        role: roleVal,
                        phone: employee.phone,
                        image_url: uploadedUrl
                    )
                    try await SupabaseManager.shared.client
                        .from("app_user")
                        .insert(insertRecord)
                        .execute()
                    persisted = true
                } catch let directError {
                    lastFailure = directError
                    print("Direct table insert fallback also failed: \(directError)")
                }
            }

            // Both persistence paths failed — surface the error instead of
            // reporting a phantom success and caching an employee the DB never got.
            guard persisted else {
                let msg = lastFailure?.localizedDescription ?? "Unknown error"
                if msg.contains("already exists") || msg.contains("duplicate") {
                    return "This email is already associated with another account."
                }
                return "Couldn't create staff member: \(msg)"
            }

            var tempEmp = employee
            if let uploadedUrl = uploadedUrl {
                tempEmp.imageUrl = uploadedUrl
                try? await SupabaseManager.shared.client
                    .from("app_user")
                    .update(["image_url": uploadedUrl])
                    .eq("email", value: employee.email)
                    .execute()
            }
            if !self.employees.contains(where: { $0.email == tempEmp.email }) {
                self.employees.append(tempEmp)
            } else if let idx = self.employees.firstIndex(where: { $0.email == tempEmp.email }) {
                self.employees[idx] = tempEmp
            }
            saveToCache()
            
            if !password.isEmpty {
                _ = await sendEmployeeEmail(to: employee.email, password: password, name: employee.name, role: employee.role)
            }
            
            await loadStaff() // Reload to get the new staff member and true ID
            return nil
            
        } catch {
            print("Error creating staff: \(error)")
            let errorMsg = error.localizedDescription
            if errorMsg.contains("already exists") {
                return "This email is already associated with another account."
            }
            return errorMsg
        }
    }
    
    func updateEmployee(_ employee: DisplayEmployee) {
        if let idx = self.employees.firstIndex(where: { $0.id == employee.id }) {
            withAnimation {
                self.employees[idx] = employee
            }
        }
        saveToCache()
        
        Task {
            let roleVal = employee.role == "After Sales Associate" ? "after_sales" : "sales_associate"
            var updateDict: [String: String] = [
                "name": employee.name,
                "email": employee.email,
                "phone": employee.phone,
                "role": roleVal
            ]
            
            if let data = employee.imageData {
                if let uploadedUrl = try? await uploadStaffImage(data: data) {
                    updateDict["image_url"] = uploadedUrl
                    await MainActor.run {
                        if let idx = self.employees.firstIndex(where: { $0.id == employee.id }) {
                            self.employees[idx].imageUrl = uploadedUrl
                        }
                        self.saveToCache()
                    }
                }
            }
            
            try? await SupabaseManager.shared.client
                .from("app_user")
                .update(updateDict)
                .eq("id", value: employee.id.uuidString)
                .execute()
        }
    }
    
    private func uploadStaffImage(data: Data) async throws -> String {
        guard let uiImage = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        let targetSize = CGSize(width: 400, height: 400)
        let size = uiImage.size
        let widthRatio = targetSize.width / max(size.width, 1)
        let heightRatio = targetSize.height / max(size.height, 1)
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        uiImage.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uiImage
        UIGraphicsEndImageContext()

        guard let uploadData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw URLError(.badServerResponse)
        }
        let path = "profiles/\(UUID().uuidString).jpg"
        let fileOptions = FileOptions(contentType: "image/jpeg")
        try await SupabaseManager.shared.client.storage
            .from("product-images")
            .upload(path, data: uploadData, options: fileOptions)

        let url = try SupabaseManager.shared.client.storage
            .from("product-images")
            .getPublicURL(path: path)
        return url.absoluteString
    }
    
    // MARK: - Resend Email Integration
    
    private func sendEmployeeEmail(to email: String, password: String, name: String, role: String) async -> Bool {
        let resendApiKey = "re_3ot8yx3s_BDYPp6FcxJXDcFsSXU6bGW7t"
        
        guard let url = URL(string: "https://api.resend.com/emails") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(resendApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let htmlBody = """
        <h2>Welcome to Nexus Retail!</h2>
        <p>Dear \(name),</p>
        <p>An employee account has been created for you as a <b>\(role)</b>.</p>
        <p>Here are your login credentials:</p>
        <ul>
            <li><b>Username (Email ID):</b> \(email)</li>
            <li><b>Password:</b> \(password)</li>
        </ul>
        <p><i>Please log in and change your password as soon as possible for security purposes.</i></p>
        <p>Warm regards,<br>Nexus Retail Management</p>
        """
        
        let payload: [String: Any] = [
            "from": "Nexus Admin <admin@updates.nexusretail.tech>",
            "to": [email],
            "subject": "Your Employee Account Details – Nexus Retail",
            "html": htmlBody
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 300 {
                print("Failed to send employee email. Status: \(httpRes.statusCode)")
                print(String(data: data, encoding: .utf8) ?? "")
                return false
            } else {
                print("Successfully dispatched employee email via Resend to \(email)!")
                return true
            }
        } catch {
            print("Network error sending employee email: \(error)")
            return false
        }
    }
}
