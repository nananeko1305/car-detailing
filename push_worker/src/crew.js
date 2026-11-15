// Who is on the crew right now and which phones they have; shared by the
// route and the cron. The worker skips the Firestore rules, so these checks
// are its own.

// The free plan allows 50 outside calls per run; a run spends a handful on
// signing in, reading and marking, the rest on pushes.
export const MAX_SENDS = 40;

/** Everything a run needs to know about the crew, in two reads. */
export async function loadCrew(google) {
  const [users, tokens] = await Promise.all([google.all('users'), google.all('pushTokens')]);
  return { users: new Map(users.map((u) => [u.id, u])), tokens };
}

/** Has a profile and is not disabled, as `isActive()` in firestore.rules. */
export const isActive = (user) => Boolean(user) && user.disabled !== true;

/**
 * The phones of every active user but [except] (who made the change and
 * knows), at most MAX_SENDS of them.
 */
export function crewPhones(crew, { except = '' } = {}) {
  const phones = crew.tokens.filter(
    (t) => t.uid !== except && isActive(crew.users.get(t.uid)),
  );
  if (phones.length > MAX_SENDS) {
    console.error(`${phones.length} phones, sending to the first ${MAX_SENDS}`);
  }
  return phones.slice(0, MAX_SENDS);
}

/**
 * Sends [message] to [phones]: how many went out, and the tokens FCM no
 * longer knows, for the caller to delete.
 */
export async function sendTo(google, phones, message) {
  const results = await Promise.all(
    phones.map(async (phone) => ({
      token: phone.id,
      result: await google.send(phone.id, message),
    })),
  );
  const failed = results.filter((r) => r.result === 'failed').length;
  if (failed > 0) console.error(`${failed} of ${results.length} pushes failed`);
  return {
    sent: results.filter((r) => r.result === 'sent').length,
    stale: results.filter((r) => r.result === 'unregistered').map((r) => r.token),
  };
}
