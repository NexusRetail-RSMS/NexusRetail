//
//  Colors.swift
//  NexusRetail
//
//  Central color palette definition for the NexusRetail RSMS design system.
//

import SwiftUI

enum RSMSColors {
    // MARK: Primary Brand Colors
    
    /// Soft cream — primary background color (#EDE7C7)
    static let cream = Color(hex: "EDE7C7")
    
    /// Burgundy — headers, primary actions (#8B0000)
    static let burgundy = Color(hex: "8B0000")
    
    /// Dark burgundy — emphasis, active states (#5B0202)
    static let darkBurgundy = Color(hex: "5B0202")
    
    /// Dark brown — text on light backgrounds (#200E01)
    static let darkBrown = Color(hex: "200E01")
    
    // MARK: Semantic Colors
    
    /// Primary background for screens
    static let background = Color(hex: "F9F8F3")
    
    /// Card and surface background
    static let cardBackground = Color.white
    
    /// Navigation bar / header background
    static let headerBackground = burgundy
    
    /// Primary text color
    static let primaryText = darkBrown
    
    /// Secondary / muted text
    static let secondaryText = Color.gray
    
    /// Primary action color (buttons, toggles)
    static let primaryAction = burgundy
    
    /// Destructive / error color
    static let error = Color(hex: "D32F2F")
    
    /// Success / configured color
    static let success = Color(hex: "2E7D32")
    
    /// Warning color
    static let warning = Color(hex: "F57C00")
    
    /// Disabled state
    static let disabled = Color.gray.opacity(0.4)
    
    /// Card border color
    static let cardBorder = Color.gray.opacity(0.15)
    
    /// Input field border
    static let inputBorder = Color.gray.opacity(0.3)
    
    /// Subtle divider
    static let divider = Color.gray.opacity(0.15)
}


