import { motion } from 'framer-motion';
import type { ReactNode } from 'react';

/**
 * `size="half"` sheets float inset from the screen edges on iPhone (Liquid Glass
 * guidance); `size="full"` sheets reach the edges and stay opaque.
 */
export function ModalSheet({
  onClose,
  children,
  size = 'half',
}: {
  onClose: () => void;
  children: ReactNode;
  size?: 'half' | 'full';
}) {
  return (
    <>
      <motion.div
        className="backdrop"
        onClick={onClose}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.25 }}
      />
      <motion.div
        className={`modal-sheet white-sheet ${size}`}
        initial={{ y: '100%' }}
        animate={{ y: 0 }}
        exit={{ y: '100%' }}
        transition={{ type: 'spring', stiffness: 300, damping: 34 }}
        drag="y"
        dragConstraints={{ top: 0, bottom: 0 }}
        dragElastic={{ top: 0, bottom: 0.6 }}
        onDragEnd={(_, info) => {
          if (info.offset.y > 120 || info.velocity.y > 600) onClose();
        }}
      >
        <div className="grabber" />
        {children}
      </motion.div>
    </>
  );
}
