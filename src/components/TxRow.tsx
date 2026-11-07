import { motion } from 'framer-motion';
import { memo, useRef } from 'react';
import { iconFor } from '../lib/categories';
import { formatTxDate, useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { useStore, type Tx } from '../lib/store';
import { useUi } from '../lib/ui';
import { Money } from './Money';

/** Transaction row: the description the user typed/said. Tap to edit, swipe sideways to delete (with undo). */
export const TxRow = memo(function TxRow({ tx, index = 0, onClick }: { tx: Tx; index?: number; onClick?: () => void }) {
  const lang = useLang();
  const t = useT();
  const deleteTx = useStore((s) => s.deleteTx);
  const restoreTx = useStore((s) => s.restoreTx);
  const toast = useUi((s) => s.showToast);
  const dragged = useRef(false);
  const Icon = iconFor(tx.note, tx.type);
  const title = tx.note.trim() || (tx.type === 'expense' ? t.expense : t.incomeOne);

  return (
    <motion.button
      className="tx-row"
      onClick={() => {
        if (!dragged.current) onClick?.();
      }}
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, height: 0, paddingTop: 0, paddingBottom: 0, transition: { duration: 0.22 } }}
      transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1], delay: Math.min(index, 6) * 0.025 }}
      whileTap={{ scale: 0.98 }}
      drag="x"
      dragDirectionLock
      dragConstraints={{ left: 0, right: 0 }}
      dragElastic={0.5}
      dragSnapToOrigin
      onDragStart={() => {
        dragged.current = true;
      }}
      onDragEnd={(_, info) => {
        setTimeout(() => (dragged.current = false), 50);
        if (Math.abs(info.offset.x) > 110) {
          tap('medium');
          const removed = deleteTx(tx.id);
          if (removed) toast(t.deleted, { label: t.undo, run: () => restoreTx(removed) });
        }
      }}
    >
      <div className="tx-icon">
        <Icon size={20} strokeWidth={1.6} />
      </div>
      <div className="tx-main">
        <div className="tx-title">{title}</div>
        <div className="tx-sub">{formatTxDate(tx.date, lang, t)}</div>
      </div>
      <div className="tx-amount">
        <Money value={tx.type === 'expense' ? -tx.amount : tx.amount} />
      </div>
    </motion.button>
  );
});
