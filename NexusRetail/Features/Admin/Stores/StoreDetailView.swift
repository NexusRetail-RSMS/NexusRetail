//
//  StoreDetailView.swift
//  NexusRetail
//

import SwiftUI

struct StoreDetailView: View {
    let store: Store
    let manager: AppUser?
    @Bindable var viewModel: StoresViewModel
    @State private var isShowingEditForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: RSMSSpacing.lg) {
                // Header
                VStack(spacing: RSMSSpacing.sm) {
                    Image(systemName: store.isWarehouse == true ? "shippingbox.fill" : "building.2.fill")
                        .font(.system(size: 64))
                        .foregroundColor(RSMSColors.burgundy)
                        .padding(24)
                        .background(RSMSColors.burgundy.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(store.name)
                        .font(RSMSFonts.title)
                        .fontWeight(.bold)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    if let status = store.status {
                        StatusPill(label: status.rawValue.capitalized, color: status == .active ? RSMSColors.success : .gray)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, RSMSSpacing.xl)
                .background(RSMSColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                // Info Cards
                VStack(spacing: RSMSSpacing.md) {
                    DetailCard(icon: "mappin.and.ellipse", title: "Address", value: store.address ?? "Not provided")
                    DetailCard(icon: "phone.fill", title: "Phone", value: store.phone ?? "Not provided")
                    DetailCard(icon: "person.text.rectangle", title: "Manager", value: manager?.name ?? "Unassigned")
                    DetailCard(icon: "globe", title: "Locale & Timezone", value: "\(store.readableLocale) • \(store.timezone ?? "N/A")")
                    DetailCard(icon: "dollarsign.circle", title: "Currency", value: store.currencyCode ?? "N/A")
                }
                .padding(.horizontal, RSMSSpacing.lg)
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isShowingEditForm = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditForm) {
            StoreFormView(viewModel: viewModel, editingStore: store)
        }
    }
}

private struct DetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(RSMSColors.burgundy)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text(value)
                    .font(RSMSFonts.body)
                    .foregroundColor(RSMSColors.primaryText)
            }
            
            Spacer()
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}
