// v1.1.0: helpers with their pay, and the equipment cost, on a job. Old jobs
// and v1.0.x apps leave both out, and must keep working.

import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, increment, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

import { as, job, seedCrew, seedJob } from './setup.js';

const helpers = [
  { uid: 'ana', payMinor: 300000 },
  { uid: 'bob', payMinor: 250000 },
];

/** JobRepository._write, as v1.1.0 sends it. */
const write = (uid, fields) =>
  updateDoc(doc(as(uid), 'jobs/j1'), {
    ...fields,
    rev: increment(1),
    updatedBy: uid,
    updatedAt: serverTimestamp(),
  });

describe('helpers and equipment', () => {
  test('a booking may name helpers with their pay and the equipment', async () => {
    await seedCrew();
    const book = (id, changes) =>
      setDoc(doc(as('boss'), `jobs/${id}`), job('boss', changes));
    await assertSucceeds(
      book('a', { helpers, equipmentMinor: 80000, workers: ['ana', 'bob'] }),
    );
    await assertSucceeds(book('b', { helpers: [], equipmentMinor: 0, workers: [] }));
  });

  test('wrong shapes are refused', async () => {
    await seedCrew();
    const book = (id, changes) =>
      setDoc(doc(as('boss'), `jobs/${id}`), job('boss', changes));
    await assertFails(book('a', { helpers: 'ana' }));
    await assertFails(book('b', { helpers: Array(11).fill({ uid: 'ana', payMinor: 0 }) }));
    await assertFails(book('c', { equipmentMinor: -1 }));
    await assertFails(book('d', { equipmentMinor: 1.5 }));
    await assertFails(book('e', { equipmentMinor: '500' }));
  });

  test('finishing writes the helpers and the equipment as they turned out', async () => {
    await seedCrew();
    await seedJob('j1', 'boss', { rev: 1 });
    await assertSucceeds(
      write('boss', {
        status: 'done',
        paidMinor: 2700000,
        toWallet: true,
        helpers,
        equipmentMinor: 120000,
        workers: ['ana', 'bob'],
        doneBy: 'boss',
        doneAt: serverTimestamp(),
      }),
    );
  });

  test('a job from v1.0.x, without them, is edited by the new app', async () => {
    await seedCrew();
    // The live job's shape on 2026-11-17: no helpers, no equipment.
    await seedJob('j1', 'boss', { rev: 3, workers: ['boss'] });
    await assertSucceeds(
      write('boss', { helpers, equipmentMinor: 50000, workers: ['ana', 'bob'] }),
    );
  });

  test('a v1.0.x app still edits a job that has them', async () => {
    await seedCrew();
    await seedJob('j1', 'boss', { rev: 2, helpers, equipmentMinor: 50000 });
    // The old app knows nothing of helpers: it sends only its own fields.
    await assertSucceeds(write('boss', { notes: 'Golf 7, crni', workers: ['ana'] }));
  });
});
