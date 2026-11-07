import { motion } from 'framer-motion';
import { Logo } from '../components/Logo';

/** Loading screen: only the bare logo mark, centred on the navy gradient. */
export function Splash() {
  return (
    <motion.div
      className="screen grad-screen center-col"
      style={{ justifyContent: 'center', zIndex: 100 }}
      exit={{ opacity: 0, scale: 1.06 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
    >
      <motion.div
        initial={{ scale: 0.6, opacity: 0 }}
        animate={{ scale: [0.6, 1, 0.96, 1], opacity: 1 }}
        transition={{ duration: 1.1, ease: [0.22, 1, 0.36, 1] }}
        style={{ filter: 'drop-shadow(0 18px 40px rgba(60, 198, 212, 0.25))' }}
      >
        <motion.div
          animate={{ scale: [1, 1.04, 1] }}
          transition={{ duration: 1.8, repeat: Infinity, ease: 'easeInOut', delay: 1.1 }}
        >
          <Logo size={150} animated />
        </motion.div>
      </motion.div>
    </motion.div>
  );
}
