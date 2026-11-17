// v1.1.2: the final discount, a whole percent from 0 to 100 on top of the
// price list's. Old jobs and older apps leave it out, and must keep working.

import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, increment, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

import { as, job, seedCrew, seedJob } from './setup.js';

/** JobRepository._write, as the app sends it. */
const write = (uid, fields) =>
  updateDoc(doc(as(uid), 'jobs/j1'), {
    ...fields,
    rev: increment(1),
    updatedBy: uid,
    updatedAt: serverTimestamp(),
  });

const book = (id, changes) => setDoc(doc(as('boss'), `jobs/${id}`), job('boss', changes));

describe('final discount', () => {
  test('a booking may give a final discount from 0 to 100 percent', async () => {
    await seedCrew();
    await assertSucceeds(book('a', { finalDiscountPercent: 5 }));
    await assertSucceeds(book('b', { finalDiscountPercent: 0 }));
    await assertSucceeds(book('c', { finalDiscountPercent: 100 }));
  });

  test('anything else is refused', async () => {
    await seedCrew();
    await assertFails(book('a', { finalDiscountPercent: -1 }));
    await assertFails(book('b', { finalDiscountPercent: 101 }));
    await assertFails(book('c', { finalDiscountPercent: 2.5 }));
    await assertFails(book('d', { finalDiscountPercent: '5' }));
  });

  test('an older job, without it, gets one from the new app', async () => {
    await seedCrew();
    // The live job's shape on 2026-11-17: no helpers, no final discount.
    await seedJob('j1', 'boss', { rev: 3, workers: ['boss'] });
    await assertSucceeds(write('ana', { finalDiscountPercent: 10, priceMinor: 1080000 }));
  });

  test('an older app still edits a job that has one', async () => {
    await seedCrew();
    await seedJob('j1', 'boss', { rev: 2, finalDiscountPercent: 5 });
    await assertSucceeds(write('ana', { notes: 'Golf 7, crni', workers: ['ana'] }));
  });
});
