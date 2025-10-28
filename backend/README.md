# Backend (Node.js/Express)

Implements registration, nonce issuance, proof verification (snarkjs or on-chain), and JWT session issuance.

## Scripts (expected)
- `dev`: run nodemon on `src/index.ts`
- `build`: TypeScript build to `dist/`
- `start`: run compiled server

## Env
- `PORT=3000`
- `JWT_SECRET=...`
- `ZK_VKEY_PATH=circuits/verification_key.json` (example)
- `ZK_WASM_PATH=circuits/build/PasswordAuth_js/PasswordAuth.wasm` (server-assisted proving)
- `ZK_ZKEY_PATH=circuits/keys/PasswordAuth_final.zkey` (server-assisted proving)

## Routes
- `POST /auth/register` → store `{ username, commitment, salt? }`
- `GET /auth/nonce?username=...` → single-use nonce
- `POST /auth/verify` → verify client-submitted proof and return `{ token }`
- `POST /auth/login` → server-assisted: with `{ username, password, salt? }` runs groth16.fullProve using issued nonce, verifies, returns `{ token }`

For now this repo includes a minimal in-memory store; replace with Postgres/Mongo later.
