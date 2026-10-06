# 모아콘 심사·출시 검증

검토일: 2026-10-06. 대상: 0.4 (4), iOS 17+, iPhone/iPad, 오프라인 SwiftUI 앱 + 사진 공유 확장.

**판정: 로컬 배포 후보. App Store 제출 준비 완료는 아니다.** 아래 필수 항목과 실제 쿠폰 검증이 남았다. 코드 검토, 자동 테스트, 로컬 설치를 구분하며 Apple 승인이나 실제 매장 사용을 보장하지 않는다.

## 이번 변경

- 선물 상자와 바코드 막대가 있는 코랄 티켓, 뒤에 겹친 아이보리 티켓으로 만든 독창적인 이모티콘 스타일 로고. Apple 이모지 파일이나 다른 서비스의 로고를 가져오지 않았다.
- 투명 BrandMark 원본을 온보딩에 사용하고, 같은 원본에서 1024px 불투명 아이콘을 내보낸다. 아이콘의 모서리는 OS가 처리한다. `swift scripts/generate-app-icon.swift`로 재생성한다.
- `PrivacyInfo.xcprivacy`에 앱 자체 설정용 UserDefaults 사용 사유 `CA92.1`, 추적 없음, 수집 데이터 없음 선언을 추가했다. 온보딩 완료 상태와 삭제 후 자동 찾기 제외 목록에 해당한다. 공유 확장은 현재 UserDefaults를 사용하지 않는다.
- 더 보기 → 개인정보 처리에서 기기 내 분석, 사진 권한, 보관·삭제, 실패 파일과 시스템 백업을 설명한다. 공개 정책 URL 및 운영자·지원 정보는 아직 없다.

## 제출 전에 해결할 항목

| 항목 | 현재 증거와 판정 | 완료 조건 |
|---|---|---|
| 개인정보처리방침 | 저장소 Markdown과 앱 내 설명은 있음. 공개 URL·운영자·지원 연락처 미설정 | 공개 HTTPS 정책에 실제 보관/삭제/백업과 운영자 연락처를 반영하고, App Store Connect에 URL 등록. 앱 내 정책과 일치시킬 것 |
| 고객지원 | 앱에 문의 수단 없음. Connect Support URL 미검증 | 공개 지원 페이지와 실제 응답할 연락처, 앱에서 접근 가능한 문의 수단 준비 |
| Privacy manifest | 이번에 앱 UserDefaults 사용 사유와 리소스 포함 수정 | 최종 Archive에 포함 확인 + Organizer 개인정보 보고서/배포 Validate 실행. 향후 SDK 추가 시 다시 감사 |
| App Privacy | 소스에서 직접 네트워크 전송·광고·분석 SDK를 발견하지 않음. 현재 기능은 기기 내 처리 | 실기기 App Privacy Report와 최종 의존성 확인 후 Connect 질문에 응답. 현 상태에서 ‘수집하지 않음’이 타당하다는 판단이며, Connect 등록 완료를 뜻하지 않음 |
| 배포 서명·앱 등록 | 개발 팀으로 로컬 설치 가능. Bundle ID/App Group은 `com.yourteam…` | 소유한 식별자, 앱 등록, 배포 권한·프로파일, App Store 배포 Validate 확인. 식별자를 바꾸면 기존 로컬/App Group 데이터 이관도 설계 |
| 메타데이터 | 실제 소개·지원 URL·스크린샷·연령 등급·수출 규정 답변은 미검증 | 실제 Release 화면으로 준비. 새 연령 등급 질문 응답. 샘플 쿠폰은 직접 만든 무효 바코드만 사용. 출시 국가·가격·권리 확인 |
| iPad와 지원 OS | iPhone 자동 QA 있음. 이전 iPad 실행은 Simulator 호스트 시작 단계에서 멈춰 미검증 | 현재 iPad 지원을 유지할 경우 실기기/정상 Simulator에서 회전·분할 화면·큰 글자·공유·원본 확대 검증. 최소 지원 iOS 17 및 최신 OS도 확인 |
| 실제 심사 접근성 | 로그인 없음. 깨끗한 설치는 빈 보관함 | Review Notes에 사진 선택/공유 경로와 무효 샘플 이미지 제공. 승인·수정·사용 완료를 재현 가능한 단계로 설명 |

Apple은 개인정보처리방침을 Connect와 앱 안에서 접근 가능하게 요구하고 완성된 앱·정확한 메타데이터를 심사한다. 위 항목은 현재 코드와 운영 자료를 대조한 결과다. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

필수 사유 API는 선언이 없으면 업로드가 거절될 수 있다. `CA92.1`은 앱 자체의 UserDefaults 읽기·쓰기에 해당한다. [Required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [승인된 사유](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype), [TN3183](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)

기기에서만 처리하는 데이터는 Apple의 App Privacy 정의에서 수집에 해당하지 않는다. 사용자에게 앱 자체 클라우드 전송과 OS 백업을 구분해서 안내해야 한다. [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

현재 Xcode 26.3 / iOS SDK 26.2는 2026-04-28 시행된 Xcode 26+ / SDK 26+ 최소 요건에 부합한다. iOS 17 최소 지원도 2026-09-09 요건(iOS 13+)에 부합한다. 디자인 방향과 업로드 SDK 최소 버전은 별도다. [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)

## 공개 출시 전에 권장하는 기능 보완

아래는 제품 신뢰성과 반복 사용에 관한 판단이다. 모든 항목이 Apple의 필수 기능이라는 의미는 아니다.

| 우선순위 | 확인한 문제 | 보완할 동작 / 검증 조건 |
|---|---|---|
| 높음 | `ManualImportView`는 바코드가 안 잡히면 등록을 종료한다 | 원본은 유지하고 번호·브랜드·유효기간을 직접 입력해 확인 필요로 보관. 흐린 이미지·잘린 바코드도 다시 촬영하지 않고 복구 가능해야 함 |
| 높음 | `GifticonParser`는 여러 바코드 중 첫 값만 저장한다 | 모든 후보를 보존하고 원본 위치와 함께 선택. 일반 상품·멤버십·배송 코드가 쿠폰 사용 번호로 확정되지 않게 할 것 |
| 높음 | 쿠폰 분류 확신과 각 필드 인식 정확도는 별개다. `parseAmount`는 첫 ‘N원’을 선택 | 상품 가격·할인액과 금액권 잔액을 분리하고 브랜드/제목/기한/금액의 불확실성을 확인 단계로 보낼 것. 금액권만 부분 차감 활성화. ‘confidence’ 수치를 실측 정확도로 홍보하지 않을 것 |
| 높음 | 공유 확장은 저장 오류를 무시하고 닫는다. 공유 가져오기는 읽기/분석 실패 시 파일만 남기고 안내하지 않는다 | 저장 성공·실패 표시, 대기/실패 항목의 재시도·직접 입력·삭제, 큰 파일 제한 및 순차 로딩. 같은 파일의 무한 재분석과 중복 파일 잔류를 방지 |
| 높음 | `NotificationService`는 찾기 완료 알림만 만든다. 만료 예약 알림 없음 | 사용자가 선택한 만료 전 알림 제공. 날짜 수정·사용 완료·삭제·권한 취소 시 예약 갱신/취소. 시간대와 마지막 사용 가능일 검증. 구현 전 ‘만료 알림’ 홍보 금지 |
| 높음 | 자동 찾기 사진은 PHAsset 참조라 Photos에서 지우거나 접근을 잃으면 원본이 없어질 수 있음 | 보관할 쿠폰의 원본 복사 정책을 마련하고 원본 누락 상태를 표시. 등록 후 사진 삭제/제한 접근 변경/오프라인에서도 실제 사용 화면 확인 |
| 중간 | 백그라운드 작업은 전체 사진을 다시 검색하며 시스템 실행 시점은 보장되지 않음 | 자동 찾기/백그라운드 선택권, 증분 검색, 중단·재시작 일관성, 사진 수별 발열·배터리·시간 측정. 15분마다 자동 갱신한다고 약속하지 않을 것 |
| 중간 | 자체 내보내기·복원 및 삭제 제외 목록 초기화 기능 없음 | 원본+정보 묶음 백업/복원, 중복 처리, 전체 데이터 삭제 옵션. 정합성·재설치·기기 변경을 확인. 서버/회원가입 도입은 필요하지 않음 |

소스 근거: `ManualImportView.swift`, `GifticonParser.swift`, `ShareViewController.swift`, `SharedImportService.swift`, `PhotoLibraryService.swift`, `BackgroundScanCoordinator.swift`, `NotificationService.swift`, `PersistenceService.swift`.

## RPI와 엘렝코스 검증

- **Research**: 정책 원문, 현재 소스, 기존 쿠폰 과업 결과를 대조. 일반 바코드 분리 기능이 있다고 해서 모든 필드가 정확하다는 결론은 성립하지 않는다.
- **Plan**: 로고 적용과 객관적인 선언 누락을 이번 변경으로 해결. 운영 정보가 필요한 정책 공개·지원·배포 등록과 제품 기능 보완은 완료 조건을 명시한다.
- **Implement**: 동일한 래스터 원본을 아이콘/온보딩에 적용하고 개인정보 선언/앱 내 접근을 추가. 자동 테스트와 Release Archive로 확인한다.
- 반증 질문: “코드가 있으니 동작했나?” → 테스트 실행과 화면 캡처로 확인. “아이콘이 예쁘니 브랜드 선호·재방문이 높나?” → 지금은 형태·색·화면 간 일관성만 확인 가능. 사용자 측정 필요. “개발 빌드가 설치되니 심사 가능하나?” → 배포 Validate와 운영 자료가 남아 있어 제출 준비 완료로 판정하지 않음.

## 실제 사용자와 출시 순서

1. 위 필수 운영 자료와 높은 우선순위 복구 기능을 준비하고, Release를 Validate한 뒤 TestFlight 내부 테스트.
2. 서로 다른 제공처의 유효/만료/사용 완료/금액권 쿠폰, 상품·멤버십·영수증·배송 바코드와 흐린/다중 코드 이미지를 함께 검증. 총 30장 이상을 시작점으로 삼되 표본을 전체 정확도로 일반화하지 않음. 실제 쿠폰 정보는 저장소·공개 화면에 남기지 않음.
3. 사진 거부/제한/전체, iCloud 사진, 비행기 모드, 큰 파일, 공유 실패, 앱 재실행, 날짜 경계, 원본 사진 삭제, 앱 업데이트를 점검. 유효 쿠폰 유실과 사용 번호 오확정은 0건이어야 함.
4. 처음 쓰는 5명에게 설명 없이 ‘사진 추가 → 확인 → 매장에서 원본 열기 → 사용 완료’를 수행하도록 관찰. 과업 성공, 수정 필드 수, 등록/사용 화면까지의 시간, 막힌 지점을 기록. 실제 매장 판독은 별도로 확인.
5. 7~14일 재사용 관찰: 쿠폰 추가 후 실제 사용 화면을 다시 여는 비율, 만료 전 알림의 도움, 로고를 보고 모아콘을 알아보는지 측정. 현재는 SUS·선호도·재방문율을 측정하지 않았다.
6. TestFlight 외부 테스트와 운영 대응 준비 후 심사 제출. 승인 이후 출시 시점을 결정. App Store Connect 업로드/심사 제출은 이번 로컬 작업에 포함하지 않았다.

## 이번 실행 결과

- iPhone 17 Pro / iOS 26.2 Simulator: 기존 전체 26개 테스트 통과(단위 20 + UI 6), 실패/스킵 0. `/tmp/moacon-logo-test.xcresult`.
- 개인정보 메뉴 → 시트 내용 → 닫기: 새 UI 테스트 1개 통과. `/tmp/moacon-logo-privacy-test.xcresult`. 합계 27개 검증, 전체 26 + 추가 1을 별도 실행했다.
- 온보딩: 새 로고 표시, 최초 완료 후 재표시 없음, 시작 전 권한 팝업 없음. 밝은 모드/다크 모드/최대 글자에서 실제 캡처 확인.
- AppIcon: 1024×1024, alpha 없음. BrandMark는 원본 투명 PNG. 검은 이미지로 잘못 내보낸 첫 결과를 이미지 검사에서 발견하고 CoreGraphics로 수정한 뒤 재확인했다.
- Release Archive 성공: `artifacts/usability/Moacon-Device-0.4.xcarchive`. 앱과 공유 확장 포함, 앱 번들 PrivacyInfo.xcprivacy 선언 확인. Apple Development 서명이며 App Store 배포 Validate는 실행하지 않았다.
- iPhone 16 Pro / iOS 26.6.1: Archive 제품 설치 및 devicectl 실행 성공. 이 결과는 실제 매장 스캐너 판독이나 iOS 27 검증을 의미하지 않는다.
- Simulator Release 빌드·설치·실행 성공. `artifacts/usability/Moacon-Simulator-0.4.zip`.
- 증거: `artifacts/usability/logo-test-summary.json`, `logo-privacy-test-summary.json`, `logo-archive.log`, `logo-device-install.log`, `logo-device-launch.log`, `logo-simulator-deploy.log`, `logo-onboarding.png`, `logo-onboarding-large-dark.png`, `logo-privacy-policy.png`.
