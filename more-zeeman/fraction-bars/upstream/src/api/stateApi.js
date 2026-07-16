// FB.StateApi -- the external integration surface for Fraction Bars.
//
// install(controller, target) defines target.FractionBars = { getState, loadState,
// onChange, version }. This is the contract a host page (or an LTI/Hermes shell)
// uses to read and restore the v2 save state.
//
// installPostMessage(api, win) bridges that contract over window.postMessage with
// strict origin checks: it only honors messages from an allowlisted origin and
// never replies with a '*' target origin to a known opener. There is no network
// access; this is purely cross-frame/cross-window message passing.

FB.StateApi = FB.StateApi || {};

FB.StateApi.install = function (controller, target) {
	target = target || {};

	var listeners = [];

	// Fire registered onChange listeners whenever the controller mutates/refreshes.
	controller.onMutate(function () {
		for (var i = 0; i < listeners.length; i++) {
			try { listeners[i](); } catch (e) { /* a bad listener must not break others */ }
		}
	});

	function getState() {
		return FB.Persistence.serialize(controller.state);
	}

	function loadState(obj) {
		if (!obj || typeof obj !== 'object') {
			throw new Error('FractionBars.loadState: expected a state object');
		}
		if (obj.format !== FB.Persistence.FORMAT) {
			throw new Error('FractionBars.loadState: unrecognized format "' + obj.format + '"');
		}
		if (!(typeof obj.version === 'number' && obj.version >= 2)) {
			throw new Error('FractionBars.loadState: unsupported version "' + obj.version + '"');
		}

		var rebuilt = FB.Persistence.deserialize(obj);
		var state = controller.state;
		state.bars = rebuilt.bars;
		state.mats = rebuilt.mats;
		state.unitBar = rebuilt.unitBar;
		state.selectedBars = [];
		state.selectedMats = [];
		state.lastSelectedBars = [];
		state.lastSelectedMats = [];
		if (rebuilt.hidden !== undefined) { state.hidden = rebuilt.hidden; }

		controller.refresh();
	}

	function onChange(cb) {
		if (typeof cb === 'function') { listeners.push(cb); }
	}

	target.FractionBars = {
		getState: getState,
		loadState: loadState,
		onChange: onChange,
		version: FB.Persistence.VERSION
	};

	return target.FractionBars;
};

// installPostMessage wires the State API to window.postMessage with origin checks.
//
//   FB.StateApi.installPostMessage(api, win, options)
//
// options.allowedOrigins : array of exact origin strings permitted to talk to us
//                          (default: [win.location.origin] when available).
// Messages must be { source:'hermes', type:'getState'|'loadState', payload? }.
// Replies are { source:'fraction-bars', type, requestId?, ok, payload|error } and
// are posted back to the *sender's* origin (event.origin), never '*'.
FB.StateApi.installPostMessage = function (api, win, options) {
	options = options || {};

	var sameOrigin = (win && win.location && win.location.origin) ? win.location.origin : null;
	var allowed = options.allowedOrigins || (sameOrigin ? [sameOrigin] : []);

	function isAllowed(origin) {
		// "null" (sandboxed iframes / file:) and the wildcard are never trusted.
		if (!origin || origin === 'null' || origin === '*') { return false; }
		for (var i = 0; i < allowed.length; i++) {
			if (allowed[i] === origin) { return true; }
		}
		return false;
	}

	function handler(event) {
		// Reject anything not from an allowlisted origin before reading the body.
		if (!isAllowed(event.origin)) { return; }

		var data = event.data;
		if (!data || typeof data !== 'object' || data.source !== 'hermes') { return; }

		var source = event.source;
		if (!source || typeof source.postMessage !== 'function') { return; }

		function reply(msg) {
			msg.source = 'fraction-bars';
			if (data.requestId !== undefined) { msg.requestId = data.requestId; }
			// Always target the verified sender origin -- never '*'.
			source.postMessage(msg, event.origin);
		}

		switch (data.type) {
			case 'getState':
				try {
					reply({ type: 'getState', ok: true, payload: api.getState() });
				} catch (e) {
					reply({ type: 'getState', ok: false, error: String(e && e.message || e) });
				}
				break;
			case 'loadState':
				try {
					api.loadState(data.payload);
					reply({ type: 'loadState', ok: true });
				} catch (e) {
					reply({ type: 'loadState', ok: false, error: String(e && e.message || e) });
				}
				break;
			default:
				// Unknown message types are ignored silently.
				break;
		}
	}

	if (win && typeof win.addEventListener === 'function') {
		win.addEventListener('message', handler, false);
	}

	return handler;
};
