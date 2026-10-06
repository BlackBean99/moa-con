# 2026-10-06 · 초기 온보딩과 네이티브 디자인 시스템

## 요청과 범위

최초 온보딩을 추가하고 AI처럼 길거나 모호한 설명을 제거. awesome-design-md와 Apple iOS 27 디자인 가이드에 근거해 시스템을 구축하고 전체 앱 화면을 리팩터링. 앞선 사용성 개선의 분류/수정/잔액/원본/로컬 배포를 보존.

## 분석과 결정

Apple의 공식 WWDC26/HIG와 링크의 독립적인 Apple 웹 분석을 구분했다. 긴 튜토리얼 대신 한 화면·한 번의 시작. 사진 권한은 자동 찾기, 알림 권한은 명시적인 알림 설정에서 요청. 쿠폰 원본과 목록에는 Glass를 깔지 않고 시스템 탐색·툴바·강조 버튼에 적용. 의미 색상으로 다크 모드 지원. 정체성은 모아콘 이름·코럴 계열·겹친 티켓 M.

## 구현

- `DESIGN.md`: 출처·토큰·타입·여백·버튼·문구·접근성·화면 계약.
- `MoaconDesignSystem.swift`, `OnboardingView.swift`: 기본 테마와 최초 진입, 완료 상태 보존.
- Root, wallet, detail, editor, manual import, scan, 저장소 오류 화면을 네이티브 패턴으로 정리. 원본을 상세의 첫 내용으로 이동. 중복 수동 가져오기 상태를 정확하게 표시.
- 자동 알림 권한 요청 제거. 사용자가 설정을 선택할 때만 요청.
- App/extension 버전 0.3/build 3. iPad 모든 회전 방향 명시, 공유 확장의 미사용 결과 경고 정리.
- 기존 Xcode 프로젝트/스킴의 사용자 업그레이드 변경을 보존. 커밋에는 작업에 필요한 파일 참조와 버전 변경만 부분 스테이징.

## 검증과 반증

전체 26개 테스트(20 unit, 6 UI) 통과. 온보딩 종료/재실행 후 재노출 없음, 시작 전후 권한 팝업 없음, 최대 글자에서 시작 버튼 누를 수 있음, 검색/수정/확인 승인/사용/삭제 취소/원본 확대 검증.

처음 다크 모드 캡처가 실제로 밝은 화면인 것을 발견해 `-AppleInterfaceStyle` 인자에 의존하던 테스트를 수정했다. DEBUG와 UI 테스트에 한정한 명시적 다크 appearance로 실제 화면을 다시 확인. 큰 글자는 운영체제 preferred content size 설정을 사용한다. 수정 시트가 닫히기 전 찍힌 캡처도 비존재 대기로 보강했다. 밝은 코럴 버튼의 흰 글자 대비가 낮아 버튼 채움을 별도 토큰으로 분리, 6.17:1을 확인하고 관련 UI 2개를 재검증했다.

- 전체: `/tmp/moacon-design-final.xcresult`, `artifacts/design/test-final.log`.
- 대비 수정: `/tmp/moacon-design-contrast.xcresult`, `artifacts/design/contrast-test.log`.
- 시뮬레이터 Release: `MOACON_BUILD_PATH=/tmp/moacon-design-release-sim ./scripts/deploy-local.sh --simulator`, 설치/실행 성공. CUA로 온보딩→빈 보관함 직접 확인.
- 실기기 Release: `MOACON_BUILD_PATH=/tmp/moacon-design-device-signed ./scripts/deploy-local.sh --device`, 설치/실행 성공. iPhone 16 Pro / iOS 26.6.1, 실행 후 프로세스 확인.
- 빌드·plist lint·diff whitespace 검사 통과. AppIntents 미사용 메타데이터 경고 외 앱/확장 소스 경고 없음.
- iPad 추가 자동화: iOS 26.2에서 초기 실행/재시작, 26.1에서 재시도했지만 UI 테스트 시작 전 앱 실행 브리지 호출이 멈춤. 호스트 프로세스 샘플로 `SimDevice launchApplication`→`host_support_mig_launch_app` 대기를 확인. 해당 시도는 종료했으며 통과로 세지 않음. 별도 iPad 실행 검증은 미완료.

## 자체 코드 검토

정확성은 기존 데이터/상태/금액 회귀 테스트와 UI 과업으로 검토. 스타일 어휘를 하나로 줄이고 native control에 렌더링을 맡겼다. 새 외부 의존성·네트워크 분석·추적·자격증명을 추가하지 않았다. 입력·중복·금액 검증을 보존. 수동 그림자 반복을 제거했지만 성능 수치 개선은 측정하지 않아 주장하지 않는다.

## 커밋과 경계

작업 브랜치 `fix/usability-review-local-release`. 커밋은 완료 후 기록. 기존 Xcode 업그레이드 변경은 사용자의 미커밋 변경으로 남긴다.

Xcode 26.3 / SDK 26.2이며 27 SDK/런타임 검증을 완료했다고 주장하지 않는다. 실제 iPhone에서는 설치·프로세스 실행을 확인했으며 실쿠폰 스캐너 판독·VoiceOver 전체 탐색·장기 반복사용/브랜드 선호도는 미검증. 신규 모델 스키마 변경이나 데이터 삭제 없이 업데이트했다. 앱 삭제 대신 이전 코드를 다시 빌드/설치하는 방식으로 롤백하며 저장소와 원본은 먼저 보존한다.
