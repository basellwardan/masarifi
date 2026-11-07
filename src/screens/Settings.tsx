import { motion } from 'framer-motion';
import { Camera, Coins, DollarSign, Info, Languages, RotateCcw, Share2, User, Wallet } from 'lucide-react';
import { useRef, useState, type ReactNode } from 'react';
import { Avatar } from '../components/Avatar';
import { GradHeader } from '../components/GradHeader';
import { Money } from '../components/Money';
import { fractionDigits, fromNew, toNew, type CurrencyCode } from '../lib/currency';
import { useLang, useT } from '../lib/i18n';
import { tap } from '../lib/native';
import { shareExpenses } from '../lib/share';
import { balanceOf, useStore } from '../lib/store';
import { useUi } from '../lib/ui';
import { readPhoto } from '../lib/photo';

function MiniSeg<T extends string>({
  id,
  value,
  options,
  onChange,
}: {
  id: string;
  value: T;
  options: { v: T; label: string }[];
  onChange: (v: T) => void;
}) {
  return (
    <div className="mini-seg">
      {options.map((o) => (
        <button
          key={o.v}
          className={value === o.v ? 'on' : ''}
          onClick={() => {
            tap();
            onChange(o.v);
          }}
        >
          {value === o.v && <motion.span layoutId={`mini-${id}`} className="seg-bg" style={{ position: 'absolute', inset: 0, borderRadius: 999, background: '#000' }} />}
          <span style={{ position: 'relative', zIndex: 1 }}>{o.label}</span>
        </button>
      ))}
    </div>
  );
}

function Row({ icon, title, sub, children, onClick }: { icon: ReactNode; title: string; sub?: string; children?: ReactNode; onClick?: () => void }) {
  const Comp = onClick ? motion.button : motion.div;
  return (
    <Comp className="row" onClick={onClick} whileTap={onClick ? { scale: 0.98 } : undefined}>
      <span className="row-icon">{icon}</span>
      <span className="row-main">
        <div className="row-title">{title}</div>
        {sub && <div className="row-sub">{sub}</div>}
      </span>
      {children}
    </Comp>
  );
}

const ic = { size: 18, strokeWidth: 1.7 };

export function Settings() {
  const t = useT();
  const lang = useLang();
  const settings = useStore((s) => s.settings);
  const profile = useStore((s) => s.profile);
  const txs = useStore((s) => s.txs);
  const updateSettings = useStore((s) => s.updateSettings);
  const updateProfile = useStore((s) => s.updateProfile);
  const resetAll = useStore((s) => s.resetAll);
  const showToast = useUi((s) => s.showToast);
  const fileRef = useRef<HTMLInputElement>(null);
  const [rate, setRate] = useState(String(settings.usdRate));
  const [opening, setOpening] = useState(() =>
    String(Number(fromNew(profile.openingBalance, settings.currency, settings.usdRate).toFixed(fractionDigits(settings.currency)))),
  );
  const [confirmReset, setConfirmReset] = useState(false);

  const balance = balanceOf(profile, txs);

  const share = async () => {
    tap('medium');
    const r = await shareExpenses({ profile, txs, lang, currency: settings.currency, usdRate: settings.usdRate });
    if (r === 'copied') showToast(t.copied);
  };

  const sections = [
    // profile
    <div className="group" key="p">
      <Row icon={<User {...ic} />} title={t.name}>
        <input
          className="rate-input"
          style={{ width: 140, fontFamily: 'inherit', fontWeight: 500 }}
          value={profile.name}
          onChange={(e) => updateProfile({ name: e.target.value })}
          dir="auto"
        />
      </Row>
      <Row icon={<Wallet {...ic} />} title={t.editBalance}>
        <input
          className="rate-input"
          style={{ width: 120 }}
          inputMode="decimal"
          value={opening}
          onChange={(e) => {
            const raw = e.target.value.replace(/[^\d.]/g, '');
            setOpening(raw);
            const v = parseFloat(raw);
            updateProfile({ openingBalance: isNaN(v) ? 0 : toNew(v, settings.currency, settings.usdRate) });
          }}
        />
      </Row>
    </div>,
    // language + currency
    <div className="group" key="l">
      <Row icon={<Languages {...ic} />} title={t.language}>
        <MiniSeg
          id="lang"
          value={settings.lang}
          options={[
            { v: 'ar', label: 'عربي' },
            { v: 'en', label: 'EN' },
          ]}
          onChange={(v) => updateSettings({ lang: v })}
        />
      </Row>
      <Row icon={<Coins {...ic} />} title={t.currency} sub={t[settings.currency]}>
        <MiniSeg<CurrencyCode>
          id="cur"
          value={settings.currency}
          options={[
            { v: 'syp_new', label: lang === 'ar' ? 'جديدة' : 'New' },
            { v: 'syp_old', label: lang === 'ar' ? 'قديمة' : 'Old' },
            { v: 'usd', label: '$' },
          ]}
          onChange={(v) => {
            updateSettings({ currency: v });
            setOpening(String(Number(fromNew(profile.openingBalance, v, settings.usdRate).toFixed(fractionDigits(v)))));
          }}
        />
      </Row>
      <Row icon={<DollarSign {...ic} />} title={t.usdRate} sub={t.usdRateHint}>
        <input
          className="rate-input"
          inputMode="decimal"
          value={rate}
          onChange={(e) => {
            const raw = e.target.value.replace(/[^\d.]/g, '');
            setRate(raw);
            const v = parseFloat(raw);
            if (v > 0) updateSettings({ usdRate: v });
          }}
        />
      </Row>
      <div className="row-sub" style={{ padding: '0 0 12px', textAlign: 'center' }}>
        {t.oldNote}
      </div>
    </div>,
    // share
    <motion.button
      key="s"
      className="pill-btn black"
      style={{ width: '100%', height: 62, marginBottom: 6 }}
      onClick={share}
      whileTap={{ scale: 0.97 }}
    >
      <Share2 size={20} strokeWidth={1.7} />
      {t.share}
    </motion.button>,
    <div key="sh" className="row-sub" style={{ textAlign: 'center', marginBottom: 16 }}>
      {t.shareHint}
    </div>,
    // about + reset
    <div className="group" key="a">
      <Row icon={<Info {...ic} />} title={t.about} sub={`${t.appName} · ${t.version} 1.0.0`} />
      <Row
        icon={<RotateCcw {...ic} color="var(--danger)" />}
        title={confirmReset ? t.resetConfirm : t.reset}
        onClick={() => {
          tap('medium');
          if (!confirmReset) {
            setConfirmReset(true);
            setTimeout(() => setConfirmReset(false), 4000);
            return;
          }
          resetAll();
          setConfirmReset(false);
        }}
      />
    </div>,
  ];

  return (
    <div className="screen grad-screen">
      <GradHeader title={t.settings} />

      <motion.div
        className="center-col"
        style={{ padding: '18px 20px 26px' }}
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <motion.button style={{ position: 'relative' }} onClick={() => fileRef.current?.click()} whileTap={{ scale: 0.94 }}>
          <Avatar size={78} />
          <span
            className="glass glass-circle"
            style={{ position: 'absolute', bottom: -4, insetInlineEnd: -6, width: 30, height: 30 }}
          >
            <Camera size={14} strokeWidth={1.8} />
          </span>
        </motion.button>
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          hidden
          onChange={async (e) => {
            const f = e.target.files?.[0];
            if (f) updateProfile({ photo: await readPhoto(f) });
          }}
        />
        <div style={{ fontSize: 20, fontWeight: 600, marginTop: 14 }}>{profile.name || t.appName}</div>
        <span className="glass glass-chip" style={{ marginTop: 10 }}>
          {t.remaining}
          <Money value={balance} />
        </span>
      </motion.div>

      <motion.div
        className="white-sheet scroll"
        style={{ flex: 1, minHeight: 0, padding: '22px 16px calc(var(--safe-bottom) + 110px)' }}
        initial={{ y: 200 }}
        animate={{ y: 0 }}
        transition={{ type: 'spring', stiffness: 200, damping: 26 }}
      >
        {sections.map((s, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 + i * 0.06, type: 'spring', stiffness: 220, damping: 26 }}
          >
            {s}
          </motion.div>
        ))}
      </motion.div>
    </div>
  );
}
