#!/usr/bin/env node
/* Shared Node adapter for drawer.js offline rendering. */
'use strict';

const fs = require('fs');
const vm = require('vm');
const path = require('path');

function escapeXml(value) {
  return String(value).replace(/[<>&"]/g, c => ({'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;'}[c]));
}

class Element {
  constructor(name) {
    this.name = name; this.attrs = {}; this.children = []; this._text = ''; this.style = {};
    this.classList = { add: (...names) => {
      const current = new Set(String(this.attrs.class || '').split(/\s+/).filter(Boolean));
      names.forEach(name => current.add(name));
      if (current.size) this.attrs.class = Array.from(current).join(' ');
    }};
  }
  setAttribute(key, value) { this.attrs[key] = String(value); }
  getAttribute(key) { return this.attrs[key]; }
  appendChild(child) { this.children.push(child); return child; }
  addEventListener() {}
  querySelectorAll() { return []; }
  getScreenCTM() { return null; }
  createSVGPoint() { return {x: 0, y: 0, matrixTransform() { return this; }}; }
  set textContent(value) { this._text = String(value); }
  get textContent() { return this._text; }
  get firstChild() { return this.children[0] || null; }
  removeChild(child) { this.children = this.children.filter(item => item !== child); }
  get outerHTML() {
    const attrs = Object.entries(this.attrs).map(([k, v]) => ` ${k}="${escapeXml(v)}"`).join('');
    const body = escapeXml(this._text) + this.children.map(c => c.outerHTML || escapeXml(String(c))).join('');
    return `<${this.name}${attrs}>${body}</${this.name}>`;
  }
}

const document = {
  documentElement: {},
  createElementNS(_namespace, name) { return new Element(name); },
  createElement(name) { return new Element(name); },
  getElementById() { return null; }, querySelectorAll() { return []; }, addEventListener() {}
};
const colorVars = {
  '--fig-unit':'#3f7f89', '--fig-iterated':'#d4a747', '--fig-highlight':'#d4a747',
  '--fig-deformation':'#b95238', '--fig-assembled':'#5d9c6d', '--fig-comparison':'#7a6fb0',
  '--fig-neutral':'#cabf9f', '--fig-whole':'#cabf9f', '--fig-peg':'#3f7f89',
  '--fig-stroke':'#0d0c08', '--paper-bg':'#f8f1df', '--fig-label':'#1b1810'
};

function loadDrawer(repoRoot) {
  const window = {};
  const getComputedStyle = () => ({getPropertyValue: name => colorVars[name] || ''});
  const context = {window, document, console, getComputedStyle, setTimeout, clearTimeout};
  context.global = context; window.document = document; window.getComputedStyle = getComputedStyle;
  vm.createContext(context);
  vm.runInContext(fs.readFileSync(path.join(repoRoot, 'hermes/web/render/drawer.js'), 'utf8'), context, {filename:'drawer.js'});
  return context.window.HermesDrawer._internal;
}

function clean(svg) {
  return svg.outerHTML.replace(/font-family="Georgia, &quot;Times New Roman&quot;, serif/g,
    'font-family="Georgia, Times New Roman, serif') + '\n';
}

function appendMetadata(svg, kind, payload) {
  if (!kind) return;
  const node = document.createElementNS('http://www.w3.org/2000/svg', 'metadata');
  node.setAttribute('data-hermes-kind', kind);
  node.textContent = JSON.stringify(payload || {});
  svg.appendChild(node);
}

function frameSvg(drawer, doc, options) {
  const frames = doc.frames || [];
  const index = Number(options.index || 0);
  const svg = drawer.buildSvg(frames[index], drawer.documentBounds(frames, doc.canvas || {}));
  svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
  svg.setAttribute('role', 'img');
  if (options.ariaLabel) svg.setAttribute('aria-label', options.ariaLabel);
  appendMetadata(svg, options.metadataKind, options.metadata);
  return clean(svg);
}

function filmstripSvg(drawer, doc, options) {
  const frames = doc.frames || [], preset = options.preset || 'standard';
  const labels = options.labels || [], captions = options.captions || [];
  const panelW = Number(options.panelWidth || (preset === 'fraction-cliff' ? 300 : 300));
  const panelH = Number(options.panelHeight || (preset === 'fraction-cliff' ? 170 : 220));
  const gap = Number(options.gap || 18), pad = Number(options.pad || 22);
  const title = options.title || '', headH = title ? Number(options.headHeight || 42) : 0;
  const rootW = pad * 2 + frames.length * panelW + Math.max(0, frames.length - 1) * gap;
  const rootH = Number(options.rootHeight || (preset === 'fraction-cliff' ? 300 : headH + panelH + 88));
  const bounds = drawer.documentBounds(frames, doc.canvas || {});
  let body = `<rect x="0" y="0" width="${rootW}" height="${rootH}" fill="#f8f1df"/>`;
  if (title && options.replicationLayout) body += `<text x="${rootW/2}" y="30" text-anchor="middle" font-family="system-ui, sans-serif" font-size="18" font-weight="700" fill="#1b1810">${escapeXml(title)}</text>`;
  else if (title && options.titleLeft) body += `<text x="${pad}" y="24" font-family="Georgia, Times New Roman, serif" font-size="18" font-weight="700" fill="#1b1810">${escapeXml(title)}</text>`;
  else if (title) body += `<text x="${rootW/2}" y="28" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700" fill="#1b1810">${escapeXml(title)}</text>`;
  for (let i = 0; i < frames.length; i += 1) {
    const frameBounds = options.perFrameBounds && doc._bounds_documents
      ? drawer.documentBounds(doc._bounds_documents[i].frames || [], doc._bounds_documents[i].canvas || {})
      : bounds;
    const x = pad + i * (panelW + gap), inner = drawer.buildSvg(frames[i], frameBounds);
    const vb = String(inner.getAttribute('viewBox') || '0 0 1 1').split(/\s+/).map(Number);
    const availableH = (preset === 'fraction-cliff' || options.fullPanelHeight) ? panelH : panelH - 8;
    const scale = Math.min(panelW / vb[2], availableH / vb[3]);
    const yBase = preset === 'fraction-cliff' ? 64 : headH + Number(options.yOffset === 0 ? 0 : (options.yOffset || 62));
    const tx = x + (panelW-vb[2]*scale)/2-vb[0]*scale;
    const ty = yBase + (panelH-vb[3]*scale)/2-vb[1]*scale;
    const children = inner.children.map(c => c.outerHTML || '').join('');
    const labelY = preset === 'fraction-cliff' ? 24 : headH + Number(options.labelOffset || 22);
    const capY = preset === 'fraction-cliff' ? 44 : headH + 42;
    let caption = captions[i] || frames[i].caption || '';
    if (options.captionEllipsis) {
      const maximum = Math.max(24, Math.floor(panelW / 6.2));
      if (caption.length > maximum) caption = caption.slice(0, maximum - 1) + '…';
    }
    if (options.captionChars) caption = caption.slice(0, Number(options.captionChars));
    if (options.replicationLayout) body += `<text x="${x+panelW/2}" y="${headH-18}" text-anchor="middle" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#1b1810">${escapeXml(labels[i] || `Frame ${i+1}`)}</text>`;
    else body += `<text x="${x+panelW/2}" y="${labelY}" text-anchor="middle" font-family="${options.labelFont || 'system-ui,sans-serif'}" font-size="${options.labelSize || 15}" font-weight="700" fill="#1b1810">${escapeXml(labels[i] || `Frame ${i+1}`)}</text>`;
    if (options.omitCaptions) {
      // Replication strips label panels above the drawing and omit captions.
    } else if (options.wrapCaption) {
      const words = String(caption).split(/\s+/), lines = []; let current = '';
      words.forEach(word => { if (`${current} ${word}`.trim().length > Number(options.wrapCaption)) { if (current) lines.push(current); current = word; } else current = `${current} ${word}`.trim(); });
      if (current) lines.push(current);
      lines.slice(0, 2).forEach((line, k) => { body += `<text x="${x+panelW/2}" y="${capY+k*13}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="${options.captionSize || 11}" fill="#5a5446">${escapeXml(line)}</text>`; });
    } else body += `<text x="${x+panelW/2}" y="${capY}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="${options.captionSize || 11}" fill="#5a5446">${escapeXml(caption)}</text>`;
    body += `<g transform="translate(${tx} ${ty}) scale(${scale})">${children}</g>`;
  }
  const aria = options.omitAria ? '' : ` aria-label="${escapeXml(options.ariaLabel || title || 'render filmstrip')}"`;
  let output = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${rootW} ${rootH}" role="img"${aria}>${body}</svg>\n`;
  if (options.cleanFonts) output = output.replace(/font-family="Georgia, &quot;Times New Roman&quot;, serif/g, 'font-family="Georgia, Times New Roman, serif');
  return output;
}

function fileName(code, total, index, side, filmstrip) {
  const tail = filmstrip ? `${side}-filmstrip.svg` : `${side}.svg`;
  return total === 1 ? `${code}-${tail}` : `${code}-${index + 1}-${tail}`;
}

function proofMetadata(code, index, side, visual, kind) {
  const proof = visual.proof || {}, sideProof = proof[side] || {};
  const payload = {kind, lesson_code:code, visual_index:index, side,
    expression:visual.expression || '', proof:{source:proof.source || '', status:sideProof.status || '',
      frame_count:Number.isInteger(sideProof.frame_count) ? sideProof.frame_count : null,
      temporal:sideProof.temporal === true, frame_sequence:Array.isArray(sideProof.frame_sequence) ? sideProof.frame_sequence : []},
    interpretive_residue:proof.interpretive_residue || {}};
  if (sideProof.grammar) payload.proof.grammar = sideProof.grammar;
  if (sideProof.refusal) payload.proof.refusal = sideProof.refusal;
  return payload;
}

function svgText(parent, x, y, value, attrs) {
  const node = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  node.setAttribute('x', x); node.setAttribute('y', y); node.textContent = value;
  Object.entries(attrs || {}).forEach(([key, attrValue]) => node.setAttribute(key, attrValue));
  parent.appendChild(node);
}

function wrapText(value, maximum) {
  const words = String(value || '').trim().split(/\s+/).filter(Boolean);
  const lines = [];
  let current = '';
  words.forEach(word => {
    const candidate = `${current} ${word}`.trim();
    if (current && candidate.length > maximum) {
      lines.push(current);
      current = word;
    } else {
      current = candidate;
    }
  });
  if (current) lines.push(current);
  return lines.length ? lines : [''];
}

function svgTextLines(parent, x, y, lines, lineHeight, attrs) {
  const node = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  node.setAttribute('x', x); node.setAttribute('y', y);
  Object.entries(attrs || {}).forEach(([key, attrValue]) => node.setAttribute(key, attrValue));
  lines.forEach((line, index) => {
    const span = document.createElementNS('http://www.w3.org/2000/svg', 'tspan');
    span.setAttribute('x', x);
    span.setAttribute('dy', index === 0 ? '0' : lineHeight);
    span.textContent = line;
    node.appendChild(span);
  });
  parent.appendChild(node);
}

function monitoringFilmstrip(drawer, doc, code, index, side, visual) {
  const frames = doc.frames || [], bounds = drawer.documentBounds(frames, doc.canvas || {});
  const panelW = 320, frameH = 176, margin = 18, gutter = 18;
  const captionLines = frames.map(frame => wrapText(frame.caption || '', 47));
  const maxCaptionLines = Math.max(1, ...captionLines.map(lines => lines.length));
  const panelH = frameH + 70 + maxCaptionLines * 15;
  const width = margin * 2 + frames.length * panelW + Math.max(0, frames.length - 1) * gutter;
  const height = margin * 2 + panelH;
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
  svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', `${code} ${side} filmstrip ${visual.expression || ''}`.trim());
  const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  Object.entries({x:'0', y:'0', width:String(width), height:String(height), fill:'#f8f1df'})
    .forEach(([key, value]) => bg.setAttribute(key, value));
  svg.appendChild(bg);
  appendMetadata(svg, 'monitoring-visual-proof', proofMetadata(code,index,side,visual,'hermes_monitoring_visual_filmstrip_proof'));
  frames.forEach((frame, frameIndex) => {
    const x = margin + frameIndex * (panelW + gutter), group = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    group.setAttribute('data-frame-index', String(frameIndex));
    group.setAttribute('data-caption-lines', String(captionLines[frameIndex].length));
    group.setAttribute('transform', `translate(${x} ${margin})`);
    const panel = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    Object.entries({x:'0', y:'0', width:String(panelW), height:String(panelH), rx:'6', fill:'#fffaf0', stroke:'#cabf9f'})
      .forEach(([key, value]) => panel.setAttribute(key, value));
    group.appendChild(panel);
    const frameNode = drawer.buildSvg(frame, bounds);
    Object.entries({x:'10', y:'10', width:String(panelW-20), height:String(frameH)})
      .forEach(([key, value]) => frameNode.setAttribute(key, value));
    group.appendChild(frameNode);
    const step = frame.step == null ? frameIndex + 1 : frame.step;
    svgText(group, 14, frameH+34, `Step ${step}: ${frame.verb || 'frame'}`, {
      'font-family':'Georgia, Times New Roman, serif', 'font-size':'14', 'font-weight':'700', fill:'#1b1810'});
    svgTextLines(group, 14, frameH+56, captionLines[frameIndex], 15, {
      'font-family':'system-ui, sans-serif', 'font-size':'12', fill:'#4d4638'});
    svg.appendChild(group);
  });
  return clean(svg);
}

function monitoring(drawer, docs, outDir) {
  const written = [];
  for (const [code, payload] of Object.entries(docs)) {
    const visuals = payload.visuals || [];
    visuals.forEach((visual, index) => ['correct', 'incorrect'].forEach(side => {
      const doc = visual[side] && visual[side].doc, frames = doc && Array.isArray(doc.frames) ? doc.frames : [];
      if (!frames.length) return;
      const finalOptions = {index:frames.length-1, ariaLabel:`${code} ${side} ${visual.expression || ''}`.trim(),
        metadataKind:'monitoring-visual-proof', metadata:proofMetadata(code,index,side,visual,'hermes_monitoring_visual_proof')};
      const finalPath = path.join(outDir, fileName(code, visuals.length, index, side, false));
      fs.writeFileSync(finalPath, frameSvg(drawer, doc, finalOptions)); written.push(finalPath);
      if (frames.length > 1) {
        const stripPath = path.join(outDir, fileName(code, visuals.length, index, side, true));
        fs.writeFileSync(stripPath, monitoringFilmstrip(drawer, doc, code, index, side, visual));
        written.push(stripPath);
      }
    }));
  }
  return written;
}

function main() {
  const input = JSON.parse(fs.readFileSync(0, 'utf8'));
  const drawer = loadDrawer(input.repoRoot || process.cwd());
  if (input.mode === 'monitoring') {
    process.stdout.write(JSON.stringify(monitoring(drawer, input.documents || {}, input.outputDir)));
    return;
  }
  if (input.mode === 'dispatch-formats') {
    process.stdout.write(JSON.stringify(Object.keys(drawer.DISPATCH)));
    return;
  }
  if (input.mode === 'frame') process.stdout.write(frameSvg(drawer, input.document, input.options || {}));
  else if (input.mode === 'filmstrip') process.stdout.write(filmstripSvg(drawer, input.document, input.options || {}));
  else throw new Error(`unsupported adapter mode: ${input.mode}`);
}

try { main(); } catch (error) { process.stderr.write(`${error.stack || error}\n`); process.exit(1); }
