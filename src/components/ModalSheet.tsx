import { motion } from 'framer-motion';
import type { ReactNode } from 'react';

/** White bottom sheet over a dimmed backdrop. Wrap in <AnimatePresence>. */
export function ModalSheet({ onClose, children }: { onClose: () => void; children: ReactNode }) {
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
        className="modal-sheet white-sheet"
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
