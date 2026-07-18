// shared.js — Discourse level persistence, navigation, and page template
// Imported by every page in the journey.

'use strict';

const Journey = {
  pages: [
    { id: 'entry',      file: 'landing.html',     title: 'Start Here' },
    { id: 'snap',       file: 'index.html',       title: 'The Snap' },
    { id: 'counting',   file: 'counting.html',    title: 'Counting' },
    { id: 'crisis',     file: 'crisis.html',      title: 'Crisis' },
    { id: 'strategies', file: 'strategies.html',   title: 'Strategies' },
    { id: 'fractal',    file: 'fractal.html',     title: 'The Fractal' },
    { id: 'playground', file: 'playground.html',  title: 'The Playground' },
    { id: 'bridge',     file: 'bridge.html',      title: 'The Bridge' },
    { id: 'boundary',   file: 'boundary.html',    title: 'The Boundary' },
    { id: 'matrix',     file: 'matrix.html',      title: 'The Matrix' },
    { id: 'muds',       file: 'muds.html',        title: 'Meaning-Use Diagrams' },
  ],

  currentIndex() {
    const pageId = document.documentElement.dataset.pageId;
    return this.pages.findIndex(p => p.id === pageId);
  },

  prev() {
    const i = this.currentIndex();
    return i > 0 ? this.pages[i - 1] : null;
  },

  next() {
    const i = this.currentIndex();
    return i >= 0 && i < this.pages.length - 1 ? this.pages[i + 1] : null;
  }
};

// --- Discourse Level ---

const Discourse = {
  LEVELS: ['freshman', 'mathEd', 'philosophy'],
  LABELS: { freshman: 'student', mathEd: 'teacher', philosophy: 'researcher' },

  current() {
    return localStorage.getItem('discourse-level') || 'freshman';
  },

  set(level) {
    if (!this.LEVELS.includes(level)) return;
    localStorage.setItem('discourse-level', level);
    this._apply(level);
  },

  _apply(level) {
    // Toggle visibility of discourse-specific content
    document.querySelectorAll('[data-discourse]').forEach(el => {
      const shows = el.dataset.discourse.split(',').map(s => s.trim());
      el.style.display = shows.includes(level) ? '' : 'none';
    });
    // Update button states
    document.querySelectorAll('.discourse-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.level === level);
    });
    // Dispatch event for canvas-based pages that need to re-render
    window.dispatchEvent(new CustomEvent('discourse-change', { detail: { level } }));
  },

  init() {
    this._apply(this.current());
  }
};

// --- Navigation Bar ---

function injectNav() {
  const prev = Journey.prev();
  const next = Journey.next();
  const idx = Journey.currentIndex();
  const total = Journey.pages.length;

  // Find or create the top-bar
  let topBar = document.querySelector('.top-bar');
  if (!topBar) {
    topBar = document.createElement('div');
    topBar.className = 'top-bar';
    document.body.insertBefore(topBar, document.body.firstChild);
  }

  // Preserve page-specific right-side content (server status, zoom, etc.)
  const existingRight = topBar.querySelector('.top-bar-right, .status-area');
  let extraRightHTML = '';
  if (existingRight) {
    extraRightHTML = existingRight.innerHTML;
  }

  // Get title from existing element or journey data
  const existingTitle = topBar.querySelector('.page-title');
  const titleText = existingTitle ? existingTitle.textContent :
    (idx >= 0 ? Journey.pages[idx].title : document.title || '');

  const level = Discourse.current();

  // Non-journey pages (idx < 0): show home link + discourse buttons only
  if (idx < 0) {
    const discourseHTML = Discourse.LEVELS.map(l =>
      `<button class="discourse-btn${level === l ? ' active' : ''}"
              data-level="${l}"
              onclick="Discourse.set('${l}')">${Discourse.LABELS[l]}</button>`
    ).join('');
    topBar.innerHTML = `
      <div class="top-bar-left">
        <a class="home-link" href="landing.html">home</a>
        <span class="page-title">${titleText}</span>
        <div class="discourse-buttons">${discourseHTML}</div>
      </div>
      <div class="top-bar-right">
        ${extraRightHTML}
      </div>
    `;
    return; // no progress bar or back/forward for non-journey pages
  }

  // Home link: always points to the theory entry page.
  const homeFile = idx === 0 ? '#' : 'landing.html';
  const homeLink = idx === 0
    ? '<span class="home-link" style="visibility:hidden;">home</span>'
    : `<a class="home-link" href="${homeFile}">home</a>`;

  const leftHTML = `
    <div class="top-bar-left">
      ${homeLink}
      ${prev ? `<a class="back-link" href="${prev.file}">&larr; ${prev.title}</a>` : '<span></span>'}
      <span class="page-title">${titleText}</span>
      <div class="discourse-buttons">
        ${Discourse.LEVELS.map(l =>
          `<button class="discourse-btn${level === l ? ' active' : ''}"
                  data-level="${l}"
                  onclick="Discourse.set('${l}')">${Discourse.LABELS[l]}</button>`
        ).join('')}
      </div>
    </div>
  `;

  const progress = idx >= 0 ? `<span class="journey-progress">${idx + 1} / ${total}</span>` : '';
  const rightHTML = `
    <div class="top-bar-right">
      ${extraRightHTML}
      ${progress}
      ${next ? `<a class="back-link" href="${next.file}">${next.title} &rarr;</a>` : '<span></span>'}
    </div>
  `;

  topBar.innerHTML = leftHTML + rightHTML;

  // Progress bar: thin visual indicator below the top-bar
  if (idx >= 0) {
    // Remove any existing progress bar to prevent duplicates on re-injection
    const existing = document.getElementById('journey-progress-bar');
    if (existing) existing.remove();

    const progressBar = document.createElement('div');
    progressBar.id = 'journey-progress-bar';
    progressBar.className = 'journey-bar';
    const fill = document.createElement('div');
    fill.className = 'journey-bar-fill';
    fill.style.width = ((idx + 1) / total * 100) + '%';
    progressBar.appendChild(fill);
    topBar.after(progressBar);
  }
}

// --- Shared CSS ---

function injectSharedCSS() {
  if (document.getElementById('shared-nav-css')) return;
  const style = document.createElement('style');
  style.id = 'shared-nav-css';
  style.textContent = `
    .home-link {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.7rem;
      color: var(--muted, #8a8470);
      text-decoration: none;
      opacity: 0.6;
      transition: opacity 0.2s, color 0.2s;
    }
    .home-link:hover {
      opacity: 1;
      color: var(--text, #d4cfc0);
    }
    .journey-progress {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.7rem;
      color: var(--muted, #8a8470);
      opacity: 0.6;
    }
    .journey-bar {
      height: 2px;
      background: var(--border, #3a3428);
      margin-bottom: 1.5rem;
      border-radius: 1px;
    }
    .journey-bar-fill {
      height: 100%;
      background: var(--snap, #e8a84c);
      border-radius: 1px;
      transition: width 0.3s;
    }
    .discourse-buttons {
      display: flex;
      gap: 0.35rem;
      align-items: center;
    }
    .discourse-btn {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.7rem;
      background: none;
      border: 1px solid var(--border, #3a3428);
      color: var(--muted, #8a8470);
      padding: 0.2rem 0.5rem;
      border-radius: 3px;
      cursor: pointer;
      transition: border-color 0.2s, color 0.2s;
    }
    .discourse-btn:hover {
      border-color: var(--muted, #8a8470);
      color: var(--text, #d4cfc0);
    }
    .discourse-btn.active {
      border-color: var(--snap, #e8a84c);
      color: var(--snap, #e8a84c);
    }
    .top-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
      flex-wrap: wrap;
      gap: 0.5rem;
    }
    .top-bar-left {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
    .top-bar-right {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
    .back-link {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.78rem;
      color: var(--muted, #8a8470);
      text-decoration: none;
    }
    .back-link:hover { color: var(--text, #d4cfc0); }
    .page-title {
      font-family: 'IBM Plex Serif', Georgia, serif;
      font-size: 1.6rem;
      font-weight: 600;
      color: var(--snap, #e8a84c);
    }
    .story-recap {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.8rem;
      color: var(--muted, #8a8470);
      font-style: italic;
      margin-bottom: 1rem;
      opacity: 0.7;
    }
    .margin-note {
      font-family: 'IBM Plex Mono', monospace;
      font-size: 0.75rem;
      color: var(--muted, #8a8470);
      border-left: 2px solid var(--border, #3a3428);
      padding-left: 0.75rem;
      margin: 1rem 0;
      text-align: left;
    }
  `;
  document.head.appendChild(style);
}

// --- Init ---

document.addEventListener('DOMContentLoaded', () => {
  injectSharedCSS();
  injectNav();
  Discourse.init();
});
