# 운영자 연락처 반영과 기기 실행 재확인

사용자가 운영자 연락처로 ymecca123@gmail.com을 제공하고 iPhone 잠금 해제를 알렸다. 이메일은 공개 운영자 연락처/지원 이메일로 반영한다. 운영자명과 개인 심사 연락처는 이메일만으로 추정해 채우지 않는다.

- docs/release/metadata.json supportEmail과 configure-release.py를 통해 앱 Info.plist MoaconSupportEmail 반영. 기존 More 메뉴의 문의 mailto 링크가 이 값을 사용한다.
- PrivacyPolicy.md와 docs/release/SUPPORT.md에 운영자 연락처/고객지원 이메일 기재.
- T11 차단 사유와 APP_STORE_READINESS의 지원 이메일 상태 갱신. 공개 정책/지원 URL과 운영자명, 심사 연락처, 배포 권한/Connect 검증은 여전히 미완료.
- Release Archive 성공(/tmp/moacon-contact-1.0.xcarchive); Archive 내부 Info.plist 이메일 일치, operatorName 미설정 유지 확인.
- Simulator Release 빌드·설치·실행 성공(contact-simulator-build.log, contact-simulator-launch.log). 연락처 설정 변경이며 앱 로직이 바뀌지 않아 기존 42개 회귀는 반복하지 않았다.
- tasks.py check: 12개 유효. release-check.py --strict: 지원 이메일 PASS, 남은 15개 조건으로 예상 실패. 제출 가능으로 판정하지 않음.
- 잠금 해제 직후 기존 UDID와 CoreDevice UUID로 실행 시도. 모두 CoreDeviceError 1011: 기기 찾기 실패. 목록에서 iPhone 16 Pro unavailable 확인. USB 연결·신뢰 확인을 비동기로 요청했고 현재 입력을 기다린다. 잠금 해제로 최종 실행 성공했다고 기록하지 않는다.

작업: ../moa-con-release, feature/release-readiness. 원래 moa-con 폴더의 Xcode 프로젝트/스킴 미커밋 변경은 보존한다. 기존 Draft PR https://github.com/BlackBean99/moa-con/pull/2 에 전달한다. 커밋은 Git 로그에서 확인한다. 이메일을 보내거나 앱을 업로드/심사 제출하지 않았다.
