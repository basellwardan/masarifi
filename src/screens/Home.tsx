import { AnimatePresence, motion } from 'framer-motion';
import { useMemo, useState } from 'react';
import { ArrowDownRight, ArrowUpDown, ArrowUpRight, Bell, TrendingDown, TrendingUp } from 'lucide-react';
import { Avatar } from '../components/Avatar';
import { CardStack } from '../components/CardStack';
import { Money } from '../components/Money';
import { TxRow } from '../components/TxRow';
import { useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { balanceOf, inMonth, monthChangePct, useStore } from '../lib/store';
import { useUi } from '../lib/ui';

const rise = (i: number) => ({
  initial: { opacity: 0, y: 18 },
  animate: { opacity: 1, y: 0 },
  transition: { type: 'spring' as const, stiffness: 200, damping: 24, delay: 0.05 + i * 0.06 },
});

export function Home() {
  const t = useT();
  const profile = useStore((s) => s.profile);
  const txs = useStore((s) => s.txs);
  const cycleCurrency = useStore((s) => s.cycleCurrency);
  const { openSheet, setTab } = useUi();
  const [spins, setSpins] = useState(0);

  const now = new Date();
  const balance = balanceOf(profile, txs);
  const pct = monthChangePct(profile, txs, now);
  const view = useUi((st) => st.view);
  const monthTxs = useMemo(() => inMonth(txs, view.year, view.month), [txs, view.year, view.month]);
  const hasAlert = pct < 0;

  return (
    <div className="screen">
      <div className="hero">
        <div className="topbar">
          <motion.button {...rise(0)} onClick={() => setTab('settings')} whileTap={{ scale: 0.92 }}>
            <Avatar />
          </motion.button>
          <motion.button
            {...rise(0)}
            className="glass glass-circle"
            onClick={() => openSheet({ kind: 'notifications' })}
            whileTap={{ scale: 0.92 }}
            aria-label={t.notifications}
          >
            <Bell size={20} strokeWidth={1.6} />
            {hasAlert && <span className="dot-badge" />}
          </motion.button>
        </div>

        <div className="balance-block">
          <motion.div className="balance-label" {...rise(1)}>
            {t.balance}
          </motion.div>
          <motion.div className="balance-amount" {...rise(2)}>
            <Money value={balance} animate />
          </motion.div>
          <motion.div {...rise(3)} style={{ marginTop: 12 }}>
            <span className="glass glass-chip">
              {pct >= 0 ? <TrendingUp size={14} strokeWidth={1.8} /> : <TrendingDown size={14} strokeWidth={1.8} />}
              <span className="num">{Math.abs(pct).toFixed(2)}%</span>
              <span>{t.thisMonth}</span>
            </span>
          </motion.div>
        </div>

        <CardStack />
      </div>

      <motion.div className="actions" {...rise(4)}>
        <motion.button
          className="pill-btn"
          whileTap={{ scale: 0.96 }}
          onClick={() => {
            tap();
            openSheet({ kind: 'add', type: 'expense' });
          }}
        >
          <ArrowUpRight size={20} strokeWidth={1.7} />
          {t.withdraw}
        </motion.button>
        <motion.button
          className="pill-btn square"
          whileTap={{ scale: 0.9 }}
          onClick={() => {
            tap();
            setSpins((n) => n + 1);
            cycleCurrency();
          }}
          aria-label={t.currency}
        >
          <motion.span
            style={{ display: 'grid' }}
            animate={{ rotate: spins * 180 }}
            transition={{ type: 'spring', stiffness: 320, damping: 22 }}
          >
            <ArrowUpDown size={20} strokeWidth={1.7} />
          </motion.span>
        </motion.button>
        <motion.button
          className="pill-btn"
          whileTap={{ scale: 0.96 }}
          onClick={() => {
            tap();
            openSheet({ kind: 'add', type: 'income' });
          }}
        >
          <ArrowDownRight size={20} strokeWidth={1.7} />
          {t.deposit}
        </motion.button>
      </motion.div>

      <motion.div className="section-head" {...rise(5)}>
        <h2>{t.recent}</h2>
        <button className="link" onClick={() => setTab('tx')}>
          {t.viewAll}
        </button>
      </motion.div>

      <div className="scroll fade-bottom" style={{ flex: 1, paddingBottom: 110 }}>
        <div className="tx-list">
          <AnimatePresence initial={false}>
            {monthTxs.slice(0, 12).map((tx, i) => (
              <TxRow key={tx.id} tx={tx} index={i} onClick={() => openSheet({ kind: 'add', type: tx.type, editId: tx.id })} />
            ))}
          </AnimatePresence>
          {monthTxs.length === 0 && (
            <motion.div className="empty" {...rise(6)}>
              <div className="big">{t.noTx}</div>
              <div>{t.noTxHint}</div>
            </motion.div>
          )}
        </div>
      </div>
      <div className="list-fade" />
    </div>
  );
}
