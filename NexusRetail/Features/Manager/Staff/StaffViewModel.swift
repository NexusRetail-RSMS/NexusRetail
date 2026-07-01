//
//  StaffViewModel.swift
//  NexusRetail
//

import SwiftUI
import Supabase

@Observable
class StaffViewModel {
    var employees: [DisplayEmployee] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    private let localCacheKey = "nexus_local_staff_cache"

    init() {
        let cached = loadFromCache()
        if !cached.isEmpty {
            self.employees = cached
        } else {
            // Sample initial data for immediate rendering / fallback
            self.employees = [
                DisplayEmployee(id: UUID(), name: "Sarah Jenkins", role: "Sales Associate", productsSold: 142, revenue: "$48,500", imageUrl: nil, phone: "+1 (555) 234-5678", email: "sarah.j@nexusretail.com"),
                DisplayEmployee(id: UUID(), name: "David Miller", role: "Sales Associate", productsSold: 118, revenue: "$39,200", imageUrl: nil, phone: "+1 (555) 876-5432", email: "david.m@nexusretail.com"),
                DisplayEmployee(id: UUID(), name: "Elena Rostova", role: "Sales Associate", productsSold: 94, revenue: "$31,400", imageUrl: nil, phone: "+1 (555) 345-6789", email: "elena.r@nexusretail.com"),
                DisplayEmployee(id: UUID(), name: "Marcus Aurelius", role: "After Sales Associate", productsSold: 65, revenue: "$18,900", imageUrl: nil, phone: "+1 (555) 901-2345", email: "marcus.a@nexusretail.com")
            ]
            saveToCache()
        }
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
            let response: [AppUser] = try await SupabaseManager.shared.client
                .from("app_user")
                .select()
                .in("role", values: ["sales_associate", "after_sales"])
                .order("name", ascending: true)
                .execute()
                .value
            
            let currentLocalList = self.employees
            
            if !response.isEmpty {
                var merged: [DisplayEmployee] = []
                let fetchedIds = Set(response.map { $0.id })
                
                // Keep any newly added local employees that aren't in Supabase yet
                for emp in currentLocalList where !fetchedIds.contains(emp.id) {
                    merged.append(emp)
                }
                
                // Map fetched records, preserving local edits/photos if present
                for user in response {
                    if let existingLocal = currentLocalList.first(where: { $0.id == user.id }) {
                        merged.append(existingLocal)
                    } else {
                        let isAfterSales = user.role == .afterSales
                        let roleStr = isAfterSales ? "After Sales Associate" : "Sales Associate"
                        let baseSold = abs(user.id.hashValue % 100) + 40
                        let baseRev = baseSold * 320
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .currency
                        formatter.currencyCode = "USD"
                        formatter.maximumFractionDigits = 0
                        let revStr = formatter.string(from: NSNumber(value: baseRev)) ?? "$\(baseRev)"
                        
                        merged.append(DisplayEmployee(
                            id: user.id,
                            name: user.name ?? "Staff Member",
                            role: roleStr,
                            productsSold: baseSold,
                            revenue: revStr,
                            imageUrl: user.imageUrl,
                            phone: user.phone ?? "",
                            email: user.email ?? ""
                        ))
                    }
                }
                self.employees = merged
            }
            saveToCache()
        } catch {
            print("Error loading staff: \(error)")
        }
        isLoading = false
    }
    
    func deleteEmployee(id: UUID) async -> Bool {
        self.employees.removeAll { $0.id == id }
        saveToCache()
        do {
            try await SupabaseManager.shared.client
                .from("app_user")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            return true
        } catch {
            print("Error deleting employee: \(error)")
            return false
        }
    }
    
    func addEmployee(_ employee: DisplayEmployee, password: String = "") {
        withAnimation {
            self.employees.insert(employee, at: 0)
        }
        saveToCache()
        
        Task {
            let roleVal = employee.role == "After Sales Associate" ? "after_sales" : "sales_associate"
            struct NewUserDTO: Encodable {
                let id: UUID
                let name: String
                let email: String
                let role: String
                let phone: String
                let is_active: Bool
            }
            let dto = NewUserDTO(
                id: employee.id,
                name: employee.name,
                email: employee.email,
                role: roleVal,
                phone: employee.phone,
                is_active: true
            )
            try? await SupabaseManager.shared.client
                .from("app_user")
                .insert(dto)
                .execute()
            
            if !password.isEmpty {
                _ = await sendEmployeeEmail(to: employee.email, password: password, name: employee.name, role: employee.role)
            }
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
            try? await SupabaseManager.shared.client
                .from("app_user")
                .update(["name": employee.name, "email": employee.email, "phone": employee.phone, "role": roleVal])
                .eq("id", value: employee.id.uuidString)
                .execute()
        }
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
