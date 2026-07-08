//
//  SearchBarView.swift
//  NexusRetail
//

import SwiftUI

struct SearchBarView: View {
    @Environment(AppTheme.self) private var theme
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.secondaryText)
            
            TextField(placeholder, text: $text)
                .font(RSMSFonts.body)
                .foregroundColor(theme.primaryText)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.md)
        .padding(.vertical, RSMSSpacing.sm)
        .background(Color.white)
        .cornerRadius(RSMSRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.small)
                .stroke(theme.inputBorder, lineWidth: 1)
        )
    }
}
