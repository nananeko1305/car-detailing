// The evening reminder: at 21:00 in Belgrade, one push to every phone of the
// crew listing tomorrow's booked jobs. `meta/reminder {day}` holds the day
// already reminded about, so a repeated run that evening sends nothing.

import { crewPhones, loadCrew, sendTo } from './crew.js';
import { addDays, dayInBelgrade, hourInBelgrade, reminderMessage } from './message.js';

export const REMINDER_HOUR = 21;

const MARKER = 'meta/reminder';

/** Both crons fire (summer and winter time); only one is 21:00 in Belgrade. */
export const isReminderHour = (now) => hourInBelgrade(now) === REMINDER_HOUR;

/** Sends the reminder if it is due at [now]; returns how many pushes went out. */
export async function runReminder(google, now) {
  if (!isReminderHour(now)) return 0;
  const tomorrow = addDays(dayInBelgrade(now), 1);
  const marker = await google.get(MARKER);
  if (marker?.day === tomorrow) return 0;
  const jobs = (await google.jobsOn(tomorrow)).filter(
    (job) => job.date === tomorrow && job.status === 'booked',
  );
  // Mark first, send second, as in announce.js: a lost push rather than a
  // double one. A day without jobs is marked too, so it is not looked at again.
  if (!(await google.writeIf(MARKER, { day: tomorrow }, marker?.updateTime ?? null))) return 0;
  if (jobs.length === 0) return 0;
  const phones = crewPhones(await loadCrew(google));
  if (phones.length === 0) return 0;
  const { sent, stale } = await sendTo(google, phones, reminderMessage(jobs, tomorrow));
  await google.deleteTokens(stale);
  return sent;
}
