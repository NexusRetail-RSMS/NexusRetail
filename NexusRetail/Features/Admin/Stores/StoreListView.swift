import SwiftUI

struct StoreListView: View {
    @State private var viewModel = StoresViewModel()
    @State private var managersViewModel = ManagersViewModel()
    @State private var isShowingCreateForm = false
    @State private var searchText = ""
    @Namespace private var heroNamespace

    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return viewModel.stores
        } else {
            return viewModel.stores.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var activeCount: Int {
        viewModel.stores.filter { $0.status == .active }.count
    }
    
    private func manager(for store: Store) -> DisplayManager? {
        managersViewModel.managers.first(where: { $0.id == store.managerID })
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    if viewModel.isLoading && viewModel.stores.isEmpty {
                        VStack(spacing: 14) {
                            ProgressView()
                                .tint(RSMSColors.burgundy)
                            Text("Loading stores…")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.stores.isEmpty {
                        VStack(spacing: RSMSSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.error.opacity(0.1))
                                    .frame(width: 76, height: 76)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(RSMSColors.error)
                            }
                            Text(errorMessage)
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await viewModel.load() }
                            } label: {
                                Text("Retry")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 11)
                                    .background(
                                        LinearGradient(
                                            colors: [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .shadow(color: RSMSColors.burgundy.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(PremiumPressStyle())
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if viewModel.stores.isEmpty {
                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [RSMSColors.burgundy.opacity(0.14), RSMSColors.burgundy.opacity(0.04)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 104, height: 104)
                                Image(systemName: "building.2.crop.circle")
                                    .font(.system(size: 46))
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                            VStack(spacing: 4) {
                                Text("No Stores Found")
                                    .font(RSMSFonts.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(RSMSColors.primaryText)
                                Text("Tap + to add your first store.")
                                    .font(RSMSFonts.subheadline)
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 320)
                    } else {
                        LazyVStack(spacing: RSMSSpacing.lg) {
                            ForEach(filteredStores) { store in
                                NavigationLink(value: store) {
                                    StoreImageCard(store: store, manager: viewModel.managers.first(where: { $0.id == store.managerID }))
                                }
                                .buttonStyle(PremiumPressStyle())
                                .matchedTransitionSource(id: store.id, in: heroNamespace)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, RSMSSpacing.md)
                    }
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .navigationDestination(for: Store.self) { store in
                StoreAnalyticsView(store: store, manager: viewModel.managers.first(where: { $0.id == store.managerID }), viewModel: viewModel, namespace: heroNamespace)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.stores.isEmpty {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $isShowingCreateForm) {
            StoreFormView(viewModel: viewModel)
        }
    }

    private var headerSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Stores")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)

                    if !viewModel.stores.isEmpty {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("\(activeCount) active of \(viewModel.stores.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button {
                    isShowingCreateForm = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: RSMSColors.burgundy.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(PremiumPressStyle())
                .accessibilityLabel("Add new store")
            }

            NexusSearchBar(text: $searchText, placeholder: "Search stores, city…")
                .padding(.vertical, 2)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

struct PremiumPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct StoreImageCard: View {
    let store: Store
    let manager: DisplayManager?

    private var isActive: Bool { store.status == .active }

    // MARK: - City · Country (clean; avoids the ugly full-address string)
    private var locationLine: String {
        let parts = [store.city, store.country].compactMap { $0?.isEmpty == false ? $0 : nil }
        return parts.isEmpty ? "Location not set" : parts.joined(separator: " · ")
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: Background — cached image or branded placeholder
            Group {
                if let url = store.imageURL, !url.isEmpty {
                    CachedStoreImage(urlString: url)
                } else {
                    placeholderBackground
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()

            // MARK: Gradient — starts at 35% down so photos read properly
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.black.opacity(0.15), location: 0.35),
                    .init(color: Color.black.opacity(0.65), location: 0.65),
                    .init(color: Color.black.opacity(0.92), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)

            // MARK: Top row — status + warehouse badge
            VStack {
                HStack(alignment: .center) {
                    // Status indicator: dot + label (slimmer than full pill)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isActive ? Color(hex: "34C759") : Color.red)
                            .frame(width: 6, height: 6)
                        Text(isActive ? "Active" : "In-Active")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)

                    Spacer()

//                    if store.isWarehouse == true {
//                        Image(systemName: "shippingbox.fill")
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(.white.opacity(0.85))
//                            .padding(8)
//                            .background(.ultraThinMaterial, in: Circle())
//                            .environment(\.colorScheme, .dark)
//                    }
                }
                Spacer()
            }
            .padding(14)
            .frame(height: 200)

            // MARK: Bottom text block
            VStack(alignment: .leading, spacing: 6) {
                Text(store.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                HStack(spacing: 10) {
                    // Location
                    HStack(spacing: 5) {
                        Image(systemName: "location")
                            .font(.system(size: 11, weight: .medium))
                        Text(locationLine)
                            .font(.system(size: 15, weight: .regular))
                            .lineLimit(nil)
                    }
                    .foregroundColor(.white.opacity(0.78))
                    
                    Spacer()
                    // Manager
                    HStack(spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 11, weight: .medium))
                        Text(manager?.name ?? "Unassigned")
                            .font(.system(size: 15, weight: manager == nil ? .regular : .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(manager == nil ? .white.opacity(0.45) : .white.opacity(0.78))
                }

                // MARK: Burgundy accent bar
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(RSMSColors.burgundy)
//                    .frame(width: 32, height: 3)
//                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 10)
    }

    // MARK: - Branded placeholder (no image uploaded yet)
    private var placeholderBackground: some View {
        ZStack {
            // Textured gradient — feels editorial, not "hotel app"
            LinearGradient(
                colors: [
                    Color(hex: "2C1010"),
                    RSMSColors.burgundy.opacity(0.4),
                    Color(hex: "1C1C1E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle noise texture via overlapping semi-transparent circles
            Circle()
                .fill(RSMSColors.burgundy.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: 60, y: -30)

            Circle()
                .fill(RSMSColors.burgundy.opacity(0.08))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .offset(x: -50, y: 40)
        }
    }
}
