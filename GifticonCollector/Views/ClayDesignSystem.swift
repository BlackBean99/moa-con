import SwiftUI

enum ClayTheme {
    static let canvas = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let ink = Color(red: 0.15, green: 0.14, blue: 0.13)
    static let mutedInk = Color(red: 0.43, green: 0.40, blue: 0.37)
    static let coral = Color(red: 0.96, green: 0.48, blue: 0.37)
    static let butter = Color(red: 0.99, green: 0.78, blue: 0.34)
    static let mint = Color(red: 0.55, green: 0.82, blue: 0.69)
    static let lilac = Color(red: 0.73, green: 0.65, blue: 0.90)
    static let sky = Color(red: 0.54, green: 0.77, blue: 0.91)
}

struct ClayCardModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.58), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
            .shadow(color: color.opacity(0.42), radius: 12, x: 0, y: 8)
    }
}

extension View {
    func clayCard(_ color: Color = .white, radius: CGFloat = 24) -> some View {
        modifier(ClayCardModifier(color: color, radius: radius))
    }
}

struct ClayIcon: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(ClayTheme.ink)
            .frame(width: size, height: size)
            .background(color, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 1))
            .shadow(color: color.opacity(0.45), radius: 7, y: 4)
    }
}

struct ClayPill: View {
    let title: String
    let color: Color
    var systemImage: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage { Image(systemName: systemImage).font(.caption.weight(.bold)) }
            Text(title).font(.caption.weight(.bold))
        }
        .foregroundStyle(ClayTheme.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color, in: Capsule())
    }
}

struct ClayPrimaryButtonStyle: ButtonStyle {
    var color: Color = ClayTheme.coral

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(ClayTheme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(color, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.55), lineWidth: 1))
            .shadow(color: color.opacity(0.42), radius: 9, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
