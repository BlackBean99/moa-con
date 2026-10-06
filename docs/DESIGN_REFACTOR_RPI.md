# 온보딩과 네이티브 디자인 리팩터링 — RPI

## Research

2026-10-06. 요청: 최초 온보딩, 불필요한 설명 제거, awesome-design-md 참고 및 Apple iOS 27 가이드 기반 전체 화면 리팩터링.

기존 구현은 강한 그림자와 색을 가진 Clay 카드·아이콘·캡슐 버튼을 반복하고, 보관함 상단의 슬로건과 설명이 목록보다 먼저 나타났다. 상세에서는 사용 버튼이 원본보다 먼저 나왔다. 실행 직후 AppDelegate가 알림 권한을 요청했고 온보딩 완료 상태는 없었다. 이 판단은 소스와 네이티브 화면에 근거한 전문가 평가이며 사용자를 모집한 만족도 조사는 아니다.

자료의 위계: Apple 공식 HIG/WWDC26이 네이티브 디자인 기준이다. awesome-design-md의 Apple 자료는 독립적인 웹 분석으로 여백·타이포그래피 및 문서화 방식만 참고했다. 공식 iOS 가이드와 동등하게 취급하지 않는다. 상세 원칙과 출처는 [DESIGN.md](../DESIGN.md).

## Plan

1. 한 화면·한 번의 시작 동작. 완료 상태 유지. 온보딩에서는 권한 미요청.
2. 의미 색상·SF 글꼴·기본 탐색/목록/폼/툴바로 통일. Glass는 조작 레이어에만 사용.
3. 목록에서 쿠폰 찾기, 상세에서 원본 제시 우선. 상태·실패·복구에 필요한 문구만 유지.
4. 사진 추가·자동 찾기·수정·승인·사용·잔액·삭제·공유 원본의 기존 기능 보존.
5. 실행 테스트와 캡처로 검증. 실제 적용된 다크 모드와 큰 글자를 관찰.

## Implementation

- ClayDesignSystem 제거, MoaconDesignSystem으로 의미 표면/강조/간격/주요 버튼/마크 정의.
- OnboardingView 추가. UserDefaults 완료 상태로 재실행 시 생략. UI 테스트 상태는 별도 키로 격리, Release에는 테스트 우회 없음.
- 목록의 반복 설명·장식 카드 제거. 검색, 상태 필터, + 버튼, 자동 찾기·알림 설정 메뉴 사용.
- 상세는 원본→상태→정보→금액→삭제. 수정과 사진 추가에서 설명을 줄이고 기본 네이티브 계층 유지.
- 실행 시 알림 권한 요청 제거. 명시적인 알림 설정 동작으로 요청, 이미 결정된 경우 시스템 설정을 열어 복구.
- 수동 중복 가져오기는 파일 생성 전에 검사하고 실제 중복 상태를 표시.
- Dynamic Type가 커지면 상태 필터는 메뉴, 내용은 여러 줄. 온보딩은 공간 부족 시 스크롤. 다크 모드는 의미 색상으로 적용.
- 기존 작업 트리의 Xcode 26.3 업그레이드 변경을 보존하고 필요한 프로젝트 파일 참조만 추가/변경. xcodegen으로 사용자 변경을 덮어쓰지 않음.

## 엘렝코스 검증

| 주장 | 반증 질문 | 관측 방법 |
|---|---|---|
| 최초 한 번만 표시 | 프로세스를 종료해도 완료 상태가 남는가? | 시작→종료→재실행 UI 테스트 |
| 온보딩에 권한 장벽 없음 | AppDelegate에서 다른 권한을 자동 요청하지 않는가? | 자동 알림 요청 제거, 시작 전/후 SpringBoard 알림 없음 검사 |
| 다크 모드 검증 | 테스트 이름만 dark이며 화면은 밝은가? | 첫 캡처에서 반증됨. DEBUG 전용 명시적 appearance 설정 후 실제 검은 표면 재검증 |
| 큰 글자에서도 행동 가능 | 존재하는 버튼이 화면 밖에서 누를 수 없는가? | 최대 접근성 크기의 시작 버튼 isHittable, 사진 추가/원본 접근 테스트 |
| native refactor가 기능 보존 | 확인 전 사용되거나 수정 후 탐색이 끊기는가? | 승인 전 사용 비활성, 승인·사용·검색·수정·삭제취소·확대 테스트 |
| iOS 27에서 실행했음 | 설치된 SDK/런타임이 정말 27인가? | Xcode 26.3 / SDK 26.2 확인. 27 실행 검증이라고 주장하지 않음 |
| 선호/반복사용 개선 | 실제 재방문 데이터가 있는가? | 없음. 기대 효용과 사용자 연구 경계를 명시 |

## 검증 결과

- iPhone 17 Pro / iOS 26.2: unit 20개 + UI 6개 = 26개 통과, 실패/건너뜀 없음. `/tmp/moacon-design-final.xcresult`, `artifacts/design/test-final.log`.
- 강조 버튼 대비 수정 후 최대 글자 온보딩·다크 모드 핵심 과업 2개 재검증 통과. `/tmp/moacon-design-contrast.xcresult`. 실제 캡처의 어두운 표면과 어두운 코럴 버튼을 확인했다. 흰 글자와 기본 채움의 대비는 6.17:1.
- Release 시뮬레이터: 0.3/build 3 빌드·설치·실행 성공. 데모 없는 보관함에 온보딩을 거쳐 진입하는 동작을 CUA로 직접 확인. `artifacts/design/simulator-deploy-final.log`.
- 실제 iPhone 16 Pro / iOS 26.6.1: 최신 Release 서명 빌드·설치·실행 성공. 잠금으로 거부된 초기 실행 후 잠금 해제 상태에서 재시도 성공, 실행 후 프로세스 PID 21393 확인. `artifacts/design/device-deploy-latest.log`, `artifacts/design/device-processes.json`.
- 앱과 확장에 컴파일 경고 없음. 미사용 AppIntents 메타데이터 추출 생략 경고만 남음. `git diff --check`, plist lint 통과.
- iPad 추가 자동화는 미완료. iOS 26.2 첫 실행/재시작과 26.1에서도 UI 테스트 시작 전 호스트의 CoreSimulator 앱 실행 브리지 호출이 멈췄다. 실행 중인 xcodebuild 샘플에서 `host_support_mig_launch_app` 대기를 확인했다. 해당 테스트 실행만 종료하고 시뮬레이터를 종료했다. 단언문이 실행되지 않은 결과를 통과로 집계하지 않는다. `artifacts/design/ipad-host-sample.txt`.

캡처는 `artifacts/design/final-screenshots/`와 `artifacts/design/contrast-screenshots/`에 보관한다. Release 패키지는 `artifacts/usability/Moacon-Simulator-0.3.zip`이며 iPhone용 IPA가 아니다. 실제 iPhone에는 `/tmp/moacon-design-device-signed/Build/Products/Release-iphoneos/GifticonCollector.app`을 설치했다.

## 경계

iOS 27 SDK/런타임이 설치되어 있지 않다. 시스템 UI와 호환 가능한 Glass 사용으로 가이드를 반영했지만 27에서의 실제 외형·리사이즈·신규 API 검증은 남아 있다. 실제 결제 스캐너, VoiceOver 전체 탐색, 장기 반복사용 및 브랜드 선호도는 실사용 연구가 필요하다. 로컬 실기기 설치는 Apple 계정 인증과 프로파일에 종속된다.
