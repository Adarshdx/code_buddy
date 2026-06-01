# Code-Buddy Firebase setup

The app runs in demo mode out of the box (Hive-backed local accounts, mock AI).
Follow this guide to enable real Firebase auth, Firestore-backed snippet sync,
the server-side AI relay, and Firebase Hosting deployment.

Everything below assumes you have **Node.js 20+**, the **Flutter SDK**, the
**Firebase CLI** (`npm install -g firebase-tools`), and **FlutterFire CLI**
(`dart pub global activate flutterfire_cli`) installed.

---

## 1. Create a Firebase project

1. Open https://console.firebase.google.com/ and click **Add project**.
2. Pick a name (e.g. `code-buddy-prod`). Disable Google Analytics if you don't
   need it.
3. Upgrade the project to the **Blaze** plan. Cloud Functions and outbound
   HTTP calls require it.

## 2. Enable the products you'll use

In the Firebase console for the new project:

- **Build → Authentication → Get started**
  - Enable **Email/Password**.
  - Enable **Google** (set a support email).
- **Build → Firestore Database → Create database**
  - Start in **production mode**, any region.
- **Build → Functions** — no setup needed in the console; CLI handles it.
- **Build → Hosting** — no setup needed in the console; CLI handles it.

## 3. Wire the Flutter app to the project

```bash
firebase login
flutterfire configure --project=<your-project-id>
```

When prompted:
- Select your project.
- Pick `web` as the only platform (unless you want mobile too).
- Accept the suggested file path for `firebase_options.dart`.

This overwrites `lib/firebase_options.dart` with real values. The demo banner
on the login screen will disappear on the next build.

## 4. Deploy Firestore rules and indexes

Rules live in `firestore.rules` and lock each user into their own
`/users/{uid}/...` subtree.

```bash
firebase use <your-project-id>
firebase deploy --only firestore
```

## 5. Deploy the AI Cloud Function

See [functions/README.md](functions/README.md) for the full walkthrough. The
short version:

```bash
firebase functions:secrets:set OPENAI_API_KEY    # paste your key
npm --prefix functions install
npm --prefix functions run build
firebase deploy --only functions
```

The CLI prints the deployed URL. In the app's **Settings → Server endpoint**,
paste that URL. The AI screen banner should flip to "Server mode".

## 6. Deploy the web app

```bash
flutter build web --release
firebase deploy --only hosting
```

The CLI prints `https://<your-project>.web.app`. Open it; the demo banner
should be gone, sign-up should email you a verification link, and snippets
saved on one browser should appear on another after you sign in there too.

## 7. CI/CD via GitHub Actions

Two workflows ship in `.github/workflows/`:

- `ci.yml` — runs on every push and PR. Format check, analyzer, tests, and a
  release web build (uploaded as an artifact).
- `deploy.yml` — runs on push to `main`. Builds the web app + functions and
  deploys to Firebase Hosting on the `live` channel.

To activate `deploy.yml`, add two repository settings on GitHub:

1. **Repo variable** `FIREBASE_PROJECT_ID` (Settings → Secrets and variables →
   Actions → Variables). Set to your project ID (e.g. `code-buddy-prod`).
2. **Repo secret** `FIREBASE_SERVICE_ACCOUNT` (Settings → Secrets and
   variables → Actions → Secrets). Paste the contents of a service-account
   JSON file with the **Firebase Hosting Admin** and **Cloud Functions
   Admin** roles. You can generate one from the Google Cloud console under
   IAM → Service Accounts, or via
   `firebase init hosting:github` which automates the whole flow.

After both are set, the next push to `main` deploys automatically.

## 8. (Optional) Local emulation

If you want to iterate on Firestore rules or the Cloud Function without
deploying:

```bash
firebase emulators:start --only auth,firestore,functions,hosting
```

Set **Server endpoint** in Settings to the emulator's functions URL (the CLI
prints it on startup).

---

## What sync gives you

- Signing in with the same Firebase account on two browsers shows the same
  snippets in real time. Edits and deletes propagate via Firestore snapshots.
- The Snippets screen shows a live "Synced / Syncing / Sync error / Local
  only" chip in the AppBar.
- Demo mode (no Firebase configured) still works exactly as before — Hive
  storage on the device, no remote.

## Troubleshooting

- **"Sign in with Google" does nothing** — make sure you enabled the Google
  provider in step 2 and re-built after step 3.
- **"Sync error" chip stays red** — Firestore rejected a write. Most likely
  the deployed rules don't match `firestore.rules`. Re-run step 4.
- **Cloud Function returns 401** — the app is sending an ID token from the
  local-shim account. Sign out, then sign back in with a real Firebase
  email / Google account.
- **`flutterfire configure` errors** — the FlutterFire CLI needs the Firebase
  CLI to be logged in. Re-run `firebase login`.
