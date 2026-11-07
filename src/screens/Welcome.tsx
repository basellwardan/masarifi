import { AnimatePresence, motion } from 'framer-motion';
import { Camera, Check } from 'lucide-react';
import { useRef, useState } from 'react';
import { Logo } from '../components/Logo';
import { symbol, toNew } from '../lib/currency';
import { useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { readPhoto } from '../lib/photo';
import { useStore } from '../lib/store';

export function Welcome() {
  const t = useT();
  const lang = useLang();
  const { currency, usdRate } = useStore((s) => s.settings);
  const updateSettings = useStore((s) => s.updateSettings);
  const complete = useStore((s) => s.completeOnboarding);
  const [step, setStep] = useState(0);
  const [dir, setDir] = useState(1);
  const [name, setName] = useState('');
  const [photo, setPhoto] = useState<string | null>(null);
  const [balance, setBalance] = useState('');
  const fileRef = useRef<HTMLInputElement>(null);

  const go = (n: number) => {
    tap();
    setDir(n > step ? 1 : -1);
    setStep(n);
  };

  const finish = () => {
    tap('medium');
    const v = parseFloat(balance);
    complete({ name: name.trim(), photo, openingBalance: isNaN(v) ? 0 : toNew(v, currency, usdRate) });
  };

  const sign = lang === 'ar' ? -1 : 1;
  const slide = {
    initial: (d: number) => ({ x: 60 * d * sign, opacity: 0 }),
    animate: { x: 0, opacity: 1 },
    exit: (d: number) => ({ x: -60 * d * sign, opacity: 0 }),
  };

  return (
    <motion.div
      className="screen grad-screen"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, scale: 0.98 }}
      transition={{ duration: 0.4 }}
    >
      <div className="topbar" style={{ justifyContent: 'flex-end' }}>
        <motion.button
          className="glass glass-chip"
          style={{ height: 40, padding: '0 16px' }}
          onClick={() => updateSettings({ lang: lang === 'ar' ? 'en' : 'ar' })}
          whileTap={{ scale: 0.94 }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4 }}
        >
          {lang === 'ar' ? 'English' : 'العربية'}
        </motion.button>
      </div>

      <div className="center-col" style={{ flex: 1, justifyContent: 'center', padding: '0 32px' }}>
        <motion.div
          className="glass logo-glass"
          layout
          initial={{ scale: 0.7, opacity: 0, rotate: -8 }}
          animate={{ scale: step === 0 ? 1 : 0.72, opacity: 1, rotate: 0 }}
          transition={{ type: 'spring', stiffness: 150, damping: 16 }}
        >
          <Logo size={92} animated />
        </motion.div>
        <motion.div
          className="app-title"
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25 }}
        >
          {t.appName}
        </motion.div>
        <motion.div
          className="tagline"
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.38 }}
        >
          {t.tagline}
        </motion.div>
      </div>

      <motion.div
        className="white-sheet"
        style={{ padding: '28px 22px calc(var(--safe-bottom) + 20px)', overflow: 'hidden' }}
        initial={{ y: 300 }}
        animate={{ y: 0 }}
        transition={{ type: 'spring', stiffness: 170, damping: 24, delay: 0.3 }}
      >
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 22 }}>
          {[0, 1, 2, 3].map((i) => (
            <motion.span
              key={i}
              animate={{ width: i === step ? 22 : 7, background: i <= step ? '#000' : '#d9dadd' }}
              style={{ height: 7, borderRadius: 4, display: 'block' }}
            />
          ))}
        </div>

        <AnimatePresence mode="wait" custom={dir} initial={false}>
          <motion.div
            key={step}
            custom={dir}
            variants={slide}
            initial="initial"
            animate="animate"
            exit="exit"
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            style={{ minHeight: 150 }}
          >
            {step === 0 && (
              <div className="center-col" style={{ gap: 6 }}>
                <h2 style={{ margin: 0, fontSize: 23, fontWeight: 600 }}>{lang === 'ar' ? 'أهلاً فيك 👋' : 'Welcome 👋'}</h2>
                <div className="row-sub" style={{ fontSize: 14.5, lineHeight: 1.6, maxWidth: 290 }}>
                  {t.allSetHint}
                </div>
              </div>
            )}
            {step === 1 && (
              <div className="center-col" style={{ gap: 14 }}>
                <h2 style={{ margin: 0, fontSize: 22, fontWeight: 600 }}>{t.yourName}</h2>
                <div style={{ display: 'flex', gap: 10, width: '100%', alignItems: 'center' }}>
                  <motion.button
                    className="tx-icon"
                    style={{ width: 52, height: 52, overflow: 'hidden' }}
                    onClick={() => fileRef.current?.click()}
                    whileTap={{ scale: 0.92 }}
                    aria-label={t.addPhoto}
                  >
                    {photo ? <img src={photo} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : <Camera size={20} strokeWidth={1.6} />}
                  </motion.button>
                  <input
                    className="field"
                    placeholder={t.namePlaceholder}
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    dir="auto"
                  />
                </div>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={async (e) => {
                    const f = e.target.files?.[0];
                    if (f) setPhoto(await readPhoto(f));
                  }}
                />
              </div>
            )}
            {step === 2 && (
              <div className="center-col" style={{ gap: 10 }}>
                <h2 style={{ margin: 0, fontSize: 22, fontWeight: 600 }}>{t.startingBalance}</h2>
                <div className="row-sub">{t.startingHint}</div>
                <div style={{ position: 'relative', width: '100%', marginTop: 6 }}>
                  <input
                    className="field num"
                    style={{ height: 64, fontSize: 28, textAlign: 'center', fontWeight: 500, display: 'block' }}
                    inputMode="decimal"
                    placeholder="0"
                    value={balance}
                    onChange={(e) => setBalance(e.target.value.replace(/[^\d.]/g, ''))}
                  />
                  <span
                    className="row-sub"
                    style={{ position: 'absolute', insetInlineEnd: 18, top: '50%', transform: 'translateY(-50%)', margin: 0 }}
                  >
                    {symbol(currency, lang)}
                  </span>
                </div>
              </div>
            )}
            {step === 3 && (
              <div className="center-col" style={{ gap: 10 }}>
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', stiffness: 260, damping: 14, delay: 0.1 }}
                  style={{ width: 60, height: 60, borderRadius: '50%', background: '#000', color: '#fff', display: 'grid', placeItems: 'center' }}
                >
                  <Check size={28} strokeWidth={2} />
                </motion.div>
                <h2 style={{ margin: 0, fontSize: 22, fontWeight: 600 }}>
                  {t.allSet}
                  {name.trim() ? `، ${name.trim()}` : ''}
                </h2>
              </div>
            )}
          </motion.div>
        </AnimatePresence>

        <div style={{ display: 'flex', gap: 8, marginTop: 18 }}>
          <AnimatePresence initial={false}>
            {step > 0 && step < 3 && (
              <motion.button
                className="pill-btn"
                style={{ flex: '0 0 30%' }}
                initial={{ opacity: 0, width: 0 }}
                animate={{ opacity: 1, width: 'auto' }}
                exit={{ opacity: 0, width: 0 }}
                onClick={() => go(step - 1)}
                whileTap={{ scale: 0.96 }}
              >
                {t.back}
              </motion.button>
            )}
          </AnimatePresence>
          <motion.button
            layout
            className="pill-btn black"
            onClick={() => (step < 3 ? go(step + 1) : finish())}
            whileTap={{ scale: 0.97 }}
          >
            {step === 0 ? t.start : step === 3 ? t.letsGo : t.next}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  );
}
