/**
 * MITRE ATLAS Kill-Chain timeline (PLAN.md §6 Phase 4) — vanilla JS/SVG, no
 * charting library dependency. This never replaces the server-rendered
 * <ol data-testid="killchain"> list next to it (that list is the accessible,
 * no-JS-safe source of truth); it only draws a decorative SVG timeline
 * alongside it, marked aria-hidden in the markup already.
 */
(function () {
  'use strict';

  const SVG_NS = 'http://www.w3.org/2000/svg';
  const NODE_RADIUS = 22;
  const NODE_SPACING = 160;
  const ROW_Y = 40;

  document.querySelectorAll('[data-testid="killchain"]').forEach(function (list) {
    let stages;
    try {
      stages = JSON.parse(list.dataset.killchain || '[]');
    } catch (e) {
      return;
    }

    const container = list.parentElement.querySelector('[data-testid="killchain-svg"]');
    if (!container || !Array.isArray(stages) || stages.length === 0) {
      return;
    }

    const width = Math.max(stages.length * NODE_SPACING, NODE_SPACING);
    const svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('viewBox', '0 0 ' + width + ' 100');
    svg.setAttribute('width', '100%');
    svg.setAttribute('height', '100');

    stages.forEach(function (stage, index) {
      const cx = NODE_SPACING / 2 + index * NODE_SPACING;

      if (index > 0) {
        const line = document.createElementNS(SVG_NS, 'line');
        line.setAttribute('x1', String(cx - NODE_SPACING + NODE_RADIUS));
        line.setAttribute('y1', String(ROW_Y));
        line.setAttribute('x2', String(cx - NODE_RADIUS));
        line.setAttribute('y2', String(ROW_Y));
        line.setAttribute('stroke', 'currentColor');
        line.setAttribute('stroke-width', '2');
        svg.appendChild(line);
      }

      const circle = document.createElementNS(SVG_NS, 'circle');
      circle.setAttribute('cx', String(cx));
      circle.setAttribute('cy', String(ROW_Y));
      circle.setAttribute('r', String(NODE_RADIUS));
      circle.setAttribute('fill', stage.id ? '#b3261e' : '#546e7a');
      svg.appendChild(circle);

      const label = document.createElementNS(SVG_NS, 'text');
      label.setAttribute('x', String(cx));
      label.setAttribute('y', String(ROW_Y + NODE_RADIUS + 18));
      label.setAttribute('text-anchor', 'middle');
      label.setAttribute('font-size', '11');
      label.setAttribute('fill', 'currentColor');
      label.textContent = stage.tactic;
      svg.appendChild(label);
    });

    container.appendChild(svg);
  });
})();
