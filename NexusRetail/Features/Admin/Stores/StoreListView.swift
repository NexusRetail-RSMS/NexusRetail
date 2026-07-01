//
//  StoreListView.swift
//  NexusRetail
//

import SwiftUI

struct StoreListView: View {
    @State private var viewModel = StoresViewModel()
    @State private var isShowingCreateForm = false
    @State private var searchText = ""
    @Environment(AdminNavigationStore.self) private var navStore
    
    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return viewModel.stores
        } else {
            return viewModel.stores.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 64))
                .foregroundColor(RSMSColors.burgundy)
            Text("No Stores Found")
                .font(RSMSFonts.title)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            Text("Tap + to add your first store.")
                .font(RSMSFonts.subheadline)
                .foregroundColor(RSMSColors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.stores.isEmpty {
                        ProgressView("Loading stores...")
                            .tint(RSMSColors.burgundy)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.stores.isEmpty {
                        VStack(spacing: RSMSSpacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(RSMSColors.error)
                            Text(errorMessage)
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await viewModel.load() }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RSMSColors.burgundy)
                            .foregroundColor(.white)
                            .cornerRadius(RSMSRadius.small)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if filteredStores.isEmpty {
                        emptyStateSection
                            .padding(.top, RSMSSpacing.xxl)
                    } else {
                        LazyVStack(spacing: RSMSSpacing.md) {
                            ForEach(filteredStores) { store in
                                NavigationLink(value: store) {
                                    StoreRow(store: store, manager: viewModel.managers.first(where: { $0.id == store.managerID }))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.md)
                        .padding(.bottom, RSMSSpacing.xxl)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                headerSection
                    .background(.ultraThinMaterial)
            }
            .refreshable {
                await viewModel.load()
            }
            .navigationDestination(for: Store.self) { store in
                StoreAnalyticsView(store: store, manager: viewModel.managers.first(where: { $0.id == store.managerID }), viewModel: viewModel)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .onChange(of: navStore.selectedTab) { _, newTab in
            if newTab == .stores {
                Task {
                    await viewModel.load()
                }
            }
        }
        .sheet(isPresented: $isShowingCreateForm) {
            StoreFormView(viewModel: viewModel)
        }
    }

    private var headerSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            HStack {
                Text("Stores")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                Button {
                    isShowingCreateForm = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                        .frame(width: 44, height: 44)
                        .background(RSMSColors.burgundy.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Add new store")
            }
            
            // Search Bar
            NexusSearchBar(text: $searchText, placeholder: "Search stores…")
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

private struct StoreRow: View {
    let store: Store
    let manager: AppUser?
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            // Header: Icon + Name + Status
            HStack(alignment: .top) {
                // Circular icon
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: store.isWarehouse == true ? "shippingbox.fill" : "building.2.fill")
                        .foregroundColor(RSMSColors.burgundy)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(RSMSFonts.headline)
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                    
                    Text(store.isWarehouse == true ? "Warehouse" : "Retail Store")
                        .font(RSMSFonts.caption)
                        .foregroundColor(RSMSColors.secondaryText)
                }
                .padding(.leading, 8)                
                Spacer()
                
                if let status = store.status {
                    StatusPill(label: status.rawValue.capitalized, color: status == .active ? RSMSColors.success : .gray)
                }
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                        .frame(width: 16)
                    Text(store.address ?? "No address provided")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.gray)
                        .frame(width: 16)
                    
                    HStack(spacing: 4) {
                        Text("Manager:")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                        Text(manager?.name ?? "Unassigned")
                            .font(RSMSFonts.subheadline)
                            .fontWeight(manager == nil ? .regular : .semibold)
                            .foregroundColor(manager == nil ? .gray : RSMSColors.primaryText)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
}
