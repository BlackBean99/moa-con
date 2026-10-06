# T14 광고 설정과 동의 검증

후속 작업: 2026-10-06–07, 1.0(6). 명세: ../AD_MONETIZATION.md.

- GoogleMobileAds 13.11.0 / UMP 3.1.0을 exactVersion과 Package.resolved revision으로 고정했다. 앱 타깃만 연결하고 공유 확장에는 의존성이 없다.
- Release 기본 disabled. 실제 앱/단위 ID 형식·게시자 일치·샘플 ID 제외·공개 HTTPS 정책·동의/개인정보/광고 준비 flags를 검사한다. DEBUG는 실제 광고를 요청하지 않으며 Google 샘플 배너 또는 UI fixture만 선택한다.
- 실제 모드는 매 앱 세션 UMP 갱신과 필요한 폼 이후 canRequestAds를 확인한다. 오류는 이전 동의를 재사용하지 않고 광고를 숨긴다. 개인정보 옵션 필요 여부는 오류 시에도 SDK 상태를 읽어 진입점을 유지한다.
- SDK 초기화 전 first-party ID와 publisher personalization을 끄고 광고 콘텐츠를 G로 제한한다. 배너 Request에도 npa=1을 넣는다. ATT 요청·사용자 계정·쿠폰 기반 타겟팅은 없다.
- 테스트 초기 실패는 정책/서비스 구현 부재였다(/tmp/moacon-ads-red.log). 구현 후 광고 단위 테스트 7개 모두 통과(/tmp/moacon-ads-green2.log). 거부/오류/중복 초기화/설정 변경/이전 완료 반례 포함.
- 상태 토큰 revision으로 동의 변경 전에 기존 배너를 없애고 이전 요청 완료가 새 설정을 덮지 않게 한다.

실제 게시자 계정 UMP 메시지와 지역별 동의 폼은 계정이 없어 검증하지 않았다. 이 작업의 단위 테스트는 그 운영 설정을 대체하지 않는다. SDK 시작 없이 수집이 절대 없다는 네트워크 전체 검증도 수행하지 않았으므로 그렇게 주장하지 않는다.
