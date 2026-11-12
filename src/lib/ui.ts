import { create } from 'zustand';
import type { TxType } from './categories';

export const TABS = ['home', 'tx', 'stats', 'voice', 'settings'] as const;
export type Tab = (typeof TABS)[number];

export interface AddPrefill {
  amount?: number; // new SYP
  note?: string;
}

export type Sheet =
  | { kind: 'add'; type: TxType; editId?: string; prefill?: AddPrefill }
  | { kind: 'month' }
  | { kind: 'notifications' }
  | null;

interface Toast {
  id: number;
  msg: string;
  action?: { label: string; run: () => void };
}

interface UiState {
  tab: Tab;
  direction: 1 | -1;
  sheet: Sheet;
  view: { year: number; month: number };
  toast: Toast | null;
  setTab: (t: Tab) => void;
  openSheet: (s: Sheet) => void;
  closeSheet: () => void;
  setView: (year: number, month: number) => void;
  showToast: (msg: string, action?: Toast['action']) => void;
  hideToast: () => void;
}

const now = new Date();
let toastTimer: ReturnType<typeof setTimeout> | undefined;

export const useUi = create<UiState>()((set, get) => ({
  tab: 'home',
  direction: 1,
  sheet: null,
  view: { year: now.getFullYear(), month: now.getMonth() },
  toast: null,
  setTab: (tab) => {
    const cur = get().tab;
    if (cur === tab) return;
    set({ tab, direction: TABS.indexOf(tab) > TABS.indexOf(cur) ? 1 : -1 });
  },
  openSheet: (sheet) => set({ sheet }),
  closeSheet: () => set({ sheet: null }),
  setView: (year, month) => set({ view: { year, month } }),
  showToast: (msg, action) => {
    clearTimeout(toastTimer);
    set({ toast: { id: Date.now(), msg, action } });
    toastTimer = setTimeout(() => set({ toast: null }), action ? 4500 : 2200);
  },
  hideToast: () => set({ toast: null }),
}));
