import { AnimatePresence, motion, type PanInfo } from 'framer-motion';
import { useRef, useState } from 'react';
import { monthName, useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { inMonth, sumOf, useStore } from '../lib/store';
import { useUi } from '../lib/ui';
import { Money } from './Money';

const SWIPE_PX = 60;
const SWIPE_VELOCITY = 450;

/**
 * The glass card stack on Home. The front card shows one month's spending;
 * swipe it sideways to flick through months (it flies off and the next card
 * rises from the stack behind). Tapping it opens Statistics for that month.
 */
export function CardStack() {
  const t = useT();
  const lang = useLang();
  const txs = useStore((s) => s.txs);
  const view = useUi((s) => s.view);
  const setView = useUi((s) => s.setView);
  const setTab = useUi((s) => s.setTab);
  // +1 = card leaves to the right, -1 = to the left
  const [flyDir, setFlyDir] = useState(1);
  const dragged = useRef(false);
  const [shake, setShake] = useState(0);

  const now = new Date();
  const isCurrent = view.year === now.getFullYear() && view.month === now.getMonth();
  const spend = sumOf(inMonth(txs, view.year, view.month), 'expense');
  const label =
    view.year === now.getFullYear()
      ? monthName(view.month, lang, true)
      : `${monthName(view.month, lang, true)} ${view.year}`;

  const shift = (delta: number) => {
    const d = new Date(view.year, view.month + delta, 1);
    setView(d.getFullYear(), d.getMonth());
  };

  const onDragEnd = (_: unknown, info: PanInfo) => {
    setTimeout(() => (dragged.current = false), 60);
    const dx = info.offset.x;
    const fast = Math.abs(info.velocity.x) > SWIPE_VELOCITY;
    if (Math.abs(dx) < SWIPE_PX && !fast) return;
    const right = (fast ? info.velocity.x : dx) > 0;
    // Like turning pages: in English swipe left for the next month, in Arabic (RTL) swipe right.
    const toNext = lang === 'ar' ? right : !right;
    if (toNext && isCurrent) {
      setShake((n) => n + 1); // no future months: small "nope" wiggle
      return;
    }
    tap();
    setFlyDir(right ? 1 : -1);
    shift(toNext ? 1 : -1);
  };

  return (
    <div className="card-stack">
      <motion.div
        className="stack-card glass c3"
        initial={{ y: 60, opacity: 0 }}
        animate={{ y: 0, opacity: 0.55 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
      />
      <motion.div
        className="stack-card glass c2"
        initial={{ y: 60, opacity: 0 }}
        animate={{ y: 0, opacity: 0.75 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1], delay: 0.14 }}
      />
      <AnimatePresence initial={false} custom={flyDir}>
        <motion.div
          key={`${view.year}-${view.month}`}
          className="stack-card glass c1 swipe-card"
          custom={flyDir}
          variants={{
            // the new month rises from the card behind
            enter: { y: -14, scale: 0.9, opacity: 0 },
            center: { x: 0, y: 0, scale: 1, opacity: 1, rotate: 0 },
            // the old month is flicked away in the swipe direction
            exit: (d: number) => ({ x: d * 340, rotate: d * 14, opacity: 0 }),
          }}
          initial="enter"
          animate="center"
          exit="exit"
          transition={{ type: 'spring', stiffness: 300, damping: 30, opacity: { duration: 0.2 } }}
          drag="x"
          dragDirectionLock
          dragSnapToOrigin
          dragElastic={0.7}
          dragConstraints={{ left: 0, right: 0 }}
          whileDrag={{ scale: 1.02 }}
          onDragStart={() => (dragged.current = true)}
          onDragEnd={onDragEnd}
          onTap={() => {
            if (!dragged.current) setTab('stats');
          }}
          style={{ touchAction: 'pan-y' }}
        >
          <motion.div
            key={shake}
            className="card-row"
            animate={shake ? { x: [0, -8, 7, -4, 0] } : undefined}
            transition={{ duration: 0.35 }}
          >
            <div className="meta">
              <span>{t.monthSpend}</span>
              <span style={{ opacity: 0.85 }}>
                <Money value={spend} />
              </span>
            </div>
            <span className="brand">{label}</span>
          </motion.div>
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
