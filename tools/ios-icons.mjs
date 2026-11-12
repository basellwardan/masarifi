// Turns the Lucide icons the Android build uses into native vector paths for
// the iPhone app (ios-native/Masarifi/UI/LucideData.swift), so both apps draw
// exactly the same icons. Every shape is converted to absolute M/L/C/Z
// commands in Lucide's 24×24 box; SwiftUI strokes them like the SVGs do.
//
//   node tools/ios-icons.mjs
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// Swift case name -> lucide file name
const ICONS = {
  creditCard: 'credit-card',
  arrowDownUp: 'arrow-down-up',
  arrowUpDown: 'arrow-up-down',
  chartPie: 'chart-pie',
  mic: 'mic',
  layoutGrid: 'layout-grid',
  bell: 'bell',
  bellOff: 'bell-off',
  trendingUp: 'trending-up',
  trendingDown: 'trending-down',
  arrowUpRight: 'arrow-up-right',
  arrowDownRight: 'arrow-down-right',
  arrowDownLeft: 'arrow-down-left',
  arrowLeft: 'arrow-left',
  arrowRight: 'arrow-right',
  calendar: 'calendar',
  ellipsis: 'ellipsis',
  square: 'square',
  camera: 'camera',
  coins: 'coins',
  dollarSign: 'dollar-sign',
  info: 'info',
  languages: 'languages',
  rotateCcw: 'rotate-ccw',
  share2: 'share-2',
  user: 'user',
  wallet: 'wallet',
  check: 'check',
  delete: 'delete',
  trash2: 'trash-2',
  chevronLeft: 'chevron-left',
  chevronRight: 'chevron-right',
  bus: 'bus',
  coffee: 'coffee',
  dumbbell: 'dumbbell',
  gift: 'gift',
  graduationCap: 'graduation-cap',
  heartPulse: 'heart-pulse',
  house: 'house',
  receipt: 'receipt',
  send: 'send',
  shirt: 'shirt',
  shoppingCart: 'shopping-cart',
};

const fmt = (n) => {
  const s = (Math.round(n * 1000) / 1000).toString();
  return s === '-0' ? '0' : s;
};

/** SVG endpoint arc -> cubic béziers (standard a2c conversion). */
function arcToCubics(x1, y1, rx, ry, phiDeg, largeArc, sweep, x2, y2) {
  if (rx === 0 || ry === 0) return [[x1, y1, x2, y2, x2, y2]];
  const phi = (phiDeg * Math.PI) / 180;
  const cos = Math.cos(phi);
  const sin = Math.sin(phi);
  const dx = (x1 - x2) / 2;
  const dy = (y1 - y2) / 2;
  const x1p = cos * dx + sin * dy;
  const y1p = -sin * dx + cos * dy;
  rx = Math.abs(rx);
  ry = Math.abs(ry);
  const lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
  if (lambda > 1) {
    rx *= Math.sqrt(lambda);
    ry *= Math.sqrt(lambda);
  }
  const num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p;
  const den = rx * rx * y1p * y1p + ry * ry * x1p * x1p;
  let coef = Math.sqrt(Math.max(0, num / den));
  if (largeArc === sweep) coef = -coef;
  const cxp = (coef * rx * y1p) / ry;
  const cyp = (-coef * ry * x1p) / rx;
  const cx = cos * cxp - sin * cyp + (x1 + x2) / 2;
  const cy = sin * cxp + cos * cyp + (y1 + y2) / 2;
  const angle = (ux, uy, vx, vy) => {
    const a = Math.atan2(ux * vy - uy * vx, ux * vx + uy * vy);
    return a;
  };
  const th1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
  let dth = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry);
  if (!sweep && dth > 0) dth -= 2 * Math.PI;
  if (sweep && dth < 0) dth += 2 * Math.PI;
  const segs = Math.ceil(Math.abs(dth) / (Math.PI / 2) - 1e-9);
  const out = [];
  const delta = dth / segs;
  const t = (4 / 3) * Math.tan(delta / 4);
  let th = th1;
  const pt = (a) => {
    const ex = rx * Math.cos(a);
    const ey = ry * Math.sin(a);
    return [cos * ex - sin * ey + cx, sin * ex + cos * ey + cy];
  };
  const dpt = (a) => {
    const ex = -rx * Math.sin(a);
    const ey = ry * Math.cos(a);
    return [cos * ex - sin * ey, sin * ex + cos * ey];
  };
  for (let i = 0; i < segs; i++) {
    const a0 = th;
    const a1 = th + delta;
    const p0 = pt(a0);
    const p1 = pt(a1);
    const d0 = dpt(a0);
    const d1 = dpt(a1);
    out.push([p0[0] + t * d0[0], p0[1] + t * d0[1], p1[0] - t * d1[0], p1[1] - t * d1[1], p1[0], p1[1]]);
    th = a1;
  }
  return out;
}

/** Parses SVG path data into absolute M/L/C/Z commands. */
function normalizePath(d) {
  const tokens = d.match(/[a-zA-Z]|-?(?:\d*\.\d+|\d+\.?)(?:e[-+]?\d+)?/g);
  let i = 0;
  let cmd = '';
  let x = 0;
  let y = 0;
  let sx = 0;
  let sy = 0;
  let lastC = null; // last cubic control point (for S)
  let lastQ = null; // last quadratic control point (for T)
  const out = [];
  const num = () => parseFloat(tokens[i++]);
  const flag = () => {
    // flags may be glued: "a1 1 0 01.5.5"
    const tk = tokens[i];
    if (tk.length > 1 && (tk[0] === '0' || tk[0] === '1') && !tk.startsWith('0.')) {
      tokens[i] = tk.slice(1);
      return tk[0] === '1';
    }
    i++;
    return parseFloat(tk) !== 0;
  };
  while (i < tokens.length) {
    if (/[a-zA-Z]/.test(tokens[i])) cmd = tokens[i++];
    const rel = cmd === cmd.toLowerCase();
    const C = cmd.toUpperCase();
    const ox = rel ? x : 0;
    const oy = rel ? y : 0;
    switch (C) {
      case 'M': {
        x = ox + num();
        y = oy + num();
        sx = x;
        sy = y;
        out.push(`M${fmt(x)} ${fmt(y)}`);
        cmd = rel ? 'l' : 'L';
        lastC = lastQ = null;
        break;
      }
      case 'L':
        x = ox + num();
        y = oy + num();
        out.push(`L${fmt(x)} ${fmt(y)}`);
        lastC = lastQ = null;
        break;
      case 'H':
        x = (rel ? x : 0) + num();
        out.push(`L${fmt(x)} ${fmt(y)}`);
        lastC = lastQ = null;
        break;
      case 'V':
        y = (rel ? y : 0) + num();
        out.push(`L${fmt(x)} ${fmt(y)}`);
        lastC = lastQ = null;
        break;
      case 'C': {
        const c = [ox + num(), oy + num(), ox + num(), oy + num(), ox + num(), oy + num()];
        out.push(`C${c.map(fmt).join(' ')}`);
        lastC = [c[2], c[3]];
        x = c[4];
        y = c[5];
        lastQ = null;
        break;
      }
      case 'S': {
        const c1 = lastC ? [2 * x - lastC[0], 2 * y - lastC[1]] : [x, y];
        const c = [ox + num(), oy + num(), ox + num(), oy + num()];
        out.push(`C${[...c1, ...c].map(fmt).join(' ')}`);
        lastC = [c[0], c[1]];
        x = c[2];
        y = c[3];
        lastQ = null;
        break;
      }
      case 'Q': {
        const q = [ox + num(), oy + num(), ox + num(), oy + num()];
        const c1 = [x + (2 / 3) * (q[0] - x), y + (2 / 3) * (q[1] - y)];
        const c2 = [q[2] + (2 / 3) * (q[0] - q[2]), q[3] + (2 / 3) * (q[1] - q[3])];
        out.push(`C${[...c1, ...c2, q[2], q[3]].map(fmt).join(' ')}`);
        lastQ = [q[0], q[1]];
        x = q[2];
        y = q[3];
        lastC = null;
        break;
      }
      case 'T': {
        const qc = lastQ ? [2 * x - lastQ[0], 2 * y - lastQ[1]] : [x, y];
        const e = [ox + num(), oy + num()];
        const c1 = [x + (2 / 3) * (qc[0] - x), y + (2 / 3) * (qc[1] - y)];
        const c2 = [e[0] + (2 / 3) * (qc[0] - e[0]), e[1] + (2 / 3) * (qc[1] - e[1])];
        out.push(`C${[...c1, ...c2, ...e].map(fmt).join(' ')}`);
        lastQ = qc;
        x = e[0];
        y = e[1];
        lastC = null;
        break;
      }
      case 'A': {
        const rx = num();
        const ry = num();
        const rot = num();
        const large = flag();
        const sweep = flag();
        const ex = ox + num();
        const ey = oy + num();
        for (const c of arcToCubics(x, y, rx, ry, rot, large, sweep, ex, ey)) out.push(`C${c.map(fmt).join(' ')}`);
        x = ex;
        y = ey;
        lastC = lastQ = null;
        break;
      }
      case 'Z':
        out.push('Z');
        x = sx;
        y = sy;
        lastC = lastQ = null;
        break;
      default:
        throw new Error(`unsupported path command ${cmd} in ${d}`);
    }
  }
  return out.join('');
}

const n = (v, dflt = 0) => (v === undefined ? dflt : parseFloat(v));

function elementToPath([tag, a]) {
  switch (tag) {
    case 'path':
      return normalizePath(a.d);
    case 'line':
      return `M${fmt(n(a.x1))} ${fmt(n(a.y1))}L${fmt(n(a.x2))} ${fmt(n(a.y2))}`;
    case 'polyline':
    case 'polygon': {
      const p = a.points.trim().split(/[\s,]+/).map(Number);
      let s = `M${fmt(p[0])} ${fmt(p[1])}`;
      for (let k = 2; k < p.length; k += 2) s += `L${fmt(p[k])} ${fmt(p[k + 1])}`;
      return tag === 'polygon' ? s + 'Z' : s;
    }
    case 'circle':
    case 'ellipse': {
      const cx = n(a.cx);
      const cy = n(a.cy);
      const rx = tag === 'circle' ? n(a.r) : n(a.rx);
      const ry = tag === 'circle' ? n(a.r) : n(a.ry);
      return normalizePath(
        `M${cx + rx} ${cy}A${rx} ${ry} 0 0 1 ${cx} ${cy + ry}A${rx} ${ry} 0 0 1 ${cx - rx} ${cy}A${rx} ${ry} 0 0 1 ${cx} ${cy - ry}A${rx} ${ry} 0 0 1 ${cx + rx} ${cy}Z`,
      );
    }
    case 'rect': {
      const x = n(a.x);
      const y = n(a.y);
      const w = n(a.width);
      const h = n(a.height);
      let rx = a.rx !== undefined ? n(a.rx) : a.ry !== undefined ? n(a.ry) : 0;
      let ry = a.ry !== undefined ? n(a.ry) : rx;
      rx = Math.min(rx, w / 2);
      ry = Math.min(ry, h / 2);
      if (!rx) return `M${x} ${y}L${x + w} ${y}L${x + w} ${y + h}L${x} ${y + h}Z`;
      return normalizePath(
        `M${x + rx} ${y}H${x + w - rx}A${rx} ${ry} 0 0 1 ${x + w} ${y + ry}V${y + h - ry}A${rx} ${ry} 0 0 1 ${x + w - rx} ${y + h}H${x + rx}A${rx} ${ry} 0 0 1 ${x} ${y + h - ry}V${y + ry}A${rx} ${ry} 0 0 1 ${x + rx} ${y}Z`,
      );
    }
    default:
      throw new Error(`unsupported element ${tag}`);
  }
}

const lines = [];
for (const [name, file] of Object.entries(ICONS)) {
  const mod = await import(`file://${join(ROOT, 'node_modules/lucide-react/dist/esm/icons', `${file}.js`).replace(/\\/g, '/')}`);
  const d = mod.__iconNode.map(elementToPath).join('');
  lines.push(`        case .${name}: return "${d}"`);
}

const swift = `// Generated by tools/ios-icons.mjs from lucide-react ${
  (await import(`file://${join(ROOT, 'node_modules/lucide-react/package.json').replace(/\\/g, '/')}`, { with: { type: 'json' } })).default.version
} (ISC licence). Do not edit.
// Absolute M/L/C/Z path data in Lucide's 24×24 box.

enum LucideIcon: CaseIterable {
    case ${Object.keys(ICONS).join(', ')}

    var pathData: String {
        switch self {
${lines.join('\n')}
        }
    }
}
`;
writeFileSync(join(ROOT, 'ios-native/Masarifi/UI/LucideData.swift'), swift);
console.log(`wrote ${Object.keys(ICONS).length} icons`);
