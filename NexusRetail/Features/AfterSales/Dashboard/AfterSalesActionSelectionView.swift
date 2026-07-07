import SwiftUI

struct AfterSalesActionSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItemIds: Set<UUID>
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Select Action")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(RSMSColors.secondaryText)
                        .padding(.horizontal, RSMSSpacing.lg)
                    
                    VStack(spacing: 20) {
                        actionCard(
                            title: "Exchange Product",
                            description: "Swap the selected item for a different size, color, or a completely new product.",
                            icon: "arrow.triangle.2.circlepath",
                            color: RSMSColors.burgundy
                        ) {
                            print("Exchange initiated for invoice \(invoiceId), items: \(selectedItemIds.count)")
                            // Future navigation to exchange flow
                        }
                        
                        actionCard(
                            title: "Repair Product",
                            description: "Send the selected item to our service center for expert repair and maintenance.",
                            icon: "wrench.and.screwdriver.fill",
                            color: Color(hex: "34495E") // A sophisticated dark blue/slate
                        ) {
                            print("Repair initiated for invoice \(invoiceId), items: \(selectedItemIds.count)")
                            // Future navigation to repair flow
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                }
                .padding(.top, 120) // push down below header
            }
            .ignoresSafeArea(edges: .top)
            
            customHeaderSection
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Process Item")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("1 item selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Action Card
    private func actionCard(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
            }
            .padding(20)
            .background(RSMSColors.cardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
