import SwiftUI
import UIKit

/// Native surfaces and controls own their appearance; the coral accent identifies 모아콘.
enum MoaconTheme {
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.53, blue: 0.43, alpha: 1)
            : UIColor(red: 0.70, green: 0.20, blue: 0.14, alpha: 1)
    })
    // Keep white labels readable in both appearances; navigation uses the brighter accent.
    static let actionFill = Color(red: 0.70, green: 0.20, blue: 0.14)
    enum Space {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let page: CGFloat = 32
    }
}

/// Liquid Glass belongs to the interaction layer, never the coupon image or list content.
struct MoaconPrimaryButtonStyle: PrimitiveButtonStyle {
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            GlassProminentButtonStyle().makeBody(configuration: configuration).tint(MoaconTheme.actionFill)
        } else {
            BorderedProminentButtonStyle().makeBody(configuration: configuration).tint(MoaconTheme.actionFill)
        }
    }
}

struct CouponStatus: View {
    let title: String
    var symbol: String = "clock"
    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A pair of tickets repeats the app icon's mark without decorating every content row.
struct MoaconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(MoaconTheme.accent.opacity(0.14))
                .frame(width: 116, height: 88)
                .rotationEffect(.degrees(-12))
                .offset(x: -8, y: -10)
            RoundedRectangle(cornerRadius: 20)
                .fill(MoaconTheme.accent)
                .frame(width: 116, height: 88)
            Text("M")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(height: 144)
        .accessibilityHidden(true)
    }
}
