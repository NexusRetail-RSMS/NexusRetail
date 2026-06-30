//
//  ClientelingView.swift
//  NexusRetail
//
//  Clients tab — searchable list of clienteling records. Driven by ClientelingViewModel.
//

import SwiftUI

struct ClientelingView: View {
    @State private var viewModel = ClientelingViewModel()
    @State private var isNewClientPresented = false

    var body: some View {
        List {
            Section {
                ForEach(viewModel.filteredClients) { client in
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        clientListRow(client)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle("Clients")
        .searchable(text: $viewModel.searchText, prompt: "Search clients")
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button {
//                    isNewClientPresented = true
//                } label: {
//                    Image(systemName: "person.badge.plus")
//                        .foregroundStyle(RSMSColors.burgundy)
//                }
//               // .accessibilityLabel("Add client")
//            }
//        }
//        .sheet(isPresented: $isNewClientPresented) {
//            NewClientSheet(viewModel: viewModel)
//        }
    }

    // MARK: - Row
    private func clientListRow(_ client: AssociateClient) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(RSMSColors.burgundy.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(client.initials)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSColors.burgundy)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                Text(client.preferences)
                    .font(RSMSFonts.subheadline)
                    .foregroundStyle(RSMSColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(client.tier)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(RSMSColors.burgundy)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RSMSColors.burgundy.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }
}
