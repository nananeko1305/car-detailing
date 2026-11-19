import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, getDocs, collection, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

import { as, entry, seed, seedCrew } from './setup.js';

const seedEntry = (id, uid) => seed(`walletEntries/${id}`, { ...entry(uid), updatedAt: new Date() });

describe('wallet', () => {
  // Since v1.2.0 the wallet is the admin's alone.
  test('the admin adds an entry, as its author, for any user', async () => {
    await seedCrew();
    const add = (id, changes) => setDoc(doc(as('boss'), `walletEntries/${id}`), entry('boss', changes));
    await assertSucceeds(add('a'));
    await assertSucceeds(add('b', { type: 'withdrawal', userId: 'bob' }));
    await assertSucceeds(getDocs(collection(as('boss'), 'walletEntries')));
    await assertFails(setDoc(doc(as('boss'), 'walletEntries/c'), entry('bob')));
    await assertFails(add('d', { amountMinor: 0 }));
    await assertFails(add('e', { amountMinor: -100 }));
    await assertFails(add('f', { type: 'gift' }));
    await assertFails(add('g', { userId: 'nobody' }));
    await assertFails(add('h', { date: '2026-11-15' }));
    await assertFails(add('i', { currency: 'RSD' }));
  });

  test('a worker neither reads nor writes it', async () => {
    await seedCrew();
    await seedEntry('w1', 'boss');
    await assertFails(getDocs(collection(as('ana'), 'walletEntries')));
    await assertFails(getDoc(doc(as('ana'), 'walletEntries/w1')));
    await assertFails(setDoc(doc(as('ana'), 'walletEntries/a'), entry('ana')));
    await assertFails(
      setDoc(doc(as('ana'), 'walletEntries/b'), entry('ana', { type: 'withdrawal' })),
    );
  });

  test('the admin changes or deletes any entry; its author stays', async () => {
    await seedCrew();
    // w1 was written by a worker before v1.2.0.
    await seedEntry('w1', 'ana');
    await seedEntry('w2', 'boss');
    const change = (uid, changes = {}) =>
      updateDoc(doc(as(uid), 'walletEntries/w1'), {
        description: 'Ispravka',
        updatedAt: serverTimestamp(),
        ...changes,
      });
    await assertFails(change('ana'));
    await assertFails(deleteDoc(doc(as('ana'), 'walletEntries/w1')));
    await assertFails(change('bob'));
    await assertSucceeds(change('boss', { amountMinor: 900000 }));
    await assertFails(change('boss', { createdBy: 'boss' }));
    await assertSucceeds(deleteDoc(doc(as('boss'), 'walletEntries/w1')));
    await assertSucceeds(deleteDoc(doc(as('boss'), 'walletEntries/w2')));
  });
});

describe('price list', () => {
  const category = { name: 'Nameštaj', note: '', order: 1, archived: false };
  const item = { categoryId: 'c1', name: 'Fotelja', priceMinor: 150000, order: 1, archived: false };
  const pricing = {
    discounts: [{ overMinor: 2000000, percent: 10 }],
    freeTravelFromMinor: 1000000,
    travelMinor: 100000,
  };
  const writes = [
    ['priceCategories/c1', category],
    ['priceItems/i1', item],
    ['meta/pricing', pricing],
  ];

  test('a worker reads it and cannot write it', async () => {
    await seedCrew();
    for (const [path, data] of writes) {
      await seed(path, data);
      await assertSucceeds(getDoc(doc(as('ana'), path)));
      await assertFails(setDoc(doc(as('ana'), path), data));
      await assertFails(setDoc(doc(as('ana'), `${path}x`), data));
    }
  });

  test('the admin writes it, with the right shape', async () => {
    await seedCrew();
    for (const [path, data] of writes) {
      await assertSucceeds(setDoc(doc(as('boss'), path), data));
      await assertSucceeds(updateDoc(doc(as('boss'), path), data));
    }
    await assertSucceeds(updateDoc(doc(as('boss'), 'priceItems/i1'), { archived: true }));
    await assertFails(setDoc(doc(as('boss'), 'priceItems/i2'), { ...item, priceMinor: -1 }));
    await assertFails(setDoc(doc(as('boss'), 'priceItems/i3'), { ...item, name: '' }));
    await assertFails(setDoc(doc(as('boss'), 'priceItems/i4'), { ...item, currency: 'RSD' }));
    await assertFails(setDoc(doc(as('boss'), 'priceCategories/c2'), { ...category, order: '1' }));
    await assertFails(setDoc(doc(as('boss'), 'meta/pricing'), { ...pricing, travelMinor: -1 }));
  });

  test('nobody deletes from it, not even the admin', async () => {
    await seedCrew();
    for (const [path, data] of writes) {
      await seed(path, data);
      await assertFails(deleteDoc(doc(as('boss'), path)));
      await assertFails(deleteDoc(doc(as('ana'), path)));
    }
  });
});
