# 광고 수익화 명세 — 2026-10-06

로그인·구독 없이 모든 쿠폰 기능을 무료로 제공한다. 앱 사용자 계정은 광고 수익의 전제 조건이 아니다. 운영자는 Google AdMob 게시자 계정/지급 정보가 필요하며 웹용 AdSense 코드를 네이티브 화면에 넣지 않는다.

## 관찰 가능한 계약

- 광고는 확인된 사용 가능 쿠폰이 있는 보관함에만 작은 배너로 표시한다. 온보딩·검색·스캔·등록·수정·상세·원본·사용 확인 중에는 표시하지 않는다. 전면/보상/앱 시작 광고는 추가하지 않는다.
- 광고 SDK는 본 앱에만 연결한다. 공유 확장은 광고 없이 저장한다. 쿠폰 번호·브랜드·상품·가격·사진·알림 설정을 광고 서비스에 전달하지 않는다.
- 실제 광고는 운영자가 설정한 ID, 공개 정책 URL, UMP 동의 메시지, 개인정보 검토가 준비된 경우만 활성화한다. 기본 Release는 광고 비활성이다. 테스트 빌드는 Google 테스트 ID만 사용한다.
- 실제 광고 요청 전에 매 실행 UMP 정보를 갱신하고 필요한 동의 폼을 처리한다. canRequestAds가 false이거나 오류가 있으면 광고 없이 정상 작동한다. 사용자 선택은 Google UMP가 관리한다. 필요한 경우 더 보기의 광고 개인정보 설정에서 변경한다.
- 개인화 광고 요청을 끄고 게시자 first-party ID를 끈다. ATT/IDFA 권한을 요청하지 않는다. 비개인화 요청도 SDK 데이터 처리가 있으므로 개인정보 수집 없음이라고 단정하지 않는다.
- 광고 실패 시 빈 배너 영역을 제거한다. 쿠폰 작업을 막는 오류 팝업·자동 요청 루프가 없다. 다음 보관함 진입에 한 번 재시도할 수 있다.
- 설정 변경 중 기존 배너를 제거하고 오래된 동의 완료가 다시 광고를 켜지 못하게 한다. SDK 초기화는 세션에서 한 번만 한다.

## 출시와 수익 개시를 구분

앱 제출 전에는 실제 공개 개인정보·지원 URL, 앱 개인정보 공개, 연령 등급/광고 콘텐츠 설정, 네이티브 QA와 배포 Validate가 필요하다. 광고 SDK 포함 빌드의 개인정보 보고서를 별도로 확인한다. 광고를 끈 버전도 해당 검토를 생략하지 않는다.

실광고 수익 개시는 실제 AdMob 앱/배너 ID, 지급 계정, UMP 설정, 개발자 웹사이트, 루트 app-ads.txt, Store 등록 연결, AdMob 앱 준비 상태 심사가 필요하다. 새 앱의 Store 연결/광고 준비 승인에는 스토어 공개가 필요할 수 있으므로 첫 제출과 동일한 gate로 강제하지 않는다. 앱 출시 뒤 실광고 활성 빌드를 별도로 검증할 수 있다.

## 검증과 한계

정책/설정/동의 실패/거부/설정 재진입/중복 초기화/오래된 완료 반례를 단위 테스트한다. 배너 위치와 숨김, 실패해도 등록 가능함을 UI 테스트한다. Google 테스트 배너를 실제 SDK로 요청해 렌더링을 확인하며 클릭하지 않는다. 테스트 배너 성공은 실광고 승인·수익·실제 계정 동의 폼 성공을 입증하지 않는다.

## 공식 근거

- https://support.google.com/admob/answer/7356173?hl=en
- https://developers.google.com/admob/ios/quick-start
- https://developers.google.com/admob/ios/banner
- https://developers.google.com/admob/ios/privacy
- https://developers.google.com/admob/ios/privacy/idfa
- https://developers.google.com/admob/ios/privacy/data-disclosure
- https://support.google.com/admob/answer/14538460?hl=en
- https://support.google.com/admob/answer/9989980?hl=en
- https://developer.apple.com/app-store/user-privacy-and-data-use/
