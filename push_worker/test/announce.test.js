import assert from 'node:assert/strict';
import { test } from 'node:test';

import { jobPushKind } from '../src/announce.js';
import worker from '../src/index.js';
import { addDays, dayInBelgrade } from '../src/message.js';
import { crewDocs, DEAD, env, fakeNetwork, idToken } from './fake.js';

const URL = 'https://car-detailing-push.car-expenses.workers.dev/announce';
const today = dayInBelgrade(new Date());

/** A job as the app saves it, booked by ana for tomorrow. */
const job = (extra = {}) => ({
  ownerId: 'ana',
  date: addDays(today, 1),
  start: '09:00',
  end: '',
  clientName: 'Jelena Marković',
  clientPhone: '',
  address: 'Vračar',
  items: [
    { itemId: 'i1', categoryId: 'c1', name: 'Ugaona garnitura', priceMinor: 500000, qty: 6 },
    { itemId: 'i2', categoryId: 'c1', name: 'Fotelja', priceMinor: 150000, qty: 1 },
  ],
  priceMinor: 3150000,
  workers: ['ana'],
  notes: '',
  status: 'booked',
  rev: 1,
  updatedBy: 'ana',
  ...extra,
});

async function call(uid, body = { kind: 'job', id: 'j1' }) {
  const response = await worker.fetch(
    new Request(URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${await idToken(uid)}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }),
    env,
  );
  return { status: response.status, body: response.status === 200 ? await response.json() : null };
}

const setup = (jobDoc) => fakeNetwork({ ...crewDocs(), 'jobs/j1': jobDoc });
const tokensSent = (world) => world.sent.map((m) => m.token).sort();

test('a new job is marked, then sent to everyone active but the actor', async () => {
  const world = setup(job());
  assert.deepEqual(await call('ana'), { status: 200, body: { sent: 2 } });
  // Not ana (who saved it), not the disabled user; bob's dead phone was tried.
  assert.deepEqual(tokensSent(world), [DEAD, 'tBob', 'tBoss'].sort());
  assert.equal(world.log[0], 'write jobs/j1');
  assert.ok(world.log.slice(1).every((entry) => !entry.startsWith('write')));
  assert.equal(world.doc('jobs/j1').pushRev, 1);
  assert.equal(world.doc('jobs/j1').pushStatus, 'booked');
  const m = world.sent[0];
  assert.deepEqual(m.android.notification, {
    title_loc_key: 'job_new_title',
    body: `${m.data.text}`,
    channel_id: 'jobs',
  });
  assert.deepEqual(m.data, {
    type: 'job',
    kind: 'jobNew',
    jobId: 'j1',
    date: addDays(today, 1),
    text: m.android.notification.body,
  });
  assert.match(m.data.text, /· 09:00 · Ugaona garnitura × 6, Fotelja · Vračar$/);
});

test('the dead token is deleted after the send', async () => {
  const world = setup(job());
  await call('ana');
  assert.equal(world.store.has(`pushTokens/${DEAD}`), false);
  assert.equal(world.store.has('pushTokens/tBob'), true);
});

test('a repeated call sends nothing', async () => {
  const world = setup(job());
  await call('ana');
  world.sent.length = 0;
  assert.deepEqual(await call('ana'), { status: 200, body: { sent: 0 } });
  assert.equal(world.sent.length, 0);
});

test('an edit after the announcement is a change, a cancellation a cancellation', async () => {
  const changed = setup(job({ rev: 2, pushRev: 1, pushStatus: 'booked', updatedBy: 'bob' }));
  await call('bob');
  assert.ok(changed.sent.every((m) => m.data.kind === 'jobChanged'));
  assert.deepEqual(tokensSent(changed), ['tAna', 'tBoss']);
  const cancelled = setup(job({ rev: 3, pushRev: 2, pushStatus: 'booked', status: 'cancelled' }));
  await call('ana');
  assert.ok(cancelled.sent.length > 0);
  assert.ok(cancelled.sent.every((m) => m.android.notification.title_loc_key === 'job_cancelled_title'));
  assert.equal(cancelled.doc('jobs/j1').pushStatus, 'cancelled');
});

test('done, cancelled before ever told, or a past day: marked, not sent', async () => {
  for (const extra of [
    { status: 'done', paidMinor: 3150000, rev: 2, pushRev: 1, pushStatus: 'booked' },
    { status: 'cancelled', rev: 2 },
    { date: addDays(today, -1) },
  ]) {
    const world = setup(job(extra));
    assert.deepEqual(await call('ana'), { status: 200, body: { sent: 0 } });
    assert.equal(world.sent.length, 0);
    assert.equal(world.doc('jobs/j1').pushRev, extra.rev ?? 1);
    assert.equal(world.doc('jobs/j1').pushStatus, extra.status ?? 'booked');
  }
});

test('only the one who saved it may ask, and only while active', async () => {
  const world = setup(job());
  assert.equal((await call('bob')).status, 403);
  assert.equal((await call('boss')).status, 403);
  const gone = setup(job({ updatedBy: 'gone' }));
  assert.equal((await call('gone')).status, 403);
  assert.equal((await call('stranger')).status, 403);
  assert.equal((await call('ana', { kind: 'job', id: 'nope' })).status, 404);
  assert.equal(world.sent.length + gone.sent.length, 0);
  assert.equal(world.doc('jobs/j1').pushRev, undefined);
});

test('requests that are not an announcement', async () => {
  setup(job());
  assert.equal((await call('ana', { kind: 'gig', id: 'j1' })).status, 400);
  assert.equal((await call('ana', { kind: 'job', id: '../users' })).status, 400);
  const get = await worker.fetch(new Request(URL), env);
  assert.equal(get.status, 405);
  const other = await worker.fetch(new Request(`${URL}x`, { method: 'POST' }), env);
  assert.equal(other.status, 404);
  const anonymous = await worker.fetch(new Request(URL, { method: 'POST', body: '{}' }), env);
  assert.equal(anonymous.status, 401);
  const forged = await worker.fetch(
    new Request(URL, { method: 'POST', headers: { Authorization: 'Bearer x.y.z' }, body: '{}' }),
    env,
  );
  assert.equal(forged.status, 401);
});

test('a lost race is tried again once, then given up', async () => {
  const world = setup(job());
  world.loseCommits = 1;
  assert.deepEqual(await call('ana'), { status: 200, body: { sent: 2 } });
  const stubborn = setup(job());
  stubborn.loseCommits = 5;
  assert.equal((await call('ana')).status, 409);
  assert.equal(stubborn.sent.length, 0);
});

test('which push a job calls for', () => {
  const day = '2026-11-16';
  const kind = (extra) => jobPushKind({ date: day, status: 'booked', ...extra }, '2026-11-15');
  assert.equal(kind({}), 'jobNew');
  assert.equal(kind({ pushStatus: 'booked' }), 'jobChanged');
  assert.equal(kind({ pushStatus: 'cancelled' }), 'jobChanged');
  assert.equal(kind({ status: 'cancelled', pushStatus: 'booked' }), 'jobCancelled');
  assert.equal(kind({ status: 'cancelled', pushStatus: 'cancelled' }), null);
  assert.equal(kind({ status: 'cancelled' }), null);
  assert.equal(kind({ status: 'done', pushStatus: 'booked' }), null);
  assert.equal(jobPushKind({ date: '2026-11-14', status: 'booked' }, '2026-11-15'), null);
  assert.equal(jobPushKind({ date: '2026-11-15', status: 'booked' }, '2026-11-15'), 'jobNew');
});
