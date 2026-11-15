// A stand-in for everything the worker reaches over the network: Firebase's
// token keys, Google sign-in, Firestore REST and FCM. Installed as the global
// fetch, so the worker runs end to end, ID token check included, offline.

import { exportJWK, exportPKCS8, generateKeyPair, SignJWT } from 'jose';

export const PROJECT = 'demo-car-detailing';
const ROOT = `projects/${PROJECT}/databases/(default)/documents`;
const FIRESTORE = `https://firestore.googleapis.com/v1/${ROOT}`;
const FCM = `https://fcm.googleapis.com/v1/projects/${PROJECT}/messages:send`;
const JWKS = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const TOKEN = 'https://oauth2.googleapis.com/token';

// Real FCM tokens have a ':', which a careless URL-encoding turns into another id.
export const DEAD = 'dead:APA91bX-y_z';

const firebase = await generateKeyPair('RS256', { extractable: true });
const account = await generateKeyPair('RS256', { extractable: true });
const publicJwk = { ...(await exportJWK(firebase.publicKey)), kid: 'test', alg: 'RS256', use: 'sig' };

export const env = {
  FIREBASE_PROJECT_ID: PROJECT,
  GOOGLE_SERVICE_ACCOUNT: JSON.stringify({
    client_email: 'push@demo.iam.gserviceaccount.com',
    private_key: await exportPKCS8(account.privateKey),
  }),
};

/** A Firebase ID token for [uid], as the app sends it. */
export const idToken = (uid) =>
  new SignJWT({})
    .setProtectedHeader({ alg: 'RS256', kid: 'test' })
    .setIssuer(`https://securetoken.google.com/${PROJECT}`)
    .setAudience(PROJECT)
    .setSubject(uid)
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(firebase.privateKey);

function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (Number.isInteger(v)) return { integerValue: String(v) };
  if (typeof v === 'number') return { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: v.length ? { values: v.map(toValue) } : {} };
  const fields = Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)]));
  return { mapValue: Object.keys(fields).length ? { fields } : {} };
}

function fromValue(v) {
  if ('integerValue' in v) return Number(v.integerValue);
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  throw new Error(`fake Firestore cannot read ${JSON.stringify(v)}`);
}

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
const failure = (status, code) => json(status, { error: { code: status, status: code } });

/**
 * Installs a fake network holding [docs] ({path: fields}) and returns what
 * it saw: `log` (writes and sends, in order), `sent`, `requests`, and
 * `loseCommits` to make the next conditional writes lose a race.
 */
export function fakeNetwork(docs = {}) {
  let clock = 0;
  const stamp = () => `2026-01-01T00:00:00.${String(++clock).padStart(6, '0')}Z`;
  const store = new Map(Object.entries(docs).map(([p, fields]) => [p, { fields, updateTime: stamp() }]));
  const world = { store, log: [], sent: [], requests: 0, loseCommits: 0, dead: new Set([DEAD]) };
  world.doc = (path) => store.get(path)?.fields ?? null;
  const asDocument = (path, d) => ({ name: `${ROOT}/${path}`, fields: toValue(d.fields).mapValue.fields ?? {}, updateTime: d.updateTime });

  function commit({ writes: [write] }) {
    const path = write.update.name.slice(ROOT.length + 1);
    const current = store.get(path);
    const pre = write.currentDocument ?? {};
    if (world.loseCommits > 0 && current) {
      // Someone else saved the document between the read and this write.
      world.loseCommits--;
      current.updateTime = stamp();
      return failure(400, 'FAILED_PRECONDITION');
    }
    if (pre.exists === false && current) return failure(409, 'ALREADY_EXISTS');
    if (pre.updateTime && !current) return failure(404, 'NOT_FOUND');
    if (pre.updateTime && current.updateTime !== pre.updateTime) return failure(400, 'FAILED_PRECONDITION');
    const fields = { ...(current?.fields ?? {}) };
    for (const key of write.updateMask.fieldPaths) fields[key] = fromValue(write.update.fields[key]);
    store.set(path, { fields, updateTime: stamp() });
    world.log.push(`write ${path}`);
    return json(200, { writeResults: [{}] });
  }

  function runQuery({ structuredQuery: q }) {
    const where = q.where ? (q.where.compositeFilter?.filters ?? [q.where]) : [];
    const match = (d) => where.every(({ fieldFilter: f }) => {
      if (f.op !== 'EQUAL') throw new Error(`fake Firestore cannot filter with ${f.op}`);
      return d.fields[f.field.fieldPath] === fromValue(f.value);
    });
    const rows = [...store.entries()]
      .filter(([p, d]) => p.split('/').length === 2 && p.startsWith(`${q.from[0].collectionId}/`) && match(d))
      .slice(0, q.limit ?? Infinity)
      .map(([p, d]) => ({ document: asDocument(p, d) }));
    // Firestore answers an empty result with one row that has no document.
    return json(200, rows.length ? rows : [{ readTime: stamp() }]);
  }

  function batchWrite({ writes }) {
    for (const w of writes) {
      // Names in a body are taken as they are, not URL-decoded.
      const path = w.delete.slice(ROOT.length + 1);
      store.delete(path);
      world.log.push(`delete ${path}`);
    }
    return json(200, { writeResults: writes.map(() => ({})), status: writes.map(() => ({})) });
  }

  function send({ message }) {
    world.sent.push(message);
    world.log.push(`send ${message.token}`);
    if (!world.dead.has(message.token)) return json(200, { name: 'm' });
    return json(404, { error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } });
  }

  globalThis.fetch = async (input, init = {}) => {
    world.requests++;
    const url = String(input);
    const body = typeof init.body === 'string' ? JSON.parse(init.body) : null;
    if (url === JWKS) return json(200, { keys: [publicJwk] });
    if (url === TOKEN) return json(200, { access_token: 'fake', expires_in: 3600 });
    if (url === FCM) return send(body);
    if (url === `${FIRESTORE}:commit`) return commit(body);
    if (url === `${FIRESTORE}:runQuery`) return runQuery(body);
    if (url === `${FIRESTORE}:batchWrite`) return batchWrite(body);
    if (url.startsWith(`${FIRESTORE}/`) && (init.method ?? 'GET') === 'GET') {
      const path = url.slice(FIRESTORE.length + 1).split('/').map(decodeURIComponent).join('/');
      const d = store.get(path);
      return d ? json(200, asDocument(path, d)) : failure(404, 'NOT_FOUND');
    }
    throw new Error(`unexpected fetch ${init.method ?? 'GET'} ${url}`);
  };
  return world;
}

/** The crew most tests start from: an admin, two workers, one disabled. */
export const crewDocs = () => {
  const user = (role, extra = {}) => ({ firstName: 'Ime', lastName: 'Prezime', role, disabled: false, ...extra });
  return {
    'users/boss': user('admin'),
    'users/ana': user('worker'),
    'users/bob': user('worker'),
    'users/gone': user('worker', { disabled: true }),
    'pushTokens/tBoss': { uid: 'boss' },
    'pushTokens/tAna': { uid: 'ana' },
    'pushTokens/tBob': { uid: 'bob' },
    [`pushTokens/${DEAD}`]: { uid: 'bob' },
    'pushTokens/tGone': { uid: 'gone' },
  };
};
