// What every rules test file shares: the emulator environment, cleared before
// each test, and the documents the way the app writes them.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach } from 'node:test';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-car-detailing-rules',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

/** Firestore as [uid], or signed out when null. */
export const as = (uid) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

/** A profile the way the app writes it. */
export const profile = (role, changes = {}) => ({
  email: `${role}@x.rs`,
  firstName: 'Ime',
  lastName: 'Prezime',
  phone: '',
  role,
  disabled: false,
  createdAt: serverTimestamp(),
  ...changes,
});

/** What the form writes for a new job. */
export const job = (uid, changes = {}) => ({
  ownerId: uid,
  date: '2026-11-16',
  start: '09:00',
  end: '',
  clientName: 'Jelena Marković',
  clientPhone: '+381601234567',
  address: 'Vračar',
  items: [{ itemId: 'i1', categoryId: 'c1', name: 'Ugaona garnitura', priceMinor: 500000, qty: 6 }],
  subtotalMinor: 3000000,
  discountPercent: 10,
  travelMinor: 0,
  priceMinor: 2700000,
  workers: [uid],
  notes: '',
  status: 'booked',
  paidMinor: null,
  toWallet: false,
  doneBy: '',
  doneAt: null,
  rev: 1,
  updatedBy: uid,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...changes,
});

/** A wallet entry the way the app writes it. */
export const entry = (uid, changes = {}) => ({
  type: 'deposit',
  amountMinor: 1500000,
  description: 'Uplata od posla',
  date: new Date('2026-11-15T10:00:00Z'),
  userId: uid,
  createdBy: uid,
  updatedAt: serverTimestamp(),
  ...changes,
});

/** Writes [data] at [path] past the rules, as the worker or a past app did. */
export const seed = (path, data) =>
  env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), data));

/** The crew as stored: the admin, two workers and one disabled. */
export async function seedCrew() {
  const at = { createdAt: new Date() };
  await seed('meta/admin', { uid: 'boss' });
  await seed('users/boss', profile('admin', at));
  await seed('users/ana', profile('worker', at));
  await seed('users/bob', profile('worker', at));
  await seed('users/gone', profile('worker', { ...at, disabled: true }));
}

/** A job already saved by [uid], with server-side times. */
export const seedJob = (id, uid, extra = {}) =>
  seed(`jobs/${id}`, { ...job(uid), createdAt: new Date(), updatedAt: new Date(), ...extra });
