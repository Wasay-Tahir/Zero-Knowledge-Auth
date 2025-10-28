import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { verifyZkProof } from './zk/verify.js';
import { fullProvePasswordAuth } from './zk/prove.js';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

type User = { username: string; commitment: string; salt?: string };
const users = new Map<string, User>();
const nonces = new Map<string, string>();

app.post('/auth/register', (req, res) => {
  const schema = z.object({
    username: z.string().min(3),
    commitment: z.string().regex(/^\d+$/),
    salt: z.string().regex(/^\d+$/).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const { username, commitment, salt } = parsed.data;
  users.set(username, { username, commitment, salt });
  return res.json({ ok: true });
});

app.get('/auth/nonce', (req, res) => {
  const username = req.query.username as string;
  if (!username || !users.has(username)) return res.status(404).json({ error: 'user not found' });
  const nonce = BigInt.asUintN(128, BigInt(Date.now()) * 1000003n + BigInt(Math.floor(Math.random() * 1e9))).toString();
  nonces.set(username, nonce);
  const salt = users.get(username)?.salt;
  return res.json({ nonce, salt });
});

// Dev helper: compute commitment = Poseidon(salt, password) so the client can avoid manual entry.
// WARNING: For production, compute this on-device; do not send raw passwords to the server.
app.post('/auth/commitment', async (req, res) => {
  const schema = z.object({ password: z.string().regex(/^\d+$/), salt: z.string().regex(/^\d+$/) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    const { poseidonCommitmentDecimal } = await import('./zk/hash.js');
    const commitment = await poseidonCommitmentDecimal(parsed.data.salt, parsed.data.password);
    return res.json({ commitment });
  } catch (e) {
    return res.status(500).json({ error: 'hash error', details: (e as Error).message });
  }
});

app.post('/auth/verify', async (req, res) => {
  const schema = z.object({
    username: z.string(),
    proof: z.unknown(),
    publicSignals: z.array(z.string())
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const { username, proof, publicSignals } = parsed.data;
  const user = users.get(username);
  if (!user) return res.status(404).json({ error: 'user not found' });
  const expectedNonce = nonces.get(username);
  if (!expectedNonce) return res.status(400).json({ error: 'nonce missing/expired' });

  try {
    const ok = await verifyZkProof(proof as any, publicSignals);
    if (!ok) return res.status(401).json({ error: 'invalid proof' });
    nonces.delete(username);
    const token = jwt.sign({ sub: username }, JWT_SECRET, { expiresIn: '15m' });
    return res.json({ token });
  } catch (e) {
    return res.status(500).json({ error: 'verification error', details: (e as Error).message });
  }
});

// Server-assisted proving + verification (dev-friendly):
// Requires a nonce to have been issued via GET /auth/nonce first.
app.post('/auth/login', async (req, res) => {
  const schema = z.object({
    username: z.string(),
    password: z.string().regex(/^\d+$/),
    // Optional if stored at registration time
    salt: z.string().regex(/^\d+$/).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const { username, password } = parsed.data;
  const user = users.get(username);
  if (!user) return res.status(404).json({ error: 'user not found' });
  const nonce = nonces.get(username);
  if (!nonce) return res.status(400).json({ error: 'nonce missing/expired' });

  const salt = parsed.data.salt ?? user.salt;
  if (!salt) return res.status(400).json({ error: 'salt required (not stored for this user)' });

  try {
    const { proof, publicSignals } = await fullProvePasswordAuth({
      password,
      salt,
      commitment: user.commitment,
      nonce,
    });
    const ok = await verifyZkProof(proof as any, publicSignals);
    if (!ok) return res.status(401).json({ error: 'invalid proof' });
    nonces.delete(username);
    const token = jwt.sign({ sub: username }, JWT_SECRET, { expiresIn: '15m' });
    return res.json({ token });
  } catch (e) {
    return res.status(500).json({ error: 'proving/verification error', details: (e as Error).message });
  }
});

app.listen(PORT, () => {
  console.log(`Backend listening on http://localhost:${PORT}`);
});
