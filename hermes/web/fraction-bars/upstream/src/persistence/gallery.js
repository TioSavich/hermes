// src/persistence/gallery.js
FB.Gallery = FB.Gallery || {};

FB.Gallery.memoryAdapter = function () {
  var m = new Map();
  return {
    get: async (k) => (m.has(k) ? m.get(k) : undefined),
    set: async (k, v) => { m.set(k, v); },
    delete: async (k) => { m.delete(k); },
    keys: async () => Array.from(m.keys()),
  };
};

FB.Gallery.indexedDbAdapter = function (dbName) {
  dbName = dbName || 'fraction-bars';
  function open() {
    return new Promise(function (res, rej) {
      var req = indexedDB.open(dbName, 1);
      req.onupgradeneeded = function () { req.result.createObjectStore('saves'); };
      req.onsuccess = function () { res(req.result); };
      req.onerror = function () { rej(req.error); };
    });
  }
  function tx(mode, fn) {
    return open().then(function (db) {
      return new Promise(function (res, rej) {
        var t = db.transaction('saves', mode), store = t.objectStore('saves'), out;
        out = fn(store);
        t.oncomplete = function () { res(out && out.result !== undefined ? out.result : out); };
        t.onerror = function () { rej(t.error); };
      });
    });
  }
  return {
    get: (k) => tx('readonly', (s) => s.get(k)),
    set: (k, v) => tx('readwrite', (s) => s.put(v, k)),
    delete: (k) => tx('readwrite', (s) => s.delete(k)),
    keys: () => tx('readonly', (s) => s.getAllKeys()),
  };
};

FB.Gallery.create = function (adapter) {
  var rec = (obj, updatedAt) => ({ updatedAt: updatedAt || 0, data: obj });
  return {
    save: async (name, obj, updatedAt) => { await adapter.set(name, rec(obj, updatedAt)); },
    load: async (name) => { var r = await adapter.get(name); return r ? r.data : null; },
    list: async () => {
      var keys = await adapter.keys(), out = [];
      for (var i = 0; i < keys.length; i++) { var r = await adapter.get(keys[i]); out.push({ name: keys[i], updatedAt: r ? r.updatedAt : 0 }); }
      return out;
    },
    rename: async (oldName, newName) => { var r = await adapter.get(oldName); if (r) { await adapter.set(newName, r); await adapter.delete(oldName); } },
    remove: async (name) => { await adapter.delete(name); },
    duplicate: async (name, copyName, updatedAt) => { var r = await adapter.get(name); if (r) await adapter.set(copyName, rec(r.data, updatedAt)); },
  };
};
