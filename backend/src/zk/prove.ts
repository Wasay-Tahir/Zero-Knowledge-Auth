// Server-assisted proving using snarkjs.groth16.fullProve
export type PasswordAuthInputs = {
  password: string; // decimal string
  salt: string;     // decimal string
  commitment: string; // decimal string (public)
  nonce: string;      // decimal string (public)
};

export async function fullProvePasswordAuth(inputs: PasswordAuthInputs): Promise<{ proof: any; publicSignals: string[] }> {
  const snarkjs = await import('snarkjs');
  const wasmPath = process.env.ZK_WASM_PATH || 'circuits/build/PasswordAuth_js/PasswordAuth.wasm';
  const zkeyPath = process.env.ZK_ZKEY_PATH || 'circuits/keys/PasswordAuth_final.zkey';
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(inputs, wasmPath, zkeyPath);
  return { proof, publicSignals };
}