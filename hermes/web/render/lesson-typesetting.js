/* Display-only repair for curriculum extraction scars.
 *
 * Stored lesson text remains unchanged. This module repairs line wrapping,
 * promotes extracted bullet glyphs to lists, spaces a welded subtraction
 * sign, and adds MathJax inline delimiters around arithmetic expressions at
 * the moment a page renders the text.
 */
(function (root, factory) {
  'use strict';
  var api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  root.HermesLessonTypesetting = api;
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  var BULLET_RE = /^([•◦])\s*(.*)$/;
  var NUMBERED_RE = /^(\d+[.)])\s+(.*)$/;
  var ROUND_RE = /^(Round\s+\d+:)\s*(.*)$/i;
  var OPERAND = '(?:\\d+(?:\\.\\d+)?(?:\\/\\d+(?:\\.\\d+)?)?[A-Za-z]?|[A-Za-z])';
  var EXPRESSION_RE = new RegExp(
    '(^|[^\\w$])(' + OPERAND + '(?:\\s*(?:[+\\-−×÷=<>])\\s*' + OPERAND + ')+)(?=$|[^\\w$])',
    'g'
  );

  function repairScars(value) {
    return String(value == null ? '' : value)
      .replace(/\r\n?/g, '\n')
      .replace(/\f/g, '')
      .replace(/(\d(?:[\d.,/]*))\s*-\s+(?=\d)/g, '$1 − ')
      .replace(/[ \t]*([•◦])[ \t]*/g, '\n$1 ')
      .replace(/\n{2,}(?=[•◦]\s)/g, '\n')
      .replace(/^\n+|\n+$/g, '');
  }

  function appendText(blocks, text) {
    var clean = text.trim();
    if (!clean) return;
    var last = blocks[blocks.length - 1];
    if (last && last.type === 'paragraph') {
      last.text += ' ' + clean;
    } else {
      blocks.push({type: 'paragraph', text: clean});
    }
  }

  function blocks(value) {
    var lines = repairScars(value).split('\n');
    var result = [];
    var list = null;
    lines.forEach(function (raw) {
      var line = raw.trim();
      if (!line) {
        list = null;
        if (result.length && result[result.length - 1].type === 'paragraph') {
          result.push({type: 'break'});
        }
        return;
      }
      var bullet = BULLET_RE.exec(line);
      if (bullet) {
        if (!list) {
          list = {type: 'list', items: []};
          result.push(list);
        }
        list.items.push({level: bullet[1] === '◦' ? 1 : 0, text: bullet[2].trim()});
        return;
      }
      var numbered = NUMBERED_RE.exec(line);
      if (numbered) {
        list = null;
        result.push({type: 'paragraph', text: numbered[1] + ' ' + numbered[2].trim()});
        return;
      }
      var round = ROUND_RE.exec(line);
      if (round) {
        list = null;
        result.push({type: 'paragraph', text: round[1] + (round[2] ? ' ' + round[2] : '')});
        return;
      }
      if (/^_+$/.test(line)) {
        var priorIndex = result.length - 1;
        while (priorIndex >= 0 && result[priorIndex].type === 'break') priorIndex -= 1;
        var prior = result[priorIndex];
        if (prior && prior.type === 'paragraph' && ROUND_RE.test(prior.text)) {
          prior.text += ' ' + line;
          result.splice(priorIndex + 1);
          return;
        }
      }
      if (list && list.items.length) {
        list.items[list.items.length - 1].text += ' ' + line;
      } else {
        appendText(result, line);
      }
    });
    return result.filter(function (block) { return block.type !== 'break'; });
  }

  function texExpression(expression) {
    return expression
      .replace(/−/g, '-')
      .replace(/×/g, '\\times ')
      .replace(/÷/g, '\\div ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  function markMath(value) {
    var pieces = String(value).split(/(\$[^$\n]+\$)/g);
    return pieces.map(function (piece) {
      if (/^\$[^$\n]+\$$/.test(piece)) return piece;
      return piece.replace(EXPRESSION_RE, function (_whole, prefix, expression) {
        return prefix + '$' + texExpression(expression) + '$';
      });
    }).join('');
  }

  function normalizedText(value) {
    return blocks(value).map(function (block) {
      if (block.type === 'break') return '';
      if (block.type === 'paragraph') return markMath(block.text);
      return block.items.map(function (item) {
        return (item.level ? '  ◦ ' : '• ') + markMath(item.text);
      }).join('\n');
    }).join('\n\n');
  }

  function renderInto(target, value) {
    target.replaceChildren();
    blocks(value).forEach(function (block) {
      if (block.type === 'break') return;
      if (block.type === 'paragraph') {
        var paragraph = document.createElement('p');
        paragraph.className = 'lesson-display-paragraph';
        paragraph.textContent = markMath(block.text);
        target.appendChild(paragraph);
        return;
      }
      var list = document.createElement('ul');
      list.className = 'lesson-display-list';
      block.items.forEach(function (item) {
        var row = document.createElement('li');
        if (item.level) row.className = 'lesson-display-subitem';
        row.textContent = markMath(item.text);
        list.appendChild(row);
      });
      target.appendChild(list);
    });
  }

  function typeset(target) {
    if (typeof window === 'undefined' || !window.MathJax || !window.MathJax.typesetPromise) {
      return Promise.resolve();
    }
    if (window.MathJax.typesetClear) window.MathJax.typesetClear([target]);
    return window.MathJax.typesetPromise([target]).catch(function () {});
  }

  return {
    blocks: blocks,
    markMath: markMath,
    normalizedText: normalizedText,
    renderInto: renderInto,
    repairScars: repairScars,
    typeset: typeset
  };
}));
