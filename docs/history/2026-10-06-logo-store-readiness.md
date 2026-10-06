# 겹친 기프티콘 로고와 심사 준비 검증

## 요청 및 범위

사용자 요청: 기프티콘 아이콘을 겹친 이모티콘 형태로 로고 제작·적용, 실제 심사와 출시까지 필요한 기능 검증. 이전 네이티브 디자인/사용성 작업 위에 반영하며 로컬 빌드와 설치를 진행한다. App Store 업로드·심사 제출은 하지 않는다.

## 판단과 구현

- imagegen으로 오리지널 코랄/아이보리 겹친 티켓과 선물 상자, 장식 바코드 로고 제작. 투명 원본을 BrandMark 이미지셋으로 보관하고 온보딩에 사용.
- CoreGraphics/ImageIO로 원본을 크림색 불투명 1024px 아이콘에 합성. AppKit bitmap 컨텍스트의 첫 내보내기가 검은 이미지인 것을 실제 이미지 검사로 발견했고 CoreGraphics로 수정했다. 최종 PNG를 눈으로 재확인했다.
- 앱/확장 버전 0.4 (4), 로컬 배포 ZIP 명칭 갱신.
- UserDefaults 사용 사유 CA92.1을 Apple 원문/JSON의 정의까지 확인하고 PrivacyInfo.xcprivacy에 반영. 앱 리소스 빌드 단계에 추가. 현재 공유 확장에는 해당 API 사용이 없다.
- 더 보기 → 개인정보 처리 네이티브 시트 추가. 기기 내 처리, 사진 선택/권한, 로컬 저장·삭제, 제외 목록, 실패 파일, OS 백업 안내. 공개 정책·지원 URL과 운영자 정보는 만들거나 완료로 주장하지 않는다.
- DESIGN.md와 PrivacyPolicy.md를 현재 동작에 맞게 갱신. docs/APP_STORE_READINESS.md에 필수 제출 항목과 제품 개선 권장 항목을 구분해 기록.

## 검증 원칙

RPI(Research / Plan / Implement)와 Socratic Elenchus: 구현 존재와 실제 동작, 로컬 개발 설치와 배포 검증, 브랜드 일관성과 사용자 선호/재방문을 구분한다. 만료 알림·수동 번호 등록·공유 실패 복구·모든 바코드 후보 선택이 없는 것을 소스에서 확인했다. 사용자 정확도/매장 판독/SUS/재방문 수치를 만들어내지 않는다.

## QA

- `swift scripts/generate-app-icon.swift`: 최종 CoreGraphics 내보내기 성공. `sips`: 1024×1024, hasAlpha no. 최종 아이콘 시각 검사 완료.
- `plutil -lint` 개인정보 선언/프로젝트: 통과.
- `xcodebuild … test -resultBundlePath /tmp/moacon-logo-test.xcresult`: 26개 통과, 실패/스킵 0.
- `xcodebuild … -only-testing:GifticonCollectorUITests/WalletFlowTests/testPrivacyPolicyIsAccessibleFromWallet test`: 추가 1개 통과. 합계 27개, 단위 20 + UI 7.
- 밝은/다크 최대 글자 온보딩 및 개인정보 시트의 테스트 캡처를 내보내 눈으로 확인.
- `xcodebuild … -configuration Release -destination generic/platform=iOS … archive`: 성공. Archive 앱에 PrivacyInfo.xcprivacy 포함 확인. Apple Development 서명.
- Archive 제품 iPhone 16 Pro 설치 및 실행 성공. 로컬 Archive는 artifacts/usability/Moacon-Device-0.4.xcarchive에 복사.
- `MOACON_BUILD_PATH=/tmp/moacon-logo-release-sim ./scripts/deploy-local.sh --simulator`: Release 빌드·설치·실행 성공, artifacts/usability/Moacon-Simulator-0.4.zip 생성.
- `git diff --check`: 통과.


## Git

작업 브랜치: fix/usability-review-local-release. 시작 시 Xcode가 수정한 project.pbxproj와 scheme 변경은 보존하고 이번 프로젝트 변경만 부분 스테이징한다. 커밋: `feat: apply coupon emoji logo and audit App Store readiness` (본 이력 포함). PR/원격 푸시 없음.

## 남은 한계

공개 정책/운영자·문의 정보, Connect 메타데이터·연령 등급·App Privacy, 배포 Validate/TestFlight 미검증. 개발 서명 Archive 설치는 App Store 배포 검증이 아니다. 이전 iPad Simulator 시작 실패는 앱 테스트 실패로 보지 않지만 iPad 지원 검증도 완료되지 않았다. 실제 쿠폰 인식과 매장 판독, iOS 17/27 런타임, 백그라운드 에너지, 사용자 재사용은 별도 필요.
