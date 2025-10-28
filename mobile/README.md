# Mobile (Flutter)

A minimal client app lives in `mobile/zk_login_app/` with Register and Login flows wired to the backend.

## Run
```bash
cd mobile/zk_login_app
flutter run
```

Notes
- Backend URL defaults to `http://localhost:3000`; on Android emulator use `http://10.0.2.2:3000`.
- Registration requires a decimal `commitment` (Poseidon(salt, password)) and optional `salt`. The app does not yet compute Poseidon; input these values manually for now.
- Login uses server-assisted proving (`POST /auth/login`): enter decimal `password`, app will request a nonce and obtain a JWT.
