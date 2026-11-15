// The text, dates and shape of the pushes: no I/O, so they can be tested
// alone. Bodies are plain Serbian (Latin) text built here; titles are string
// resources in the app, so each phone shows its own language.

const TIME_ZONE = 'Europe/Belgrade';
const HOUR_S = 60 * 60;

export const JOB_BODY_MAX = 120;
export const REMINDER_BODY_MAX = 200;

const DAYS = ['Ned', 'Pon', 'Uto', 'Sre', 'Čet', 'Pet', 'Sub'];
const MONTHS = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];

function partsInBelgrade(date, options) {
  const format = new Intl.DateTimeFormat('en-GB', { timeZone: TIME_ZONE, ...options });
  return Object.fromEntries(format.formatToParts(date).map((part) => [part.type, part.value]));
}

/** The day [date] falls on in Belgrade, as yyyy-MM-dd. */
export function dayInBelgrade(date) {
  const { year, month, day } = partsInBelgrade(date, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return `${year}-${month}-${day}`;
}

/** The hour (0-23) on the clock in Belgrade at [date]. */
export function hourInBelgrade(date) {
  return Number(partsInBelgrade(date, { hour: '2-digit', hourCycle: 'h23' }).hour);
}

/** [day] moved by [n] days, both as yyyy-MM-dd; calendar days, no clocks. */
export function addDays(day, n) {
  const [y, m, d] = day.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}

/** "2026-11-16" -> "Pon 16. nov". */
export function dayLabel(day) {
  const [y, m, d] = day.split('-').map(Number);
  const weekday = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  return `${DAYS[weekday]} ${d}. ${MONTHS[m - 1]}`;
}

/** [text] cut to [max] characters, ending in "…" when it had to be. */
export function clip(text, max) {
  const chars = [...text];
  if (chars.length <= max) return text;
  return `${chars.slice(0, max - 1).join('').trimEnd()}…`;
}

const firstLine = (text) => String(text ?? '').split('\n')[0].trim();

/** "Ugaona garnitura × 6, Fotelja": the items, with the count when over 1. */
export function itemsText(items) {
  return (Array.isArray(items) ? items : [])
    .map((item) => ({ name: firstLine(item?.name), qty: item?.qty }))
    .filter((item) => item.name)
    .map((item) => (Number.isInteger(item.qty) && item.qty > 1 ? `${item.name} × ${item.qty}` : item.name))
    .join(', ');
}

/** "Pon 16. nov · 09:00 · Ugaona garnitura × 6, Fotelja · Vračar". */
export function jobBody(job) {
  const what = itemsText(job.items) || firstLine(job.notes);
  const parts = [dayLabel(job.date), job.start, clip(what, 70), firstLine(job.address)];
  return clip(parts.filter((s) => s).join(' · '), JOB_BODY_MAX);
}

/** "1 posao", "3 posla", "5 poslova", "21 posao". */
export function jobCount(n) {
  const ten = n % 10;
  const hundred = n % 100;
  if (ten === 1 && hundred !== 11) return `${n} posao`;
  if (ten >= 2 && ten <= 4 && (hundred < 12 || hundred > 14)) return `${n} posla`;
  return `${n} poslova`;
}

/** "Jelena Marković" -> "Jelena M."; a single name stays as it is. */
export function shortName(name) {
  const words = firstLine(name).split(/\s+/).filter((w) => w);
  if (words.length < 2) return words[0] ?? '';
  return `${words[0]} ${[...words.at(-1)][0].toUpperCase()}.`;
}

const byStart = (a, b) => String(a.start ?? '').localeCompare(String(b.start ?? ''));

/** "3 posla: 09:00 Jelena M. · 12:00 Passat karavan · 16:30 Ana R.". */
export function reminderBody(jobs) {
  const lines = [...jobs]
    .sort(byStart)
    .map((job) => [job.start, shortName(job.clientName) || clip(firstLine(job.notes), 30)])
    .map((parts) => parts.filter((s) => s).join(' '));
  return clip(`${jobCount(jobs.length)}: ${lines.join(' · ')}`, REMINDER_BODY_MAX);
}

// Per kind: the title resource in the app (res/values*/strings.xml), the
// Android channel (created by the app), the data type the app routes on, and
// how long the push is worth delivering.
const KINDS = {
  jobNew: { title: 'job_new_title', channel: 'jobs', type: 'job', ttl: 2 * 24 * HOUR_S },
  jobChanged: { title: 'job_changed_title', channel: 'jobs', type: 'job', ttl: 2 * 24 * HOUR_S },
  jobCancelled: { title: 'job_cancelled_title', channel: 'jobs', type: 'job', ttl: 2 * 24 * HOUR_S },
  jobTomorrow: { title: 'job_tomorrow_title', channel: 'reminders', type: 'reminder', ttl: 12 * HOUR_S },
};

/**
 * The FCM message for [kind] with [text] as its body. The app shows a push
 * itself while open, so the body also goes in data as `text`. Every data
 * value is a string: FCM refuses anything else.
 */
export function message(kind, text, data = {}) {
  const spec = KINDS[kind];
  if (!spec) throw new Error(`Unknown push kind ${kind}`);
  const all = { type: spec.type, kind, ...data, text };
  return {
    data: Object.fromEntries(Object.entries(all).map(([k, v]) => [k, String(v ?? '')])),
    android: {
      priority: 'high',
      ttl: `${spec.ttl}s`,
      notification: { title_loc_key: spec.title, body: text, channel_id: spec.channel },
    },
  };
}

/** A new, changed or cancelled job. */
export const jobMessage = (kind, job) =>
  message(kind, jobBody(job), { jobId: job.id, date: job.date });

/** The evening reminder of [day]'s jobs. */
export const reminderMessage = (jobs, day) =>
  message('jobTomorrow', reminderBody(jobs), { date: day });
