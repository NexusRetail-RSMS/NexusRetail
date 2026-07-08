import SwiftUI
import PhotosUI

struct AddProductView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ProductCatalogueViewModel

    @State private var productName = ""
    @State private var sku = ""
    @State private var category = "Bags"
    @State private var stock = ""
    @State private var basePrice = ""
    @State private var floorPrice = ""
    @State private var currency = "INR"
    @State private var launchDate = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?
    let product: CatalogueProduct?
    let categories = ["Bags", "Watches", "Perfumes", "Clothes", "Jewellery"]
    
    init(product: CatalogueProduct? = nil) {
        self.product = product

        _productName = State(initialValue: product?.name ?? "")
        _sku = State(initialValue: product?.sku ?? "")
        _category = State(initialValue: product?.category ?? "Bags")
        _stock = State(initialValue: product.map { String($0.stock) } ?? "")
        _basePrice = State(initialValue: product.map { String($0.price) } ?? "")
        _floorPrice = State(initialValue: "")
        _currency = State(initialValue: "INR")
        _selectedImage = State(initialValue: product?.image)
    }
    
    private var canSave: Bool {
        !productName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(basePrice) != nil &&
        // Stock is only entered when adding; on edit the field is hidden.
        (product != nil || Int(stock) != nil)
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
                                        .fill(theme.cardBackground)
                                        .overlay {
                                            VStack(spacing: 10) {

                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 34))
                                                    .foregroundStyle(theme.burgundy)

                                                Text("Upload Product Image")
                                                    .font(.headline)
                                                    .foregroundStyle(theme.darkBrown)

                                                Text("Tap to select an image")
                                                    .font(.caption)
                                                    .foregroundStyle(theme.secondaryText)
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
                                        .fill(theme.burgundy)
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
                    
                    TextField("SKU (Auto-generated)", text: $sku)
                        .disabled(true)
                        .foregroundStyle(theme.secondaryText)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .tint(theme.burgundy)
                }

                // Stock is set only at creation. On edit it's aggregated per-store
                // from inventory and can't be written back here, so hide the field
                // rather than show a control that silently does nothing.
                if product == nil {
                    Section("Stocks") {
                        TextField("Stock Quantity", text: $stock)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Pricing") {
                    HStack {
                        Text("Base Price")
                        Spacer()
                        TextField("0.00", text: $basePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(theme.darkBrown)
                    }
                    HStack {
                        Text("Floor Price")
                        Spacer()
                        TextField("0.00", text: $floorPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(theme.darkBrown)
                    }
                    Picker("Currency", selection: $currency) {
                        Text("INR").tag("INR")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                    }
                    .tint(theme.burgundy)
                }

                if product == nil {
                    Section("Launch") {
                        DatePicker(
                            "Launch Date",
                            selection: $launchDate,
                            in: Calendar.current.startOfDay(for: Date())...,
                            displayedComponents: .date
                        )
                        .tint(theme.burgundy)
                    }
                }
            }
            .navigationTitle(product == nil ? "Add New Product" : "Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn’t save product",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if product == nil && sku.isEmpty {
                    sku = viewModel.generateSKU(for: category)
                }
            }
            .onChange(of: category) { _, newCat in
                if product == nil {
                    sku = viewModel.generateSKU(for: newCat)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(theme.burgundy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(product == nil ? "Save" : "Update") {
                            guard canSave, let price = Double(basePrice) else { return }

                            Task {
                                isSaving = true
                                defer { isSaving = false }
                                do {
                                    if let product {
                                        // Stock is not editable here (tracked per-store in inventory).
                                        try await viewModel.updateProduct(
                                            product,
                                            name: productName,
                                            sku: sku,
                                            category: category,
                                            price: price,
                                            floorPrice: Double(floorPrice),
                                            image: selectedImage
                                        )
                                    } else {
                                        guard let stockInt = Int(stock) else { return }
                                        try await viewModel.addProduct(
                                            name: productName,
                                            sku: sku,
                                            category: category,
                                            price: price,
                                            stock: stockInt,
                                            launchDate: launchDate,
                                            floorPrice: Double(floorPrice),
                                            image: selectedImage
                                        )
                                    }
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .fontWeight(.bold)
                        .tint(theme.burgundy)
                        .disabled(!canSave)
                    }
                }
            }
        }
    }
}

#Preview {
    AddProductView()
        .environmentObject(ProductCatalogueViewModel())
}
