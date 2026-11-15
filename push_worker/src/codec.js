// Firestore REST values to plain JavaScript and back.

/**
 * One Firestore value as plain JavaScript: strings, booleans, integers,
 * doubles, timestamps (as ISO text), arrays and maps; anything else is null.
 */
export function decodeValue(value) {
  if ('arrayValue' in value) {
    // Firestore leaves `values` out of an empty array.
    return (value.arrayValue.values ?? []).map(decodeValue);
  }
  if ('mapValue' in value) {
    // Firestore leaves `fields` out of an empty map.
    return Object.fromEntries(
      Object.entries(value.mapValue.fields ?? {}).map(([k, v]) => [k, decodeValue(v)]),
    );
  }
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  return value.stringValue ?? value.booleanValue ?? value.timestampValue ?? null;
}

/** A Firestore document as plain values, with its id and update time. */
export function decode(document) {
  const fields = {};
  for (const [name, value] of Object.entries(document.fields ?? {})) {
    fields[name] = decodeValue(value);
  }
  return {
    ...fields,
    id: document.name.split('/').pop(),
    updateTime: document.updateTime,
  };
}

/** The worker's own marks as Firestore fields: booleans, integers, text. */
export function encode(fields) {
  const encoded = {};
  for (const [name, value] of Object.entries(fields)) {
    if (typeof value === 'boolean') encoded[name] = { booleanValue: value };
    else if (Number.isInteger(value)) encoded[name] = { integerValue: String(value) };
    else encoded[name] = { stringValue: String(value) };
  }
  return encoded;
}
