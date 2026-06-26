//
//  AddProductView.swift
//  NexusRetail
//

import SwiftUI
import PhotosUI

struct AddProductView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ProductCatalogueViewModel
    @State private var productName = ""
    @State private var sku = ""
    @State private var category = "Bags"
    @State private var stock = ""
    @State private var basePrice = ""
    @State private var floorPrice = ""
    @State private var currency = "USD"
    @State private var launchDate = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let categories = ["Bags","Watches","Fragrances"]

    var body: some View {

        NavigationStack {

            ZStack {

                RSMSColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 18) {

                        // MARK: Image Upload

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {

                            ZStack {

                                RoundedRectangle(cornerRadius: 20)
                                    .fill(RSMSColors.cardBackground)

                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(RSMSColors.cardBorder)

                                if let image = selectedImage {

                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 170)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))

                                } else {

                                    VStack(spacing: 12) {

                                        Image(systemName: "camera")
                                            .font(.system(size: 34))
                                            .foregroundColor(RSMSColors.burgundy)

                                        Text("Upload Product Image")
                                            .foregroundColor(RSMSColors.secondaryText)
                                    }
                                }
                            }
                            .frame(height: 170)
                        }
                        .onChange(of: selectedPhoto) { _, newItem in

                            Task {

                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {

                                    await MainActor.run {
                                        selectedImage = uiImage
                                    }
                                }
                            }
                        }

                        HStack(spacing: 14) {

                            InputField(
                                title: "Product Name",
                                text: $productName
                            )

                            InputField(
                                title: "SKU",
                                text: $sku
                            )
                        }

                        HStack(spacing: 14) {

                            PickerField(
                                title: "Category",
                                selection: $category,
                                values: categories
                            )

                            InputField(
                                title: "Stock",
                                text: $stock
                            )
                        }

                        HStack(spacing: 14) {

                            InputField(
                                title: "Base Price",
                                text: $basePrice
                            )

                            InputField(
                                title: "Floor Price",
                                text: $floorPrice
                            )

                            InputField(
                                title: "Currency",
                                text: $currency
                            )
                        }

                        DatePicker(
                            "Launch Date",
                            selection: $launchDate,
                            in: Calendar.current.startOfDay(for: Date())...,
                            displayedComponents: .date
                        )
                        .tint(RSMSColors.burgundy)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(RSMSColors.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(RSMSColors.burgundy.opacity(0.35), lineWidth: 1.2)
                        )
                        
                        Button {

                            guard
                                !productName.isEmpty,
                                !sku.isEmpty,
                                let price = Double(basePrice),
                                let stock = Int(stock),
                                launchDate >= Calendar.current.startOfDay(for: Date())
                            else {
                                return
                            }
                            viewModel.addProduct(
                                name: productName,
                                sku: sku,
                                category: category,
                                price: price,
                                stock: stock,
                                launchDate: launchDate,
                                image: selectedImage
                            )

                            dismiss()

                        } label: {

                            Text("Save Product")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(RSMSColors.burgundy)
                                .cornerRadius(18)
                        }                    }
                    .padding()
                }
            }
            .navigationTitle("Add New Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
    }
}

struct InputField: View {

    let title: String
    @Binding var text: String

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.caption)
                .foregroundColor(RSMSColors.secondaryText)

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(RSMSColors.darkBrown)
                .tint(RSMSColors.burgundy)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(RSMSColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSColors.burgundy.opacity(0.35), lineWidth: 1.2)
        )
    }
}

struct PickerField: View {

    let title: String

    @Binding var selection: String

    let values: [String]

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.caption)
                .foregroundColor(RSMSColors.secondaryText)

            Picker(title, selection: $selection) {
                ForEach(values, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.menu)
            .tint(RSMSColors.burgundy)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(RSMSColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSColors.burgundy.opacity(0.35), lineWidth: 1.2)
        )
    }
}

#Preview {

    AddProductView()
}
