// Since v1.2.0 only the admin writes jobs; workers read the calendar.

import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import { as, job, seedCrew, seedJob } from './setup.js';

/** An edit the way the app writes it: the change, plus the bookkeeping. */
const edit = (uid, changes = {}, rev = 2) =>
  updateDoc(doc(as(uid), 'jobs/j1'), {
    rev,
    updatedBy: uid,
    updatedAt: serverTimestamp(),
    ...changes,
  });

const create = (id, uid, changes) => setDoc(doc(as(uid), `jobs/${id}`), job(uid, changes));

describe('booking a job', () => {
  test('the admin books, as themselves', async () => {
    await seedCrew();
    await assertSucceeds(create('a', 'boss'));
    await assertSucceeds(create('b', 'boss', { items: [], notes: 'Passat karavan', end: '' }));
    await assertFails(setDoc(doc(as('boss'), 'jobs/c'), job('ana')));
    await assertFails(create('d', 'boss', { updatedBy: 'ana' }));
    await assertFails(create('e', 'boss', { rev: 2 }));
    await assertFails(create('f', 'boss', { status: 'cancelled' }));
  });

  test('a worker books nothing, not even as themselves', async () => {
    await seedCrew();
    await assertFails(create('a', 'ana'));
    await assertFails(create('b', 'bob', { status: 'done', paidMinor: 500000 }));
    await assertFails(create('c', 'gone'));
  });

  test('a booked job may leave out what is filled in when done', async () => {
    await seedCrew();
    const bare = job('boss');
    for (const key of ['paidMinor', 'toWallet', 'doneBy', 'doneAt']) delete bare[key];
    await assertSucceeds(setDoc(doc(as('boss'), 'jobs/a'), bare));
    const missing = job('boss');
    delete missing.travelMinor;
    await assertFails(setDoc(doc(as('boss'), 'jobs/b'), missing));
  });

  test('a job done on the spot needs what was paid', async () => {
    await seedCrew();
    const done = { status: 'done', doneBy: 'boss', doneAt: serverTimestamp(), toWallet: true };
    await assertFails(create('a', 'boss', done));
    await assertSucceeds(create('b', 'boss', { ...done, paidMinor: 2700000 }));
  });

  test('fields have the right shape', async () => {
    await seedCrew();
    const bad = [
      { date: '16.11.2026' },
      { date: '2026-11-160' },
      { start: '9:00' },
      { start: '24:00' },
      { end: '25:00' },
      { discountPercent: 101 },
      { discountPercent: -1 },
      { priceMinor: -1 },
      { priceMinor: 1.5 },
      { travelMinor: '0' },
      { paidMinor: -5 },
      { items: Array.from({ length: 61 }, (_, i) => ({ itemId: `i${i}` })) },
      { workers: Array.from({ length: 21 }, (_, i) => `u${i}`) },
      { items: 'Fotelja' },
      { clientName: 'x'.repeat(121) },
      { toWallet: 'yes' },
      { pushRev: 1 },
      { pushStatus: 'booked' },
      { currency: 'RSD' },
    ];
    for (const [i, changes] of bad.entries()) {
      await assertFails(create(`bad${i}`, 'boss', changes));
    }
  });
});

describe('reading jobs', () => {
  test('every active account reads the calendar; a switched-off one does not', async () => {
    await seedCrew();
    await seedJob('j1', 'boss');
    await assertSucceeds(getDoc(doc(as('ana'), 'jobs/j1')));
    await assertSucceeds(getDocs(collection(as('bob'), 'jobs')));
    await assertFails(getDoc(doc(as('gone'), 'jobs/j1')));
  });
});

describe('changing a job', () => {
  test('the admin edits, finishes, cancels and reopens', async () => {
    await seedCrew();
    await seedJob('j1', 'boss');
    await assertSucceeds(edit('boss', { address: 'Zvezdara', workers: ['ana', 'bob'] }));
    await assertSucceeds(edit('boss', { status: 'cancelled' }, 3));
    await assertSucceeds(edit('boss', { status: 'booked' }, 4));
    await assertSucceeds(
      edit('boss', { status: 'done', paidMinor: 2500000, toWallet: true, doneBy: 'boss', doneAt: serverTimestamp() }, 5),
    );
    await assertFails(edit('boss', { status: 'finished' }, 6));
    await assertFails(edit('boss', { status: 'done', paidMinor: null }, 6));
  });

  test('a worker changes nothing, not even a job they help on', async () => {
    await seedCrew();
    await seedJob('j1', 'boss', { workers: ['ana'], helpers: [{ uid: 'ana', payMinor: 300000 }] });
    await assertFails(edit('ana', { notes: 'Kasnim 10 min' }));
    await assertFails(edit('ana', { status: 'done', paidMinor: 2500000, toWallet: true, doneBy: 'ana', doneAt: serverTimestamp() }));
    await assertFails(edit('ana', { status: 'cancelled' }));
    await assertFails(edit('ana', { helpers: [{ uid: 'ana', payMinor: 900000 }] }));
    await assertFails(edit('bob', { address: 'Zvezdara' }));
  });

  test('rev counts up by exactly one, as the one who saves', async () => {
    await seedCrew();
    await seedJob('j1', 'boss', { rev: 3 });
    await assertFails(edit('boss', { notes: 'x' }, 3));
    await assertFails(edit('boss', { notes: 'x' }, 5));
    await assertFails(edit('boss', { notes: 'x', updatedBy: 'ana' }, 4));
    await assertSucceeds(edit('boss', { notes: 'x' }, 4));
  });

  test('nobody writes pushRev or pushStatus, or changes the author', async () => {
    await seedCrew();
    await seedJob('j1', 'ana', { pushRev: 1, pushStatus: 'booked' });
    await assertFails(edit('boss', { pushRev: 2 }));
    await assertFails(edit('boss', { pushStatus: 'cancelled' }));
    await assertFails(edit('boss', { ownerId: 'boss' }));
    await assertFails(edit('boss', { createdAt: serverTimestamp() }));
    // The worker's marks already on the job, and a worker as its author
    // (from before v1.2.0), do not get in the way.
    await assertSucceeds(edit('boss', { notes: 'Pozvati pre dolaska' }));
  });
});

describe('deleting a job', () => {
  test('only the admin, even for a job a worker booked before v1.2.0', async () => {
    await seedCrew();
    await seedJob('j1', 'ana');
    await seedJob('j2', 'boss');
    await assertFails(deleteDoc(doc(as('ana'), 'jobs/j1')));
    await assertFails(deleteDoc(doc(as('bob'), 'jobs/j2')));
    await assertFails(deleteDoc(doc(as('gone'), 'jobs/j2')));
    await assertSucceeds(deleteDoc(doc(as('boss'), 'jobs/j1')));
    await assertSucceeds(deleteDoc(doc(as('boss'), 'jobs/j2')));
  });
});
