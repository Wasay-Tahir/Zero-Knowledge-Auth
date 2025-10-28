import type { poseidon as PoseidonFn } from 'circomlibjs';

export async function poseidonCommitmentDecimal(saltDec: string, passwordDec: string): Promise<string> {
  // Lazy import circomlibjs poseidon
  const lib = await import('circomlibjs');
  // @ts-ignore - buildPoseidon may exist; otherwise poseidon is ready
  const poseidon: any = (await (lib as any).buildPoseidon?.()) || (lib as any).poseidon;
  const F = poseidon.F || (lib as any).F1Field;
  const salt = BigInt(saltDec);
  const password = BigInt(passwordDec);
  const out = poseidon([salt, password]);
  const toString = F?.toString ? F.toString.bind(F) : (x: any) => x.toString();
  return toString(out);
}