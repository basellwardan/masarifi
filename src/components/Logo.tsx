import { motion } from 'framer-motion';

// Two capsules folded into a diamond (after the reference mark). Drawn in a
// 120×120 box before a 45° rotation: a left and a right bar with square-ish
// outer corners and one large rounded inner end each.
export const LOGO_LEFT =
  'M24 16 L38.5 16 A20.5 20.5 0 0 1 59 36.5 L59 98 A6 6 0 0 1 53 104 L24 104 A8 8 0 0 1 16 96 L16 24 A8 8 0 0 1 24 16 Z';
export const LOGO_RIGHT =
  'M67 16 L96 16 A8 8 0 0 1 104 24 L104 96 A8 8 0 0 1 96 104 L81.5 104 A20.5 20.5 0 0 1 61 83.5 L61 22 A6 6 0 0 1 67 16 Z';

export function LogoDefs() {
  return (
    <defs>
      <linearGradient id="lg-a" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#5ED6DE" />
        <stop offset="0.38" stopColor="#2F8FD6" />
        <stop offset="0.66" stopColor="#0D2E7A" />
        <stop offset="1" stopColor="#3CC6D4" />
      </linearGradient>
      <linearGradient id="lg-b" x1="0" y1="1" x2="0" y2="0">
        <stop offset="0" stopColor="#5ED6DE" />
        <stop offset="0.38" stopColor="#2F8FD6" />
        <stop offset="0.66" stopColor="#0D2E7A" />
        <stop offset="1" stopColor="#3CC6D4" />
      </linearGradient>
      <linearGradient id="lg-shine" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stopColor="#fff" stopOpacity="0.28" />
        <stop offset="0.6" stopColor="#fff" stopOpacity="0" />
      </linearGradient>
    </defs>
  );
}

export function Logo({ size = 72, animated = false }: { size?: number; animated?: boolean }) {
  const t = { type: 'spring' as const, stiffness: 140, damping: 16, delay: 0.15 };
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" aria-hidden>
      <LogoDefs />
      <g transform="rotate(45 60 60)">
        <motion.g initial={animated ? { y: -22, opacity: 0 } : false} animate={{ y: 0, opacity: 1 }} transition={t}>
          <path d={LOGO_LEFT} fill="url(#lg-a)" />
          <path d={LOGO_LEFT} fill="url(#lg-shine)" />
        </motion.g>
        <motion.g initial={animated ? { y: 22, opacity: 0 } : false} animate={{ y: 0, opacity: 1 }} transition={t}>
          <path d={LOGO_RIGHT} fill="url(#lg-b)" />
          <path d={LOGO_RIGHT} fill="url(#lg-shine)" />
        </motion.g>
      </g>
    </svg>
  );
}
