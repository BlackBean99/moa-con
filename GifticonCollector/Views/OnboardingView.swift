import SwiftUI

struct OnboardingView: View {
    let onStart: () -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            welcome
            ScrollView { welcome }
        }
        .background(MoaconTheme.canvas.ignoresSafeArea())
        .tint(MoaconTheme.accent)
    }

    private var welcome: some View {
        VStack(spacing: MoaconTheme.Space.page) {
            Spacer(minLength: MoaconTheme.Space.large)
            MoaconMark()
            VStack(spacing: MoaconTheme.Space.small) {
                Text("모아콘")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("쿠폰을 한곳에")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: MoaconTheme.Space.large)
            Button(action: onStart) {
                Text("시작하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(MoaconPrimaryButtonStyle())
            .accessibilityIdentifier("onboarding.start")
        }
        .frame(maxWidth: 440)
        .padding(MoaconTheme.Space.page)
    }
}
