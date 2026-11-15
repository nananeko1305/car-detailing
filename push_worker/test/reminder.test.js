import assert from 'node:assert/strict';
import { test } from 'node:test';

import worker from '../src/index.js';
import { crewDocs, DEAD, env, fakeNetwork } from './fake.js';

// 21:00 in Belgrade: 20:00 UTC in winter, 19:00 UTC in summer.
const WINTER_21 = new Date('2026-11-15T20:00:00Z');
const WINTER_20 = new Date('2026-11-15T19:00:00Z');
const SUMMER_21 = new Date('2026-07-01T19:00:00Z');
const SUMMER_22 = new Date('2026-07-01T20:00:00Z');

const job = (date, start, extra = {}) => ({
  date,
  start,
  clientName: '',
  notes: '',
  status: 'booked',
  ...extra,
});

const tomorrowJobs = (date) => ({
  'jobs/a': job(date, '12:00', { notes: 'Passat karavan\nključ kod portira' }),
  'jobs/b': job(date, '09:00', { clientName: 'Jelena Marković' }),
  'jobs/c': job(date, '16:30', { clientName: 'Ana Ristić', notes: 'treći sprat' }),
  'jobs/d': job(date, '10:00', { clientName: 'Otkazan', status: 'cancelled' }),
  'jobs/e': job(date, '11:00', { clientName: 'Gotov', status: 'done' }),
  'jobs/f': job('2030-01-01', '08:00', { clientName: 'Drugi dan' }),
});

const run = (at) => worker.scheduled({ scheduledTime: at.getTime(), cron: '' }, env);

test('at 21:00 one push per phone lists tomorrow’s booked jobs', async () => {
  const world = fakeNetwork({ ...crewDocs(), ...tomorrowJobs('2026-11-16') });
  await run(WINTER_21);
  // Every active user's phones, the admin's too; not the disabled user's.
  assert.deepEqual(world.sent.map((m) => m.token).sort(), [DEAD, 'tAna', 'tBob', 'tBoss'].sort());
  const text = '3 posla: 09:00 Jelena M. · 12:00 Passat karavan · 16:30 Ana R.';
  for (const m of world.sent) {
    assert.deepEqual(m.data, { type: 'reminder', kind: 'jobTomorrow', date: '2026-11-16', text });
    assert.deepEqual(m.android.notification, {
      title_loc_key: 'job_tomorrow_title',
      body: text,
      channel_id: 'reminders',
    });
  }
  assert.deepEqual(world.doc('meta/reminder'), { day: '2026-11-16' });
  assert.equal(world.log[0], 'write meta/reminder');
  assert.equal(world.store.has(`pushTokens/${DEAD}`), false);
});

test('the reminder goes out once per day', async () => {
  const world = fakeNetwork({ ...crewDocs(), ...tomorrowJobs('2026-11-16') });
  await run(WINTER_21);
  world.sent.length = 0;
  await run(WINTER_21);
  assert.equal(world.sent.length, 0);
  // The next evening is a new day, with a marker that already exists.
  const next = fakeNetwork({
    ...crewDocs(),
    ...tomorrowJobs('2026-11-17'),
    'meta/reminder': { day: '2026-11-16' },
  });
  await run(new Date('2026-11-16T20:00:00Z'));
  assert.equal(next.sent.length, 4);
  assert.deepEqual(next.doc('meta/reminder'), { day: '2026-11-17' });
});

test('only in the 21:00 hour in Belgrade, summer and winter', async () => {
  const winter = fakeNetwork({ ...crewDocs(), ...tomorrowJobs('2026-11-16') });
  await run(WINTER_20);
  assert.equal(winter.requests, 0);
  const summer = fakeNetwork({ ...crewDocs(), ...tomorrowJobs('2026-07-02') });
  await run(SUMMER_22);
  assert.equal(summer.requests, 0);
  await run(SUMMER_21);
  assert.equal(summer.sent.length, 4);
  assert.deepEqual(summer.doc('meta/reminder'), { day: '2026-07-02' });
});

test('a day without booked jobs is recorded and sends nothing', async () => {
  const world = fakeNetwork({
    ...crewDocs(),
    'jobs/x': job('2026-11-16', '09:00', { status: 'cancelled' }),
  });
  await run(WINTER_21);
  assert.equal(world.sent.length, 0);
  assert.deepEqual(world.doc('meta/reminder'), { day: '2026-11-16' });
});

test('a run that loses the marker to another sends nothing', async () => {
  const world = fakeNetwork({
    ...crewDocs(),
    ...tomorrowJobs('2026-11-16'),
    'meta/reminder': { day: '2026-11-15' },
  });
  world.loseCommits = 1;
  await run(WINTER_21);
  assert.equal(world.sent.length, 0);
});
