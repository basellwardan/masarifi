import { AnimatePresence, motion } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';
import { moneyParts } from '../lib/currency';
import { useStore } from '../lib/store';

interface Props {
  /** value in new SYP */
  value: number;
  className?: string;
  signed?: boolean;
  /** animate between values (count-up) */
  animate?: boolean;
  hideSymbol?: boolean;
}

function useCountUp(target: number, enabled: boolean, duration = 900) {
  const [shown, setShown] = useState(enabled ? 0 : target);
  const from = useRef(enabled ? 0 : target);
  useEffect(() => {
    if (!enabled) {
      setShown(target);
      return;
    }
    const start = performance.now();
    const a = from.current;
    let raf = 0;
    const step = (now: number) => {
      const p = Math.min(1, (now - start) / duration);
      const e = 1 - Math.pow(1 - p, 4);
      const v = a + (target - a) * e;
      setShown(v);
      from.current = v;
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target, enabled, duration]);
  return shown;
}

/**
 * Amount with a muted fraction, like "$12,680.42" in the reference UI.
 * When the display currency changes (⇅ button / Settings) the old amount slides
 * out and the new one slides in with the same spring as the tab transitions.
 */
export function Money({ value, className = '', signed, animate, hideSymbol }: Props) {
  const { currency, usdRate, lang } = useStore((s) => s.settings);
  const v = useCountUp(value, !!animate);
  const p = moneyParts(v, currency, usdRate, lang, { signed });
  const dx = lang === 'ar' ? -28 : 28;
  return (
    <span className="money-swap">
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.span
          key={currency}
          className={`num ${className}`}
          initial={{ x: dx, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          exit={{ x: -dx, opacity: 0 }}
          transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
        >
          {p.sign}
          {!hideSymbol && p.symbolFirst && <span>{p.symbol}</span>}
          {p.int}
          <span className="frac">{p.frac}</span>
          {!hideSymbol && !p.symbolFirst && <span className="sym">{p.symbol}</span>}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}
