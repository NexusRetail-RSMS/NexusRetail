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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Action")
                        .font(.system(size: 14, weight: .medium))
                        .textCase(.uppercase)
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 4)
                    
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
                .padding(.top, 150) // push down below header with more gap
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
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.06))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(RSMSColors.secondaryText)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.3))
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(CardPressStyle())
    }
}
