# Code-Buddy local AI server

Tiny Express relay that holds your AI provider key on your machine. The
Flutter app calls this endpoint instead of the provider directly, so the
key never reaches the browser.

The server speaks the **OpenAI chat-completions API**, which means any
OpenAI-compatible provider works — and several have generous free tiers.

## Setup (one-time)

```powershell
cd server
npm install
copy .env.example .env       # cp .env.example .env on macOS/Linux
# open .env, pick a provider block, paste your key
```

## Free providers (recommended)

| Provider     | Free tier             | Get a key                                    | Speed     |
| ------------ | --------------------- | -------------------------------------------- | --------- |
| **Groq**     | Yes, generous         | https://console.groq.com → API Keys          | Fastest   |
| OpenRouter   | Yes, on select models | https://openrouter.ai/keys                   | Varies    |
| Together AI  | Free signup credits   | https://api.together.xyz/settings/api-keys   | Fast      |
| Ollama       | Fully local, no key   | Install https://ollama.com, then `ollama pull llama3.2` | Depends on your machine |
| OpenAI       | No real free tier     | https://platform.openai.com/api-keys         | Fast      |

`.env.example` has a ready-to-uncomment block for each. Default points at Groq.

## Run

```powershell
npm start
```

You should see:

```
[ai] Code-Buddy AI relay listening on http://localhost:3001
[ai] Upstream: https://api.groq.com/openai/v1
[ai] Model:    llama-3.3-70b-versatile
[ai] API key:  ✓
```

Leave it running. In another terminal, start the Flutter app
(`flutter run -d chrome`) and the AI tab will call this server
automatically.

`npm run dev` does the same thing but restarts on file changes.

## Switching providers

Edit `.env`, restart the server. No code changes anywhere.

The Flutter app's Settings → "AI model" dropdown is intentionally a
no-op for the real model name — the server is the source of truth.
Pick `mock-tutor` in the dropdown if you want the local stub response;
anything else routes to the server.

## Configuration

| Env var            | Default                             | Notes                                                                 |
| ------------------ | ----------------------------------- | --------------------------------------------------------------------- |
| `OPENAI_API_KEY`   | (none)                              | Required. Without it, the server returns 500 with a helpful message. |
| `OPENAI_API_BASE`  | `https://api.openai.com/v1`         | Provider's base URL (without trailing `/chat/completions`).          |
| `OPENAI_MODEL`     | `gpt-4o-mini`                       | Model name the upstream provider expects.                            |
| `PORT`             | `3001`                              | Match the URL set in the app's Settings.                             |

## Endpoints

- `GET /api/health` → `{ ok: true, hasKey: true, apiBase: "...", model: "..." }`
- `POST /api/ai/debug` → SSE stream of chat-completion deltas. Body:
  `{ "code": "...", "language": "Python" }`. (The `model` field, if
  sent, is ignored; the server uses `OPENAI_MODEL`.)

The SSE response is the raw OpenAI-style format (`data: {...}\n\n`
lines plus a final `data: [DONE]`), which is what the Flutter client
parses.

## Security note

Local dev only. The server listens on all interfaces but you're not
opening any firewall ports — only localhost can reach it. If you ever
want to expose it on a network, add authentication first.
