document.addEventListener('DOMContentLoaded', () => {

  // ═══════════ PHASE SYSTEM ═══════════
  // The page unfolds as the user interacts.
  // Phase 0: invitation + machine (always visible)
  // Phase 1: after 1st snap — "that was a catastrophe" + tape
  // Phase 2: after 3 snaps — matrix + explanation
  // Phase 3: after 5 snaps — bifurcation + controls + explanation
  // Phase 4: after 10 snaps — fist metaphor + investigation prompts + acoustic
  // Phase 5: after 18 snaps — what's missing + next link

  const phases = {
    1: { threshold: 1, ids: ['phase-1', 'tape-phase'] },
    2: { threshold: 2, ids: ['phase-2', 'matrix-phase'] },
    3: { threshold: 3, ids: ['phase-3', 'bif-phase'] },
    4: { threshold: 5, ids: ['phase-4', 'acoustic-phase'] },
    5: { threshold: 8, ids: ['phase-5'] },
  };

  let currentPhase = 0;
  let totalSnaps = 0;

  function checkPhases() {
    for (const [phase, config] of Object.entries(phases)) {
      if (totalSnaps >= config.threshold && currentPhase < parseInt(phase)) {
        currentPhase = parseInt(phase);
        config.ids.forEach(id => {
          const el = document.getElementById(id);
          if (el) {
            el.classList.add('revealed');
            // Scroll the newly revealed content into view, gently
            setTimeout(() => {
              el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }, 400);
          }
        });
      }
    }

    // Update invitation cue after first snap
    if (totalSnaps >= 1) {
      const cue = document.getElementById('cue');
      if (cue) cue.classList.add('still');
    }
  }

  // ═══════════ RESPONSIVE CANVAS ═══════════
  function setupCanvas(canvas, logicalW, logicalH) {
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.parentElement.getBoundingClientRect();
    const w = rect.width;
    const aspect = logicalH / logicalW;
    const h = w * aspect;
    canvas.style.height = h + 'px';
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    const ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { w, h, ctx };
  }

  // ═══════════ COLORS ═══════════
  const C = {
    bg: '#1a1710',
    tension: '#d4634a',
    release: '#5b9eae',
    snap: '#e8a84c',
    mColor: '#9b6b9e',
    wColor: '#6b9e8c',
    wheel: '#201c14',
    wheelBorder: '#3a3428',
    slack: '#3a3428',
    letter: '#f0ead8',
    letterBlur: 'rgba(240, 234, 216, 0.25)',
    text: '#d4cfc0',
    muted: '#8a8470',
    gridLine: '#201c14',
    particle: '#5b9eae',
    piston: '#3a3428',
    pistonBorder: '#5a5440',
    wall: '#2a2518',
    controlDrag: '#f0ead8',
  };

  // ═══════════ SNAP HISTORY ═══════════
  const snapHistory = [];

  // ═══════════ SCORE DISPLAY ═══════════
  const scoreEl = document.getElementById('score');
  function updateScore() {
    scoreEl.textContent = totalSnaps;
    // Brief color flash
    scoreEl.style.color = '#ede8f2';
    setTimeout(() => { scoreEl.style.color = ''; }, 300);
  }

  // ═══════════ SNAP FLASH ═══════════
  const flashEl = document.getElementById('snap-flash');
  function triggerFlash() {
    flashEl.classList.add('active');
    setTimeout(() => flashEl.classList.remove('active'), 200);
  }

  // ═══════════ MATRIX AUTOMATON ═══════════
  class MatrixAutomaton {
    constructor() {
      this.gridContainer = document.getElementById('matrix-grid');
      this.matrix = [['M']];
      this.maxSize = 8;
      this.render();
    }

    grow(ch) {
      let base = this.matrix;
      let newSize = this.matrix.length + 1;
      if (this.matrix.length >= this.maxSize) {
        newSize = this.maxSize;
        base = [];
        for (let i = 1; i < this.matrix.length; i++) base.push(this.matrix[i].slice(1));
      }
      const n = base.length;
      const m = Array(newSize).fill(null).map(() => Array(newSize).fill(null));
      for (let i = 0; i < n; i++)
        for (let j = 0; j < n; j++) m[i][j] = base[i][j];
      const diag = [];
      for (let i = 0; i < n; i++) diag.push(base[i][i]);
      const neg = diag.map(c => c === 'M' ? 'W' : 'M');
      for (let i = 0; i < n; i++) { m[n][i] = neg[i]; m[i][n] = neg[i]; }
      m[n][n] = ch;
      this.matrix = m;
      this.render();
    }

    render() {
      this.gridContainer.innerHTML = '';
      const size = this.matrix.length;
      const cellPx = size <= 4 ? 36 : size <= 6 ? 30 : 26;
      this.gridContainer.style.gridTemplateColumns = `repeat(${size}, ${cellPx}px)`;
      for (let i = 0; i < size; i++) {
        for (let j = 0; j < size; j++) {
          const cell = document.createElement('div');
          cell.classList.add('matrix-cell');
          cell.style.width = cellPx + 'px';
          cell.style.height = cellPx + 'px';
          cell.style.fontSize = (cellPx <= 26 ? 0.72 : 0.88) + 'rem';
          const v = this.matrix[i][j] || '';
          cell.textContent = v;
          cell.classList.add(v === 'M' ? 'm-cell' : 'w-cell');
          if (i === j) cell.classList.add('diagonal');
          this.gridContainer.appendChild(cell);
        }
      }
    }
  }

  // ═══════════ TAPE ═══════════
  class TapeRenderer {
    constructor() {
      this.container = document.getElementById('tape-container');
    }
    addEvent(entry) {
      const el = document.createElement('div');
      el.classList.add('tape-event');
      const letter = document.createElement('span');
      letter.classList.add('tape-letter');
      letter.textContent = entry.letter;
      letter.style.color = entry.letter === 'M' ? C.mColor : C.wColor;
      const bar = document.createElement('div');
      bar.classList.add('tape-bar');
      const total = entry.tension1 + entry.tension2;
      const h = Math.min(45, Math.max(5, (total / 300) * 45));
      bar.style.height = h + 'px';
      const ratio = Math.min(1, total / 300);
      bar.style.background = ratio > 0.5 ? C.tension : C.release;
      bar.style.opacity = 0.4 + ratio * 0.6;
      el.appendChild(letter);
      el.appendChild(bar);
      this.container.appendChild(el);
      this.container.scrollLeft = this.container.scrollWidth;
    }
  }

  // ═══════════ BIFURCATION PLOT ═══════════
  class BifurcationPlot {
    constructor() {
      this.canvas = document.getElementById('bifurcation-canvas');
      this.points = [];
      this.resize();
    }
    resize() {
      const s = setupCanvas(this.canvas, 500, 300);
      this.w = s.w; this.h = s.h; this.ctx = s.ctx;
      this.draw();
    }
    addPoint(dist, angle, letter) {
      this.points.push({ dist, angle, letter });
      this.draw();
    }
    clear() { this.points = []; this.draw(); }
    draw() {
      const ctx = this.ctx, w = this.w, h = this.h;
      ctx.fillStyle = C.bg;
      ctx.fillRect(0, 0, w, h);
      const p = { l: 36, r: 12, t: 12, b: 24 };
      const pw = w - p.l - p.r, ph = h - p.t - p.b;
      // Grid
      ctx.strokeStyle = C.gridLine; ctx.lineWidth = 1;
      for (let i = 0; i <= 4; i++) {
        const x = p.l + (i / 4) * pw;
        ctx.beginPath(); ctx.moveTo(x, p.t); ctx.lineTo(x, p.t + ph); ctx.stroke();
        const y = p.t + (i / 4) * ph;
        ctx.beginPath(); ctx.moveTo(p.l, y); ctx.lineTo(p.l + pw, y); ctx.stroke();
      }
      // Axes
      ctx.fillStyle = C.muted;
      ctx.font = '9px IBM Plex Mono, monospace';
      ctx.textAlign = 'center';
      ctx.fillText('pull distance', p.l + pw / 2, h - 3);
      ctx.save();
      ctx.translate(8, p.t + ph / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.fillText('snap angle', 0, 0);
      ctx.restore();
      // Points
      const maxDist = 400;
      for (const pt of this.points) {
        const x = p.l + (Math.min(pt.dist, maxDist) / maxDist) * pw;
        const y = p.t + ph - (pt.angle / (2 * Math.PI)) * ph;
        ctx.beginPath();
        ctx.arc(x, y, 3, 0, 2 * Math.PI);
        ctx.fillStyle = pt.letter === 'M' ? C.mColor : C.wColor;
        ctx.globalAlpha = 0.75;
        ctx.fill();
        ctx.globalAlpha = 1;
      }
      ctx.strokeStyle = C.gridLine; ctx.lineWidth = 1;
      ctx.strokeRect(p.l, p.t, pw, ph);
    }
  }

  // ═══════════ ZEEMAN MACHINE ═══════════
  class ZeemanMachine {
    constructor(matrix, tape, bif) {
      this.canvas = document.getElementById('zeeman-canvas');
      this.matrix = matrix;
      this.tape = tape;
      this.bif = bif;
      this.resize();

      // Physics
      this.springK = 2.0;
      this.L0 = 100;
      this.angle = Math.PI / 2;
      this.previousAngle = this.angle;

      // Interaction
      this.isDragging = false;
      this.controlPoint = { x: this.w * 0.65, y: this.h * 0.65 };

      // State
      this.isStable = true;
      this.currentStability = 1.0;
      this._lastGrow = 0;
      this._snapDebounce = 500;

      this.updateGeometry();
      this.bindEvents();
      this.bindSliders();
      this.loop();
    }

    updateGeometry() {
      const s = Math.min(this.w, this.h);
      this.wheelRadius = s * 0.1;
      this.attachmentRadius = s * 0.083;
      this.wheelCenter = { x: this.w / 2, y: this.h / 2 };
      this.fixedAnchor = { x: this.w / 2, y: this.h * 0.1 };
    }

    resize() {
      const s = setupCanvas(this.canvas, 600, 600);
      this.w = s.w; this.h = s.h; this.ctx = s.ctx;
      this.updateGeometry();
    }

    bindEvents() {
      const getPos = (e) => {
        const rect = this.canvas.getBoundingClientRect();
        const sx = this.w / rect.width, sy = this.h / rect.height;
        if (e.touches && e.touches.length) {
          return { x: (e.touches[0].clientX - rect.left) * sx, y: (e.touches[0].clientY - rect.top) * sy };
        }
        return { x: (e.clientX - rect.left) * sx, y: (e.clientY - rect.top) * sy };
      };
      const hit = (pos) => Math.hypot(pos.x - this.controlPoint.x, pos.y - this.controlPoint.y) < 30;
      const down = (e) => { if (hit(getPos(e))) { this.isDragging = true; e.preventDefault(); } };
      const move = (e) => {
        if (!this.isDragging) return;
        e.preventDefault();
        const pos = getPos(e);
        this.controlPoint.x = Math.max(0, Math.min(this.w, pos.x));
        this.controlPoint.y = Math.max(0, Math.min(this.h, pos.y));
      };
      const up = () => { this.isDragging = false; };
      this.canvas.addEventListener('mousedown', down);
      window.addEventListener('mousemove', move);
      window.addEventListener('mouseup', up);
      this.canvas.addEventListener('touchstart', down, { passive: false });
      window.addEventListener('touchmove', move, { passive: false });
      window.addEventListener('touchend', up);
    }

    bindSliders() {
      const kSlider = document.getElementById('spring-k');
      const l0Slider = document.getElementById('natural-length');
      const kDisp = document.getElementById('k-value');
      const l0Disp = document.getElementById('l0-value');
      if (kSlider) kSlider.addEventListener('input', e => {
        this.springK = parseFloat(e.target.value);
        kDisp.textContent = this.springK.toFixed(1);
      });
      if (l0Slider) l0Slider.addEventListener('input', e => {
        this.L0 = parseFloat(e.target.value);
        l0Disp.textContent = this.L0.toFixed(0);
      });
    }

    getAttachmentPoint(a) {
      return {
        x: this.wheelCenter.x + this.attachmentRadius * Math.cos(a),
        y: this.wheelCenter.y + this.attachmentRadius * Math.sin(a)
      };
    }

    calculateGradient(a) {
      const R = this.attachmentRadius;
      const Fx = this.fixedAnchor.x - this.wheelCenter.x;
      const Fy = this.fixedAnchor.y - this.wheelCenter.y;
      const Cx = this.controlPoint.x - this.wheelCenter.x;
      const Cy = this.controlPoint.y - this.wheelCenter.y;
      const Px = R * Math.cos(a), Py = R * Math.sin(a);
      const L1 = Math.hypot(Px - Fx, Py - Fy);
      const L2 = Math.hypot(Px - Cx, Py - Cy);
      let T1 = 0, T2 = 0;
      if (L1 > this.L0 && L1 > 0.001)
        T1 = this.springK * (1 - this.L0 / L1) * (Fx * Math.sin(a) - Fy * Math.cos(a));
      if (L2 > this.L0 && L2 > 0.001)
        T2 = this.springK * (1 - this.L0 / L2) * (Cx * Math.sin(a) - Cy * Math.cos(a));
      return R * (T1 + T2);
    }

    estimateStability(a) {
      const d = 0.01;
      return (this.calculateGradient(a + d) - this.calculateGradient(a - d)) / (2 * d);
    }

    updateState() {
      let a = this.angle;
      let stab = 0;
      for (let i = 0; i < 250; i++) {
        const g = this.calculateGradient(a);
        if (Math.abs(g) < 0.05) { stab = this.estimateStability(a); if (stab > 0) break; }
        a -= Math.max(-0.1, Math.min(0.1, 0.001 * g));
        a = ((a % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
      }
      if (stab <= 0) stab = this.estimateStability(a);
      let diff = a - this.angle;
      while (diff > Math.PI) diff -= 2 * Math.PI;
      while (diff < -Math.PI) diff += 2 * Math.PI;
      const snapped = Math.abs(diff) > 0.6;
      const before = this.angle;
      this.angle = a;
      this.currentStability = Math.max(0, Math.min(1, stab / 5000));
      return { snapped, before };
    }

    recordSnap(letter, before) {
      const P = this.getAttachmentPoint(this.angle);
      const L1 = Math.hypot(P.x - this.fixedAnchor.x, P.y - this.fixedAnchor.y);
      const L2 = Math.hypot(P.x - this.controlPoint.x, P.y - this.controlPoint.y);
      const t1 = Math.max(0, L1 - this.L0) * this.springK;
      const t2 = Math.max(0, L2 - this.L0) * this.springK;
      const dist = Math.hypot(this.controlPoint.x - this.wheelCenter.x, this.controlPoint.y - this.wheelCenter.y);
      const entry = { letter, controlDist: dist, angleBefore: before, angleAfter: this.angle, tension1: t1, tension2: t2, timestamp: Date.now() };
      snapHistory.push(entry);
      totalSnaps++;
      updateScore();
      triggerFlash();
      this.tape.addEvent(entry);
      this.bif.addPoint(dist, this.angle, letter);
      checkPhases();
    }

    update() {
      const { snapped, before } = this.updateState();
      const letter = (this.angle > Math.PI / 2 && this.angle < 3 * Math.PI / 2) ? 'W' : 'M';
      this.isStable = this.currentStability > 0.3;
      if (this.isStable && snapped) {
        const now = Date.now();
        if (now - this._lastGrow > this._snapDebounce) {
          this._lastGrow = now;
          this.matrix.grow(letter);
          this.recordSnap(letter, before);
        }
      }
    }

    draw() {
      const ctx = this.ctx, w = this.w, h = this.h;
      ctx.fillStyle = C.bg;
      ctx.fillRect(0, 0, w, h);

      const P = this.getAttachmentPoint(this.angle);
      const L1 = Math.hypot(P.x - this.fixedAnchor.x, P.y - this.fixedAnchor.y);
      const L2 = Math.hypot(P.x - this.controlPoint.x, P.y - this.controlPoint.y);

      // Band to anchor
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.moveTo(this.fixedAnchor.x, this.fixedAnchor.y);
      ctx.lineTo(P.x, P.y);
      if (L1 <= this.L0) {
        ctx.setLineDash([4, 4]); ctx.strokeStyle = C.slack;
      } else {
        ctx.setLineDash([]);
        const s = Math.min(1, (L1 - this.L0) / 150);
        ctx.strokeStyle = `rgba(212,99,74,${0.3 + s * 0.7})`;
        ctx.lineWidth = 2.5 + s * 1.5;
      }
      ctx.stroke();

      // Band to control
      ctx.beginPath();
      ctx.moveTo(this.controlPoint.x, this.controlPoint.y);
      ctx.lineTo(P.x, P.y);
      if (L2 <= this.L0) {
        ctx.setLineDash([4, 4]); ctx.strokeStyle = C.slack;
      } else {
        ctx.setLineDash([]);
        const s = Math.min(1, (L2 - this.L0) / 150);
        ctx.strokeStyle = `rgba(107,140,206,${0.3 + s * 0.7})`;
        ctx.lineWidth = 2.5 + s * 1.5;
      }
      ctx.stroke();
      ctx.setLineDash([]);

      // Fixed anchor
      ctx.beginPath();
      ctx.arc(this.fixedAnchor.x, this.fixedAnchor.y, 6, 0, 2 * Math.PI);
      ctx.fillStyle = C.tension; ctx.fill();
      // Label
      ctx.font = '10px IBM Plex Mono, monospace';
      ctx.fillStyle = C.muted; ctx.textAlign = 'center';
      ctx.fillText('fixed', this.fixedAnchor.x, this.fixedAnchor.y - 12);

      // Wheel
      ctx.beginPath();
      ctx.arc(this.wheelCenter.x, this.wheelCenter.y, this.wheelRadius, 0, 2 * Math.PI);
      ctx.fillStyle = C.wheel; ctx.fill();
      ctx.strokeStyle = C.wheelBorder; ctx.lineWidth = 2; ctx.stroke();

      // Letter
      ctx.save();
      ctx.translate(this.wheelCenter.x, this.wheelCenter.y);
      ctx.rotate(this.angle + Math.PI / 2);
      const fs = this.wheelRadius * 0.9;
      ctx.font = `600 ${fs}px IBM Plex Mono, monospace`;
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      if (!this.isStable) {
        ctx.fillStyle = C.letterBlur;
        ctx.filter = `blur(${(1 - this.currentStability) * 4}px)`;
      } else {
        ctx.fillStyle = C.letter;
      }
      ctx.fillText('M', 0, 0);
      ctx.restore();

      // Attachment point
      ctx.beginPath();
      ctx.arc(P.x, P.y, 4, 0, 2 * Math.PI);
      ctx.fillStyle = C.text; ctx.fill();

      // Control point
      ctx.beginPath();
      ctx.arc(this.controlPoint.x, this.controlPoint.y, 12, 0, 2 * Math.PI);
      ctx.fillStyle = C.release; ctx.fill();
      ctx.strokeStyle = this.isDragging ? C.controlDrag : C.wheelBorder;
      ctx.lineWidth = 2; ctx.stroke();

      // Pulse ring hint (first 3 snaps)
      if (!this.isDragging && totalSnaps < 3) {
        const p = 0.3 + 0.2 * Math.sin(Date.now() / 500);
        ctx.beginPath();
        ctx.arc(this.controlPoint.x, this.controlPoint.y, 22, 0, 2 * Math.PI);
        ctx.strokeStyle = `rgba(107,140,206,${p})`;
        ctx.lineWidth = 1.5; ctx.stroke();
      }

      // Current state indicator (top-right corner of canvas)
      if (this.isStable) {
        const letter = (this.angle > Math.PI / 2 && this.angle < 3 * Math.PI / 2) ? 'W' : 'M';
        ctx.font = '600 18px IBM Plex Mono, monospace';
        ctx.fillStyle = letter === 'M' ? C.mColor : C.wColor;
        ctx.textAlign = 'right';
        ctx.fillText(letter, w - 16, 28);
      } else {
        ctx.font = '11px IBM Plex Mono, monospace';
        ctx.fillStyle = C.muted;
        ctx.textAlign = 'right';
        ctx.fillText('?', w - 16, 28);
      }
    }

    loop() {
      this.update();
      this.draw();
      requestAnimationFrame(() => this.loop());
    }
  }

  // ═══════════ ACOUSTIC ═══════════
  class AcousticVisualization {
    constructor(zeeman) {
      this.zeeman = zeeman;
      this.svg = document.getElementById('acoustic-svg');
      this.svgNS = 'http://www.w3.org/2000/svg';
      this.width = 800; this.height = 160;
      this.numParticles = 220;
      this.speakerWidth = 32; this.speakerHeight = 110;
      this.speakerX = 45;
      this.speakerY = (this.height - this.speakerHeight) / 2;
      this.chamberEndX = this.width - 12;
      this.waveSpeed = 6;
      this.history = new Array(90).fill(0);
      this.historyIndex = 0;
      this.maxDisp = 22;
      this.sensitivity = 15;
      this.smoothed = 0;
      this.particles = [];
      this.pistonRect = null;
      this.init();
    }

    init() {
      this.svg.innerHTML = '';
      // Background
      const bg = document.createElementNS(this.svgNS, 'rect');
      bg.setAttribute('x', 0); bg.setAttribute('y', 0);
      bg.setAttribute('width', this.width); bg.setAttribute('height', this.height);
      bg.setAttribute('fill', C.bg); bg.setAttribute('rx', '4');
      this.svg.appendChild(bg);
      // Walls
      [this.speakerY, this.speakerY + this.speakerHeight].forEach(y => {
        const l = document.createElementNS(this.svgNS, 'line');
        l.setAttribute('x1', this.speakerX); l.setAttribute('y1', y);
        l.setAttribute('x2', this.chamberEndX); l.setAttribute('y2', y);
        l.setAttribute('stroke', C.wall); l.setAttribute('stroke-width', '2');
        this.svg.appendChild(l);
      });
      // Piston
      this.pistonRect = document.createElementNS(this.svgNS, 'rect');
      this.pistonRect.setAttribute('x', this.speakerX - this.speakerWidth);
      this.pistonRect.setAttribute('y', this.speakerY);
      this.pistonRect.setAttribute('width', this.speakerWidth);
      this.pistonRect.setAttribute('height', this.speakerHeight);
      this.pistonRect.setAttribute('fill', C.piston);
      this.pistonRect.setAttribute('stroke', C.pistonBorder);
      this.pistonRect.setAttribute('stroke-width', '1.5');
      this.pistonRect.setAttribute('rx', '3');
      this.svg.appendChild(this.pistonRect);
      // Particles
      const g = document.createElementNS(this.svgNS, 'g');
      this.svg.appendChild(g);
      const sx = this.speakerX + 4, ex = this.chamberEndX - 4;
      const sy = this.speakerY + 4, ey = this.speakerY + this.speakerHeight - 4;
      const area = (ex - sx) * (ey - sy);
      const sp = Math.sqrt(area / this.numParticles);
      const nx = Math.floor((ex - sx) / sp), ny = Math.floor((ey - sy) / sp);
      for (let i = 0; i <= nx; i++) {
        for (let j = 0; j <= ny; j++) {
          if (this.particles.length >= this.numParticles) break;
          const bx = sx + i * sp + (Math.random() - 0.5) * sp * 0.4;
          const by = sy + j * sp + (Math.random() - 0.5) * sp * 0.4;
          const c = document.createElementNS(this.svgNS, 'circle');
          c.setAttribute('cx', bx.toFixed(1)); c.setAttribute('cy', by.toFixed(1));
          c.setAttribute('r', '2'); c.setAttribute('fill', C.particle);
          c.setAttribute('opacity', '0.55');
          g.appendChild(c);
          this.particles.push({ el: c, bx, by });
        }
      }
    }

    animate() {
      let dT = this.zeeman.angle - this.zeeman.previousAngle;
      while (dT > Math.PI) dT -= 2 * Math.PI;
      while (dT < -Math.PI) dT += 2 * Math.PI;
      const target = this.maxDisp * Math.tanh(dT * this.sensitivity);
      this.smoothed += (target - this.smoothed) * 0.2;
      this.history[this.historyIndex] = this.smoothed;
      this.historyIndex = (this.historyIndex + 1) % this.history.length;
      this.pistonRect.setAttribute('x', (this.speakerX - this.speakerWidth + this.smoothed).toFixed(2));
      const face = this.speakerX + this.smoothed;
      for (const p of this.particles) {
        const d = p.bx - this.speakerX;
        let idx = Math.round(this.historyIndex - 1 - d / this.waveSpeed);
        idx = ((idx % this.history.length) + this.history.length) % this.history.length;
        const hd = this.history[idx] || 0;
        const cx = Math.max(face + 2, Math.min(this.chamberEndX - 2, p.bx + hd * Math.exp(-0.003 * d)));
        p.el.setAttribute('cx', cx.toFixed(2));
      }
      this.zeeman.previousAngle = this.zeeman.angle;
    }
  }

  // ═══════════ INIT ═══════════
  const matrixAuto = new MatrixAutomaton();
  const tapeRender = new TapeRenderer();
  const bifPlot = new BifurcationPlot();
  const zeeman = new ZeemanMachine(matrixAuto, tapeRender, bifPlot);
  const acoustic = new AcousticVisualization(zeeman);

  document.getElementById('clear-bif').addEventListener('click', () => bifPlot.clear());

  function animLoop() {
    acoustic.animate();
    requestAnimationFrame(animLoop);
  }
  animLoop();

  // Resize
  let rTimer;
  window.addEventListener('resize', () => {
    clearTimeout(rTimer);
    rTimer = setTimeout(() => { zeeman.resize(); bifPlot.resize(); }, 200);
  });

  // ═══════════ AUTOPILOT ═══════════
  // Moves the control point along paths that explore the catastrophe region.
  // Pauses when user drags; resumes when they release or click the button.

  let autopilotActive = false;
  let autopilotTime = 0;
  let autopilotSpeed = 1; // 1 = gentle explore, 2+ = fast accumulation
  const autopilotBtn = document.getElementById('autopilot-btn');
  const speedBtn = document.getElementById('speed-btn');

  // Path: a slowly varying trajectory that sweeps through the catastrophe cusp.
  // Uses two superimposed sine waves at irrational frequency ratios
  // so the path never exactly repeats, exploring the parameter space over time.
  function autopilotPosition(t) {
    const cx = zeeman.wheelCenter.x;
    const cy = zeeman.wheelCenter.y;
    const r = zeeman.w * 0.32;
    // Lissajous-like curve with irrational ratio — never repeats
    const fx = 0.23, fy = 0.17;
    const x = cx + r * Math.sin(fx * t) * (0.6 + 0.4 * Math.sin(0.07 * t));
    const y = cy + r * Math.cos(fy * t) * (0.5 + 0.5 * Math.sin(0.11 * t)) + r * 0.3;
    return {
      x: Math.max(10, Math.min(zeeman.w - 10, x)),
      y: Math.max(10, Math.min(zeeman.h - 10, y))
    };
  }

  function autopilotStep() {
    if (!autopilotActive || zeeman.isDragging) return;
    // Speed 1: gentle (0.025/frame). Speed 5: fast accumulation (0.125/frame).
    // At higher speeds, take multiple sub-steps per frame for smoother traversal.
    const steps = autopilotSpeed <= 2 ? 1 : autopilotSpeed;
    const dt = 0.025 * autopilotSpeed;
    for (let i = 0; i < steps; i++) {
      autopilotTime += dt / steps;
      const pos = autopilotPosition(autopilotTime);
      zeeman.controlPoint.x = pos.x;
      zeeman.controlPoint.y = pos.y;
      // At high speed, run physics multiple times per frame to accumulate snaps
      if (autopilotSpeed >= 3) {
        zeeman.update();
      }
    }
  }

  // Run autopilot on each frame
  function autopilotLoop() {
    autopilotStep();
    requestAnimationFrame(autopilotLoop);
  }
  autopilotLoop();

  window.toggleAutopilot = function () {
    autopilotActive = !autopilotActive;
    autopilotSpeed = 1;
    autopilotBtn.classList.toggle('active', autopilotActive);
    autopilotBtn.textContent = autopilotActive ? 'take control' : 'or just watch';
    if (speedBtn) speedBtn.style.display = autopilotActive ? 'inline-block' : 'none';
    // Update invitation cue
    const cue = document.getElementById('cue');
    if (cue && autopilotActive) {
      cue.textContent = 'watch the machine explore';
      cue.classList.add('still');
    } else if (cue && !autopilotActive) {
      cue.textContent = totalSnaps > 0 ? 'keep dragging' : 'drag the blue point';
      if (totalSnaps > 0) cue.classList.add('still');
      else cue.classList.remove('still');
    }
  };

  // Speed cycling: 1x → 3x → 8x → 20x → 1x
  const speedLevels = [1, 3, 8, 20];
  let speedIndex = 0;
  window.cycleSpeed = function () {
    speedIndex = (speedIndex + 1) % speedLevels.length;
    autopilotSpeed = speedLevels[speedIndex];
    if (speedBtn) speedBtn.textContent = autopilotSpeed + 'x';
    // At high speed, reduce snap debounce so we accumulate faster
    if (autopilotSpeed >= 3) {
      zeeman._snapDebounce = Math.max(50, Math.floor(500 / autopilotSpeed));
    } else {
      zeeman._snapDebounce = 500;
    }
  };

  // Pause autopilot when user starts dragging
  const origDown = zeeman.canvas.onmousedown;
  zeeman.canvas.addEventListener('mousedown', () => {
    if (autopilotActive) {
      // Don't fully disable — just let isDragging suppress movement
      // User can resume by releasing and not touching
    }
  });
  zeeman.canvas.addEventListener('touchstart', () => {
    if (autopilotActive) {
      // Same — isDragging will suppress autopilot movement
    }
  }, { passive: true });
});
