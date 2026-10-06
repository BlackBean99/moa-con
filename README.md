# 모아콘

사진 속 기프티콘을 모아두고 제때 쓰는 네이티브 iOS 앱입니다. 일반 바코드는 확인 필요로 분리하고, 사용 가능 쿠폰은 만료 가까운 순서로 보여줍니다.

브랜드·상품 검색, 인식 정보 수정과 확인 승인, 원본 확대, 사용 상태 및 부분 차감을 지원합니다. 사진 권한 없이도 사진 선택/공유 가져오기와 보관함을 사용할 수 있습니다. 첫 실행에는 한 화면의 온보딩을 보여주며, 다음 실행부터 보관함을 엽니다.

[디자인 시스템](DESIGN.md) · [온보딩·디자인 RPI 검증](docs/DESIGN_REFACTOR_RPI.md) · [전문가 사용성 평가와 RPI 검증](docs/USABILITY_RPI.md) · [개인정보 처리 원칙](PrivacyPolicy.md)

## 출시 과업 관리

현재 작업은 `feature/release-readiness` 브랜치와 별도 `../moa-con-release` worktree에서 진행합니다. 원래 작업 폴더의 미커밋 Xcode 변경은 보존합니다.

[과업 목록](tasks/todo.md) · [구현 계획](tasks/plan.md) · [심사 준비 판정](docs/APP_STORE_READINESS.md) · [제출 직전 절차](docs/release/RELEASE_RUNBOOK.md)

```sh
python3 scripts/tasks.py list
python3 scripts/tasks.py next
python3 scripts/tasks.py check
python3 scripts/tasks.py start T09
python3 scripts/tasks.py done T09 --evidence docs/qa/T09-release.md
python3 scripts/release-check.py --strict
```

GitHub의 Task integrity 검사는 push/PR마다 의존 관계·증거 경로·관리 스크립트를 검사하고 제출 차단 상태를 보고합니다. 이 검사의 성공은 iOS 앱 테스트/서명/제출 승인을 뜻하지 않습니다.

완료에는 검증 기록과 선행 과업 완료가 필요합니다. `block ID --reason "이유"`로 외부 조건을 기록하며, 미완료 상태를 제출 가능으로 처리하지 않습니다. 운영 정보는 `docs/release/metadata.json`에 입력한 뒤 `python3 scripts/configure-release.py`로 앱에 반영합니다. 제출 검사는 업로드하지 않습니다.

로컬 Release 빌드·설치·실행:

```sh
./scripts/deploy-local.sh --simulator
./scripts/deploy-local.sh --device
```

실기기 명령에는 Xcode 계정 로그인과 유효한 개발 프로비저닝 프로파일이 필요합니다. 시뮬레이터 Release에는 데모 데이터가 포함되지 않습니다.


## Two-agent launcher

The launcher supports two independent agents:

- `glm`: calls GLM through NVIDIA NIM using `GLM_API_KEY`.
- `codex`: calls the installed Codex CLI using its existing login/Pro session.

Create the local environment file and add only the GLM token:

```sh
cp .env.example .env.local
chmod +x start-script.sh
./start-script.sh --provider glm "Hello, GLM"
./start-script.sh --provider codex "Review this repository"
```

You can select the default provider with `AI_PROVIDER=glm` or `AI_PROVIDER=codex`.
Use `--model MODEL` or `CODEX_MODEL` for Codex. GLM uses `GLM_BASE_URL` and
`GLM_MODEL` overrides.

`GLM_BASE_URL` may be either the API base (`https://integrate.api.nvidia.com/v1`)
or the complete chat endpoint (`https://integrate.api.nvidia.com/v1/chat/completions`).
The launcher normalizes both forms and prints the completion content from the
streaming response.

Codex Pro/ChatGPT authentication is separate from an OpenAI API key. Do not
put the Pro credential in `.env.local`; authenticate the CLI with `codex login`.
`.env.local` is ignored by Git.

## GifticonCollector iOS scaffold

The native iOS scaffold lives in `GifticonCollector/` and targets iOS 17+ with
Swift 6, SwiftUI, Photos/PhotosUI, Vision, SwiftData, and BackgroundTasks.

```sh
xcodegen generate
xcodebuild -project GifticonCollector.xcodeproj \
  -scheme GifticonCollector \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

The app performs OCR, barcode detection, classification, parsing, and storage
on-device. See `PrivacyPolicy.md` for the privacy and pre-release verification
checklist. A small reviewed brand list and exchange-location fallback are included. Incremental scan checkpoints and real-device accuracy/energy benchmarks still require follow-up.

실제 iPhone 연결·서명·설치와 기능 검증 절차는
[`docs/DEVICE_TESTING.md`](docs/DEVICE_TESTING.md)를 참고하세요.

바코드 우선 선별, 중복 방지, 잔액 추적의 결정 배경은
[`docs/decisions/0001-barcode-first-archive.md`](docs/decisions/0001-barcode-first-archive.md)에 기록되어 있습니다.

문자 첨부 이미지의 명시적 공유 가져오기 절차는
[`docs/MESSAGE_ATTACHMENT_IMPORT.md`](docs/MESSAGE_ATTACHMENT_IMPORT.md)를 참고하세요.
