import { motion } from 'framer-motion';
import { Calendar } from 'lucide-react';
import { useLayoutEffect, useMemo, useRef, useState } from 'react';
import { GlassIconButton, GradHeader } from '../components/GradHeader';
import { Money } from '../components/Money';
import { iconFor } from '../lib/categories';
import { MoreHorizontal } from 'lucide-react';
import { monthName, useLang, useT } from '../lib/i18n';
import { byItem, inMonth, sumOf, useStore } from '../lib/store';
import { useUi } from '../lib/ui';

/**
 * Bubble slots copied from the reference layout (x/y as fractions of the area,
 * d = diameter as a fraction of the width), ordered by rank: the biggest
 * category takes the big right bubble, the second the top-left one, etc.
 */
const SLOTS = [
  { x: 0.7, y: 0.52, d: 0.47 },
  { x: 0.29, y: 0.25, d: 0.43 },
  { x: 0.3, y: 0.8, d: 0.37 },
  { x: 0.72, y: 0.15, d: 0.3 },
  { x: 0.71, y: 0.85, d: 0.29 },
  { x: 0.23, y: 0.53, d: 0.27 }, // smallest: "Others" goes here
];

const MAX_BUBBLES = 6;

const GAP = 16; // minimum free space between neighbouring bubbles (px)

/**
 * Start from the reference slots, then push overlapping bubbles apart and keep
 * them inside the area, shrinking all of them a little until every pair has
 * GAP px of air between their outer arcs. Returns centres/diameters in px.
 */
function layoutBubbles(n: number, w: number, h: number) {
  const unit = Math.min(w, h * 0.8);
  let scale = 0.94;
  for (let attempt = 0; attempt < 12; attempt++) {
    const b = SLOTS.slice(0, n).map((s) => ({ x: s.x * w, y: s.y * h, r: (s.d * unit * scale) / 2 }));
    // the white arc sits 6% outside the circle
    const outer = (r: number) => r * 1.06 + 2;
    for (let it = 0; it < 300; it++) {
      let moved = false;
      for (let i = 0; i < b.length; i++) {
        for (let j = i + 1; j < b.length; j++) {
          const dx = b[j].x - b[i].x;
          const dy = b[j].y - b[i].y;
          const dist = Math.hypot(dx, dy) || 0.01;
          const need = outer(b[i].r) + outer(b[j].r) + GAP;
          if (dist < need) {
            const push = (need - dist) / 2;
            const ux = dx / dist;
            const uy = dy / dist;
            b[i].x -= ux * push;
            b[i].y -= uy * push;
            b[j].x += ux * push;
            b[j].y += uy * push;
            moved = true;
          }
        }
      }
      for (const c of b) {
        const m = outer(c.r) + 4;
        c.x = Math.min(Math.max(c.x, m), w - m);
        c.y = Math.min(Math.max(c.y, m), h - m);
      }
      if (!moved) break;
    }
    const ok = b.every((p, i) =>
      b.every((q, j) => j <= i || Math.hypot(p.x - q.x, p.y - q.y) >= outer(p.r) + outer(q.r) + GAP - 0.5),
    );
    if (ok) return b.map((c) => ({ x: c.x / w, y: c.y / h, size: c.r * 2 }));
    scale *= 0.94;
  }
  return SLOTS.slice(0, n).map((s) => ({ x: s.x, y: s.y, size: s.d * unit * scale }));
}

function Bubble({
  slot,
  size,
  share,
  label,
  Icon,
  index,
  pctText,
}: {
  slot: { x: number; y: number };
  size: number;
  share: number;
  label: string;
  Icon: React.ComponentType<{ size?: number; strokeWidth?: number }>;
  index: number;
  pctText: string;
}) {
  const r = 50;
  const ringR = 53;
  return (
    <motion.div
      className="bubble"
      style={{ left: `${slot.x * 100}%`, top: `${slot.y * 100}%`, width: size, height: size }}
      initial={{ scale: 0, opacity: 0, x: '-50%', y: '-50%' }}
      animate={{ scale: 1, opacity: 1, x: '-50%', y: '-50%' }}
      transition={{ type: 'spring', stiffness: 160, damping: 15, delay: 0.08 + index * 0.07 }}
    >
      <svg className="ring" viewBox="0 0 100 100">
        <defs>
          <linearGradient id={`arc-${index}`} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#fff" stopOpacity="0.15" />
            <stop offset="0.35" stopColor="#fff" stopOpacity="1" />
          </linearGradient>
        </defs>
        {/* lighter pie sector for the share */}
        <motion.circle
          cx="50"
          cy="50"
          r={r / 2}
          fill="none"
          stroke="rgba(255,255,255,0.16)"
          strokeWidth={r}
          transform="rotate(-90 50 50)"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: share }}
          transition={{ duration: 1.1, ease: [0.22, 1, 0.36, 1], delay: 0.35 + index * 0.07 }}
        />
        {/* thin white arc just outside the edge */}
        <motion.circle
          cx="50"
          cy="50"
          r={ringR}
          fill="none"
          stroke={`url(#arc-${index})`}
          strokeWidth="1.6"
          strokeLinecap="round"
          transform="rotate(-90 50 50)"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: share }}
          transition={{ duration: 1.1, ease: [0.22, 1, 0.36, 1], delay: 0.35 + index * 0.07 }}
        />
      </svg>
      <Icon size={Math.max(18, size * 0.13)} strokeWidth={1.5} />
      <div
        className="b-label"
        style={{ fontSize: size < 110 ? 10.5 : 12, WebkitLineClamp: size < 110 ? 2 : 3 }}
      >
        {label}
      </div>
      <div className="b-pct num">{pctText}</div>
    </motion.div>
  );
}

export function Stats() {
  const t = useT();
  const lang = useLang();
  const txs = useStore((s) => s.txs);
  const { view, openSheet, setTab } = useUi();
  const area = useRef<HTMLDivElement>(null);
  const [box, setBox] = useState({ w: 340, h: 420 });

  useLayoutEffect(() => {
    const el = area.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setBox({ w: el.clientWidth, h: el.clientHeight }));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const month = inMonth(txs, view.year, view.month);
  const total = sumOf(month, 'expense');
  // one bubble per thing the money was spent on (the user's own words):
  // the five biggest, plus one "Others" bubble for the rest
  let cats = byItem(month, 'expense').map((c) => ({ ...c, others: false }));
  if (cats.length > MAX_BUBBLES) {
    const rest = cats.slice(MAX_BUBBLES - 1).reduce((s, c) => s + c.total, 0);
    cats = [...cats.slice(0, MAX_BUBBLES - 1), { key: '__others', label: t.others, total: rest, others: true }];
  }
  const labelOf = (c: (typeof cats)[number]) => c.label || t.expense;
  const iconOf = (c: (typeof cats)[number]) => (c.others ? MoreHorizontal : iconFor(c.label, 'expense'));
  // spaced so every bubble has room around it, on any screen height
  const placed = useMemo(() => layoutBubbles(cats.length, box.w, box.h), [cats.length, box.w, box.h]);
  const fmtPct = (v: number) =>
    v.toLocaleString(lang === 'ar' ? 'ar-SY-u-nu-latn' : 'de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 }) + '%';

  return (
    <div className="screen grad-screen">
      <GradHeader
        title={`${monthName(view.month, lang)} ${view.year}`}
        action={
          <GlassIconButton onClick={() => openSheet({ kind: 'month' })} label={t.pickMonth}>
            <Calendar size={20} strokeWidth={1.6} />
          </GlassIconButton>
        }
      />

      <div className="bubbles" ref={area} key={`${view.year}-${view.month}`}>
        {cats.length === 0 ? (
          <motion.div
            className="center-col"
            style={{ position: 'absolute', inset: 0, justifyContent: 'center', color: 'rgba(255,255,255,.75)' }}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
          >
            <div className="bubble" style={{ position: 'relative', width: 150, height: 150, transform: 'none' }} />
            <div style={{ marginTop: 18 }}>{t.noStats}</div>
          </motion.div>
        ) : (
          cats.map((c, i) => {
            const share = total > 0 ? c.total / total : 0;
            const slot = placed[i];
            return (
              <Bubble
                key={c.key}
                slot={slot}
                size={slot.size}
                share={share}
                label={labelOf(c)}
                Icon={iconOf(c)}
                index={i}
                pctText={fmtPct(share * 100)}
              />
            );
          })
        )}
      </div>

      <motion.div
        className="white-sheet"
        style={{ padding: '24px 20px calc(var(--safe-bottom) + 92px)', flex: 'none' }}
        initial={{ y: 120 }}
        animate={{ y: 0 }}
        transition={{ type: 'spring', stiffness: 200, damping: 26 }}
      >
        <div className="sheet-head">
          <h2>{t.expenses}</h2>
          <button className="link" onClick={() => setTab('tx')}>
            {t.viewAll}
          </button>
        </div>
        <div className="big-amount">
          <Money value={total} animate />
        </div>
        <div className="tiles">
          {[0, 1].map((i) => {
            const c = cats[i];
            const Icon = c ? iconOf(c) : null;
            return (
              <motion.div
                key={c?.key ?? `empty-${i}`}
                className="tile"
                initial={{ opacity: 0, y: 14 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.25 + i * 0.08 }}
              >
                <div className="tile-top">
                  <span className="tile-label">{c ? labelOf(c) : '—'}</span>
                  {Icon && <Icon size={17} strokeWidth={1.6} />}
                </div>
                <div className="tile-amount">
                  <Money value={c?.total ?? 0} />
                </div>
              </motion.div>
            );
          })}
        </div>
      </motion.div>
    </div>
  );
}
