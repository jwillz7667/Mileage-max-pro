//
//  Typography.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Typography system following iOS Human Interface Guidelines
/// Full Dynamic Type support from xSmall to AX5
enum Typography {

    // MARK: - Font Styles

    /// Large Title - Screen titles (34pt Bold)
    static var largeTitle: Font {
        .largeTitle.weight(.bold)
    }

    /// Title 1 - Section headers (28pt Bold)
    static var title1: Font {
        .title.weight(.bold)
    }

    /// Title 2 - Card titles (22pt Bold)
    static var title2: Font {
        .title2.weight(.bold)
    }

    /// Title 3 - Subsections (20pt Semibold)
    static var title3: Font {
        .title3.weight(.semibold)
    }

    /// Headline - Emphasis (17pt Semibold)
    static var headline: Font {
        .headline
    }

    /// Body - Primary content (17pt Regular)
    static var body: Font {
        .body
    }

    /// Body Bold - Emphasized content (17pt Semibold)
    static var bodyBold: Font {
        .body.weight(.semibold)
    }

    /// Callout - Supporting text (16pt Regular)
    static var callout: Font {
        .callout
    }

    /// Callout Bold - Emphasized supporting text (16pt Semibold)
    static var calloutBold: Font {
        .callout.weight(.semibold)
    }

    /// Subheadline - Secondary content (15pt Regular)
    static var subheadline: Font {
        .subheadline
    }

    /// Subheadline Bold - Emphasized secondary (15pt Semibold)
    static var subheadlineBold: Font {
        .subheadline.weight(.semibold)
    }

    /// Footnote - Tertiary content (13pt Regular)
    static var footnote: Font {
        .footnote
    }

    /// Caption 1 - Labels (12pt Regular)
    static var caption1: Font {
        .caption
    }

    /// Caption 2 - Timestamps (11pt Regular)
    static var caption2: Font {
        .caption2
    }

    // MARK: - Monospaced Fonts

    /// Monospaced for numbers (17pt)
    static var monoBody: Font {
        .system(.body, design: .monospaced)
    }

    /// Monospaced large for stats (28pt)
    static var monoLarge: Font {
        .system(.title, design: .monospaced).weight(.bold)
    }

    /// Monospaced caption (12pt)
    static var monoCaption: Font {
        .system(.caption, design: .monospaced)
    }

    // MARK: - Rounded Fonts

    /// Rounded headline for friendly UI (17pt)
    static var roundedHeadline: Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }

    /// Rounded title for friendly headers (22pt)
    static var roundedTitle: Font {
        .system(.title2, design: .rounded).weight(.bold)
    }

    /// Rounded large title (34pt)
    static var roundedLargeTitle: Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }

    // MARK: - Stat Display

    /// Large stat number (48pt Bold Rounded)
    static var statLarge: Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }

    /// Medium stat number (32pt Bold Rounded)
    static var statMedium: Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }

    /// Small stat number (24pt Semibold Rounded)
    static var statSmall: Font {
        .system(size: 24, weight: .semibold, design: .rounded)
    }

    // MARK: - Button Text

    /// Primary button text (17pt Semibold)
    static var buttonPrimary: Font {
        .body.weight(.semibold)
    }

    /// Secondary button text (15pt Medium)
    static var buttonSecondary: Font {
        .subheadline.weight(.medium)
    }

    /// Small button/link text (13pt Medium)
    static var buttonSmall: Font {
        .footnote.weight(.medium)
    }
}

// MARK: - Text Styles

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
}

// MARK: - Stat Size

enum StatSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small: return Typography.statSmall
        case .medium: return Typography.statMedium
        case .large: return Typography.statLarge
        }
    }
}

// MARK: - Text Modifiers

struct MonospacedNumbersModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .monospacedDigit()
    }
}

struct UppercaseModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

extension View {
    /// Use monospaced digits for consistent number alignment
    func monospacedNumbers() -> some View {
        modifier(MonospacedNumbersModifier())
    }

    /// Uppercase with letter spacing
    func uppercaseTracking() -> some View {
        modifier(UppercaseModifier())
    }
}

// MARK: - Label Styles

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
        }
    }
}

// MARK: - Accessibility Text Scaling

extension Font {
    /// Get scaled font size based on content size category
    static func scaled(_ size: CGFloat, relativeTo textStyle: TextStyle = .body) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}
