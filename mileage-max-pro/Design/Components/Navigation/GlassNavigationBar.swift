//
//  GlassNavigationBar.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI

/// Glass-styled navigation bar with Liquid Glass effect
struct GlassNavigationBar<LeadingContent: View, TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    let leadingContent: LeadingContent
    let trailingContent: TrailingContent

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailing: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Leading
            leadingContent
                .frame(minWidth: 44)

            Spacer()

            // Title
            VStack(spacing: 2) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorConstants.Text.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.caption2)
                        .foregroundStyle(ColorConstants.Text.secondary)
                }
            }

            Spacer()

            // Trailing
            trailingContent
                .frame(minWidth: 44)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Navigation Back Button

struct NavigationBackButton: View {
    let title: String?
    let action: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(title: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            if let action = action {
                action()
            } else {
                dismiss()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))

                if let title = title {
                    Text(title)
                        .font(Typography.body)
                }
            }
            .foregroundStyle(ColorConstants.primary)
        }
    }
}

// MARK: - Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, label: String)]

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                GlassTabItem(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: selectedTab == index,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }
}

// MARK: - Glass Tab Item

struct GlassTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(ColorConstants.primary.opacity(0.15))
                            .matchedGeometryEffect(id: "tab_background", in: namespace)
                    }

                    Image(systemName: isSelected ? icon : icon.replacingOccurrences(of: ".fill", with: ""))
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? ColorConstants.primary : ColorConstants.Text.tertiary)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(width: 56, height: 32)

                Text(label)
                    .font(Typography.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? ColorConstants.primary : ColorConstants.Text.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Page Indicator

struct GlassPageIndicator: View {
    let pageCount: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? ColorConstants.primary : ColorConstants.Text.tertiary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    .onTapGesture {
                        HapticManager.shared.lightImpact()
                        currentPage = index
                    }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Glass Breadcrumb

struct GlassBreadcrumb: View {
    let items: [String]
    let onTap: ((Int) -> Void)?

    init(items: [String], onTap: ((Int) -> Void)? = nil) {
        self.items = items
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorConstants.Text.tertiary)
                }

                if let onTap = onTap, index < items.count - 1 {
                    Button {
                        onTap(index)
                    } label: {
                        Text(item)
                            .font(Typography.caption1)
                            .foregroundStyle(ColorConstants.primary)
                    }
                } else {
                    Text(item)
                        .font(Typography.caption1)
                        .fontWeight(index == items.count - 1 ? .semibold : .regular)
                        .foregroundStyle(index == items.count - 1 ? ColorConstants.Text.primary : ColorConstants.Text.secondary)
                }
            }
        }
    }
}

// MARK: - Glass Chip

struct GlassChip: View {
    let text: String
    let icon: String?
    let isSelected: Bool
    let action: (() -> Void)?

    init(
        _ text: String,
        icon: String? = nil,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action?()
        } label: {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(text)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : ColorConstants.Text.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? ColorConstants.primary : Color.gray.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Glass Chip Group

struct GlassChipGroup<T: Hashable & CustomStringConvertible>: View {
    @Binding var selection: Set<T>
    let options: [(value: T, icon: String?)]
    let allowsMultiple: Bool

    init(
        selection: Binding<Set<T>>,
        options: [(value: T, icon: String?)],
        allowsMultiple: Bool = true
    ) {
        self._selection = selection
        self.options = options
        self.allowsMultiple = allowsMultiple
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.value) { option in
                GlassChip(
                    option.value.description,
                    icon: option.icon,
                    isSelected: selection.contains(option.value)
                ) {
                    if allowsMultiple {
                        if selection.contains(option.value) {
                            selection.remove(option.value)
                        } else {
                            selection.insert(option.value)
                        }
                    } else {
                        selection = [option.value]
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), frames)
    }
}

// MARK: - Preview

#Preview("Glass Navigation") {
    VStack(spacing: 0) {
        GlassNavigationBar(
            title: "Trip Details",
            subtitle: "12.5 miles",
            leading: {
                NavigationBackButton(title: "Back")
            },
            trailing: {
                GlassIconButton(icon: "square.and.arrow.up", style: .secondary, size: 36, action: {})
            }
        )

        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Breadcrumb
                GlassBreadcrumb(items: ["Home", "Trips", "December 2024", "Trip #42"])
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Page indicator
                GlassPageIndicator(pageCount: 4, currentPage: .constant(1))

                // Chips
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Categories")
                        .font(Typography.caption1)
                        .foregroundStyle(ColorConstants.Text.secondary)

                    HStack(spacing: 8) {
                        GlassChip("Business", icon: "briefcase", isSelected: true) {}
                        GlassChip("Personal", icon: "person", isSelected: false) {}
                        GlassChip("Medical", icon: "cross.case", isSelected: false) {}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
        }

        Spacer()

        // Tab bar
        GlassTabBar(
            selectedTab: .constant(0),
            tabs: [
                ("house.fill", "Home"),
                ("car.fill", "Trips"),
                ("map.fill", "Routes"),
                ("chart.bar.fill", "Reports"),
                ("gearshape.fill", "Settings")
            ]
        )
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
