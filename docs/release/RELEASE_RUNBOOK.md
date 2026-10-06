# 심사 제출 직전 절차

## 로컬 검증

1. `python3 scripts/tasks.py check`와 `python3 scripts/release-check.py` 실행.
2. 전체 unit/UI 테스트 및 실제 iPhone/iPad 핵심 과업. 실제 쿠폰 정확도와 매장 판독, iOS 17/최신 OS, 저장 공간 부족/권한 변경/iCloud 사진은 별도 사람/기기 검증을 기록한다.
3. 버전/앱 확장 버전 일치, 필수 사유 PrivacyInfo.xcprivacy, 무효 샘플 원본, 아이콘 alpha와 스크린샷 규격 확인.
4. Release Archive. export의 destination=export로 배포용 IPA 준비. 업로드는 이 단계에서 하지 않는다.

## 운영 자료

metadata.json에 공개 운영자, 지원 이메일, 공개 HTTPS 정책/지원 URL을 입력한다. 개인 심사 연락처와 계정 검증 상태는 Git 제외된 metadata.local.json에 같은 키로 넣을 수 있다. 두 도구는 로컬 값을 덮어 적용한다. 개인 전화번호를 저장소에 커밋하지 않는다. `python3 scripts/configure-release.py`로 앱 Info.plist의 정보와 연결한다. 초안 정책을 운영 정보에 맞춰 검토하고 공개한다. 고객 쿠폰 사진·번호를 공개 문서에 포함하지 않는다.

iPhone 6.9인치 또는 6.5인치, iPad 지원 시 13인치의 실제 앱 화면을 준비한다. 캡처를 늘려 규격에 맞추지 않는다. [Apple 스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

## 계정/배포

App Store Connect의 앱 레코드·Bundle ID·App Group·계정 권한을 확인한다. 가격·출시 국가·연령 등급 질문·App Privacy·수출 관련 답변·개인정보처리방침/지원 URL을 실제 기능에 맞춰 입력한다. 현재 설정은 ITSAppUsesNonExemptEncryption=false다. Google Ads/UMP를 추가했으므로 배포 Archive에 포함된 프레임워크의 암호화 사용까지 검토하고 해당 답변을 확정한다. [Apple 암호화 선언](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption)

Organizer → Validate App 결과를 저장한 뒤 distributionValidated를 true로 기록한다. Export 성공만으로 서버의 Validate 완료를 대신하지 않는다. 실제 심사에 앞서 TestFlight로 Release 과업을 확인하는 것을 권장한다. [Apple 배포/Validate 절차](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

## 마지막 상태

`python3 scripts/release-check.py --strict`가 통과하고 체크리스트 증거가 있어야 제출 직전 준비로 판정한다. 마지막 제출 버튼을 누르거나 약관을 수락하지 않는다. 이를 사용자에게 별도 결과로 넘긴다.

## 출시 후 오류 대응

쿠폰 유실·잘못된 사용 번호·잔액 복원이 발견되면 배포 확대를 중단하고 데이터 보존을 우선한다. 아직 출시되지 않은 후보는 이전 검증 빌드로 교체한다. 이미 설치된 iOS 앱은 즉시 강제 롤백할 수 없으므로 새 수정 빌드를 올리고 사용자에게 안내한다. 로컬 DB 스키마를 과거 버전으로 임의 다운그레이드하지 않는다.

## 광고 지원 출시와 수익 개시

기본 후보 1.0(6)은 광고 비활성이다. SDK가 포함되므로 광고를 끈 상태에서도 앱/Google Ads/UMP 합산 개인정보 명세를 확인하고 App Privacy를 확정한다. 광고 없는 첫 출시와 광고 수익 개시를 구분한다.

1. 운영자의 AdMob/지급 계정을 준비하고 iOS 앱과 보관함 배너를 생성한다. 앱 사용자 로그인은 추가하지 않는다.
2. docs/release/metadata.local.json에 ads 설정을 넣는다. 공유 metadata.json은 기본 disabled다. 실제 appID/bannerUnitID/publisherID, 개발자 웹사이트를 입력한다. 공개 정책/지원 페이지에 실제 운영 정보를 반영한다.
3. AdMob Privacy & messaging에서 대상 국가별 메시지를 설정하고 실제 앱 ID/테스트 기기로 동의·거부·다시 설정·오류 흐름을 확인한다. DEBUG의 --ads-sdk-testing은 Google 샘플 배너만 시험하며 실제 계정 UMP 설정을 검증하지 않는다.
4. python3 scripts/ads-check.py --write-app-ads-txt로 실제 게시자 파일을 생성한다. 이 파일을 개발자 웹사이트 루트 /app-ads.txt에 공개한다. Store listing의 Developer Website에 같은 호스트를 넣고 AdMob에서 검증한다. 명령은 호스팅을 수행하지 않는다.
5. Store 앱을 AdMob에 연결하고 app readiness 심사를 확인한다. 새 앱은 공개 전 이 단계를 완료하지 못할 수 있다. Google 승인을 직접 확인한 뒤 flags를 기록한다.
6. 광고 활성 설정과 실제 SDK 데이터 처리를 기준으로 App Privacy, 연령 등급, 광고 콘텐츠 제한을 확인한다. 현재 SDK 최대 광고 등급은 G다. 서비스 연령 정책은 운영자 확인 없이 아동용으로 표시하지 않는다.
7. python3 scripts/ads-check.py --strict와 configure-release.py를 통과한 후 enabled=true를 적용한다. 후보 빌드에서 쿠폰 과업·개인정보 설정을 다시 검증한다. 테스트 중 실제 광고를 클릭하지 않는다.
8. release-check.py --strict로 기존 제출 gate도 통과한다. 실제 계정/승인/공개 URL은 코드 존재로 대체하지 않는다. 광고 추가로 SDK·개인정보 처리 조건이 달라지면 새 버전을 검증한다.

광고 수익의 크기는 활성 사용자, 지역, 노출·채움률 및 단가에 달린다. 로그인이나 구독 추가만으로 광고 수익이 보장되지 않는다. 실패 시 배너를 숨기며 쿠폰 사용을 막거나 전면 광고로 보완하지 않는다.
