//
//  Spacing.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Spacing system based on 4-point grid
enum Spacing {

    // MARK: - Base Spacing Values

    /// 4pt - Minimal spacing
    static let xxs: CGFloat = 4

    /// 8pt - Tight spacing
    static let xs: CGFloat = 8

    /// 12pt - Compact spacing
    static let sm: CGFloat = 12

    /// 16pt - Standard spacing
    static let md: CGFloat = 16

    /// 24pt - Comfortable spacing
    static let lg: CGFloat = 24

    /// 32pt - Generous spacing
    static let xl: CGFloat = 32

    /// 48pt - Very generous spacing
    static let xxl: CGFloat = 48

    /// 64pt - Extra large spacing
    static let xxxl: CGFloat = 64

    // MARK: - Semantic Spacing

    /// Standard horizontal margin for screen content
    static let screenHorizontal: CGFloat = md

    /// Standard vertical margin for screen content
    static let screenVertical: CGFloat = md

    /// Spacing between cards
    static let cardGap: CGFloat = sm

    /// Internal padding for cards
    static let cardPadding: CGFloat = md

    /// Spacing between list items
    static let listItemGap: CGFloat = xs

    /// Spacing between form fields
    static let formFieldGap: CGFloat = md

    /// Spacing between section headers and content
    static let sectionGap: CGFloat = xs

    /// Spacing between major sections
    static let majorSectionGap: CGFloat = xl

    /// Icon to text spacing
    static let iconTextGap: CGFloat = xs

    /// Button internal horizontal padding
    static let buttonHorizontal: CGFloat = md

    /// Button internal vertical padding
    static let buttonVertical: CGFloat = sm

    /// Minimum touch target size
    static let minimumTouchTarget: CGFloat = 44

    // MARK: - Edge Insets

    /// Standard screen edge insets
    static var screenInsets: EdgeInsets {
        EdgeInsets(
            top: screenVertical,
            leading: screenHorizontal,
            bottom: screenVertical,
            trailing: screenHorizontal
        )
    }

    /// Card padding insets
    static var cardInsets: EdgeInsets {
        EdgeInsets(
            top: cardPadding,
            leading: cardPadding,
            bottom: cardPadding,
            trailing: cardPadding
        )
    }

    /// Compact card insets
    static var compactCardInsets: EdgeInsets {
        EdgeInsets(
            top: sm,
            leading: sm,
            bottom: sm,
            trailing: sm
        )
    }

    /// Button content insets
    static var buttonInsets: EdgeInsets {
        EdgeInsets(
            top: buttonVertical,
            leading: buttonHorizontal,
            bottom: buttonVertical,
            trailing: buttonHorizontal
        )
    }

    /// Zero insets
    static var zero: EdgeInsets {
        EdgeInsets()
    }
}

// MARK: - Spacing View Builders

/// Fixed width spacer
struct HSpacing: View {
    let width: CGFloat

    init(_ width: CGFloat) {
        self.width = width
    }

    var body: some View {
        Spacer().frame(width: width)
    }
}

/// Fixed height spacer
struct VSpacing: View {
    let height: CGFloat

    init(_ height: CGFloat) {
        self.height = height
    }

    var body: some View {
        Spacer().frame(height: height)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard screen padding
    func screenPadding() -> some View {
        self.padding(Spacing.screenInsets)
    }

    /// Apply horizontal screen padding only
    func horizontalScreenPadding() -> some View {
        self.padding(.horizontal, Spacing.screenHorizontal)
    }

    /// Apply vertical screen padding only
    func verticalScreenPadding() -> some View {
        self.padding(.vertical, Spacing.screenVertical)
    }

    /// Apply card internal padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardInsets)
    }

    /// Apply compact padding
    func compactPadding() -> some View {
        self.padding(Spacing.compactCardInsets)
    }

    /// Apply spacing from enum
    func padding(_ spacing: SpacingSize) -> some View {
        self.padding(spacing.value)
    }

    /// Apply horizontal spacing from enum
    func horizontalPadding(_ spacing: SpacingSize) -> some View {
        self.padding(.horizontal, spacing.value)
    }

    /// Apply vertical spacing from enum
    func verticalPadding(_ spacing: SpacingSize) -> some View {
        self.padding(.vertical, spacing.value)
    }
}

// MARK: - Layout Helpers

extension View {
    /// Frame with standard touch target minimum
    func touchTarget() -> some View {
        self.frame(minWidth: Spacing.minimumTouchTarget, minHeight: Spacing.minimumTouchTarget)
    }

    /// Frame with specific size maintaining touch target minimum
    func sized(_ size: CGFloat) -> some View {
        self.frame(
            width: max(size, Spacing.minimumTouchTarget),
            height: max(size, Spacing.minimumTouchTarget)
        )
    }

    /// Fill available width
    func fillWidth(alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }

    /// Fill available height
    func fillHeight(alignment: Alignment = .center) -> some View {
        self.frame(maxHeight: .infinity, alignment: alignment)
    }

    /// Fill available space
    func fill(alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

// MARK: - Stack Helpers

extension HStack {
    /// HStack with standard spacing
    init(spacing: SpacingSize, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing.value, content: content)
    }
}

extension VStack {
    /// VStack with standard spacing
    init(spacing: SpacingSize, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing.value, content: content)
    }
}

// MARK: - Grid Helpers

extension LazyVGrid {
    /// Create adaptive grid with standard spacing
    static func adaptive(
        minimum: CGFloat = 150,
        spacing: CGFloat = Spacing.cardGap
    ) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum), spacing: spacing)]
    }

    /// Create fixed column grid
    static func fixed(
        columns: Int,
        spacing: CGFloat = Spacing.cardGap
    ) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
}

// MARK: - Divider with Spacing

struct SpacedDivider: View {
    let spacing: CGFloat

    init(spacing: CGFloat = Spacing.md) {
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: spacing)
            Divider()
            Spacer().frame(height: spacing)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(_ title: String, action: (() -> Void)? = nil, actionLabel: String? = nil) {
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        HStack {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(ColorConstants.Text.primary)

            Spacer()

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorConstants.primary)
                }
            }
        }
        .padding(.bottom, Spacing.sectionGap)
    }
}
