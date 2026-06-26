//
//  CSVDataLoader.swift
//  NexusRetail
//
//  Parses the bundled retail_sales.csv (Kaggle-format) into typed
//  Swift structs for the Dashboard charts and KPIs.
//
//  The CSV has columns:
//    Transaction ID, Date, Customer ID, Gender, Age,
//    Product Category, Quantity, Price per Unit, Total Amount,
//    Store, Country
//

import Foundation

// MARK: - Raw Transaction Record

/// A single row from the retail_sales.csv file.
struct SalesTransaction: Identifiable {
    let id: Int                 // Transaction ID
    let date: Date
    let customerID: String
    let gender: String
    let age: Int
    let productCategory: String
    let quantity: Int
    let pricePerUnit: Double
    let totalAmount: Double
    let store: String
    let country: String

    /// The month component (1–12).
    var month: Int { Calendar.current.component(.month, from: date) }

    /// The day-of-week component (1 = Sunday … 7 = Saturday).
    var weekday: Int { Calendar.current.component(.weekday, from: date) }

    /// Short month label: "Jan", "Feb" …
    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    /// Short weekday label: "Mon", "Tue" …
    var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - CSV Loader

enum CSVDataLoader {

    /// Loads and parses the bundled `retail_sales.csv`.
    /// Returns an empty array if the file is missing or corrupt.
    static func loadTransactions() -> [SalesTransaction] {
        guard let url = Bundle.main.url(forResource: "retail_sales", withExtension: "csv") else {
            print("⚠️ retail_sales.csv not found in bundle")
            return []
        }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            print("⚠️ Could not read retail_sales.csv")
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        var transactions: [SalesTransaction] = []

        let lines = contents.components(separatedBy: .newlines)
        // Skip header (first line)
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let columns = trimmed.components(separatedBy: ",")
            guard columns.count >= 11 else { continue }

            guard let txnID = Int(columns[0].trimmingCharacters(in: .whitespaces)),
                  let date = dateFormatter.date(from: columns[1].trimmingCharacters(in: .whitespaces)),
                  let age = Int(columns[4].trimmingCharacters(in: .whitespaces)),
                  let quantity = Int(columns[6].trimmingCharacters(in: .whitespaces)),
                  let pricePerUnit = Double(columns[7].trimmingCharacters(in: .whitespaces)),
                  let totalAmount = Double(columns[8].trimmingCharacters(in: .whitespaces))
            else { continue }

            let transaction = SalesTransaction(
                id: txnID,
                date: date,
                customerID: columns[2].trimmingCharacters(in: .whitespaces),
                gender: columns[3].trimmingCharacters(in: .whitespaces),
                age: age,
                productCategory: columns[5].trimmingCharacters(in: .whitespaces),
                quantity: quantity,
                pricePerUnit: pricePerUnit,
                totalAmount: totalAmount,
                store: columns[9].trimmingCharacters(in: .whitespaces),
                country: columns[10].trimmingCharacters(in: .whitespaces)
            )
            transactions.append(transaction)
        }

        print("✅ Loaded \(transactions.count) transactions from retail_sales.csv")
        return transactions
    }
}
