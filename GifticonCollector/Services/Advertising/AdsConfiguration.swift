import Foundation

struct AdsConfiguration {
    enum Mode: Equatable { case disabled, test, live, preview, failedPreview }
    static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    static let testBannerID = "ca-app-pub-3940256099942544/2435281174"
    let mode: Mode
    let bannerID: String

    static var current: AdsConfiguration {
        #if DEBUG
        AdsConfiguration(info: Bundle.main.infoDictionary ?? [:], arguments: ProcessInfo.processInfo.arguments, permitsDebugTools: true)
        #else
        AdsConfiguration(info: Bundle.main.infoDictionary ?? [:])
        #endif
    }

    init(info: [String: Any], arguments: [String] = [], permitsDebugTools: Bool = false) {
        if permitsDebugTools {
            if arguments.contains("--ads-sdk-testing") { mode = .test; bannerID = Self.testBannerID; return }
            if arguments.contains("--ads-ui-testing") {
                mode = arguments.contains("--ads-failure-testing") ? .failedPreview : .preview
                bannerID = ""; return
            }
            // Debug builds never serve revenue-generating ads, even with production metadata.
            mode = .disabled; bannerID = ""; return
        }
        let appID = info["GADApplicationIdentifier"] as? String ?? ""
        let unitID = info["MoaconBannerAdUnitID"] as? String ?? ""
        let policy = URL(string: info["MoaconPrivacyPolicyURL"] as? String ?? "")
        let flags = ["MoaconAdsEnabled", "MoaconAdsConsentConfigured", "MoaconAdsPrivacyReviewed",
                     "MoaconAdsAppAdsTxtVerified", "MoaconAdsReadinessApproved"]
        let appValid = appID.range(of: "^ca-app-pub-[0-9]{16}~[0-9]{10}$", options: .regularExpression) != nil
        let unitValid = unitID.range(of: "^ca-app-pub-[0-9]{16}/[0-9]{10}$", options: .regularExpression) != nil
        let samePublisher = appID.split(separator: "~").first == unitID.split(separator: "/").first
        let isSamplePublisher = appID.hasPrefix("ca-app-pub-3940256099942544") || unitID.hasPrefix("ca-app-pub-3940256099942544")
        guard flags.allSatisfy({ info[$0] as? Bool == true }), appValid, unitValid, samePublisher,
              !isSamplePublisher, policy?.scheme == "https", policy?.host?.isEmpty == false,
              policy?.user == nil, policy?.password == nil else {
            mode = .disabled; bannerID = ""; return
        }
        mode = .live; bannerID = unitID
    }
}

enum AdPlacement {
    static func isEligible(hasCoupons: Bool, isSearchPresented: Bool, isBusy: Bool, isDetail: Bool) -> Bool {
        hasCoupons && !isSearchPresented && !isBusy && !isDetail
    }
}
