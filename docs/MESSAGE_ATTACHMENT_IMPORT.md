# 문자 첨부 이미지 가져오기

Messages 앱 내부 첨부 이미지는 iOS 공개 API로 앱이 직접 열람할 수 없습니다. 따라서 GifticonCollector는 Share Extension을 통해 사용자가 명시적으로 선택한 이미지만 받습니다.

1. Messages에서 기프트콘 이미지가 있는 대화를 엽니다.
2. 이미지를 길게 누르고 `공유`를 선택합니다.
3. 공유 시트에서 `기프티콘 수집함`을 선택합니다.
4. 공유가 끝나면 GifticonCollector를 열거나 다음 활성화 시 자동으로 온디바이스 OCR이 실행됩니다.
5. 바코드가 확인된 이미지와 OCR 분류 결과만 저장되며, 같은 바코드는 중복 저장되지 않습니다.

첨부 원본은 App Group의 로컬 임시 보관함에만 저장됩니다. 인식 성공 후에는 해당 임시 파일을 제거하고, SwiftData에는 앱이 다시 표시할 수 있는 로컬 파일 참조만 남깁니다. 네트워크 요청은 사용하지 않습니다.

## 배포 전 확인

- Apple Developer 계정에서 `group.com.yourteam.gifticoncollector` App Group을 앱과 Share Extension 양쪽에 등록합니다.
- 실제 기기에서 Share Extension이 Messages 공유 시트에 표시되는지 확인합니다.
- 공유 후 앱 재실행, 바코드 없는 이미지, 중복 바코드, 여러 장 공유를 각각 확인합니다.
