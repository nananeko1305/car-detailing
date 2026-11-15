import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

import { as, job, seedCrew, seedJob } from './setup.js';

/** An edit the way the app writes it: the change, plus the bookkeeping. */
const edit = (uid, changes = {}, rev = 2) =>
  updateDoc(doc(as(uid), 'jobs/j1'), {
    rev,
    updatedBy: uid,
    updatedAt: serverTimestamp(),
    ...changes,
  });

describe('booking a job', () => {
  test('anyone active books, as themselves', async () => {
    await seedCrew();
    const create = (id, uid, changes) => setDoc(doc(as(uid), `jobs/${id}`), job(uid, changes));
    await assertSucceeds(create('a', 'ana'));
    await assertSucceeds(create('b', 'boss'));
    await assertSucceeds(create('c', 'ana', { items: [], notes: 'Passat karavan', end: '11:30' }));
    await assertFails(setDoc(doc(as('ana'), 'jobs/d'), job('bob')));
    await assertFails(create('e', 'ana', { updatedBy: 'bob' }));
    await assertFails(create('f', 'ana', { rev: 2 }));
    await assertFails(create('g', 'ana', { status: 'cancelled' }));
  });

  test('a booked job may leave out what is filled in when done', async () => {
    await seedCrew();
    const bare = job('ana');
    for (const key of ['paidMinor', 'toWallet', 'doneBy', 'doneAt']) delete bare[key];
    await assertSucceeds(setDoc(doc(as('ana'), 'jobs/a'), bare));
    const missing = job('ana');
    delete missing.travelMinor;
    await assertFails(setDoc(doc(as('ana'), 'jobs/b'), missing));
  });

  test('a job done on the spot needs what was paid', async () => {
    await seedCrew();
    const done = { status: 'done', doneBy: 'ana', doneAt: serverTimestamp(), toWallet: true };
    await assertFails(setDoc(doc(as('ana'), 'jobs/a'), job('ana', done)));
    await assertSucceeds(setDoc(doc(as('ana'), 'jobs/b'), job('ana', { ...done, paidMinor: 2700000 })));
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
      await assertFails(setDoc(doc(as('ana'), `jobs/bad${i}`), job('ana', changes)));
    }
  });
});

describe('changing a job', () => {
  test('anyone active edits, finishes or cancels anyone’s job', async () => {
    await seedCrew();
    await seedJob('j1', 'ana');
    await assertSucceeds(edit('bob', { address: 'Zvezdara', workers: ['ana', 'bob'] }));
    await assertSucceeds(edit('boss', { status: 'cancelled' }, 3));
    await assertSucceeds(edit('ana', { status: 'booked' }, 4));
    await assertSucceeds(
      edit('bob', { status: 'done', paidMinor: 2500000, toWallet: true, doneBy: 'bob', doneAt: serverTimestamp() }, 5),
    );
    await assertFails(edit('bob', { status: 'finished' }, 6));
    await assertFails(edit('bob', { status: 'done', paidMinor: null }, 6));
  });

  test('rev counts up by exactly one, as the one who saves', async () => {
    await seedCrew();
    await seedJob('j1', 'ana', { rev: 3 });
    await assertFails(edit('bob', { notes: 'x' }, 3));
    await assertFails(edit('bob', { notes: 'x' }, 5));
    await assertFails(edit('bob', { notes: 'x', updatedBy: 'ana' }, 4));
    await assertSucceeds(edit('bob', { notes: 'x' }, 4));
  });

  test('nobody writes pushRev or pushStatus, or changes the author', async () => {
    await seedCrew();
    await seedJob('j1', 'ana', { pushRev: 1, pushStatus: 'booked' });
    for (const uid of ['ana', 'boss']) {
      await assertFails(edit(uid, { pushRev: 2 }));
      await assertFails(edit(uid, { pushStatus: 'cancelled' }));
      await assertFails(edit(uid, { ownerId: 'bob' }));
      await assertFails(edit(uid, { createdAt: serverTimestamp() }));
    }
    // The worker's marks already on the job do not get in the way.
    await assertSucceeds(edit('bob', { notes: 'Pozvati pre dolaska' }));
  });
});

describe('deleting a job', () => {
  test('only its author or the admin', async () => {
    await seedCrew();
    await seedJob('j1', 'ana');
    await seedJob('j2', 'bob');
    await assertFails(deleteDoc(doc(as('bob'), 'jobs/j1')));
    await assertFails(deleteDoc(doc(as('gone'), 'jobs/j2')));
    await assertSucceeds(deleteDoc(doc(as('ana'), 'jobs/j1')));
    await assertSucceeds(deleteDoc(doc(as('boss'), 'jobs/j2')));
  });
});
