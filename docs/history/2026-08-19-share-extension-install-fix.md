# Share Extension 설치 오류 수정

## 요청

실제 iPhone 설치 시 `GifticonCollectorShare.appex`의 `CFBundleExecutable`이 없거나 유효하지 않아 설치되지 않는 문제를 해결하고, 이후 개발 대화별 Markdown 이력 관리 루틴을 시작한다.

## 원인

`GifticonCollectorShare/Info.plist`에 앱 확장 번들의 필수 실행 파일 키가 없었다. 시뮬레이터 컴파일은 통과했지만 iOS CoreDevice 설치 검증에서 `MIInstallerErrorDomain / MissingBundleExecutable`로 거부되었다.

## 변경

- Share Extension `Info.plist`에 `CFBundleExecutable = $(EXECUTABLE_NAME)` 추가
- `CFBundleName`, 버전 키 추가
- `project.yml`에 Share Extension의 `PRODUCT_NAME`, 버전 설정 명시
- `docs/history/README.md`에 대화별 이력 작성 규칙 추가

## QA

- XcodeGen 프로젝트 재생성
- iOS Simulator 앱/Share Extension/테스트 타겟 빌드
- 생성된 `.appex/Info.plist`에서 `CFBundleExecutable` 값이 실제 실행 파일명으로 확장되는지 확인
- 연결된 iPhone 16 Pro에 실제 설치/실행 재시도

## 최종 QA 결과

- 생성된 Simulator `.appex/Info.plist`: `CFBundleExecutable = GifticonCollectorShare`
- iOS Simulator `build-for-testing`: 성공
- iPhone 16 Pro용 `xcodebuild build`: 성공
- 앱 설치: 성공 (`com.yourteam.gifticoncollector`)
- 앱 실행: 기기 보안 정책으로 거부됨. `developerModeStatus = enabled`, 프로파일·App Group은 정상이며, iOS가 개발자 앱 신뢰를 요구하는 상태임.

## 상태

설치 오류 수정 완료. 기기에서 앱 실행 시 iPhone의 개발자 앱 신뢰 설정을 확인해야 한다.
