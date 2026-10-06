# T09 출시 후보 검증

대상: 1.0 (5), feature/release-readiness, Xcode 26.3 / iOS SDK 26.2.

## 확인한 결과

- 최초 전체 회귀: 단위 30 통과, UI 10 통과/1 실패. `/tmp/moacon-release-final.xcresult`.
- 실패 화면은 시스템 Settings였다. 알림 권한 처리용 `app.tap()`이 권한이 이미 허용된 상태에서 화면 중앙의 ‘시스템 알림 설정’을 눌렀다. 해당 무조건 탭을 제거하고 SpringBoard 권한 알림의 허용 버튼만 처리하도록 변경했다. 취소 검증을 삭제하거나 기대값을 낮추지 않았다.
- 수정 후 전체 회귀: 단위 30 + UI 11, 41개 모두 통과, 실패/스킵 0. 결과 `/tmp/moacon-release-corrected.xcresult`, 로그 `artifacts/release/corrected-tests.log`.
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
