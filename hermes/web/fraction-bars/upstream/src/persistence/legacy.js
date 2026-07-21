// Safe replacement for Crockford retrocycle: walk $ref paths via a parsed token list.
var REF_PATH = /^\$(?:\[(?:\d+|"(?:[^"\\]|\\.)*")\])*$/;

// Keys that must never be followed or written when resolving attacker-supplied
// save data, to prevent prototype-pollution via a crafted file.
function isUnsafeKey(k) {
  return k === '__proto__' || k === 'constructor' || k === 'prototype';
}

function parseRefPath(path) {
  // returns array of keys (strings/numbers) for paths like $["mBars"][0]
  var keys = [];
  var re = /\[(?:(\d+)|"((?:[^"\\]|\\.)*)")\]/g, m;
  while ((m = re.exec(path)) !== null) {
    if (m[1] !== undefined) keys.push(parseInt(m[1], 10));
    else keys.push(JSON.parse('"' + m[2] + '"'));
  }
  return keys;
}

FB.Persistence.resolveRefs = function (root) {
  function deref(path) {
    if (typeof path !== 'string' || !REF_PATH.test(path)) return undefined;
    var node = root, keys = parseRefPath(path);
    for (var i = 0; i < keys.length; i++) {
      if (node == null) return undefined;
      if (isUnsafeKey(keys[i])) return undefined;
      node = node[keys[i]];
    }
    return node;
  }
  (function rez(value) {
    if (!value || typeof value !== 'object') return;
    var keys = Array.isArray(value) ? value.map(function (_, i) { return i; }) : Object.keys(value);
    for (var k = 0; k < keys.length; k++) {
      var name = keys[k];
      if (isUnsafeKey(name)) continue;
      var item = value[name];
      if (item && typeof item === 'object') {
        if (typeof item.$ref === 'string') {
          var target = deref(item.$ref);
          if (target !== undefined) value[name] = target; // else leave invalid $ref untouched
        } else {
          rez(item);
        }
      }
    }
  })(root);
  return root;
};

FB.Persistence.detectVersion = function (obj) {
  if (obj && obj.format === FB.Persistence.FORMAT && obj.version >= 2) return 2;
  return 1; // legacy decycled CanvasState
};

FB.Persistence.parseFile = function (text) {
  var clean = String(text).replace(/(\r\n|\n|\r)/gm, '');
  var raw = JSON.parse(clean);
  if (FB.Persistence.detectVersion(raw) === 2) return raw;
  var resolved = FB.Persistence.resolveRefs(raw);
  var bars = (resolved.mBars || []);
  var unitIdx = resolved.mUnitBar ? bars.indexOf(resolved.mUnitBar) : -1;
  return {
    format: FB.Persistence.FORMAT,
    version: 2,
    bars: bars.map(function (b) {
      return { x:b.x,y:b.y,w:b.w,h:b.h,size:b.size,color:b.color,label:b.label||'',
        isUnitBar:!!b.isUnitBar,fraction:b.fraction||'',type:b.type||'bar',
        splits:(b.splits||[]).map(function(s){return {x:s.x,y:s.y,w:s.w,h:s.h,color:s.color};}) };
    }),
    mats: (resolved.mMats || []).map(function (m) {
      return { x:m.x,y:m.y,w:m.w,h:m.h,size:m.size,color:m.color,type:m.type||'mat' };
    }),
    unitBarIndex: unitIdx >= 0 ? unitIdx : null,
    hidden: (resolved.mHidden || []).slice(0)
  };
};
