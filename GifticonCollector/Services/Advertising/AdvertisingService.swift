import Combine
import Foundation
import GoogleMobileAds
import OSLog
import UserMessagingPlatform

struct ConsentSnapshot: Sendable {
    var canRequestAds: Bool
    var privacyOptionsRequired: Bool
}

@MainActor protocol AdvertisingConsent {
    var snapshot: ConsentSnapshot { get }
    func gather() async throws -> ConsentSnapshot
    func presentPrivacyOptions() async throws -> ConsentSnapshot
}

@MainActor final class GoogleAdvertisingConsent: AdvertisingConsent {
    var snapshot: ConsentSnapshot {
        ConsentSnapshot(canRequestAds: ConsentInformation.shared.canRequestAds,
                        privacyOptionsRequired: ConsentInformation.shared.privacyOptionsRequirementStatus == .required)
    }
    func gather() async throws -> ConsentSnapshot {
        let parameters = RequestParameters()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
        try await ConsentForm.loadAndPresentIfRequired(from: nil)
        return snapshot
    }
    func presentPrivacyOptions() async throws -> ConsentSnapshot {
        try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        return snapshot
    }
}

@MainActor final class AdvertisingService: ObservableObject {
    let configuration: AdsConfiguration
    @Published private(set) var canShowAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var privacyError: String?
    @Published private(set) var isUpdatingPrivacy = false
    @Published private(set) var revision = 0
    private let consent: any AdvertisingConsent
    private let startSDK: @MainActor () -> Void
    private var attempted = false
    private var started = false
    private let logger = Logger(subsystem: "com.yourteam.gifticoncollector", category: "Advertising")

    init(configuration: AdsConfiguration = .current,
         consent: any AdvertisingConsent = GoogleAdvertisingConsent(),
         startSDK: @escaping @MainActor () -> Void = AdvertisingService.startGoogleSDK) {
        self.configuration = configuration
        self.consent = consent
        self.startSDK = startSDK
    }

    static func startGoogleSDK() {
        let request = MobileAds.shared.requestConfiguration
        request.setPublisherFirstPartyIDEnabled(false)
        request.publisherPrivacyPersonalizationState = .disabled
        request.maxAdContentRating = .general
        MobileAds.shared.start()
    }

    func prepare() async {
        guard !attempted else { return }
        attempted = true
        switch configuration.mode {
        case .disabled, .failedPreview: return
        case .preview: canShowAds = true
        case .test:
            // Explicit DEBUG-only Google sample inventory. This does not validate a publisher's UMP messages.
            startOnce(); canShowAds = true
        case .live: await refreshConsent(presentOptions: false)
        }
    }

    func retryConsent() async {
        guard configuration.mode == .live, !isUpdatingPrivacy else { return }
        await refreshConsent(presentOptions: false)
    }

    func changePrivacyOptions() async {
        guard configuration.mode == .live else { return }
        await refreshConsent(presentOptions: true)
    }

    private func refreshConsent(presentOptions: Bool) async {
        revision += 1
        let requestRevision = revision
        canShowAds = false
        privacyError = nil
        isUpdatingPrivacy = true
        do {
            let state = try await (presentOptions ? consent.presentPrivacyOptions() : consent.gather())
            guard requestRevision == revision else { return }
            privacyOptionsRequired = state.privacyOptionsRequired
            if state.canRequestAds { startOnce(); canShowAds = true }
        } catch {
            guard requestRevision == revision else { return }
            // Preserve the entry point even after an error; never silently reuse consent to serve ads.
            privacyOptionsRequired = consent.snapshot.privacyOptionsRequired
            privacyError = "광고 설정을 불러오지 못했어요. 다시 시도해 주세요."
            logger.notice("Consent unavailable; advertising remains hidden")
        }
        guard requestRevision == revision else { return }
        isUpdatingPrivacy = false
    }

    private func startOnce() {
        guard !started else { return }
        started = true
        startSDK()
    }
}
