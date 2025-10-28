# Circuits

- `PasswordAuth.circom`: proves Poseidon(salt, password) == commitment and outputs Poseidon(pwHash, nonce).

## Build (example)
Requires `circom` v2 and `snarkjs`.

```bash
# compile
circom PasswordAuth.circom --r1cs --wasm -o build

# trusted setup (Groth16 example)
# 1) powers of tau
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="first" -v
# 2) circuit-specific
snarkjs groth16 setup build/PasswordAuth.r1cs pot12_0001.ptau keys/PasswordAuth_0000.zkey
snarkjs zkey contribute keys/PasswordAuth_0000.zkey keys/PasswordAuth_final.zkey --name="phase2" -v
# 3) export verification key
snarkjs zkey export verificationkey keys/PasswordAuth_final.zkey verification_key.json
```

Keep `.zkey`/`ptau` files out of VCS (see .gitignore). For production, use secure multi-party ceremony or PLONK.
