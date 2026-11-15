import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

import { as, entry, job, profile, seed, seedCrew, seedJob } from './setup.js';

describe('admin claim', () => {
  const claim = (uid) => {
    const db = as(uid);
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${uid}`), profile('admin'));
    batch.set(doc(db, 'meta/admin'), { uid });
    return batch.commit();
  };

  test('the first account becomes the admin, once', async () => {
    await assertSucceeds(getDoc(doc(as('first'), 'meta/admin')));
    await assertSucceeds(claim('first'));
    await assertFails(claim('second'));
    // Once the marker exists, a profile alone must not make anyone admin.
    await assertFails(setDoc(doc(as('second'), 'users/second'), profile('admin')));
    await assertFails(setDoc(doc(as('first'), 'meta/admin'), { uid: 'first' }));
  });

  test('no claim without the marker, or for someone else', async () => {
    await assertFails(setDoc(doc(as('x'), 'users/x'), profile('admin')));
    await assertFails(setDoc(doc(as('x'), 'users/x'), profile('worker')));
    await assertFails(setDoc(doc(as('x'), 'meta/admin'), { uid: 'x' }));
    const db = as('x');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/y'), profile('admin'));
    batch.set(doc(db, 'meta/admin'), { uid: 'y' });
    await assertFails(batch.commit());
  });
});

describe('users', () => {
  test('the admin adds workers; a worker adds nobody', async () => {
    await seedCrew();
    await assertSucceeds(setDoc(doc(as('boss'), 'users/new1'), profile('worker')));
    await assertFails(setDoc(doc(as('boss'), 'users/new2'), profile('admin')));
    await assertFails(setDoc(doc(as('boss'), 'users/new3'), profile('worker', { disabled: true })));
    await assertFails(setDoc(doc(as('ana'), 'users/new4'), profile('worker')));
  });

  test('nobody changes a role or an email', async () => {
    await seedCrew();
    await assertFails(updateDoc(doc(as('ana'), 'users/ana'), { role: 'admin' }));
    await assertFails(updateDoc(doc(as('ana'), 'users/bob'), { role: 'admin' }));
    await assertFails(updateDoc(doc(as('boss'), 'users/ana'), { role: 'admin' }));
    await assertFails(updateDoc(doc(as('boss'), 'users/ana'), { email: 'x@x.rs' }));
    await assertFails(updateDoc(doc(as('boss'), 'users/boss'), { role: 'worker' }));
  });

  test('the admin edits and disables others, never themself', async () => {
    await seedCrew();
    const ref = (path) => doc(as('boss'), path);
    await assertSucceeds(updateDoc(ref('users/ana'), { firstName: 'Ana', phone: '+38160' }));
    await assertSucceeds(updateDoc(ref('users/ana'), { disabled: true }));
    await assertSucceeds(updateDoc(ref('users/gone'), { disabled: false }));
    await assertFails(updateDoc(ref('users/boss'), { disabled: true }));
    await assertFails(updateDoc(ref('users/bob'), { disabled: 'yes' }));
  });

  test('everyone edits their own name and phone, nobody else’s', async () => {
    await seedCrew();
    await assertSucceeds(updateDoc(doc(as('ana'), 'users/ana'), { lastName: 'Ilić', phone: '061' }));
    await assertSucceeds(updateDoc(doc(as('boss'), 'users/boss'), { firstName: 'Šef' }));
    await assertFails(updateDoc(doc(as('ana'), 'users/ana'), { disabled: true }));
    await assertFails(updateDoc(doc(as('ana'), 'users/bob'), { firstName: 'X' }));
    await assertFails(updateDoc(doc(as('ana'), 'users/ana'), { firstName: 'x'.repeat(51) }));
    await assertFails(deleteDoc(doc(as('boss'), 'users/ana')));
  });
});

describe('a disabled user', () => {
  test('is denied everything but their own profile and signing out', async () => {
    await seedCrew();
    await seedJob('j1', 'ana');
    await seed('walletEntries/w1', { ...entry('ana'), updatedAt: new Date() });
    await seed('pushTokens/t1', { uid: 'gone' });
    const db = as('gone');
    await assertSucceeds(getDoc(doc(db, 'users/gone')));
    await assertFails(getDoc(doc(db, 'users/ana')));
    await assertFails(getDocs(collection(db, 'users')));
    await assertFails(getDocs(collection(db, 'jobs')));
    await assertFails(getDoc(doc(db, 'jobs/j1')));
    await assertFails(setDoc(doc(db, 'jobs/x'), job('gone')));
    await assertFails(updateDoc(doc(db, 'jobs/j1'), { notes: 'x' }));
    await assertFails(getDocs(collection(db, 'walletEntries')));
    await assertFails(setDoc(doc(db, 'walletEntries/x'), entry('gone')));
    await assertFails(getDocs(collection(db, 'priceItems')));
    await assertFails(getDoc(doc(db, 'meta/pricing')));
    await assertFails(updateDoc(doc(db, 'users/gone'), { firstName: 'X' }));
    await assertFails(setDoc(doc(db, 'pushTokens/t2'), { uid: 'gone' }));
    await assertSucceeds(deleteDoc(doc(db, 'pushTokens/t1')));
  });

  test('signed out reads and writes nothing', async () => {
    await seedCrew();
    await assertFails(getDoc(doc(as(null), 'meta/admin')));
    await assertFails(getDocs(collection(as(null), 'users')));
    await assertFails(getDocs(collection(as(null), 'jobs')));
  });

  test('a signed-in account without a profile sees nothing either', async () => {
    await seedCrew();
    await assertSucceeds(getDoc(doc(as('stranger'), 'users/stranger')));
    await assertFails(getDocs(collection(as('stranger'), 'jobs')));
    await assertFails(getDocs(collection(as('stranger'), 'users')));
  });
});

describe('push tokens and worker documents', () => {
  test('a token belongs to whoever saves it, and only the worker reads it', async () => {
    await seedCrew();
    await assertSucceeds(setDoc(doc(as('ana'), 'pushTokens/t1'), { uid: 'ana' }));
    await assertFails(setDoc(doc(as('ana'), 'pushTokens/t2'), { uid: 'bob' }));
    await assertFails(getDoc(doc(as('ana'), 'pushTokens/t1')));
    await assertFails(deleteDoc(doc(as('bob'), 'pushTokens/t1')));
    await assertSucceeds(deleteDoc(doc(as('ana'), 'pushTokens/t1')));
  });

  test('meta/reminder is the worker’s alone, even for the admin', async () => {
    await seedCrew();
    await seed('meta/reminder', { day: '2026-11-16' });
    await assertFails(getDoc(doc(as('boss'), 'meta/reminder')));
    await assertFails(setDoc(doc(as('boss'), 'meta/reminder'), { day: '2026-11-17' }));
    await assertFails(setDoc(doc(as('boss'), 'meta/other'), { x: 1 }));
  });
});
