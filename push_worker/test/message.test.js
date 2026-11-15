import assert from 'node:assert/strict';
import { test } from 'node:test';

import { decodeValue } from '../src/codec.js';
import {
  addDays,
  clip,
  dayInBelgrade,
  dayLabel,
  hourInBelgrade,
  jobBody,
  jobCount,
  JOB_BODY_MAX,
  message,
  reminderBody,
  shortName,
} from '../src/message.js';

test('Belgrade days and hours across daylight saving', () => {
  // 23:30 UTC on 25 October 2026 is 00:30 on the 26th in Belgrade (winter).
  assert.equal(dayInBelgrade(new Date('2026-10-25T23:30:00Z')), '2026-10-26');
  assert.equal(hourInBelgrade(new Date('2026-07-01T19:00:00Z')), 21);
  assert.equal(hourInBelgrade(new Date('2026-12-01T20:00:00Z')), 21);
});

test('days move by the calendar', () => {
  assert.equal(addDays('2026-10-31', 1), '2026-11-01');
  assert.equal(addDays('2026-03-01', -1), '2026-02-28');
  assert.equal(addDays('2026-12-31', 2), '2027-01-02');
});

test('a day reads short, in Serbian', () => {
  assert.equal(dayLabel('2026-11-16'), 'Pon 16. nov');
  assert.equal(dayLabel('2026-11-15'), 'Ned 15. nov');
  assert.equal(dayLabel('2026-08-06'), 'Čet 6. avg');
});

test('a job in one line: items with counts, or the notes', () => {
  const job = {
    date: '2026-11-16',
    start: '09:00',
    address: 'Vračar',
    items: [
      { name: 'Ugaona garnitura', qty: 6 },
      { name: 'Fotelja', qty: 1 },
    ],
    notes: 'ne piše se',
  };
  assert.equal(jobBody(job), 'Pon 16. nov · 09:00 · Ugaona garnitura × 6, Fotelja · Vračar');
  assert.equal(
    jobBody({ ...job, items: [], notes: 'Passat karavan\nključ kod portira', address: '' }),
    'Pon 16. nov · 09:00 · Passat karavan',
  );
  const long = jobBody({ ...job, items: Array.from({ length: 30 }, () => ({ name: 'Tepih', qty: 2 })) });
  assert.ok([...long].length <= JOB_BODY_MAX);
  assert.ok(long.endsWith('Vračar'));
});

test('cut text ends in an ellipsis', () => {
  assert.equal(clip('kratko', 10), 'kratko');
  assert.equal(clip('a'.repeat(12), 10), `${'a'.repeat(9)}…`);
});

test('counts and names the Serbian way', () => {
  assert.deepEqual([1, 2, 4, 5, 11, 12, 21, 22, 25].map(jobCount), [
    '1 posao', '2 posla', '4 posla', '5 poslova', '11 poslova', '12 poslova',
    '21 posao', '22 posla', '25 poslova',
  ]);
  assert.equal(shortName('Jelena Marković'), 'Jelena M.');
  assert.equal(shortName('Ana Marija ristić'), 'Ana R.');
  assert.equal(shortName('  Firma  '), 'Firma');
  assert.equal(shortName(''), '');
});

test('the reminder lists jobs by start time', () => {
  assert.equal(
    reminderBody([
      { start: '16:30', clientName: 'Ana Ristić' },
      { start: '09:00', clientName: 'Jelena Marković' },
      { start: '12:00', clientName: '', notes: 'Passat karavan' },
    ]),
    '3 posla: 09:00 Jelena M. · 12:00 Passat karavan · 16:30 Ana R.',
  );
  assert.equal(reminderBody([{ start: '09:00', clientName: '' }]), '1 posao: 09:00');
});

test('every data value is a string, and the body is in data too', () => {
  const m = message('jobNew', 'tekst', { jobId: 'j1', date: '2026-11-16', extra: 5 });
  for (const v of Object.values(m.data)) assert.equal(typeof v, 'string');
  assert.equal(m.data.text, 'tekst');
  assert.equal(m.android.notification.body, 'tekst');
  assert.equal(m.android.notification.channel_id, 'jobs');
  assert.equal(m.android.notification.title_loc_key, 'job_new_title');
  assert.equal(m.android.notification.title_loc_args, undefined);
  assert.throws(() => message('nope', ''));
});

test('job items come back from Firestore as plain maps', () => {
  const value = {
    arrayValue: {
      values: [
        { mapValue: { fields: { name: { stringValue: 'Fotelja' }, qty: { integerValue: '2' } } } },
      ],
    },
  };
  assert.deepEqual(decodeValue(value), [{ name: 'Fotelja', qty: 2 }]);
  assert.deepEqual(decodeValue({ arrayValue: {} }), []);
  assert.equal(decodeValue({ nullValue: null }), null);
});
