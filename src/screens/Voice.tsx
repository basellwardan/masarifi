import { AnimatePresence, motion } from 'framer-motion';
import { Mic, Square } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { GradHeader } from '../components/GradHeader';
import { Money } from '../components/Money';
import { iconFor } from '../lib/categories';
import { toNew } from '../lib/currency';
import { useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { startListening, type SpeechSession } from '../lib/speech';
import { useStore } from '../lib/store';
import { useUi } from '../lib/ui';
import { parseVoice, type ParsedVoice } from '../lib/voiceParser';

export function Voice() {
  const t = useT();
  const lang = useLang();
  const { currency, usdRate } = useStore((s) => s.settings);
  const addTx = useStore((s) => s.addTx);
  const { openSheet, showToast, setTab } = useUi();

  const [listening, setListening] = useState(false);
  const [text, setText] = useState('');
  const [result, setResult] = useState<ParsedVoice | null>(null);
  const [error, setError] = useState('');
  const session = useRef<SpeechSession | null>(null);

  useEffect(() => () => session.current?.stop(), []);

  const amountNew = result?.amount ? toNew(result.amount, result.unit ?? currency, usdRate) : 0;

  const handleText = (spoken: string) => {
    setText(spoken);
    const p = parseVoice(spoken);
    setResult(p);
    setError(p.amount ? '' : t.didntCatch);
  };

  const toggle = async () => {
    if (listening) {
      session.current?.stop();
      return;
    }
    tap('medium');
    setResult(null);
    setError('');
    setText('');
    setListening(true);
    session.current = await startListening(lang, {
      onPartial: setText,
      onEnd: (finalText) => {
        setListening(false);
        if (finalText) handleText(finalText);
      },
      onError: (e) => {
        setListening(false);
        setError(e === 'denied' ? t.micDenied : e === 'unavailable' ? t.micUnavailable : t.didntCatch);
      },
    });
    if (!session.current) setListening(false);
  };

  const confirm = () => {
    if (!result || !amountNew) return;
    tap('medium');
    addTx({
      type: result.type,
      amount: amountNew,
      note: result.note,
      date: new Date().toISOString(),
    });
    showToast(t.saved);
    setResult(null);
    setText('');
    setTab('home');
  };

  const edit = () => {
    if (!result) return;
    openSheet({
      kind: 'add',
      type: result.type,
      prefill: { amount: amountNew || undefined, note: result.note },
    });
    setResult(null);
    setText('');
  };

  const CatIcon = result ? iconFor(result.note, result.type) : null;
  const showSheet = !!result && !!result.amount;

  return (
    <div className="screen grad-screen">
      <GradHeader title={t.voice} />

      <div className="center-col" style={{ flex: 1, justifyContent: 'center', padding: '0 28px', gap: 26 }}>
        <div style={{ position: 'relative', width: 180, height: 180, display: 'grid', placeItems: 'center' }}>
          <AnimatePresence>
            {listening &&
              [0, 1, 2].map((i) => (
                <motion.span
                  key={i}
                  className="bubble"
                  style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', left: 0, top: 0, transform: 'none' }}
                  initial={{ scale: 1, opacity: 0.6 }}
                  animate={{ scale: 1.9, opacity: 0 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 2.4, repeat: Infinity, delay: i * 0.8, ease: 'easeOut' }}
                />
              ))}
          </AnimatePresence>
          <motion.button
            className="bubble"
            style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', left: 0, top: 0 }}
            onClick={toggle}
            initial={{ scale: 0.6, opacity: 0 }}
            animate={{ scale: listening ? 1.06 : 1, opacity: 1 }}
            whileTap={{ scale: 0.94 }}
            transition={{ type: 'spring', stiffness: 220, damping: 16 }}
            aria-label={t.tapToSpeak}
          >
            <AnimatePresence mode="wait" initial={false}>
              <motion.span
                key={listening ? 'stop' : 'mic'}
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.5, opacity: 0 }}
                transition={{ duration: 0.18 }}
                style={{ display: 'grid' }}
              >
                {listening ? <Square size={34} strokeWidth={1.4} fill="#fff" /> : <Mic size={46} strokeWidth={1.3} />}
              </motion.span>
            </AnimatePresence>
          </motion.button>
        </div>

        <div style={{ minHeight: 90 }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={listening ? 'l' : text ? 'tx' : error ? 'e' : 'idle'}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.2 }}
            >
              <div style={{ fontSize: 20, fontWeight: 600 }}>
                {listening ? t.listening : text ? `“${text}”` : t.tapToSpeak}
              </div>
              <div style={{ marginTop: 8, color: error ? '#ffd2d2' : 'rgba(255,255,255,.65)', fontSize: 14.5 }}>
                {error || (!text && !listening ? t.voiceHint : '')}
              </div>
            </motion.div>
          </AnimatePresence>
        </div>

        <AnimatePresence>
          {!listening && !showSheet && (
            <motion.div
              style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              {t.voiceExamples.map((ex, i) => (
                <motion.button
                  key={ex}
                  className="glass glass-chip"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.15 + i * 0.07 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => handleText(ex)}
                >
                  {ex}
                </motion.button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div style={{ height: 'calc(var(--safe-bottom) + 90px)', flex: 'none' }} />

      <AnimatePresence>
        {showSheet && result && CatIcon && (
          <motion.div
            className="white-sheet"
            style={{
              position: 'absolute',
              insetInline: 0,
              bottom: 0,
              padding: '24px 20px calc(var(--safe-bottom) + 92px)',
              zIndex: 5,
            }}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 260, damping: 30 }}
          >
            <div className="sheet-head">
              <h2>{result.type === 'expense' ? t.expense : t.incomeOne}</h2>
              <button className="link" onClick={() => setResult(null)}>
                {t.cancel}
              </button>
            </div>
            <div className="big-amount">
              <Money value={amountNew} />
            </div>
            <div className="tiles" style={{ gridTemplateColumns: '1fr' }}>
              <div className="tile" style={{ minHeight: 0 }}>
                <div className="tile-top">
                  <span style={{ fontWeight: 600, fontSize: 15, lineHeight: 1.5 }}>{result.note}</span>
                  <CatIcon size={18} strokeWidth={1.6} />
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              <motion.button className="pill-btn" onClick={edit} whileTap={{ scale: 0.96 }}>
                {t.edit}
              </motion.button>
              <motion.button className="pill-btn black" onClick={confirm} whileTap={{ scale: 0.96 }}>
                {t.confirm}
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
