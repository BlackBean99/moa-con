# T16 광고 개인정보와 출시 검사

1.0(6)은 광고가 꺼진 후보이며 SDK를 포함한다. `PrivacyPolicy.md`, 앱 내 광고 고지, 심사 노트와 출시 절차를 갱신했다. 광고 지원과 웹 AdSense를 구분하고 실제 데이터 수집 없음이라고 단정하는 기존 문구를 제거했다.

`advertising_config.py`는 메타데이터 병합과 실광고 검사를 공유한다. `configure-release.py`는 동의·개인정보·지급 계정·app-ads.txt·AdMob 앱 준비 등 모든 조건이 충족되지 않으면 실제 광고 활성 설정을 쓰기 전에 실패한다. `ads-check.py --strict`는 수익 개시 gate이며 광고를 끈 첫 앱 제출 gate와 구분한다. 실제 게시자 ID가 없으면 가짜 app-ads.txt를 생성하지 않는다. 배너·앱·게시자 ID 소유자 불일치도 차단한다.

Python 반례 테스트 4개 통과: 정상 설정, 각 승인 누락, 샘플/다른 게시자/HTTP 정책, 가짜 게시자 파일 생성. 현재 실제 운영 설정은 10개 미완료이며 해당 검사 실패는 의도된 출시 차단이다. 실제 개인정보 검토는 운영자가 확정해야 하므로 metadata의 privacyDisclosureReviewed/appPrivacyCompleted를 false로 유지한다.

## 배포 SDK의 개인정보 선언 확인

SPM 다운로드의 각 ios-arm64 프레임워크 PrivacyInfo.xcprivacy를 읽었다. 원본 SDK 선언을 수정하지 않았다.

| 제공자 | 선언 항목 | 연결/추적 관련 사항 |
|---|---|---|
| Google Mobile Ads 13.11.0 | OtherDiagnosticData, CoarseLocation, PerformanceData, CrashData, AdvertisingData, ProductInteraction, DeviceID | CoarseLocation/AdvertisingData/ProductInteraction/DeviceID linked=true. **DeviceID tracking=true** 포함. 광고·분석·개발자 광고 목적 포함 |
| UMP 3.1.0 | CoarseLocation, PerformanceData, ProductInteraction | linked=false, tracking=false, AppFunctionality 목적 |

앱 자체 UserDefaults CA92.1/수집 없음 선언은 앱 소유 코드의 동작이며 이 SDK 선언을 덮어쓰지 않는다. 합산 보고서, 실제 비개인화/first-party ID 비활성 설정, IDFA 미허용, 네트워크 요청과 Store 개인정보 공개를 함께 확인해야 한다. 단순 NPA 요청이나 SDK 통합만으로 개인정보·추적 관련 출시 준비 완료를 주장하지 않는다.

Google 공식 quick-start에서 2026-10-07 조회한 SKAdNetwork 식별자 50개를 Info.plist에 반영했다. 이는 개인정보 승인이나 App Store 심사를 대체하지 않는다. `GADDelayAppMeasurementInit=true`와 명시적 동의 전 start 호출 없음으로 준비했지만, SDK 내부 초기 동작을 네트워크 캡처로 완전히 입증한 것은 아니다.

공식 근거: [SDK 데이터 공개](https://developers.google.com/admob/ios/privacy/data-disclosure), [Apple 사용자 개인정보](https://developer.apple.com/app-store/user-privacy-and-data-use/), [AdMob 앱 검증](https://support.google.com/admob/answer/14538460?hl=en).
