import GoogleMobileAds
import OSLog
import SwiftUI

/// Only this view knows about ad inventory. No coupon model or contents enter an ad request.
struct WalletAdvertisement: View {
    let configuration: AdsConfiguration
    @State private var loadedHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            if loadedHeight > 0 {
                Text("광고").font(.caption2).foregroundStyle(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .accessibilityIdentifier("ads.label")
            }
            GeometryReader { geometry in
                Group {
                    if configuration.mode == .preview {
                        Text("테스트 광고").font(.footnote).dynamicTypeSize(.large).frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.quaternary).accessibilityIdentifier("ads.test-preview")
                            .task { loadedHeight = 50 }
                    } else if geometry.size.width >= 320 {
                        GoogleWalletBanner(unitID: configuration.bannerID) { height in
                            loadedHeight = height
                        }
                        
                    }
                }
            }
            .frame(height: loadedHeight > 0 ? loadedHeight : 60)
        }
        .frame(height: loadedHeight > 0 ? nil : 0)
        .opacity(loadedHeight > 0 ? 1 : 0)
        .clipped()
        .padding(.top, loadedHeight > 0 ? 12 : 0)
        .padding(.bottom, loadedHeight > 0 ? 24 : 0)
        .background(MoaconTheme.canvas)
        .allowsHitTesting(loadedHeight > 0)
        .accessibilityHidden(loadedHeight == 0)
    }
}

private struct GoogleWalletBanner: UIViewControllerRepresentable {
    let unitID: String
    let onHeight: @MainActor (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onHeight: onHeight) }
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = unitID
        banner.rootViewController = controller
        banner.delegate = context.coordinator
        banner.adSizeDelegate = context.coordinator
        banner.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            banner.topAnchor.constraint(equalTo: controller.view.topAnchor)
        ])
        context.coordinator.banner = banner
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        banner.load(request)
        return controller
    }
    func updateUIViewController(_ controller: UIViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: UIViewController, coordinator: Coordinator) {
        coordinator.banner?.delegate = nil
        coordinator.banner?.adSizeDelegate = nil
        coordinator.banner?.removeFromSuperview()
        coordinator.banner = nil
    }

    @MainActor final class Coordinator: NSObject, BannerViewDelegate, AdSizeDelegate {
        let onHeight: @MainActor (CGFloat) -> Void
        var banner: BannerView?
        private var received = false
        private var height: CGFloat = 50
        private let logger = Logger(subsystem: "com.yourteam.gifticoncollector", category: "Advertising")
        init(onHeight: @escaping @MainActor (CGFloat) -> Void) { self.onHeight = onHeight }
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            received = true
            let actual = bannerView.bounds.height
            if actual > 0 { height = actual }
            onHeight(height)
            logger.notice("Wallet test/live banner loaded")
        }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            received = false; onHeight(0)
            logger.notice("Wallet banner unavailable, code \((error as NSError).code); no coupon operation interrupted")
        }
        func adView(_ bannerView: BannerView, willChangeAdSizeTo size: AdSize) {
            height = size.size.height
            if received { onHeight(height) }
        }
    }
}
