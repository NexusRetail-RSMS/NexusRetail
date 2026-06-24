//
//  StoreListView.swift
//  NexusRetail
//

import SwiftUI

struct StoreListView: View {
    @State private var viewModel = StoresViewModel()
    @State private var isShowingCreateForm = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.stores.isEmpty {
                ProgressView("Loading stores...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.stores.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if viewModel.stores.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 64))
                        .foregroundColor(Color.nexusGold)
                    Text("No Stores Found")
                        .font(.title3.bold())
                    Text("Tap + to add your first store.")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(viewModel.stores) { store in
                        StoreRow(store: store, manager: viewModel.managers.first(where: { $0.id == store.managerID }))
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.load()
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
                        .foregroundColor(Color.nexusGold)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(store.name)
                    .font(.headline)
                    .foregroundColor(Color.nexusNavy)
                
                Spacer()
                
                if store.status == .archived {
                    Text("Archived")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.secondary)
                Text(store.address ?? "No address")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "person.text.rectangle")
                    .foregroundColor(.secondary)
                Text(manager?.name ?? "No Manager Assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.name), located at \(store.address). Manager: \(manager?.name ?? "None")")
    }
}
