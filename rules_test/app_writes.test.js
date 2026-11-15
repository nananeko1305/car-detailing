// The writes exactly as lib/services/*_repository.dart sends them: the
// increment on `rev`, server times, finishing, reopening, a walk-in job and
// the admin loading the price list in one batch.

import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  doc,
  increment,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

import { as, job, seedCrew, seedJob } from './setup.js';

/** JobRepository._write */
const write = (uid, fields) =>
  updateDoc(doc(as(uid), 'jobs/j1'), {
    ...fields,
    rev: increment(1),
    updatedBy: uid,
    updatedAt: serverTimestamp(),
  });

describe('the app as written', () => {
  test('finish, reopen and cancel go through with rev: increment(1)', async () => {
    await seedCrew();
    await seedJob('j1', 'boss', { rev: 1 });
    await assertSucceeds(
      write('ana', {
        status: 'done',
        paidMinor: 2700000,
        toWallet: true,
        workers: ['ana', 'bob'],
        doneBy: 'ana',
        doneAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      write('bob', { status: 'booked', paidMinor: null, doneBy: '', doneAt: null }),
    );
    await assertSucceeds(write('ana', { status: 'cancelled' }));
    await assertFails(write('gone', { status: 'booked' }));
  });

  test('a walk-in job is created done with the phone time', async () => {
    await seedCrew();
    await assertSucceeds(
      setDoc(
        doc(as('ana'), 'jobs/walkin'),
        job('ana', {
          status: 'done',
          paidMinor: 550000,
          toWallet: true,
          doneBy: 'ana',
          doneAt: Timestamp.fromDate(new Date()),
        }),
      ),
    );
  });

  test('the admin loads the whole price list in one batch', async () => {
    await seedCrew();
    const load = (uid) => {
      const db = as(uid);
      const batch = writeBatch(db);
      batch.set(doc(db, 'priceCategories/c1'), {
        name: 'Dušeci',
        note: '',
        order: 0,
        archived: false,
      });
      for (let i = 0; i < 5; i++) {
        batch.set(doc(db, `priceItems/i${i}`), {
          categoryId: 'c1',
          name: `Dušek ${i}`,
          priceMinor: 110000,
          order: i,
          archived: false,
        });
      }
      batch.set(doc(db, 'meta/pricing'), {
        discounts: [
          { overMinor: 600000, percent: 10 },
          { overMinor: 1000000, percent: 15 },
        ],
        freeTravelFromMinor: 250000,
      travelMinor: 0,
      });
      return batch.commit();
    };
    await assertFails(load('ana'));
    await assertSucceeds(load('boss'));
  });
});
