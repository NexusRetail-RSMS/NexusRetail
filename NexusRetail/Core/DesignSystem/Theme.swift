//
//  Theme.swift
//  NexusRetail
//
//  App-wide typography, spacing, and radius configurations for dynamic type support.
//

import SwiftUI

// MARK: - Typography

enum RSMSFonts {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 22, weight: .bold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Spacing

enum RSMSSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius

enum RSMSRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}
