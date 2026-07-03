//
//  SearchBarView.swift
//  NexusRetail
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(RSMSColors.secondaryText)
            
            TextField(placeholder, text: $text)
                .font(RSMSFonts.body)
                .foregroundColor(RSMSColors.primaryText)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.md)
        .padding(.vertical, RSMSSpacing.sm)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(RSMSColors.inputBorder, lineWidth: 1)
        )
    }
}
