//
//  StoreListView.swift
//  NexusRetail
//

import SwiftUI

struct StoreListView: View {
    @State private var viewModel = StoresViewModel()
    @State private var isShowingCreateForm = false
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            Group {
                if viewModel.isLoading && viewModel.stores.isEmpty {
                    ProgressView("Loading stores...")
                        .tint(RSMSColors.burgundy)
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
                } else if viewModel.stores.isEmpty {
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
                } else {
                    ScrollView {
                        LazyVStack(spacing: RSMSSpacing.md) {
                            ForEach(viewModel.stores) { store in
                                StoreRow(store: store, manager: viewModel.managers.first(where: { $0.id == store.managerID }))
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.vertical, RSMSSpacing.md)
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
        }
        .task {
            if viewModel.stores.isEmpty {
                await viewModel.load()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingCreateForm = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(RSMSColors.burgundy)
                }
                .accessibilityLabel("Add new store")
            }
        }
        .sheet(isPresented: $isShowingCreateForm) {
            StoreFormView(viewModel: viewModel)
        }
    }
}

private struct StoreRow: View {
    let store: Store
    let manager: AppUser?
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            HStack {
                Text(store.name)
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                if let status = store.status {
                    Text(status.rawValue.capitalized)
                        .font(RSMSFonts.caption)
                        .fontWeight(.bold)
                        .foregroundColor(status == .active ? RSMSColors.success : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status == .active ? RSMSColors.success.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(RSMSRadius.small)
                }
            }
            
            HStack(spacing: RSMSSpacing.sm) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(RSMSColors.burgundy)
                    .imageScale(.medium)
                Text(store.address ?? "No address")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            HStack(spacing: RSMSSpacing.sm) {
                Image(systemName: "person.text.rectangle")
                    .foregroundColor(RSMSColors.burgundy)
                    .imageScale(.medium)
                Text(manager?.name ?? "No Manager Assigned")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
}
