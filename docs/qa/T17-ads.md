# T17 광고 후보 네이티브 검증과 로컬 배포

대상 1.0(6), Xcode 26.3/iOS SDK 26.2, iPhone 17 Pro Simulator iOS 26.2. 기본 Release 광고 비활성, 공개 지원 이메일 유지. 계정·앱 데이터 모델·쿠폰 권한 조건은 추가하지 않았다.

## 자동 검증

- `xcodebuild test ... -skip-testing:GifticonCollectorUITests/AdSDKIntegrationTests`: 단위 38 + UI 15 = **53/53 통과**, 실패/스킵 0. /tmp/moacon-ads-regression.xcresult, artifacts/release/ads-regression-summary.json.
- 실제 Google 공식 테스트 배너는 별도 SDK 통합 실행에서 성공. 배너를 클릭하지 않았다. UI fixture로 대체하지 않았다.
- 레이아웃/검토 화면 숨김 수정 뒤 UI 4 + SDK 1 = **5/5 통과**, 실패/스킵 0. /tmp/moacon-ads-final-ui.xcresult, artifacts/release/ads-final-ui-summary.json.
- 최대 글자/다크 모드에서 등록 후 보관함으로 돌아와 스크롤→쿠폰 열기→원본 버튼 접근까지 추가 검증: **1/1 통과**. /tmp/moacon-ads-large-final.xcresult. 단순 광고 표기 존재 검사만으로 접근성 완료를 판단하지 않았다.
- Python 광고 활성 설정 반례 4개 통과. tasks check/스크립트 compile/bash 문법/git diff 공백 검사 통과.

재현: `xcodebuild -project GifticonCollector.xcodeproj -scheme GifticonCollector -destination 'platform=iOS Simulator,id=D843BD0C-6CB9-4444-817C-E45B00736225' -derivedDataPath /tmp/moacon-preflight-tests -skip-testing:GifticonCollectorUITests/AdSDKIntegrationTests test`. SDK 요청은 `-only-testing:GifticonCollectorUITests/AdSDKIntegrationTests`로 별도 실행한다. 지역 UMP 테스트와 실제 계정 검증은 T18에 남긴다.

## 빌드와 배포

Release Archive 성공: artifacts/release/Moacon-Device-1.0-6.xcarchive. Apple Development 서명이며 앱/공유 확장 버전 모두 1.0(6). 앱에 Google Ads/UMP 프레임워크와 각 SDK privacy manifest가 포함되고 공유 확장에는 없다. GAD 앱 ID는 샘플이며 MoaconAdsEnabled=false다. App Store용 Validate/배포 프로파일 승인을 뜻하지 않는다.

Simulator Release 빌드·설치·실행 성공(초기 PID 52035, 최종 정리 후 재설치·실행 로그 ads-simulator-deploy.log). scripts/deploy-local.sh --simulator 명령, artifacts/usability/Moacon-Simulator-1.0-6.zip. SDK UI 테스트의 쿠폰은 합성 fixtures이며 실제 매장 사용은 검증하지 않았다.

실기기 iPhone 16 Pro는 처음 unavailable, 잠시 available(paired), 설치 시 CoreDeviceError 4000/연결 채널 reset(Network error 54), 이후 다시 unavailable였다. `artifacts/release/ads-device-install.log`. **새 1.0(6) 기기 설치·실행은 미완료다.** 이전 1.0(5) 설치·실행 성공 기록을 새 버전 성공으로 재사용하지 않았다. USB 재연결·잠금 해제를 비동기로 요청했다.

## 소크라테스 반증 결과

- ‘로그인 없으면 광고 불가’ → 앱의 사용자 계정 없이 SDK 테스트 배너가 렌더링됐다. 운영자 지급/게시자 계정은 별개다.
- ‘UI 배너 그림만 있으면 통합 완료’ → Google SDK receipt와 Test mode 캡처 확인. 실제 publisher/UMP/AdMob 심사는 미확인이다.
- ‘테스트 통과면 큰 글자도 좋다’ → 초기 캡처에서 잘림 발견, 레이아웃 수정 후 재검증했다.
- ‘비개인화면 개인정보 수집 없음’ → SDK 명세 DeviceID tracking=true 등 확인, 정책/실제 운영 검토 gate를 추가했다.
- ‘Archive 성공이면 기기 배포 완료’ → 실제 설치 연결 오류 확인, T17 blocked로 남긴다.

최소 OS/iPad/Photos 호스트/권한 변경/저장 공간 QA와 Store 자료/프로파일은 기존 T09–T11에서 계속 차단한다. 자동 테스트·Archive와 실제 운영 준비를 구분한다.
