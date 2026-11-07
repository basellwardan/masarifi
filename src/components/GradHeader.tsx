import { motion } from 'framer-motion';
import { ArrowLeft, ArrowRight } from 'lucide-react';
import type { ReactNode } from 'react';
import { useLang } from '../lib/i18n';
import { useUi } from '../lib/ui';

/** Back arrow + optional title + optional glass action, as on the Expenses reference screen. */
export function GradHeader({ title, action }: { title?: string; action?: ReactNode }) {
  const lang = useLang();
  const setTab = useUi((s) => s.setTab);
  const Back = lang === 'ar' ? ArrowRight : ArrowLeft;
  return (
    <div className="topbar">
      <motion.button
        className="glass glass-circle"
        onClick={() => setTab('home')}
        whileTap={{ scale: 0.9 }}
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        aria-label="back"
      >
        <Back size={20} strokeWidth={1.6} />
      </motion.button>
      {title && (
        <motion.div
          className="screen-title"
          initial={{ opacity: 0, y: -6 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.05 }}
        >
          {title}
        </motion.div>
      )}
      {action ?? <span style={{ width: 46 }} />}
    </div>
  );
}

export function GlassIconButton({ onClick, children, label }: { onClick: () => void; children: ReactNode; label: string }) {
  return (
    <motion.button
      className="glass glass-circle"
      onClick={onClick}
      whileTap={{ scale: 0.9 }}
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      aria-label={label}
    >
      {children}
    </motion.button>
  );
}
