# 로그인 없는 광고 수익화 — 2026-10-06–07

사용자 요청: 로그인/구독 없이 무료 기능을 제공하며 배너 등 광고 수익화를 전제로 과업을 설정하고 개발한다. 기존 worktree feature/release-readiness와 상태 원본 tasks/todo.md를 유지했다. T13–T18을 추가했다.

공식 Google/Apple 문서를 확인해 네이티브 AdMob과 웹 AdSense를 구분했다. 앱 사용자 계정은 광고 수익의 조건이 아니며 운영자 게시자/지급 계정과 앱 검증은 별도로 필요하다. 쿠폰 핵심 기능과 매장 제시를 방해하지 않는 보관함 배너를 선택했다.

Google Ads 13.11.0/UMP 3.1.0 고정, 비개인화·first-party ID 비활성, Release 기본 꺼짐, 실제 ID·동의·개인정보·앱 검증 flags, UMP 매 실행 갱신/변경 진입점, 오류/오래된 완료/중복 초기화 방지를 구현했다. 광고 서비스에 쿠폰 내용/사진을 전달하지 않는다. 공유 확장에는 SDK를 연결하지 않았다.

큰 글자 캡처에서 광고 표기가 잘리는 반례를 발견하고 높이와 글자 확대 상한을 수정했다. 검색·등록·상세·원본·검토 중 배너를 제거한다. 광고 실패 시 빈 공간을 없애고 기능을 유지한다. 기존 무광고 SDK 문구와 심사 노트, 정책, 제출/수익 gate를 갱신했다. SDK manifest의 DeviceID tracking=true를 확인했으므로 비개인화라는 이유로 데이터 없음이라고 주장하지 않았다.

검증: Python 설정 반례 4개 통과. 네이티브 회귀 단위 38 + UI 15 = 53/53 통과. 실제 Google 테스트 배너 별도 통과. 레이아웃 수정 후 관련 UI/SDK 5/5 추가 통과. 1.0(6) Release Archive 및 Simulator 설치·실행 성공. 실제 기기 설치는 CoreDevice 연결 reset으로 실패해 완료로 표시하지 않았다. 증거: docs/qa/T14-ad-consent.md, T15-wallet-ad.md, T16-ad-release-gates.md, T17-ads.md.

원본 작업 디렉터리의 사용자 Xcode 변경은 보존한다. 원격 전달은 feature/release-readiness / Draft PR #2(https://github.com/BlackBean99/moa-con/pull/2)이며 실제 Store 업로드/심사 제출은 하지 않는다. 최종 커밋은 이 파일을 포함하는 커밋과 Git log로 연결한다.

남은 조건: 기기 연결과 1.0(6) 설치·실행; 실제 게시자 앱/단위/지급 계정, UMP 메시지와 지역 동의 검증, 공개 정책·개발자 웹사이트/app-ads.txt, Store 연결/AdMob 승인, 실제 SDK 데이터·App Privacy 확정. 기존 T09–T11의 iPad/최소 OS/Photos 호스트·사진 삭제/권한/저장 실패 QA, 스크린샷, 운영/심사 정보와 배포 권한도 여전히 미완료다. 코드와 테스트 성공이 수익·심사 승인을 뜻하지 않는다.
