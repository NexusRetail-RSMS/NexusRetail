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
    let product: CatalogueProduct?
    let categories = ["Bags", "Watches", "Fragrances", "Clothes", "Jewelry"]
    
    init(product: CatalogueProduct? = nil) {
        self.product = product

        _productName = State(initialValue: product?.name ?? "")
        _sku = State(initialValue: product?.sku ?? "")
        _category = State(initialValue: product?.category ?? "Bags")
        _stock = State(initialValue: product.map { String($0.stock) } ?? "")
        _basePrice = State(initialValue: product.map { String($0.price) } ?? "")
        _floorPrice = State(initialValue: "")
        _currency = State(initialValue: "USD")
        _selectedImage = State(initialValue: product?.image)
    }
    
    private var canSave: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !sku.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(basePrice) != nil &&
        Int(stock) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {

                        ZStack(alignment: .bottomTrailing) {

                            Group {
                                if let image = selectedImage {

                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()

                                } else if let imageName = product?.imageName {

                                    Image(imageName)
                                        .resizable()
                                        .scaledToFill()

                                } else {

                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(RSMSColors.cardBackground)
                                        .overlay {
                                            VStack(spacing: 10) {

                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 34))
                                                    .foregroundStyle(RSMSColors.burgundy)

                                                Text("Upload Product Image")
                                                    .font(.headline)
                                                    .foregroundStyle(RSMSColors.darkBrown)

                                                Text("Tap to select an image")
                                                    .font(.caption)
                                                    .foregroundStyle(RSMSColors.secondaryText)
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                            // Edit Badge (only while editing)
                            if product != nil {

                                ZStack {

                                    Circle()
                                        .fill(RSMSColors.burgundy)
                                        .frame(width: 46, height: 46)

                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)

                                }
                                .padding(14)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
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
                }
                .listRowInsets(EdgeInsets())
                Section("Product Details") {
                    TextField("Product Name", text: $productName)
                        .autocorrectionDisabled()
                    TextField("SKU", text: $sku)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .tint(RSMSColors.burgundy)
                }

                Section("Stocks") {
                    TextField("Stock Quantity", text: $stock)
                        .keyboardType(.numberPad)
                }

                Section("Pricing") {
                    HStack {
                        Text("Base Price")
                        Spacer()
                        TextField("0.00", text: $basePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(RSMSColors.darkBrown)
                    }
                    HStack {
                        Text("Floor Price")
                        Spacer()
                        TextField("0.00", text: $floorPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(RSMSColors.darkBrown)
                    }
                    Picker("Currency", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("INR").tag("INR")
                    }
                    .tint(RSMSColors.burgundy)
                }

                if product == nil {
                    Section("Launch") {
                        DatePicker(
                            "Launch Date",
                            selection: $launchDate,
                            in: Calendar.current.startOfDay(for: Date())...,
                            displayedComponents: .date
                        )
                        .tint(RSMSColors.burgundy)
                    }
                }

                Section {
                    Button {
                        guard
                            canSave,
                            let price = Double(basePrice),
                            let stockInt = Int(stock)
                        else { return }
                        if let product {

                            viewModel.updateProduct(
                                product,
                                name: productName,
                                sku: sku,
                                category: category,
                                price: price,
                                stock: stockInt,
                                image: selectedImage
                            )

                        } else {

                            viewModel.addProduct(
                                name: productName,
                                sku: sku,
                                category: category,
                                price: price,
                                stock: stockInt,
                                launchDate: launchDate,
                                image: selectedImage
                            )
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text(product == nil ? "Save Product" : "Update Product")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(!canSave)
                    .tint(RSMSColors.burgundy)
                }
            }
            .navigationTitle(product == nil ? "Add New Product" : "Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(RSMSColors.burgundy)
                }
            }
        }
    }
}

#Preview {
    AddProductView()
        .environmentObject(ProductCatalogueViewModel())
}
