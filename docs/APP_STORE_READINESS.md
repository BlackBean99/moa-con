# 모아콘 심사·출시 검증

검토일: 2026-10-06. 대상: 1.0 (5), iOS 17+, iPhone/iPad, SwiftUI/SwiftData 앱과 사진 공유 확장.

**판정: 기능 구현과 로컬 Release 후보 자동 검증 완료. 제출 직전 준비는 아직 차단된다.** 배포 프로파일 권한, 실제 운영 자료, 지원 기기 과업과 제출용 화면 검증을 남긴다. 실제 심사 제출/업로드는 하지 않았다.

## 구현과 증거

| 과업 | 동작 | 증거 |
|---|---|---|
| 직접 등록·번호 선택 | 인식 실패에도 원본 입력 폼. 여러 번호는 자동 확정하지 않고 후보 선택/직접 입력. 중복 저장 차단 | [T03](qa/T03-registration.md), [T04](qa/T04-editor.md) |
| 금액 구분 | 교환권 상품 가격·할인액과 금액권 원금·잔액 분리. 이미 차감한 잔액을 수정으로 복원할 수 없음 | [T02](qa/T02-models.md), [T04](qa/T04-editor.md) |
| 공유·재시도 | 공유 확장 저장/실패 수와 실패 재시도. 앱의 실패 큐는 재시도/직접 입력/확인 후 삭제 | [T05](qa/T05-sharing.md), [T06](qa/T06-queue.md) |
| 원본 보존 | 사진 라이브러리 참조와 별도로 새 원본 파일을 저장한 후 등록. 접근 가능한 기존 참조도 복사 | [T07](qa/T07-originals.md) |
| 만료 알림 | 명시적 설정/권한. 확인한 미사용·미만료 쿠폰에 최대 50개. 날짜/사용/삭제/권한 변화에 갱신 | [T08](qa/T08-reminders.md) |
| 브랜드·초기 진입 | 겹친 선물 티켓 로고, 간결한 온보딩, 시스템 네비게이션·큰 글자·다크 모드 | [디자인 시스템](../DESIGN.md) |

원본 보존은 과거에 이미 삭제되고 복사되지 않은 사진의 복원을 뜻하지 않는다. iCloud-only 사진은 자동 원본 복사에서 제외될 수 있으며 사진 선택으로 가져올 수 있다. 알림 전달은 OS 상태에 따른다. 일반 바코드의 쿠폰 분류 정확도와 사용자의 재방문은 합성 테스트만으로 입증하지 않았다.

## 로컬 결과

- 최종 전체 자동 테스트 **42/42 통과**(단위 31 + UI 11), 실패/스킵 0. `/tmp/moacon-release-isolated.xcresult`, `artifacts/release/test-summary.json`.
- 최초 전체 실행의 알림 UI 실패는 권한용 무조건 화면 중앙 탭이 Settings를 연 문제였다. SpringBoard 권한 버튼만 처리하도록 수정한 뒤 예약 1 → 취소 0을 포함해 전체 재검증했다.
- 최종 Release Archive 성공: `artifacts/release/Moacon-Device-1.0.xcarchive`. Apple Development 서명과 공유 확장. App Store Validate 완료와 구분한다.
- Simulator Release 빌드·설치·실행 성공과 실제 보관함 화면 확인. ZIP: `artifacts/release/Moacon-Simulator-1.0.zip`.
- 실제 iPhone 16 Pro 설치 성공. T12 이전 1.0 빌드는 잠금 해제 후 devicectl 실행 성공. T12 포함 빌드 설치 후 자동 잠금으로 실행이 거부됐다. 사용자 잠금 해제 이후에는 기기가 unavailable로 연결되지 않아 실행 미확인. 지원 이메일 반영 최신 Archive는 준비됐지만 실기기 설치는 연결 복구 후 진행한다. 화면별 과업과 매장 판독을 모두 검증했다는 의미는 아니다.
- App Store export 실제 시도 실패: 현재 서명 Team은 iOS App Store 프로파일 생성 권한이 없고 앱/확장 배포 프로파일도 없다. `artifacts/release/export.log`.
- [상세 검증·반증 기록](qa/T09-release.md). 원본 작업 폴더의 기존 Xcode 미커밋 변경은 보존했다.

## 제출 차단 항목

| 항목 | 현재 상태 | 완료 조건 |
|---|---|---|
| 배포 계정 | App Store profile 생성 권한 부족, 개발 서명만 가능 | 유효한 유료 팀/권한, 앱과 확장 배포 프로파일, 소유한 Bundle ID/App Group와 Connect 앱 등록, Organizer Validate 결과 |
| 정책·지원 | 저장소 정책·앱 내 안내·조건부 문의 링크 준비. 지원 이메일 ymecca123@gmail.com 반영. 운영자명/공개 URL 미설정 | 운영자가 확인한 공개 HTTPS 정책·지원 페이지. 앱과 Connect 정보 일치, 실제 문의 응답 수단 |
| 심사 연락처 | 비어 있음 | 이름/이메일/전화. 개인 정보는 Git 제외 metadata.local.json에 보관 |
| 스토어 설정 | 한국/무료 초안, 소개/심사 노트 작성. Connect 입력 여부 미확인 | 국가·가격·연령 질문·App Privacy·수출 답변의 실제 등록과 권리 검토 |
| 기기·호스트 QA | iPhone 자동 회귀 완료. 새 iPad Simulator 앱 프로세스 시작 지연/실패 | 정상 iPad에서 회전·분할·큰 글자·원본 확대·공유, 최소 지원 OS 검증. 사진 삭제/권한 변경/저장 공간 부족/iCloud 입력의 실제 기기 과업 |
| 공유 확장 | 확장 컴파일·파일 실패 큐·앱 복구 UI 검증. Photos 호스트 진입은 미완료 | Photos 공유 → 저장 결과 → 앱 가져오기, 실패 재시도를 실제 호스트에서 기록 |
| 스크린샷 | 자동 QA 캡처와 무효 입력 이미지 3종 있음 | 실제 iPhone 6.9/6.5 및 지원 iPad 13인치 앱 화면. 입력 fixtures를 앱 스크린샷으로 사용하지 않음 |

Apple은 완성된 앱, 정확한 메타데이터, 앱과 Connect에서 접근 가능한 개인정보처리방침을 요구한다. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

UserDefaults 사유 CA92.1과 추적/수집 없음 Privacy manifest를 포함한다. 기기에서만 처리하는 데이터는 Apple App Privacy의 수집 정의에 해당하지 않는다는 현재 소스 판단이며, Connect 질문 응답 완료는 아니다. [Required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

제출 화면 규격과 배포 Validate는 Apple 문서에 따라 별도로 확인한다. [스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [배포·Validate 절차](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

## 관리와 다음 실행

상태 원본은 [tasks/todo.md](../tasks/todo.md), 재현 명령과 제출 gate는 [RELEASE_RUNBOOK](release/RELEASE_RUNBOOK.md)에 있다. `python3 scripts/release-check.py --strict`는 하나라도 미완료면 실패하며 업로드하지 않는다. 개발용 Archive가 있어도 제출 준비로 자동 승인하지 않는다.
