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
