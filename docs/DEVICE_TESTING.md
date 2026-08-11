# GifticonCollector 실기기 테스트 가이드

이 문서는 USB-C to USB-C 케이블로 연결한 iPhone 16 Pro에서
GifticonCollector를 빌드·설치하고, 온디바이스 인식 품질을 측정하는 절차입니다.

## 1. 사전 조건

- macOS와 Xcode가 설치되어 있어야 합니다.
- iPhone에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 켭니다.
- iPhone을 Mac에 연결하고 iPhone에서 **이 컴퓨터를 신뢰**를 승인합니다.
- Apple ID가 Xcode에 로그인되어 있어야 합니다.
- 무료 Personal Team 또는 Apple Developer Program Team이 Xcode에 등록되어 있어야 합니다.
- iPhone의 iOS 버전에 맞는 Device Support/Developer Disk Image를 제공하는 Xcode 버전을 사용합니다.

현재 개발 환경에서 확인된 기기:

```text
Name:       aa_KT_WiFi
Model:      iPhone 16 Pro (iPhone17,1)
Identifier: 00008140-001809CA18A2201C
```

기기 확인:

```sh
xcrun devicectl list devices
xcodebuild -project GifticonCollector.xcodeproj \
  -scheme GifticonCollector \
  -showdestinations
```

## 2. Xcode에서 최초 서명 설정

1. `GifticonCollector.xcodeproj`를 Xcode로 엽니다.
2. `GifticonCollector` target → **Signing & Capabilities**로 이동합니다.
3. **Automatically manage signing**을 켭니다.
4. 본인의 Team을 선택합니다.
5. Bundle Identifier가 다른 앱과 겹치지 않도록 변경합니다. 예:
   `com.<your-team>.gifticoncollector`
6. iPhone 16 Pro를 실행 대상으로 선택합니다.
7. Xcode가 요청하면 iPhone의 개발자 인증을 승인합니다.

CLI 빌드 전에 서명 identity가 보이는지 확인합니다.

```sh
security find-identity -v -p codesigning
```

`0 valid identities found`라면 Xcode에서 Team을 설정하거나 Apple Developer
인증서를 설치하기 전까지 실기기 설치를 진행할 수 없습니다.

## 3. CLI에서 실기기 빌드

프로젝트 루트에서 실행합니다.

```sh
DEVICE_ID=00008140-001809CA18A2201C

xcodebuild \
  -project GifticonCollector.xcodeproj \
  -scheme GifticonCollector \
  -destination "id=${DEVICE_ID}" \
  -configuration Debug \
  -allowProvisioningUpdates \
  build
```

빌드 산출물 위치를 직접 지정하려면:

```sh
xcodebuild \
  -project GifticonCollector.xcodeproj \
  -scheme GifticonCollector \
  -destination "id=${DEVICE_ID}" \
  -configuration Debug \
  -derivedDataPath /tmp/GifticonCollectorDeviceData \
  -allowProvisioningUpdates \
  build
```

## 4. 앱 설치

빌드가 성공하면 `.app` 경로를 확인합니다.

```sh
find /tmp/GifticonCollectorDeviceData/Build/Products -name 'GifticonCollector.app' -print
```

`devicectl`로 설치합니다.

```sh
xcrun devicectl device install app \
  --device "${DEVICE_ID}" \
  /tmp/GifticonCollectorDeviceData/Build/Products/Debug-iphoneos/GifticonCollector.app
```

설치 후 실행:

```sh
xcrun devicectl device process launch \
  --device "${DEVICE_ID}" \
  com.yourteam.gifticoncollector
```

Bundle Identifier를 변경했다면 마지막 명령의 식별자도 동일하게 변경합니다.

## 5. 기능 테스트 순서

### 권한 플로우

1. 앱을 처음 실행합니다.
2. 시스템 권한 요청 전에 프리프롬프트가 표시되는지 확인합니다.
3. 전체 접근을 허용하고 앱이 기프트콘 목록 화면으로 이동하는지 확인합니다.
4. 사진 접근을 Limited로 설정합니다.
5. 안내 배너와 **더 많은 사진 선택** 버튼이 나타나는지 확인합니다.
6. 버튼으로 Limited 사진 선택 UI가 열리고, 추가 선택 후 목록이 갱신되는지 확인합니다.
7. 사진 접근을 거부한 뒤 `PhotosPicker`로 한 장을 선택합니다.
8. 선택한 이미지가 기기 내 OCR/바코드 처리 후 SwiftData에 등록되는지 확인합니다.

### 인식 품질

카카오톡·문자로 받은 실제 기프트콘 캡처 이미지 10~20장을 준비하고 다음을
각각 기록합니다.

| 항목 | 기록 방법 |
|---|---|
| 브랜드명 | 정답/인식값 일치 여부 |
| 금액·상품명 | 정답/인식값 일치 여부 |
| 바코드 번호 | 전체 문자열 일치 여부 |
| 유효기간 | 날짜 일치 여부 |
| 전체 분류 | 기프트콘/오탐/미탐 |
| 처리 시간 | 이미지 1장당 초 |

각 이미지에 대해 조명, 기울기, 스크린샷 압축 여부도 함께 기록합니다.

### 후보 선별·중복·차감 기능

1. 사진 라이브러리에 일반 사진 20장과 바코드가 포함된 기프트콘 5장을 섞습니다.
2. 전체 스캔 진행 화면에서 `OCR 대상 후보` 수가 바코드 사진 수와 가까운지 확인합니다.
3. 같은 바코드 사진을 다시 스캔해도 목록 항목이 늘지 않는지 확인합니다.
4. 바코드가 없는 상품권 이미지를 직접 선택했을 때 등록되지 않는지 확인합니다.
5. 바코드가 있는 이미지를 `사진 한 장 선택`으로 등록하고 목록에 표시되는지 확인합니다.
6. 상세 화면에서 `사용 완료 처리`와 취소가 동작하는지 확인합니다.
7. 금액이 있는 항목에서 `부분 차감 허용`을 켜고 일부 금액을 차감합니다.
8. 잔액이 0이 되면 자동으로 사용 완료 처리되는지 확인합니다.
9. 부분 차감 허용이 꺼진 상태에서는 차감 UI가 노출되지 않는지 확인합니다.

### 백그라운드 스캔

1. 앱을 한 번 실행해 BackgroundTasks가 등록되도록 합니다.
2. 앱을 백그라운드로 보냅니다.
3. 새 사진을 추가합니다.
4. iOS가 `BGProcessingTask`를 실행할 때까지 기다립니다.
5. 콘솔 로그와 마지막 변경 시각을 비교합니다.

`BGProcessingTask` 실행 시점은 시스템이 결정하므로 즉시 실행을 기대하지
않습니다. 실제 주기와 배터리·발열·소요시간은 실기기에서 측정해야 합니다.

## 6. 온디바이스 개인정보 검증

- 앱 실행 중 네트워크 요청이 발생하지 않는지 Xcode Network Instruments 또는
  패킷 관찰 도구로 확인합니다.
- 사진 원본 파일이 앱 컨테이너에 복사되지 않고
  `PHAsset.localIdentifier`만 저장되는지 확인합니다.
- SwiftData에 OCR 결과가 로컬로 저장되는지 확인합니다.
- 로그·스크린샷·테스트 리포트에 실제 바코드 번호와 개인정보가 노출되지 않도록 합니다.

## 7. 현재 환경에서 발생한 차단 사항

다음 상태에서는 앱을 실기기에 설치할 수 없습니다.

```text
security find-identity -v -p codesigning
→ 0 valid identities found

xcrun devicectl list devices
→ connected (no DDI)
```

해결 순서는 다음과 같습니다.

1. iPhone에서 개발자 모드와 이 컴퓨터 신뢰를 확인합니다.
2. iOS 버전을 지원하는 최신 Xcode로 업데이트합니다.
3. Xcode Accounts에 Apple ID를 추가하고 Team을 선택합니다.
4. Signing & Capabilities에서 자동 서명을 활성화합니다.
5. 다시 `security find-identity`와 `xcrun devicectl list devices`를 실행합니다.
6. 위의 실기기 빌드·설치 명령을 재실행합니다.

시뮬레이터에서는 Photos 권한, 실제 사진 라이브러리, 바코드 품질, 백그라운드
실행 주기를 실기기와 동일하게 검증할 수 없습니다.
