import { create } from 'zustand';
import { createJSONStorage, persist, type StateStorage } from 'zustand/middleware';
import { Preferences } from '@capacitor/preferences';
import { CURRENCY_ORDER, DEFAULT_USD_RATE, type CurrencyCode, type Lang } from './currency';
import type { TxType } from './categories';
import { normalize } from './normalize';

export interface Tx {
  id: string;
  type: TxType;
  /** always new SYP */
  amount: number;
  /** legacy field from the first version; no longer shown */
  categoryId?: string;
  /** what the money was spent on / came from, exactly as typed or said */
  note: string;
  date: string; // ISO
}

export interface Settings {
  lang: Lang;
  currency: CurrencyCode;
  usdRate: number;
}

export interface Profile {
  name: string;
  photo: string | null; // data URL
  openingBalance: number; // new SYP
}

interface State {
  hydrated: boolean;
  onboarded: boolean;
  profile: Profile;
  settings: Settings;
  txs: Tx[];
  setHydrated: () => void;
  completeOnboarding: (p: Profile) => void;
  updateProfile: (p: Partial<Profile>) => void;
  updateSettings: (s: Partial<Settings>) => void;
  cycleCurrency: () => void;
  addTx: (tx: Omit<Tx, 'id'>) => Tx;
  updateTx: (id: string, tx: Partial<Omit<Tx, 'id'>>) => void;
  deleteTx: (id: string) => Tx | undefined;
  restoreTx: (tx: Tx) => void;
  resetAll: () => void;
}

const preferencesStorage: StateStorage = {
  getItem: async (name) => (await Preferences.get({ key: name })).value,
  setItem: async (name, value) => Preferences.set({ key: name, value }),
  removeItem: async (name) => Preferences.remove({ key: name }),
};

const initial = {
  onboarded: false,
  profile: { name: '', photo: null, openingBalance: 0 } as Profile,
  settings: { lang: 'ar', currency: 'syp_new', usdRate: DEFAULT_USD_RATE } as Settings,
  txs: [] as Tx[],
};

const uid = () => `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;

const sortTxs = (txs: Tx[]) => [...txs].sort((a, b) => b.date.localeCompare(a.date));

export const useStore = create<State>()(
  persist(
    (set, get) => ({
      hydrated: false,
      ...initial,
      setHydrated: () => set({ hydrated: true }),
      completeOnboarding: (profile) => set({ profile, onboarded: true }),
      updateProfile: (p) => set({ profile: { ...get().profile, ...p } }),
      updateSettings: (s) => set({ settings: { ...get().settings, ...s } }),
      cycleCurrency: () => {
        const cur = get().settings.currency;
        const next = CURRENCY_ORDER[(CURRENCY_ORDER.indexOf(cur) + 1) % CURRENCY_ORDER.length];
        set({ settings: { ...get().settings, currency: next } });
      },
      addTx: (tx) => {
        const full = { ...tx, id: uid() };
        set({ txs: sortTxs([full, ...get().txs]) });
        return full;
      },
      updateTx: (id, tx) =>
        set({ txs: sortTxs(get().txs.map((t) => (t.id === id ? { ...t, ...tx } : t))) }),
      deleteTx: (id) => {
        const found = get().txs.find((t) => t.id === id);
        set({ txs: get().txs.filter((t) => t.id !== id) });
        return found;
      },
      restoreTx: (tx) => set({ txs: sortTxs([tx, ...get().txs]) }),
      resetAll: () => set({ ...initial, settings: get().settings }),
    }),
    {
      name: 'masarifi-v1',
      storage: createJSONStorage(() => preferencesStorage),
      partialize: (s) => ({ onboarded: s.onboarded, profile: s.profile, settings: s.settings, txs: s.txs }),
      onRehydrateStorage: () => (state) => state?.setHydrated(),
    },
  ),
);

// ---- derived helpers -------------------------------------------------------
export function balanceOf(profile: Profile, txs: Tx[]): number {
  return txs.reduce((b, t) => (t.type === 'income' ? b + t.amount : b - t.amount), profile.openingBalance);
}

export function inMonth(txs: Tx[], year: number, month: number): Tx[] {
  return txs.filter((t) => {
    const d = new Date(t.date);
    return d.getFullYear() === year && d.getMonth() === month;
  });
}

export function sumOf(txs: Tx[], type: TxType): number {
  return txs.reduce((s, t) => (t.type === type ? s + t.amount : s), 0);
}

/** Percent change of the balance since the start of the current month. */
export function monthChangePct(profile: Profile, txs: Tx[], now = new Date()): number {
  const balance = balanceOf(profile, txs);
  const month = inMonth(txs, now.getFullYear(), now.getMonth());
  const net = sumOf(month, 'income') - sumOf(month, 'expense');
  const start = balance - net;
  if (start <= 0) return net === 0 ? 0 : net > 0 ? 100 : -100;
  return (net / start) * 100;
}

/**
 * Spending grouped by its description (same words = same item), biggest first.
 * The label is the description as the user last wrote/said it.
 */
export function byItem(txs: Tx[], type: TxType): { key: string; label: string; total: number }[] {
  const map = new Map<string, { key: string; label: string; total: number }>();
  for (const t of txs) {
    if (t.type !== type) continue;
    const label = t.note.trim();
    const key = normalize(label) || `__${type}`;
    const cur = map.get(key);
    if (cur) cur.total += t.amount;
    else map.set(key, { key, label, total: t.amount });
  }
  return [...map.values()].sort((a, b) => b.total - a.total);
}
