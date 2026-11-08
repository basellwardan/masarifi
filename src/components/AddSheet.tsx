import { AnimatePresence, motion } from 'framer-motion';
import { Delete, Mic, Trash2 } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import type { TxType } from '../lib/categories';
import { formatMoney, fractionDigits, fromNew, symbol, toNew } from '../lib/currency';
import { useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { startListening, type SpeechSession } from '../lib/speech';
import { useStore } from '../lib/store';
import { parseVoice } from '../lib/voiceParser';
import { useUi, type AddPrefill } from '../lib/ui';
import { ModalSheet } from './ModalSheet';

interface Props {
  type: TxType;
  editId?: string;
  prefill?: AddPrefill;
}

export function AddSheet({ type: initialType, editId, prefill }: Props) {
  const t = useT();
  const { currency, usdRate, lang } = useStore((s) => s.settings);
  const existing = useStore((s) => (editId ? s.txs.find((x) => x.id === editId) : undefined));
  const addTx = useStore((s) => s.addTx);
  const updateTx = useStore((s) => s.updateTx);
  const deleteTx = useStore((s) => s.deleteTx);
  const restoreTx = useStore((s) => s.restoreTx);
  const close = useUi((s) => s.closeSheet);
  const toast = useUi((s) => s.showToast);

  const startNew = existing?.amount ?? prefill?.amount;
  const [type, setType] = useState<TxType>(existing?.type ?? initialType);
  const [amountStr, setAmountStr] = useState(() => {
    if (!startNew) return '';
    const v = fromNew(startNew, currency, usdRate);
    return String(Number(v.toFixed(fractionDigits(currency))));
  });
  const [note, setNote] = useState(existing?.note ?? prefill?.note ?? '');
  const [listening, setListening] = useState(false);
  const session = useRef<SpeechSession | null>(null);

  useEffect(() => () => session.current?.stop(), []);

  const switchType = (next: TxType) => {
    if (next === type) return;
    tap();
    setType(next);
  };

  const press = (k: string) => {
    tap();
    setAmountStr((s) => {
      if (k === 'del') return s.slice(0, -1);
      if (k === '.') {
        if (fractionDigits(currency) === 0 || s.includes('.')) return s;
        return (s || '0') + '.';
      }
      const [, frac] = s.split('.');
      if (frac !== undefined && frac.length >= fractionDigits(currency)) return s;
      if (s.replace('.', '').length >= 12) return s;
      if (s === '0') return k;
      return s + k;
    });
  };

  const value = parseFloat(amountStr || '0');
  const valueNew = toNew(value, currency, usdRate);
  const display = amountStr
    ? amountStr.replace(/^(\d+)/, (m) => Number(m).toLocaleString('en-US'))
    : '0';
  const equiv =
    value > 0 && currency !== 'syp_new' ? `≈ ${formatMoney(valueNew, 'syp_new', usdRate, lang)}` : '';

  const save = () => {
    if (!(valueNew > 0)) return;
    tap('medium');
    if (existing) {
      updateTx(existing.id, { type, amount: valueNew, note: note.trim() });
    } else {
      addTx({ type, amount: valueNew, note: note.trim(), date: new Date().toISOString() });
    }
    toast(t.saved);
    close();
  };

  const remove = () => {
    if (!existing) return;
    const removed = deleteTx(existing.id);
    close();
    if (removed) toast(t.deleted, { label: t.undo, run: () => restoreTx(removed) });
  };

  const toggleMic = async () => {
    if (listening) {
      session.current?.stop();
      return;
    }
    tap('medium');
    setListening(true);
    session.current = await startListening(lang, {
      onPartial: () => undefined,
      onEnd: (text) => {
        setListening(false);
        if (!text) return;
        const p = parseVoice(text);
        setType(p.type);
        setNote(p.note);
        if (p.amount) {
          const asNew = toNew(p.amount, p.unit ?? currency, usdRate);
          const v = fromNew(asNew, currency, usdRate);
          setAmountStr(String(Number(v.toFixed(fractionDigits(currency)))));
        }
      },
      onError: (e) => {
        setListening(false);
        toast(e === 'denied' ? t.micDenied : t.micUnavailable);
      },
    });
    if (!session.current) setListening(false);
  };

  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'del'];

  return (
    <ModalSheet onClose={close} size="full">
      <div className="segmented">
        {(['expense', 'income'] as TxType[]).map((k) => (
          <button key={k} className={type === k ? 'on' : ''} onClick={() => switchType(k)}>
            {type === k && <motion.span layoutId="seg-add" className="seg-bg" />}
            <span>{k === 'expense' ? t.withdraw : t.deposit}</span>
          </button>
        ))}
      </div>

      <div className="amount-entry">
        <motion.button
          className="mic-mini"
          onClick={toggleMic}
          whileTap={{ scale: 0.9 }}
          animate={listening ? { scale: [1, 1.12, 1], background: '#000', color: '#fff' } : { scale: 1, background: '#ebecee', color: '#0b0b0c' }}
          transition={listening ? { repeat: Infinity, duration: 1.1 } : { duration: 0.2 }}
          aria-label="mic"
        >
          <Mic size={18} strokeWidth={1.8} />
        </motion.button>
        <span className="num val">
          {currency === 'usd' && <span className="sym" style={{ fontSize: 28, color: 'var(--ink)' }}>$</span>}
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.span
              key={display}
              initial={{ y: 12, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: -12, opacity: 0 }}
              transition={{ duration: 0.16 }}
              style={{ display: 'inline-block', color: amountStr ? 'var(--ink)' : 'var(--muted-2)' }}
            >
              {display}
            </motion.span>
          </AnimatePresence>
        </span>
        {currency !== 'usd' && <span className="sym">{symbol(currency, lang)}</span>}
      </div>
      <div className="equiv num" style={{ display: 'block' }}>{equiv}</div>


      <input
        className="field"
        style={{ marginTop: 12 }}
        placeholder={type === 'expense' ? t.notePlaceholderExpense : t.notePlaceholderIncome}
        value={note}
        onChange={(e) => setNote(e.target.value)}
        dir="auto"
      />

      <div className="keypad" style={{ marginTop: 10 }}>
        {keys.map((k) => (
          <motion.button key={k} className="key" onClick={() => press(k)} whileTap={{ scale: 0.9 }}>
            {k === 'del' ? <Delete size={24} strokeWidth={1.6} /> : k}
          </motion.button>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
        {existing && (
          <motion.button className="pill-btn square" onClick={remove} whileTap={{ scale: 0.94 }} aria-label={t.delete}>
            <Trash2 size={20} strokeWidth={1.7} color="var(--danger)" />
          </motion.button>
        )}
        <motion.button
          className="pill-btn black"
          onClick={save}
          whileTap={{ scale: 0.97 }}
          animate={{ opacity: valueNew > 0 ? 1 : 0.35 }}
        >
          {t.save}
        </motion.button>
      </div>
    </ModalSheet>
  );
}
