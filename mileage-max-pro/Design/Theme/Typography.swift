//
//  Typography.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//  Premium Typography System - SF Pro (Bold, Semibold, Regular)
//

import SwiftUI

/// Premium Typography System following iOS 26 Human Interface Guidelines
/// Uses SF Pro font family with Dynamic Type support
enum Typography {

    // MARK: - Display Fonts (Hero/Marketing)

    /// Display Large - 56pt Bold
    static var displayLarge: Font {
        .system(size: 56, weight: .bold, design: .default)
    }

    /// Display Medium - 44pt Bold
    static var displayMedium: Font {
        .system(size: 44, weight: .bold, design: .default)
    }

    /// Display Small - 36pt Bold
    static var displaySmall: Font {
        .system(size: 36, weight: .bold, design: .default)
    }

    // MARK: - Title Fonts

    /// Large Title - 34pt Bold (iOS Standard)
    static var largeTitle: Font {
        .largeTitle.weight(.bold)
    }

    /// Title 1 - 28pt Bold
    static var title1: Font {
        .title.weight(.bold)
    }

    /// Title 2 - 22pt Bold
    static var title2: Font {
        .title2.weight(.bold)
    }

    /// Title 3 - 20pt Semibold
    static var title3: Font {
        .title3.weight(.semibold)
    }

    // MARK: - Body Fonts

    /// Headline - 17pt Semibold
    static var headline: Font {
        .headline.weight(.semibold)
    }

    /// Body - 17pt Regular
    static var body: Font {
        .body
    }

    /// Body Bold - 17pt Semibold
    static var bodyBold: Font {
        .body.weight(.semibold)
    }

    /// Callout - 16pt Regular
    static var callout: Font {
        .callout
    }

    /// Callout Bold - 16pt Semibold
    static var calloutBold: Font {
        .callout.weight(.semibold)
    }

    /// Subheadline - 15pt Regular
    static var subheadline: Font {
        .subheadline
    }

    /// Subheadline Bold - 15pt Semibold
    static var subheadlineBold: Font {
        .subheadline.weight(.semibold)
    }

    // MARK: - Small Fonts

    /// Footnote - 13pt Regular
    static var footnote: Font {
        .footnote
    }

    /// Footnote Bold - 13pt Semibold
    static var footnoteBold: Font {
        .footnote.weight(.semibold)
    }

    /// Caption 1 - 12pt Regular
    static var caption1: Font {
        .caption
    }

    /// Caption 1 Bold - 12pt Semibold
    static var caption1Bold: Font {
        .caption.weight(.semibold)
    }

    /// Caption 2 - 11pt Regular
    static var caption2: Font {
        .caption2
    }

    /// Caption 2 Bold - 11pt Semibold
    static var caption2Bold: Font {
        .caption2.weight(.semibold)
    }

    // MARK: - Stat Display Fonts (Rounded for Numbers)

    /// Stat Hero - 64pt Bold Rounded
    static var statHero: Font {
        .system(size: 64, weight: .bold, design: .rounded)
    }

    /// Stat Large - 48pt Bold Rounded
    static var statLarge: Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }

    /// Stat Medium - 32pt Bold Rounded
    static var statMedium: Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }

    /// Stat Small - 24pt Semibold Rounded
    static var statSmall: Font {
        .system(size: 24, weight: .semibold, design: .rounded)
    }

    /// Stat Mini - 18pt Semibold Rounded
    static var statMini: Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    // MARK: - Monospaced Fonts

    /// Mono Body - 17pt
    static var monoBody: Font {
        .system(.body, design: .monospaced)
    }

    /// Mono Large - 28pt Bold
    static var monoLarge: Font {
        .system(.title, design: .monospaced).weight(.bold)
    }

    /// Mono Caption - 12pt
    static var monoCaption: Font {
        .system(.caption, design: .monospaced)
    }

    // MARK: - Button Fonts

    /// Button Primary - 17pt Semibold
    static var buttonPrimary: Font {
        .body.weight(.semibold)
    }

    /// Button Secondary - 15pt Semibold
    static var buttonSecondary: Font {
        .subheadline.weight(.semibold)
    }

    /// Button Small - 13pt Semibold
    static var buttonSmall: Font {
        .footnote.weight(.semibold)
    }

    /// Button Large - 18pt Semibold
    static var buttonLarge: Font {
        .system(size: 18, weight: .semibold)
    }

    // MARK: - Label Fonts

    /// Label - 12pt Bold Uppercase
    static var label: Font {
        .system(size: 12, weight: .bold)
    }

    /// Tag - 11pt Semibold
    static var tag: Font {
        .system(size: 11, weight: .semibold)
    }
}

// MARK: - Premium Text Styles

extension View {
    /// Apply large title styling
    func largeTitleStyle() -> some View {
        self
            .font(Typography.largeTitle)
            .foregroundStyle(ColorConstants.Text.primary)
    }

    /// Apply title 1 styling
    func title1Style() -> some View {
        self
            .font(Typography.title1)
            .foregroundStyle(ColorConstants.Text.primary)
    }

    /// Apply title 2 styling
    func title2Style() -> some View {
        self
            .font(Typography.title2)
            .foregroundStyle(ColorConstants.Text.primary)
    }

    /// Apply title 3 styling
    func title3Style() -> some View {
        self
            .font(Typography.title3)
            .foregroundStyle(ColorConstants.Text.primary)
    }

    /// Apply headline styling
    func headlineStyle() -> some View {
        self
            .font(Typography.headline)
            .foregroundStyle(ColorConstants.Text.primary)
    }

    /// Apply body styling
    func bodyStyle() -> some View {
        self
            .font(Typography.body)
            .foregroundStyle(ColorConstants.Text.primary)
    }

    /// Apply secondary body styling
    func secondaryBodyStyle() -> some View {
        self
            .font(Typography.body)
            .foregroundStyle(ColorConstants.Text.secondary)
    }

    /// Apply callout styling
    func calloutStyle() -> some View {
        self
            .font(Typography.callout)
            .foregroundStyle(ColorConstants.Text.secondary)
    }

    /// Apply subheadline styling
    func subheadlineStyle() -> some View {
        self
            .font(Typography.subheadline)
            .foregroundStyle(ColorConstants.Text.secondary)
    }

    /// Apply footnote styling
    func footnoteStyle() -> some View {
        self
            .font(Typography.footnote)
            .foregroundStyle(ColorConstants.Text.tertiary)
    }

    /// Apply caption styling
    func captionStyle() -> some View {
        self
            .font(Typography.caption1)
            .foregroundStyle(ColorConstants.Text.tertiary)
    }

    /// Apply stat display styling
    func statStyle(size: StatSize = .medium) -> some View {
        self
            .font(size.font)
            .foregroundStyle(ColorConstants.Text.primary)
            .monospacedDigit()
    }

    /// Apply primary accent styling
    func primaryStyle() -> some View {
        self
            .font(Typography.body)
            .foregroundStyle(ColorConstants.primary)
    }

    /// Apply link styling
    func linkStyle() -> some View {
        self
            .font(Typography.body)
            .foregroundStyle(ColorConstants.primary)
    }

    /// Apply error text styling
    func errorStyle() -> some View {
        self
            .font(Typography.footnote)
            .foregroundStyle(ColorConstants.error)
    }

    /// Apply success text styling
    func successStyle() -> some View {
        self
            .font(Typography.footnote)
            .foregroundStyle(ColorConstants.success)
    }

    /// Apply label styling (uppercase, tracked)
    func labelStyle() -> some View {
        self
            .font(Typography.label)
            .foregroundStyle(ColorConstants.Text.tertiary)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

// MARK: - Stat Size

enum StatSize {
    case mini
    case small
    case medium
    case large
    case hero

    var font: Font {
        switch self {
        case .mini: return Typography.statMini
        case .small: return Typography.statSmall
        case .medium: return Typography.statMedium
        case .large: return Typography.statLarge
        case .hero: return Typography.statHero
        }
    }
}

// MARK: - Text Modifiers

struct MonospacedNumbersModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.monospacedDigit()
    }
}

struct UppercaseTrackingModifier: ViewModifier {
    let tracking: CGFloat

    func body(content: Content) -> some View {
        content
            .textCase(.uppercase)
            .tracking(tracking)
    }
}

extension View {
    /// Use monospaced digits for consistent number alignment
    func monospacedNumbers() -> some View {
        modifier(MonospacedNumbersModifier())
    }

    /// Uppercase with letter spacing
    func uppercaseTracking(_ tracking: CGFloat = 1.2) -> some View {
        modifier(UppercaseTrackingModifier(tracking: tracking))
    }
}

// MARK: - Premium Label Styles

extension LabelStyle where Self == TitleAndIconLabelStyle {
    static var titleAndIcon: TitleAndIconLabelStyle {
        TitleAndIconLabelStyle()
    }
}

struct TitleAndIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(ColorConstants.primary)
            configuration.title
                .font(Typography.body)
                .foregroundStyle(ColorConstants.Text.primary)
        }
    }
}

struct PremiumIconLabelStyle: LabelStyle {
    let iconColor: Color
    let iconSize: CGFloat

    init(iconColor: Color = ColorConstants.primary, iconSize: CGFloat = 20) {
        self.iconColor = iconColor
        self.iconSize = iconSize
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: iconSize + 8, height: iconSize + 8)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.1))
                )
            configuration.title
                .font(Typography.body)
                .foregroundStyle(ColorConstants.Text.primary)
        }
    }
}

// MARK: - Accessibility Text Scaling

extension Font {
    /// Get scaled font size based on content size category
    static func scaled(_ size: CGFloat, weight: Weight = .regular, design: Design = .default) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}
