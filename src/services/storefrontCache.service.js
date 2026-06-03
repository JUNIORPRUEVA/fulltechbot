const store = new Map();

function now() {
  return Date.now();
}

function buildKey(scope, payload = '') {
  return `${scope}::${payload}`;
}

function get(scope, payload) {
  const key = buildKey(scope, payload);
  const entry = store.get(key);

  if (!entry) {
    return null;
  }

  if (entry.expiresAt <= now()) {
    store.delete(key);
    return null;
  }

  return entry.value;
}

function set(scope, payload, value, ttlMs) {
  const key = buildKey(scope, payload);
  store.set(key, {
    value,
    expiresAt: now() + ttlMs,
  });
  return value;
}

function getOrSet(scope, payload, ttlMs, factory) {
  const cached = get(scope, payload);
  if (cached !== null) {
    return Promise.resolve(cached);
  }

  return Promise.resolve(factory()).then((value) => set(scope, payload, value, ttlMs));
}

function invalidatePrefix(prefix) {
  const fullPrefix = `${prefix}::`;
  for (const key of store.keys()) {
    if (key.startsWith(fullPrefix)) {
      store.delete(key);
    }
  }
}

function clearAll() {
  store.clear();
}

module.exports = {
  get,
  set,
  getOrSet,
  invalidatePrefix,
  clearAll,
};
