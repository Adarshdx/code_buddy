# Code-Buddy AI relay (Cloud Function)

This folder holds the server-side relay for the AI tutor. Once Firebase is
configured for the project (Phase 5), deploy it so the OpenAI key never ships
to the browser.

## Prerequisites

- A Firebase project on the Blaze (pay-as-you-go) plan — required for outbound
  HTTP calls from Cloud Functions.
- Node.js 20+ and the Firebase CLI (`npm install -g firebase-tools`).
- `flutterfire configure` already run in the Flutter app so `firebase_options.dart`
  points at the same project.

## One-time setup

```bash
firebase login
firebase use --add        # pick the project, alias it as "default"
npm --prefix functions install
firebase functions:secrets:set OPENAI_API_KEY   # paste your key when prompted
```

## Deploy

```bash
npm --prefix functions run build
firebase deploy --only functions
```

The CLI prints the deployed URL (e.g.
`https://us-central1-<project>.cloudfunctions.net/debugCode`).

## Configure the app

In the app's Settings screen, paste that URL into "Server endpoint". The
AI screen banner should switch to "Server mode".

## Local emulation

```bash
firebase emulators:start --only functions
```

The emulator prints a `http://127.0.0.1:5001/<project>/us-central1/debugCode`
URL you can paste into Settings during development. Browser-direct (developer
mode) calls still work, but the emulator path keeps the API key out of the
browser even locally.

## Security notes

- The function verifies a Firebase ID token on every request.
- CORS is open (`cors: true`) so the Flutter web client can call it from any
  origin you serve the PWA from. Tighten this if you host the PWA on a fixed
  domain.
- The OpenAI key is stored via Firebase Secrets, not in source or in
  environment files.
