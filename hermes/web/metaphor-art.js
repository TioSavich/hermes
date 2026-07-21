// metaphor-art.js — Source-domain SVG illustrations for the seven grounding
// metaphors. Each function returns an inline <svg>...</svg> string sized to
// fit the 110px illustration banner at the top of a metaphor card.
//
// Visual conventions:
//   - basic metaphors use the release (teal) palette: --release
//   - repair metaphors use the accent (gold) palette: --accent
//   - everything is hand-drawn primitives: circles, rects, lines, arcs.
//     no decorative complexity, no AI-slop florishes.

'use strict';

const MetaphorArt = {

  // ─────────────────────────── BASIC FOUR ───────────────────────────

  arithmetic_is_object_collection() {
    // Pile of small circles — a "collection".
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="A loose pile of small circles representing a collection of objects.">
        <g fill="none" stroke="var(--release)" stroke-width="1.4">
          <circle cx="40"  cy="58" r="9"/>
          <circle cx="58"  cy="44" r="9"/>
          <circle cx="60"  cy="68" r="9"/>
          <circle cx="78"  cy="56" r="9"/>
          <circle cx="96"  cy="42" r="9"/>
          <circle cx="100" cy="66" r="9"/>
          <circle cx="118" cy="54" r="9"/>
          <circle cx="138" cy="64" r="9"/>
          <circle cx="138" cy="42" r="9"/>
          <circle cx="160" cy="56" r="9"/>
          <circle cx="178" cy="48" r="9"/>
        </g>
        <g fill="var(--release)" opacity=".35">
          <circle cx="40"  cy="58" r="3"/><circle cx="58"  cy="44" r="3"/>
          <circle cx="60"  cy="68" r="3"/><circle cx="78"  cy="56" r="3"/>
          <circle cx="96"  cy="42" r="3"/><circle cx="100" cy="66" r="3"/>
          <circle cx="118" cy="54" r="3"/><circle cx="138" cy="64" r="3"/>
          <circle cx="138" cy="42" r="3"/><circle cx="160" cy="56" r="3"/>
          <circle cx="178" cy="48" r="3"/>
        </g>
        <text x="110" y="84" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8"
          letter-spacing="0.2em" fill="var(--muted)">{ POOL · GATHER }</text>
      </svg>`;
  },

  arithmetic_is_object_construction() {
    // Stacked rectangular parts — building blocks fitted together.
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="Rectangular blocks stacked and fitted together to make a larger object.">
        <g stroke="var(--release)" stroke-width="1.4" fill="none">
          <!-- bottom row -->
          <rect x="48"  y="60" width="20" height="16"/>
          <rect x="68"  y="60" width="20" height="16"/>
          <rect x="88"  y="60" width="20" height="16"/>
          <rect x="108" y="60" width="20" height="16"/>
          <rect x="128" y="60" width="20" height="16"/>
          <rect x="148" y="60" width="20" height="16"/>
          <!-- middle row -->
          <rect x="58"  y="44" width="20" height="16"/>
          <rect x="78"  y="44" width="20" height="16"/>
          <rect x="98"  y="44" width="20" height="16"/>
          <rect x="118" y="44" width="20" height="16"/>
          <rect x="138" y="44" width="20" height="16"/>
          <!-- top row -->
          <rect x="78"  y="28" width="20" height="16"/>
          <rect x="98"  y="28" width="20" height="16"/>
          <rect x="118" y="28" width="20" height="16"/>
        </g>
        <text x="110" y="84" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8"
          letter-spacing="0.2em" fill="var(--muted)">PARTS · FITTED · ASSEMBLED</text>
      </svg>`;
  },

  arithmetic_is_measuring_stick() {
    // A ruler with tick marks and a labelled unit-segment.
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="A measuring stick with tick marks; a unit segment is highlighted between 0 and 1.">
        <!-- the stick -->
        <rect x="20" y="36" width="180" height="24" fill="none" stroke="var(--release)" stroke-width="1.4"/>
        <!-- ticks -->
        <g stroke="var(--release)" stroke-width="1.2">
          <line x1="40"  y1="36" x2="40"  y2="46"/>
          <line x1="60"  y1="36" x2="60"  y2="46"/>
          <line x1="80"  y1="36" x2="80"  y2="46"/>
          <line x1="100" y1="36" x2="100" y2="46"/>
          <line x1="120" y1="36" x2="120" y2="46"/>
          <line x1="140" y1="36" x2="140" y2="46"/>
          <line x1="160" y1="36" x2="160" y2="46"/>
          <line x1="180" y1="36" x2="180" y2="46"/>
        </g>
        <!-- minor ticks -->
        <g stroke="var(--release)" stroke-width="1" opacity=".5">
          <line x1="50"  y1="36" x2="50"  y2="42"/>
          <line x1="70"  y1="36" x2="70"  y2="42"/>
          <line x1="90"  y1="36" x2="90"  y2="42"/>
          <line x1="110" y1="36" x2="110" y2="42"/>
          <line x1="130" y1="36" x2="130" y2="42"/>
          <line x1="150" y1="36" x2="150" y2="42"/>
          <line x1="170" y1="36" x2="170" y2="42"/>
        </g>
        <!-- unit segment overlay -->
        <line x1="40" y1="28" x2="60" y2="28" stroke="var(--release)" stroke-width="2"/>
        <line x1="40" y1="25" x2="40" y2="31" stroke="var(--release)" stroke-width="2"/>
        <line x1="60" y1="25" x2="60" y2="31" stroke="var(--release)" stroke-width="2"/>
        <text x="50" y="22" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8"
          fill="var(--release)" font-weight="600">UNIT</text>
        <!-- numerals -->
        <g font-family="IBM Plex Mono, monospace" font-size="8" fill="var(--muted)" text-anchor="middle">
          <text x="40"  y="74">0</text>
          <text x="60"  y="74">1</text>
          <text x="80"  y="74">2</text>
          <text x="100" y="74">3</text>
          <text x="120" y="74">4</text>
          <text x="140" y="74">5</text>
          <text x="160" y="74">6</text>
          <text x="180" y="74">7</text>
        </g>
        <text x="110" y="88" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="7.5"
          letter-spacing="0.18em" fill="var(--muted)">LENGTHS · CONCATENATED</text>
      </svg>`;
  },

  arithmetic_is_motion_along_a_path() {
    // Number line with arrow showing forward motion from origin.
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="A number line with an arrow showing motion from origin toward positive numbers.">
        <defs>
          <marker id="ma-arr" viewBox="0 -5 10 10" refX="9" refY="0" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M0,-5L10,0L0,5" fill="var(--release)"/>
          </marker>
          <marker id="ma-arr-left" viewBox="0 -5 10 10" refX="9" refY="0" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M0,-5L10,0L0,5" fill="var(--release)" opacity=".55"/>
          </marker>
        </defs>
        <!-- path -->
        <line x1="14" y1="50" x2="206" y2="50" stroke="var(--release)" stroke-width="1.4"/>
        <line x1="14" y1="50" x2="14"  y2="50" stroke="var(--release)" stroke-width="1.4" marker-end="url(#ma-arr-left)"/>
        <line x1="206" y1="50" x2="206" y2="50" stroke="var(--release)" stroke-width="1.4" marker-end="url(#ma-arr)"/>
        <line x1="14" y1="46" x2="206" y2="46" stroke="var(--release)" stroke-width="0" />
        <!-- ticks -->
        <g stroke="var(--release)" stroke-width="1.2">
          <line x1="40"  y1="46" x2="40"  y2="54"/>
          <line x1="65"  y1="46" x2="65"  y2="54"/>
          <line x1="90"  y1="46" x2="90"  y2="54"/>
          <line x1="115" y1="46" x2="115" y2="54"/>
          <line x1="140" y1="46" x2="140" y2="54"/>
          <line x1="165" y1="46" x2="165" y2="54"/>
          <line x1="190" y1="46" x2="190" y2="54"/>
        </g>
        <!-- origin emphasis -->
        <circle cx="90" cy="50" r="3.6" fill="var(--release)"/>
        <text x="90" y="40" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8"
          fill="var(--release)" font-weight="600">0</text>
        <!-- motion arrow above -->
        <path d="M 90 26 Q 130 6 165 26" fill="none"
              stroke="var(--release)" stroke-width="1.8" marker-end="url(#ma-arr)"/>
        <!-- step labels -->
        <g font-family="IBM Plex Mono, monospace" font-size="7.5" fill="var(--muted)" text-anchor="middle">
          <text x="40"  y="68">−2</text>
          <text x="65"  y="68">−1</text>
          <text x="115" y="68">+1</text>
          <text x="140" y="68">+2</text>
          <text x="165" y="68">+3</text>
        </g>
        <text x="110" y="84" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="7.5"
          letter-spacing="0.18em" fill="var(--muted)">STEPS · ALONG · A · PATH</text>
      </svg>`;
  },

  // ─────────────────────────── REPAIR METAPHORS ───────────────────────────

  multiplication_by_minus_one_is_rotation_by_180_degrees() {
    // A vector at 0° rotating 180° to land at the opposite point.
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="A unit vector rotating 180 degrees around the origin to its opposite.">
        <defs>
          <marker id="rot-arr" viewBox="0 -5 10 10" refX="9" refY="0" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M0,-5L10,0L0,5" fill="var(--accent)"/>
          </marker>
          <marker id="rot-arr-faint" viewBox="0 -5 10 10" refX="9" refY="0" markerWidth="5" markerHeight="5" orient="auto">
            <path d="M0,-5L10,0L0,5" fill="var(--accent)" opacity=".55"/>
          </marker>
        </defs>
        <!-- axis line -->
        <line x1="40" y1="50" x2="180" y2="50" stroke="var(--muted)" stroke-width="0.8" opacity=".5" stroke-dasharray="2 3"/>
        <!-- arc -->
        <path d="M 150 50 A 40 40 0 0 1 70 50" fill="none"
              stroke="var(--accent)" stroke-width="1.6" stroke-dasharray="4 3" marker-end="url(#rot-arr)"/>
        <!-- origin -->
        <circle cx="110" cy="50" r="3.6" fill="var(--accent)"/>
        <!-- vector +1 -->
        <line x1="110" y1="50" x2="150" y2="50" stroke="var(--accent)" stroke-width="2" marker-end="url(#rot-arr)"/>
        <!-- vector -1 (faint) -->
        <line x1="110" y1="50" x2="70" y2="50" stroke="var(--accent)" stroke-width="2" opacity=".55" marker-end="url(#rot-arr-faint)"/>
        <!-- labels -->
        <text x="156" y="64" text-anchor="start"
          font-family="IBM Plex Mono, monospace" font-size="9"
          fill="var(--accent)" font-weight="600">+1</text>
        <text x="64" y="64" text-anchor="end"
          font-family="IBM Plex Mono, monospace" font-size="9"
          fill="var(--accent)" opacity=".7" font-weight="600">−1</text>
        <text x="110" y="22" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8.5"
          fill="var(--accent)">180°</text>
        <text x="110" y="84" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="7.5"
          letter-spacing="0.18em" fill="var(--muted)">×(−1) ≡ HALF-TURN</text>
      </svg>`;
  },

  zero_collection_metaphor() {
    // Empty pair of curly brackets — set-builder for "no objects".
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="A pair of large curly brackets with nothing between them, representing the empty collection.">
        <!-- left brace -->
        <path d="M 95 20 Q 80 20 80 35 Q 80 50 70 50 Q 80 50 80 65 Q 80 80 95 80"
              fill="none" stroke="var(--accent)" stroke-width="2"/>
        <!-- right brace -->
        <path d="M 125 20 Q 140 20 140 35 Q 140 50 150 50 Q 140 50 140 65 Q 140 80 125 80"
              fill="none" stroke="var(--accent)" stroke-width="2"/>
        <!-- ghosted dot in middle -->
        <circle cx="110" cy="50" r="6" fill="none" stroke="var(--muted)" stroke-width="0.8" stroke-dasharray="2 2" opacity=".5"/>
        <line x1="103" y1="43" x2="117" y2="57" stroke="var(--muted)" stroke-width="0.8" opacity=".5"/>
        <line x1="117" y1="43" x2="103" y2="57" stroke="var(--muted)" stroke-width="0.8" opacity=".5"/>
        <!-- caption -->
        <text x="110" y="14" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8"
          fill="var(--accent)" font-weight="600">{ } ≡ 0</text>
        <text x="110" y="88" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="7.5"
          letter-spacing="0.18em" fill="var(--muted)">EMPTY · POSITED · AS · IDENTITY</text>
      </svg>`;
  },

  zero_object_metaphor() {
    // A dashed phantom outline of an object — "absence-of-object is an object".
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg" aria-label="A dashed phantom outline of an object, representing the absence of an object reified as zero.">
        <!-- ghost of a constructed object -->
        <g stroke="var(--accent)" stroke-width="1.4" fill="none" stroke-dasharray="4 3" opacity=".8">
          <rect x="80"  y="44" width="16" height="16"/>
          <rect x="96"  y="44" width="16" height="16"/>
          <rect x="112" y="44" width="16" height="16"/>
          <rect x="128" y="44" width="16" height="16"/>
          <rect x="96"  y="28" width="16" height="16"/>
          <rect x="112" y="28" width="16" height="16"/>
        </g>
        <!-- cross through -->
        <line x1="68" y1="22" x2="156" y2="68" stroke="var(--accent)" stroke-width="1" opacity=".4"/>
        <line x1="68" y1="68" x2="156" y2="22" stroke="var(--accent)" stroke-width="1" opacity=".4"/>
        <!-- caption -->
        <text x="110" y="14" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="8"
          fill="var(--accent)" font-weight="600">¬OBJECT ≡ 0</text>
        <text x="110" y="86" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="7.5"
          letter-spacing="0.18em" fill="var(--muted)">ABSENCE · REIFIED · AS · OBJECT</text>
      </svg>`;
  },

  // ───────────────────────── FALLBACK ─────────────────────────

  _fallback() {
    return `
      <svg viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg">
        <text x="110" y="48" text-anchor="middle"
          font-family="IBM Plex Mono, monospace" font-size="9"
          fill="var(--muted)" letter-spacing="0.2em">[ NO ILLUSTRATION ]</text>
      </svg>`;
  },

  for(id) {
    if (typeof this[id] === 'function') return this[id]();
    return this._fallback();
  }
};

window.MetaphorArt = MetaphorArt;
