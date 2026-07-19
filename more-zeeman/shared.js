// shared.js — Discourse-level persistence for the journey pages.

'use strict';

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
    document.querySelectorAll('[data-discourse]').forEach(el => {
      const shows = el.dataset.discourse.split(',').map(s => s.trim());
      el.style.display = shows.includes(level) ? '' : 'none';
    });
    document.querySelectorAll('.discourse-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.level === level);
    });
    window.dispatchEvent(new CustomEvent('discourse-change', { detail: { level } }));
  },

  init() {
    this._apply(this.current());
  }
};

function injectDiscourseControls() {
  if (document.querySelector('.discourse-buttons')) return;

  const controls = document.createElement('div');
  controls.className = 'discourse-buttons';
  Discourse.LEVELS.forEach(level => {
    const button = document.createElement('button');
    button.className = 'discourse-btn';
    button.dataset.level = level;
    button.textContent = Discourse.LABELS[level];
    button.addEventListener('click', () => Discourse.set(level));
    controls.appendChild(button);
  });

  if (window.HermesShell && window.HermesShell.slot) {
    window.HermesShell.slot.appendChild(controls);
  }
}

function injectDiscourseCSS() {
  if (document.getElementById('shared-discourse-css')) return;
  const style = document.createElement('style');
  style.id = 'shared-discourse-css';
  style.textContent = `
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
  `;
  document.head.appendChild(style);
}

document.addEventListener('DOMContentLoaded', () => {
  injectDiscourseCSS();
  injectDiscourseControls();
  Discourse.init();
});
