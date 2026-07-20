(function (global) {
  "use strict";

  const DEFAULT_TIMEOUT_MS = 8000;
  const WORKER_TIMEOUT_MS = 22000;

  class HermesRequestError extends Error {
    constructor(kind, message, status) {
      super(message);
      this.name = "HermesRequestError";
      this.kind = kind;
      this.status = status || 0;
    }
  }

  async function requestJSON(url, options) {
    const settings = Object.assign({}, options || {});
    const timeoutMs = settings.timeoutMs || DEFAULT_TIMEOUT_MS;
    delete settings.timeoutMs;

    const controller = new AbortController();
    const upstreamSignal = settings.signal;
    delete settings.signal;
    let timedOut = false;
    const timer = global.setTimeout(function () {
      timedOut = true;
      controller.abort();
    }, timeoutMs);

    if (upstreamSignal) {
      if (upstreamSignal.aborted) controller.abort();
      else upstreamSignal.addEventListener("abort", function () { controller.abort(); }, { once: true });
    }

    try {
      const response = await global.fetch(url, Object.assign({}, settings, { signal: controller.signal }));
      let data;
      try {
        data = await response.json();
      } catch (_error) {
        return { kind: "broken", status: response.status, response: response, data: null };
      }
      if (!response.ok) {
        return { kind: "http-error", status: response.status, response: response, data: data };
      }
      return { kind: "ok", status: response.status, response: response, data: data };
    } catch (error) {
      if (timedOut) return { kind: "timeout", status: 0, response: null, data: null, error: error };
      return { kind: "offline", status: 0, response: null, data: null, error: error };
    } finally {
      global.clearTimeout(timer);
    }
  }

  function messageFor(result) {
    if (result.kind === "timeout" || result.kind === "offline") {
      return "The app isn't answering. Start it with the run button, or this stays a static view.";
    }
    if (result.kind === "http-error") return "The app returned HTTP " + result.status + ".";
    return "The app returned a broken reply.";
  }

  function requireOK(result) {
    if (result.kind === "ok") return result.data;
    throw new HermesRequestError(result.kind, messageFor(result), result.status);
  }

  function setState(element, state, label) {
    if (!element) return;
    const glyph = { pending: "◌", ready: "✓", offline: "×", broken: "!" }[state] || "";
    element.classList.remove("pending", "ready", "offline", "broken");
    element.classList.add(state);
    element.dataset.requestState = state;
    element.textContent = (glyph ? glyph + " " : "") + label;
  }

  function startElapsed(element, message, render) {
    const started = Date.now();
    element.classList.remove("pending", "ready", "offline", "broken");
    element.classList.add("pending");
    element.dataset.requestState = "pending";
    const show = function () {
      const label = message + " (" + Math.floor((Date.now() - started) / 1000) + "s)";
      if (render) render(element, label);
      else element.textContent = label;
    };
    show();
    const timer = global.setInterval(show, 1000);
    return function () {
      global.clearInterval(timer);
      if (element.dataset.requestState === "pending") {
        element.classList.remove("pending");
        delete element.dataset.requestState;
      }
    };
  }

  global.HermesFetch = {
    DEFAULT_TIMEOUT_MS: DEFAULT_TIMEOUT_MS,
    WORKER_TIMEOUT_MS: WORKER_TIMEOUT_MS,
    HermesRequestError: HermesRequestError,
    messageFor: messageFor,
    requestJSON: requestJSON,
    requireOK: requireOK,
    setState: setState,
    startElapsed: startElapsed,
  };
})(window);
