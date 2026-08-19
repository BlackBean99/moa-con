Native iOS gift-con collecting service.

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
checklist. Brand dictionaries, incremental scan checkpoints, and the real
device accuracy benchmark remain explicit TODOs for the PoC phase.

실제 iPhone 연결·서명·설치와 기능 검증 절차는
[`docs/DEVICE_TESTING.md`](docs/DEVICE_TESTING.md)를 참고하세요.

바코드 우선 선별, 중복 방지, 잔액 추적의 결정 배경은
[`docs/decisions/0001-barcode-first-archive.md`](docs/decisions/0001-barcode-first-archive.md)에 기록되어 있습니다.

문자 첨부 이미지의 명시적 공유 가져오기 절차는
[`docs/MESSAGE_ATTACHMENT_IMPORT.md`](docs/MESSAGE_ATTACHMENT_IMPORT.md)를 참고하세요.
