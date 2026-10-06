# 연결 복구 후 최신 Release 실기기 검증

사용자가 실기기 연결 완료를 알렸다. 기존 feature/release-readiness worktree와 연결된 iPhone 16 Pro에서 작업을 이어갔다.

- devicectl list devices: 기존 기기 connected 확인.
- /tmp/moacon-contact-1.0.xcarchive/Products/Applications/GifticonCollector.app 설치 성공. 운영자 지원 이메일이 반영된 1.0(5) Release 빌드.
- devicectl device process launch 성공.
- devicectl device info processes에서 GifticonCollector 앱 경로와 PID 22206 확인. 설치 시의 경로와 일치해 최신 설치 앱임을 확인했다.
- 증거: artifacts/release/contact-device-install.log, contact-device-launch.log, contact-device-processes.log.
- APP_STORE_READINESS와 T09 증거의 현재 상태를 갱신. 지난 unavailable/자동 잠금 기록은 당시 실패 증거로 유지한다.

설치·실행과 프로세스 확인은 화면별 사용성, 실제 공유/원본 삭제·권한 변경·저장 실패·iCloud, iPad/최소 OS 과업을 대신하지 않는다. T09–T11은 이 검증과 운영자명/공개 정책·지원 URL/심사 연락처/배포 권한·Connect·Validate가 남아 blocked 유지한다. 기존 42개 자동 테스트는 이번 배포 확인에서 반복하지 않았다. 실제 업로드나 심사 제출은 하지 않았다.

Git 전달: 기존 Draft PR https://github.com/BlackBean99/moa-con/pull/2 . 원래 작업 폴더의 Xcode 미커밋 변경은 건드리지 않았다. 커밋 ID는 Git 로그에서 확인한다.
