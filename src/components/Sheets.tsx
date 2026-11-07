import { motion } from 'framer-motion';
import { ChevronLeft, ChevronRight, TrendingDown, TrendingUp, BellOff } from 'lucide-react';
import { iconFor } from '../lib/categories';
import { monthName, useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { byItem, inMonth, sumOf, useStore } from '../lib/store';
import { useUi } from '../lib/ui';
import { ModalSheet } from './ModalSheet';
import { Money } from './Money';

export function MonthSheet() {
  const t = useT();
  const lang = useLang();
  const { view, setView, closeSheet } = useUi();
  const [Prev, Next] = lang === 'ar' ? [ChevronRight, ChevronLeft] : [ChevronLeft, ChevronRight];
  return (
    <ModalSheet onClose={closeSheet}>
      <div className="sheet-head" style={{ alignItems: 'center', marginBottom: 16 }}>
        <h2>{t.pickMonth}</h2>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <button className="mic-mini" onClick={() => setView(view.year - 1, view.month)} aria-label="prev">
            <Prev size={18} />
          </button>
          <span className="num" style={{ fontWeight: 600, minWidth: 48, textAlign: 'center' }}>
            {view.year}
          </span>
          <button className="mic-mini" onClick={() => setView(view.year + 1, view.month)} aria-label="next">
            <Next size={18} />
          </button>
        </div>
      </div>
      <div className="month-grid">
        {Array.from({ length: 12 }, (_, m) => (
          <motion.button
            key={m}
            className={`chip plain ${view.month === m ? 'on' : ''}`}
            whileTap={{ scale: 0.94 }}
            onClick={() => {
              tap();
              setView(view.year, m);
              setTimeout(closeSheet, 160);
            }}
          >
            {monthName(m, lang)}
          </motion.button>
        ))}
      </div>
    </ModalSheet>
  );
}

export function NotificationsSheet() {
  const t = useT();
  const txs = useStore((s) => s.txs);
  const closeSheet = useUi((s) => s.closeSheet);
  const now = new Date();
  const month = inMonth(txs, now.getFullYear(), now.getMonth());
  const spend = sumOf(month, 'expense');
  const income = sumOf(month, 'income');
  const top = byItem(month, 'expense')[0];

  const items = [];
  if (spend > income && spend > 0)
    items.push(
      <div className="insight" key="over">
        <span className="row-icon">
          <TrendingDown size={18} strokeWidth={1.7} color="var(--danger)" />
        </span>
        <div className="row-main">
          <div className="row-title">{t.spentMoreThan}</div>
          <div className="row-sub">
            <Money value={spend - income} />
          </div>
        </div>
      </div>,
    );
  if (top) {
    const Icon = iconFor(top.label, 'expense');
    items.push(
      <div className="insight" key="top">
        <span className="row-icon">
          <Icon size={18} strokeWidth={1.7} />
        </span>
        <div className="row-main">
          <div className="row-title">{t.topCategory}</div>
          <div className="row-sub">
            {top.label || t.expense} · <Money value={top.total} />
          </div>
        </div>
        <TrendingUp size={18} strokeWidth={1.7} color="var(--muted)" />
      </div>,
    );
  }

  return (
    <ModalSheet onClose={closeSheet}>
      <div className="sheet-head" style={{ marginBottom: 16 }}>
        <h2>{t.notifications}</h2>
      </div>
      {items.length ? (
        items
      ) : (
        <div className="empty">
          <BellOff size={28} strokeWidth={1.4} />
          <div style={{ marginTop: 10 }}>{t.noNotifications}</div>
        </div>
      )}
    </ModalSheet>
  );
}
