// POST /announce: the phone that saved a job asks the worker to tell the rest
// of the crew. The job says what is due (`rev` ahead of `pushRev`); the
// request only says where to look, so a repeated or forged call can at most
// repeat nothing.

import { crewPhones, isActive, sendTo } from './crew.js';
import { dayInBelgrade, jobMessage } from './message.js';

const CLAIM_ATTEMPTS = 2;

export const KINDS = ['job'];

/** Whether [job] has a change the crew has not been told about. */
export const isDue = (job) => (job.pushRev ?? 0) < (job.rev ?? 1);

/**
 * The push a job's state calls for, from the status announced last
 * (`pushStatus`, missing when never announced), or null when the change is
 * only marked: a finished job, a past day, or a cancellation of a job nobody
 * was ever told about.
 */
export function jobPushKind(job, today) {
  const told = job.pushStatus ?? '';
  if (typeof job.date !== 'string' || job.date < today) return null;
  if (job.status === 'booked') return told ? 'jobChanged' : 'jobNew';
  if (job.status === 'cancelled' && told && told !== 'cancelled') return 'jobCancelled';
  return null;
}

/**
 * Handles one announcement by [uid] about job [id]. Returns {status} for the
 * HTTP answer: 200 with {sent} when done or nothing was due, 403 when [uid]
 * may not ask, 404 when the job is gone, 409 when another write kept winning.
 */
export async function announce(google, crew, uid, id, now) {
  if (!isActive(crew.users.get(uid))) return { status: 403 };
  const path = `jobs/${id}`;
  let job = await google.get(path);
  // Mark first, send second: if FCM fails right then, that push is lost, but
  // nothing is ever sent twice.
  for (let attempt = 1; ; attempt++) {
    if (!job) return { status: 404 };
    // Checked on every read: after a newer edit, its author's call tells.
    if (job.updatedBy !== uid) return { status: 403 };
    if (!isDue(job)) return { status: 200, sent: 0 };
    const mark = { pushRev: job.rev ?? 1, pushStatus: String(job.status ?? '') };
    if (await google.writeIf(path, mark, job.updateTime)) break;
    if (attempt === CLAIM_ATTEMPTS) return { status: 409 };
    job = await google.get(path);
  }
  const kind = jobPushKind(job, dayInBelgrade(now));
  if (!kind) return { status: 200, sent: 0 };
  const phones = crewPhones(crew, { except: uid });
  if (phones.length === 0) return { status: 200, sent: 0 };
  const { sent, stale } = await sendTo(google, phones, jobMessage(kind, job));
  await google.deleteTokens(stale);
  return { status: 200, sent };
}
