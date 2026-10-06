# T09 출시 후보 검증

대상: 1.0 (5), feature/release-readiness, Xcode 26.3 / iOS SDK 26.2.

## 확인한 결과

- 최초 전체 회귀: 단위 30 통과, UI 10 통과/1 실패. `/tmp/moacon-release-final.xcresult`.
- 실패 화면은 시스템 Settings였다. 알림 권한 처리용 `app.tap()`이 권한이 이미 허용된 상태에서 화면 중앙의 ‘시스템 알림 설정’을 눌렀다. 해당 무조건 탭을 제거하고 SpringBoard 권한 알림의 허용 버튼만 처리하도록 변경했다. 취소 검증을 삭제하거나 기대값을 낮추지 않았다.
- 수정 후 전체 회귀: T12와 UI 원본 격리 보완을 포함한 단위 31 + UI 11, 42개 모두 통과, 실패/스킵 0. 결과 `/tmp/moacon-release-isolated.xcresult`, 로그 `artifacts/release/isolated-tests.log`.
- Release Archive 성공: `artifacts/release/Moacon-Device-1.0.xcarchive`. Apple Development 서명, 공유 확장 포함. App Store 서명/Validate 성공을 뜻하지 않는다.
- 실제 iPhone 16 Pro에 1.0 설치 성공. 잠금 상태 첫 실행은 OS가 거부했으며 사용자 잠금 해제 후 devicectl 실행 성공. `artifacts/release/device-launch-unlocked.log`.
- App Store IPA export 실패: 현재 Team에 iOS App Store provisioning profile 생성 권한이 없으며 앱/확장 배포 프로파일도 없다. `artifacts/release/export.log`. 업로드하지 않았다.

## 미완료 gate

- 새 iPad Air 13 / iOS 26.2에서도 앱 프로세스를 만들지 못했다. launch 실패 ‘did not return a process handle nor launch error’; GUI는 검은 시스템 로딩 화면이었다. 정상 앱 화면으로 오인하거나 스크린샷으로 제출하지 않는다. 기본 Settings 실행도 완료되지 않아 중단했다. 추가 시뮬레이터 종료 후 iPhone 테스트의 재실행 지연은 해소됐다. 원인은 확정하지 않았다. 정상 iPad 환경에서 회전/분할/큰 글자/원본 확대/공유를 검증해야 한다.
- iPhone 6.9인치와 지원 iPad 13인치 규격의 실제 앱 스크린샷이 필요하다. 기존 17 Pro 캡처는 QA용이며 제출 대표 규격으로 대체하지 않는다.
- Photos → 공유 확장 실제 진입/실패/재시도, 사진 삭제·권한 변경, 저장 공간 부족, iCloud-only 입력을 기기에서 확인해야 한다. 공유 확장 컴파일과 파일 큐 단위 검증은 이 실제 호스트 실행을 대체하지 않는다.
- 실제 쿠폰 정확도/매장 판독과 최소 지원 OS 17 검증은 합성 이미지 자동 테스트로 증명하지 않았다.

## RPI / 엘렝코스 검증

Research: 번호 자동 선택과 금액 혼합, 실패 후 원본 유실, 일회성 완료 알림을 과업으로 분해했다.
Plan: tasks/todo.md의 수용 조건과 선행 과업으로 연결했다.
Implement: T02–T08 구현과 각 증거 기록, 전체 회귀 및 네이티브 설치를 수행했다.

‘여러 번호면 첫 번호가 쿠폰 번호인가?’ 반례로 자동 선택을 제거했다. ‘가격은 사용할 잔액인가?’ 교환권의 가격·할인액과 금액권 원금·잔액을 분리했다. ‘수정 후 차감액이 복원되는가?’ 원금 변경과 종류 전환을 제한한 테스트로 반증했다. ‘권한이 바뀌어도 원본이 있는가?’ 새 원본은 앱 저장소에 복사한 후 등록하고 접근 가능한 기존 참조도 복사한다. 과거에 이미 삭제되고 복사되지 않은 사진은 복원할 수 없다. ‘알림이 실제 예약됐는가?’ OS pending 목록 1→0을 UI에서 확인했다. ‘심사 직전인가?’ 배포 export와 iPad/운영 gate가 미완료이므로 그렇다고 선언할 수 없다.

- T12 추가 회귀에서 이전 UI 테스트의 Saved 파일과 매번 빈 DB의 수명이 달라 복구 큐 누적/큰 글자 검증이 실패했다. 테스트 원본을 실행별 격리한 후 42개 전체 통과. 제품 복구 로직은 유지했다.
- 최종 T12 포함 실기기 빌드 설치 완료. 실행은 다시 자동 잠금으로 거부돼 사용자에게 해제를 요청했으며 최종 실행 확인은 미완료.
- GitHub Task integrity 검사 성공, Draft PR https://github.com/BlackBean99/moa-con/pull/2 . CI 성공은 앱/스토어 승인 판정이 아니다.

- 최종 Simulator Release 설치·실행 성공(com.yourteam.gifticoncollector 프로세스 23067). actual-release-wallet.png에서 실제 Release 보관함 표시 확인. 기존 테스트 잔여 파일 14개가 복구 목록에 노출됐으며 실제 쿠폰은 없는 QA 상태다. 이 iPhone 17 Pro 화면은 제출 대표 규격 스크린샷으로 사용하지 않는다.
- Photos에 합성 입력을 넣고 Library 표시까지 확인했지만 CUA 클릭은 windowNotFound/noWindowsAvailable 오류로 완료하지 못했다. 확장의 실제 공유 진입/재시도 통과로 기록하지 않는다.
