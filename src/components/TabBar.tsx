import { motion } from 'framer-motion';
import { ArrowDownUp, ChartPie, CreditCard, LayoutGrid, Mic } from 'lucide-react';
import { tap } from '../lib/native';
import { useNativeTabBar } from '../lib/glassTabBar';
import { useUi, type Tab } from '../lib/ui';

const ITEMS: { id: Tab; Icon: typeof CreditCard }[] = [
  { id: 'home', Icon: CreditCard },
  { id: 'tx', Icon: ArrowDownUp },
  { id: 'stats', Icon: ChartPie },
  { id: 'voice', Icon: Mic },
  { id: 'settings', Icon: LayoutGrid },
];

export function TabBar() {
  const tab = useUi((s) => s.tab);
  const setTab = useUi((s) => s.setTab);
  const nativeTabBar = useUi((s) => s.nativeTabBar);
  useNativeTabBar();
  if (nativeTabBar) return null; // iPhone iOS 26+: native Liquid Glass bar instead
  return (
    <motion.nav
      className="tabbar"
      initial={{ y: 90, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ type: 'spring', stiffness: 220, damping: 26, delay: 0.25 }}
    >
      {ITEMS.map(({ id, Icon }) => {
        const on = tab === id;
        return (
          <motion.button
            key={id}
            className="tab"
            onClick={() => {
              tap();
              setTab(id);
            }}
            whileTap={{ scale: 0.88 }}
            aria-label={id}
          >
            {on && (
              <motion.span
                layoutId="tab-pill"
                className="active-pill"
                transition={{ type: 'spring', stiffness: 420, damping: 34 }}
              />
            )}
            <motion.span
              animate={{ color: on ? '#ffffff' : '#1c1d20' }}
              transition={{ duration: 0.2 }}
              style={{ display: 'grid', position: 'relative', zIndex: 1 }}
            >
              <Icon size={22} strokeWidth={1.6} />
            </motion.span>
          </motion.button>
        );
      })}
    </motion.nav>
  );
}
