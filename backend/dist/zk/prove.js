export async function fullProvePasswordAuth(inputs) {
    const snarkjs = await import('snarkjs');
    const wasmPath = process.env.ZK_WASM_PATH || 'circuits/build/PasswordAuth_js/PasswordAuth.wasm';
    const zkeyPath = process.env.ZK_ZKEY_PATH || 'circuits/keys/PasswordAuth_final.zkey';
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(inputs, wasmPath, zkeyPath);
    return { proof, publicSignals };
}
