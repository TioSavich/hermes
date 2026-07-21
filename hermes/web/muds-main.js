// muds-main.js — page glue: register switcher, picker, metaphor cards.
// Depends on mud-render.js (MudRender) and metaphor-art.js (MetaphorArt).

'use strict';

(function() {

  // ────── Discursive-level toggle (page-local; intro prose only) ──────

  const PROSE_AREA = document.getElementById('prose-area');
  const ORIGINAL_PROSE = PROSE_AREA.innerHTML;

  // Each register narrates the same diagram for a different reader. The
  // facts underneath (formal/pml/mua_relations.pl) do not change; the
  // vocabulary that makes them accessible does.
  const REGISTER_PROSE = {
    'math-ed': `
      <h2 class="head">Doings and sayings in a strategy registry</h2>
      <p class="lead">A child who counts on from the larger addend can
      already do most of what long division will one day require: hold a
      number, act on it in order, keep track of what remains. This page
      charts relations of that kind. A box is a practice a student can
      have; an oval is a vocabulary a classroom can talk in; an arrow
      records a sufficiency claim &mdash; this doing is enough to build
      that one, this talk is enough to spell out that doing. Brandom's
      name for the composite relation, LX, fits classroom work closely:
      talk that grows out of a practice and, once grown, says what the
      practice was already doing.</p>
      <p>The pairing teachers usually meet as procedural and conceptual
      knowledge sits inside these arrows rather than beside them. On the
      account this page draws from, grasping a concept is a practical
      mastery: the student who reliably makes ten, and can tell what
      makes the move good, holds the concept, and the telling is the
      doing made explicit. Long division is Brandom's own example of
      elaboration &mdash; multiplication and subtraction exercised in the
      right order under the right conditions. What a curriculum calls
      building on prior knowledge, the diagram treats as a claim precise
      enough to check: which abilities suffice to assemble which others.</p>
      <p>The arrows also carry a stake beyond arithmetic. A strategy is
      an action, and an action is something a student can answer for.
      When a student names the move they made and stands behind it, or
      revises it under a classmate's question, they take on a commitment;
      the mathematics becomes theirs to defend and to change. Freedom in
      a mathematics classroom, read this way, is the capacity to bind
      oneself to a claim and remain answerable for it. The diagram cannot
      draw that becoming, but every LX edge it holds is a place where it
      can happen.</p>`,
    freshman: `
      <h2 class="head">What you can do and what you can say</h2>
      <p class="lead">You already know how to do more mathematics than
      you can put into words. This page draws maps of that gap and of the
      ways across it. A box is something a person can do: count on from
      the larger number, split a ten, share a total into equal groups. An
      oval is a way of talking. An arrow is a claim about enough: if you
      can do this, you can already build that; if a class can talk this
      way, it can spell out what that doing was.</p>
      <p>The example the framework itself uses is long division. There is
      no extra ingredient in it: multiplication, subtraction, and writing
      results down, run in the right order, are the whole of it. New
      abilities in mathematics are mostly old abilities put together
      under a schedule, and the diagram records which ones suffice.</p>
      <p>The dashed line marks something worth noticing in your own work.
      When you explain why your move was a good one, the explanation
      turns a habit into a claim you hold: a thing you can defend, fix
      when it fails, or hand to someone else. Mathematics starts to
      belong to you at exactly that step, and it is also the step where
      you can be asked for reasons. Both are the same fact about what an
      explanation is.</p>`,
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
      } else if (REGISTER_PROSE[reg]) {
        PROSE_AREA.innerHTML = REGISTER_PROSE[reg];
      } else {
        PROSE_AREA.innerHTML = `
          <div class="stub">
            <b>${reg} register — not yet written</b>
            This register is not yet written.
          </div>`;
      }
    });
  });

  // ────── Metaphor cards ──────
  //
  // Both kind and short-name come from the Prolog-emitted JSON
  // (grounding_metaphors:metaphor_kind/2 and metaphor_short_name/2). Kind is
  // not limited to basic|repair — the registry also carries
  // algebraic_essence, schema, specialization_substrate,
  // philosophical_substrate, metonymy, and blend. basic and repair route to
  // their own grids; every other kind routes to the third, "extended" grid.
  // Adding a new metaphor only requires Prolog edits + a re-run of
  // research_corpus/scripts/export_mua_for_mud.py; no JS changes here as
  // long as its kind is one of the three routed groups.

  function metaphorKind(m) {
    return m.kind || 'basic';
  }

  function metaphorGroup(m) {
    const kind = metaphorKind(m);
    if (kind === 'basic' || kind === 'repair') return kind;
    return 'extended';
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
    const extendedDiv = document.getElementById('gm-extended');
    basicDiv.innerHTML = '';
    repairDiv.innerHTML = '';
    extendedDiv.innerHTML = '';

    // Group + order by the Prolog-emitted `kind` field. Within each
    // group we keep the natural order from the JSON (which sorts
    // alphabetically by id); the four L&N grounding metaphors already
    // read collection -> construction -> measuring stick -> motion
    // under that order, so no additional rule is needed. New metaphors
    // land in the correct group automatically once they have a
    // `metaphor_kind/2` fact in Prolog: basic and repair get their own
    // grid, every other kind lands in the extended grid.
    const byId = new Map(data.metaphors.map(m => [m.id, m]));
    const basics = data.metaphors.filter(m => metaphorGroup(m) === 'basic');
    const repairs = data.metaphors.filter(m => metaphorGroup(m) === 'repair');
    const extended = data.metaphors.filter(m => metaphorGroup(m) === 'extended');

    const KIND_LABEL = {
      basic: 'Basic grounding',
      repair: 'Repair metaphor',
    };

    function buildCard(m) {
      const group = metaphorGroup(m);
      const mBreaks = data.metaphor_breaks.filter(r => r.metaphor === m.id);
      const mRepairs = data.metaphor_repairs.filter(r => r.broken === m.id);
      const repairsForBreak = [];
      for (const r of mRepairs) {
        if (mBreaks.some(b => b.inference === r.inference)) repairsForBreak.push(r);
      }
      const card = document.createElement('div');
      card.className = 'gm-card ' + group;
      const kindLabel = KIND_LABEL[group] ||
        ('Extended registry · ' + metaphorKind(m).replace(/_/g, ' '));

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
          <div class="kind">${kindLabel}</div>
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
    extended.forEach(m => extendedDiv.appendChild(buildCard(m)));
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
