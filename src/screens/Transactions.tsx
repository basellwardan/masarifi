import { AnimatePresence, motion } from 'framer-motion';
import { Calendar } from 'lucide-react';
import { useState } from 'react';
import { GlassIconButton, GradHeader } from '../components/GradHeader';
import { Money } from '../components/Money';
import { TxRow } from '../components/TxRow';
import { formatDayHeader, monthName, useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { inMonth, sumOf, useStore, type Tx } from '../lib/store';
import { useUi } from '../lib/ui';

type Filter = 'all' | 'expense' | 'income';

export function Transactions() {
  const t = useT();
  const lang = useLang();
  const txs = useStore((s) => s.txs);
  const { view, openSheet } = useUi();
  const [filter, setFilter] = useState<Filter>('all');

  const month = inMonth(txs, view.year, view.month);
  const spend = sumOf(month, 'expense');
  const income = sumOf(month, 'income');
  const list = month.filter((x) => filter === 'all' || x.type === filter);

  const groups: { key: string; label: string; items: Tx[] }[] = [];
  for (const tx of list) {
    const key = tx.date.slice(0, 10);
    const last = groups[groups.length - 1];
    if (last?.key === key) last.items.push(tx);
    else groups.push({ key, label: formatDayHeader(tx.date, lang, t), items: [tx] });
  }

  const filters: { id: Filter; label: string }[] = [
    { id: 'all', label: t.all },
    { id: 'expense', label: t.expenses },
    { id: 'income', label: t.income },
  ];

  let idx = 0;
  return (
    <div className="screen grad-screen">
      <GradHeader
        title={t.transactions}
        action={
          <GlassIconButton onClick={() => openSheet({ kind: 'month' })} label={t.pickMonth}>
            <Calendar size={20} strokeWidth={1.6} />
          </GlassIconButton>
        }
      />

      <motion.div
        className="center-col"
        style={{ padding: '22px 20px 28px' }}
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: 'spring', stiffness: 200, damping: 24 }}
      >
        <div className="balance-label">
          {t.monthSpend} · {monthName(view.month, lang)}
        </div>
        <div className="balance-amount" style={{ fontSize: 44 }}>
          <Money value={spend} animate />
        </div>
        <span className="glass glass-chip" style={{ marginTop: 12 }}>
          {t.income}
          <Money value={income} />
        </span>
      </motion.div>

      <motion.div
        className="white-sheet"
        style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column', paddingTop: 22 }}
        initial={{ y: 200 }}
        animate={{ y: 0 }}
        transition={{ type: 'spring', stiffness: 200, damping: 26 }}
      >
        <div className="chip-row" style={{ padding: '0 20px 6px', justifyContent: 'center' }}>
          {filters.map((f) => (
            <motion.button
              key={f.id}
              className={`chip plain ${filter === f.id ? 'on' : ''}`}
              onClick={() => {
                tap();
                setFilter(f.id);
              }}
              whileTap={{ scale: 0.95 }}
            >
              {f.label}
            </motion.button>
          ))}
        </div>

        <div className="scroll fade-bottom" style={{ flex: 1, paddingBottom: 120 }}>
          {groups.length === 0 && (
            <div className="empty">
              <div className="big">{t.noTx}</div>
              <div>{t.noTxHint}</div>
            </div>
          )}
          <AnimatePresence initial={false}>
            {groups.map((g) => (
              <motion.div key={g.key} layout className="tx-list" exit={{ opacity: 0 }}>
                <div className="tx-sub" style={{ padding: '18px 0 4px', fontSize: 13 }}>
                  {g.label}
                </div>
                <AnimatePresence initial={false}>
                  {g.items.map((tx) => (
                    <TxRow
                      key={tx.id}
                      tx={tx}
                      index={idx++}
                      onClick={() => openSheet({ kind: 'add', type: tx.type, editId: tx.id })}
                    />
                  ))}
                </AnimatePresence>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </motion.div>
      <div className="list-fade white" />
    </div>
  );
}
