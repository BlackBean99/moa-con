# 쿠폰 복구와 심사 제출 직전 준비

## 요청과 범위

인식 실패 직접 등록, 다중 번호 선택, 가격/할인/잔액 구분, 공유 저장 결과·재시도, 만료 알림과 원본 보존을 구현한다. 과업 관리 시스템과 별도 Git worktree를 활성화하고 로컬 네이티브 빌드·설치 및 제출 전 자료를 준비한다. 실제 업로드/심사 제출은 제외한다.

## 결정과 구현

원래 moa-con 폴더의 기존 Xcode 프로젝트/스킴 미커밋 변경을 보존하고 ../moa-con-release, feature/release-readiness에서 작업했다. 기준 0c73eea. 상태 원본 tasks/todo.md, 의존/증거 검증 scripts/tasks.py, events.md, 이슈/PR 템플릿과 Task integrity CI를 추가했다.

쿠폰 종류와 상품 가격/할인액/원금/잔액, 모든 바코드 후보와 사진 출처를 추가 필드로 보존한다. 다중 번호는 자동 선택하지 않는다. 공통 등록/수정 폼은 실패에도 원본과 직접 입력을 유지하며 중복/금액을 검증한다. 사용한 잔액은 편집으로 복원하지 않는다. 공유 확장은 결과와 재시도, 앱은 실패 원본 큐와 복구 화면을 제공한다. 자동 찾기·기존 Photos 원본을 앱 사본으로 보존하고 선택한 만료 알림을 직렬 갱신한다.

파일 보관과 DB 저장 사이 중단된 원본을 다음 실행에서 복구하는 T12를 발견·추가했다. 실제 쿠폰에 연결된 파일은 이동하지 않는다. UI 테스트는 빈 메모리 DB와 파일 저장소의 수명을 맞춰 실행별로 격리했다.

1.0 (5) 버전과 조건부 공개 정책/지원 링크를 준비했다. docs/release의 소개/지원/심사 노트/절차/메타데이터와 합성 무효 입력 PNG 3종, configure-release.py, release-check.py를 추가했다. 개인 심사 연락처는 Git 제외 metadata.local.json에 둘 수 있다.

## QA와 반증

- 단위 테스트를 단계별로 확장해 31개 통과. 돈의 의미/후보/차감 복원/파일 실패·원본·중단 복구/날짜 경계와 50개 알림 제한을 검증.
- 최초 전체 41개 중 알림 UI 하나 실패. 실패 캡처는 Settings였고 무조건 app.tap()이 중앙의 시스템 설정 버튼을 눌렀다. SpringBoard 권한 허용 버튼만 처리해 전체 41개 통과.
- T12 추가 전체 실행에서는 이전 테스트 원본이 복구 큐에 쌓여 빈 큐/큰 글자 검증 실패. DEBUG --ui-testing 원본 저장소를 프로세스별로 격리했다. 최종 42개(단위 31 + UI 11) 전체 통과, 실패/스킵 0: /tmp/moacon-release-isolated.xcresult.
- Release Archive와 Simulator Release 빌드·설치·실행 성공. 실제 Release 보관함 화면도 확인. 앱/확장 1.0(5), 최종 Archive에 PrivacyInfo.xcprivacy 포함 확인.
- 실제 iPhone 설치 성공. 1.0 잠금 해제 후 실행 성공. 최종 T12 포함 설치 후 재실행은 기기 자동 잠금으로 거부돼 다시 해제를 요청했다.
- 새 iPad/Pro Max Simulator에서 앱 프로세스 생성 지연/실패. 기본 Settings 실행도 완료되지 않았다. 추가 기기 종료 후 iPhone 실행은 회복됐지만 원인은 확정하지 않았다. 정상 iPad 앱 화면/제출 스크린샷으로 취급하지 않는다.
- App Store export 실제 실패: 현재 Team의 iOS App Store profile 생성 권한 부족 및 앱/확장 배포 프로파일 없음. export.log. destination=export였으며 업로드하지 않았다.
- python3 scripts/tasks.py check: 12개 유효. release-check.py --strict: 외부 조건/QA gate 미완료로 의도한 실패.

자세한 RPI/엘렝코스 과업 판정은 docs/release/TASK_ANALYSIS.md와 docs/qa/T09-release.md에 있다.

## Git 전달

T01 5e82854, T02 6668505, T03 5c771a5, T05 bd9f9da, T04 d6d21a6, T06 01a1c30, T07 956181d, T08 b2e3289, T12 64ee00b. 제출 준비/검증 자료: 4848d3a. Draft PR https://github.com/BlackBean99/moa-con/pull/2 . Task integrity CI 성공. 최종 결과 갱신 커밋은 Git 로그에서 확인한다. 브랜치는 feature/release-readiness이며 main에 병합하지 않는다.

## 제한과 다음 조건

9개 기능/관리 과업 done, T09–T11은 blocked. 정상 iPad/최소 OS/Photos 공유 호스트/원본 삭제·권한 변경/디스크 부족/iCloud 실제 과업과 제출 규격 화면이 남았다. 운영자/실제 지원·공개 정책 URL/심사 연락처, 유료 배포 팀 권한, Connect 등록·App Privacy·연령 응답·Validate가 필요하다. 실제 매장 판독/정확도/재방문을 자동 QA로 입증하지 않는다. 이미 삭제된 미복사 사진은 복구할 수 없다.
