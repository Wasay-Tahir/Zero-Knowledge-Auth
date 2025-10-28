# Zero-Knowledge Authentication (ZK-Login)

A monorepo for a ZK-Login system featuring:
- Flutter mobile app (client)
- Node.js/Express backend (server)
- Circom circuits (ZK)
- Solidity verifier (optional, via Hardhat)

## Structure
- `backend/`: Node.js/Express server (verification, JWT issuance, nonce mgmt)
- `circuits/`: Circom v2 circuits and build instructions
- `mobile/`: Flutter app (register/login UI, local crypto, optional WASM prover)
- `contracts/`: Solidity verifier and Hardhat config (optional)

## Quick start
1. Backend dev
   - See `backend/README.md` for dev server scripts and env.
2. Circuits
   - See `circuits/README.md` for building `.r1cs`, `.zkey`, and verifier.
3. Mobile
   - See `mobile/README.md` to bootstrap Flutter app and integrate prover.
4. Contracts (optional)
   - See `contracts/README.md` to init Hardhat and deploy verifier.

Security notes:
- Use unique 128+ bit salts, single-use nonces, and never log secrets.
- Prefer Poseidon/BLAKE2s in-circuit for efficiency.
- Consider server-assisted proving for initial milestone; move to on-device later.
