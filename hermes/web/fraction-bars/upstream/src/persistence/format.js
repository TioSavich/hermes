FB.Persistence = FB.Persistence || {};
FB.Persistence.FORMAT = 'fraction-bars';
FB.Persistence.VERSION = 2;

function barToPlain(b) {
  return { x:b.x, y:b.y, w:b.w, h:b.h, size:b.size, color:b.color, label:b.label,
    isUnitBar:!!b.isUnitBar, fraction:b.fraction, type:b.type,
    splits:(b.splits||[]).map(function(s){ return { x:s.x, y:s.y, w:s.w, h:s.h, color:s.color }; }) };
}
function matToPlain(m) {
  return { x:m.x, y:m.y, w:m.w, h:m.h, size:m.size, color:m.color, type:m.type };
}

FB.Persistence.serialize = function (state) {
  var bars = state.bars || [];
  var idx = state.unitBar ? bars.indexOf(state.unitBar) : -1;
  return {
    format: FB.Persistence.FORMAT,
    version: FB.Persistence.VERSION,
    bars: bars.map(barToPlain),
    mats: (state.mats || []).map(matToPlain),
    unitBarIndex: idx >= 0 ? idx : null,
    hidden: (state.hidden || []).slice(0)
  };
};

FB.Persistence.toJSON = function (state) { return JSON.stringify(FB.Persistence.serialize(state)); };

FB.Persistence.deserialize = function (obj) {
  var bars = (obj.bars || []).map(FB.Bar.copyFromJSON);
  var mats = (obj.mats || []).map(FB.Mat.copyFromJSON);
  var unitBar = null;
  if (obj.unitBarIndex !== null && obj.unitBarIndex !== undefined && bars[obj.unitBarIndex]) {
    unitBar = bars[obj.unitBarIndex];
    unitBar.isUnitBar = true;
    unitBar.fraction = '1/1';
  }
  return { bars: bars, mats: mats, unitBar: unitBar, hidden: (obj.hidden || []).slice(0) };
};
