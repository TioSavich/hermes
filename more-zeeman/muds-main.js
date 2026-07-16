// muds-main.js — page glue: register switcher, picker, metaphor cards.
// Depends on mud-render.js (MudRender) and metaphor-art.js (MetaphorArt).

'use strict';

(function() {

  // ────── Discursive-level toggle (page-local; intro prose only) ──────

  const PROSE_AREA = document.getElementById('prose-area');
  const ORIGINAL_PROSE = PROSE_AREA.innerHTML;

  const REGISTER_STUB = {
    freshman:
      'This register is not yet written. The philosopher register below is what has been written so far. The freshman view will narrate the same diagram in undergraduate language, but that prose has not yet been drafted.',
    'math-ed':
      'This register is not yet written. The philosopher register below is what has been written so far. The math-ed view will frame the diagram for teacher educators, but that prose has not yet been drafted.',
  };

  document.querySelectorAll('.reg-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.reg-btn').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-pressed', 'false');
      });
      btn.classList.add('active');
      btn.setAttribute('aria-pressed', 'true');
      const reg = btn.dataset.reg;
      if (reg === 'philosopher') {
        PROSE_AREA.innerHTML = ORIGINAL_PROSE;
      } else {
        const note = REGISTER_STUB[reg] || 'This register is not yet written.';
        PROSE_AREA.innerHTML = `
          <div class="stub">
            <b>${reg} register — not yet written</b>
            ${note}
          </div>`;
      }
    });
  });

  // ────── Metaphor cards ──────
  //
  // Both kind (basic|repair) and short-name come from the Prolog-emitted
  // JSON (grounding_metaphors:metaphor_kind/2 and metaphor_short_name/2).
  // Adding a new metaphor only requires Prolog edits + a re-run of
  // research_corpus/scripts/export_mua_for_mud.py; no JS changes here.

  function metaphorKind(m) {
    return m.kind || 'basic';
  }

  function metaphorTitle(id, byId) {
    // Prefer the Prolog-emitted short_name; fall back to underscore-split.
    if (byId && byId.has(id)) {
      const m = byId.get(id);
      if (m && m.short_name) {
        // The Prolog short name uses ASCII "-1"; render with Unicode minus
        // when displaying the rotation repair to honour the typographic
        // intent of the original short label.
        if (id === 'multiplication_by_minus_one_is_rotation_by_180_degrees') {
          return m.short_name.replace(/-1\b/, '−1').replace(/(\d)\s*degrees/, '$1°');
        }
        return m.short_name;
      }
    }
    return id.replace(/_/g, ' ');
  }

  function illustrationFor(id) {
    // Map metaphor id → MetaphorArt method.
    return MetaphorArt.for(id);
  }

  function renderMetaphors(data) {
    const basicDiv = document.getElementById('gm-basic');
    const repairDiv = document.getElementById('gm-repair');
    basicDiv.innerHTML = '';
    repairDiv.innerHTML = '';

    // Group + order by the Prolog-emitted `kind` field. Within each
    // group we keep the natural order from the JSON (which sorts
    // alphabetically by id); the four basic metaphors already read
    // collection -> construction -> measuring stick -> motion under
    // that order, so no additional rule is needed. New metaphors land
    // in the correct group automatically once they have a
    // `metaphor_kind/2` fact in Prolog.
    const byId = new Map(data.metaphors.map(m => [m.id, m]));
    const basics = data.metaphors.filter(m => metaphorKind(m) === 'basic');
    const repairs = data.metaphors.filter(m => metaphorKind(m) === 'repair');

    function buildCard(m) {
      const isBasic = metaphorKind(m) === 'basic';
      const mBreaks = data.metaphor_breaks.filter(r => r.metaphor === m.id);
      const mRepairs = data.metaphor_repairs.filter(r => r.broken === m.id);
      const repairsForBreak = [];
      for (const r of mRepairs) {
        if (mBreaks.some(b => b.inference === r.inference)) repairsForBreak.push(r);
      }
      const card = document.createElement('div');
      card.className = 'gm-card ' + (isBasic ? 'basic' : 'repair');

      const breaksHtml = mBreaks.length
        ? `<div class="section">Breaks at</div>
           <ul>${mBreaks.map(b => `
             <li class="brk"><code>${b.inference.replace(/_/g,' ')}</code>
             <span class="why">${b.reason}</span></li>`).join('')}
           </ul>`
        : '';

      const repairsHtml = repairsForBreak.length
        ? `<div class="section">Repaired by</div>
           <ul>${repairsForBreak.map(r => {
             const mech = r.mechanism.replace(/^see\(|\)$/g,'').replace(/_/g,' ');
             const target = r.repair === 'none_in_this_metaphor'
               ? `<em>no in-metaphor repair — see ${mech}</em>`
               : `<code>${metaphorTitle(r.repair, byId)}</code>`;
             return `<li class="rep"><code>${r.inference.replace(/_/g,' ')}</code> → ${target}
                     <span class="why">${mech}</span></li>`;
           }).join('')}</ul>`
        : '';

      card.innerHTML = `
        <div class="illus">${illustrationFor(m.id)}</div>
        <div class="body">
          <h4>${metaphorTitle(m.id, byId)}</h4>
          <div class="kind">${isBasic ? 'Basic grounding' : 'Repair metaphor'}</div>
          <div class="src">source: ${m.source.replace(/_/g,' ')}
            <span class="arr">→</span> target: ${m.target.replace(/_/g,' ')}</div>
          <div class="desc">${m.description}</div>
          ${breaksHtml}
          ${repairsHtml}
        </div>`;
      return card;
    }

    basics.forEach(m => basicDiv.appendChild(buildCard(m)));
    repairs.forEach(m => repairDiv.appendChild(buildCard(m)));
  }

  // ────── Picker ──────

  function populatePicker(data) {
    const sel = document.getElementById('practice-select');
    sel.innerHTML = '';
    const items = data.practices.slice().sort((a, b) =>
      MudRender.prettyId(a.id).localeCompare(MudRender.prettyId(b.id))
    );
    for (const p of items) {
      const opt = document.createElement('option');
      opt.value = p.id;
      opt.textContent = MudRender.prettyId(p.id);
      sel.appendChild(opt);
    }
    sel.value = 'p_cross_multiplication_rule_from_pattern';
    sel.addEventListener('change', e => MudRender.renderMud(data, e.target.value));

    // quick-pick buttons
    document.querySelectorAll('.quick-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.quick;
        sel.value = id;
        MudRender.renderMud(data, id);
      });
    });
  }

  // ────── Boot ──────

  Spine.loadJson('mua_data.json', { root: '' })
    .then(data => {
      populatePicker(data);
      MudRender.renderMud(data, 'p_cross_multiplication_rule_from_pattern');
      renderMetaphors(data);
    })
    .catch(err => {
      const cap = document.getElementById('mud-caption');
      if (cap) cap.textContent =
        'Could not load mua_data.json. Run research_corpus/scripts/export_mua_for_mud.py and reload. (' + err + ')';
    });

})();
