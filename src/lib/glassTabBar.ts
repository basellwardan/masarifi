import { Capacitor, registerPlugin, type PluginListenerHandle } from '@capacitor/core';
import { useEffect } from 'react';
import { DICTS } from './i18n';
import { useStore } from './store';
import { TABS, useUi, type Tab } from './ui';

/** iPhone only: native Liquid Glass tab bar (iOS 26+), see ios/App/App/AppDelegate.swift. */
interface A11yState {
  reduceTransparency: boolean;
  increaseContrast: boolean;
  reduceMotion: boolean;
}

interface GlassTabBarPlugin {
  show(options: { tabs: { id: string; symbol: string; label: string }[]; selected: string; rtl: boolean }): Promise<void>;
  select(options: { tab: string }): Promise<void>;
  setHidden(options: { hidden: boolean }): Promise<void>;
  setMinimized(options: { minimized: boolean }): Promise<void>;
  accessibility(): Promise<A11yState>;
  addListener(event: 'tabSelected', fn: (d: { tab: string }) => void): Promise<PluginListenerHandle>;
  addListener(event: 'accessibilityChanged', fn: (d: A11yState) => void): Promise<PluginListenerHandle>;
}

export const isIOS = Capacitor.getPlatform() === 'ios';
const GlassTabBar = registerPlugin<GlassTabBarPlugin>('GlassTabBar');

/** SF Symbols matching the web tab bar icons. */
const SYMBOLS: Record<Tab, string> = {
  home: 'creditcard',
  tx: 'arrow.up.arrow.down',
  stats: 'chart.pie',
  voice: 'mic',
  settings: 'square.grid.2x2',
};

const LABEL: Record<Tab, 'balance' | 'transactions' | 'stats' | 'voice' | 'settings'> = {
  home: 'balance',
  tx: 'transactions',
  stats: 'stats',
  voice: 'voice',
  settings: 'settings',
};

function applyA11y(a: A11yState) {
  const c = document.documentElement.classList;
  c.toggle('reduce-transparency', a.reduceTransparency);
  c.toggle('increase-contrast', a.increaseContrast);
}

/** Reads iOS accessibility settings (Reduce Transparency, Increase Contrast) into <html> classes. */
export function useIOSAccessibility() {
  useEffect(() => {
    if (!isIOS) return;
    let handle: PluginListenerHandle | undefined;
    GlassTabBar.accessibility().then(applyA11y).catch(() => undefined);
    GlassTabBar.addListener('accessibilityChanged', applyA11y)
      .then((h) => (handle = h))
      .catch(() => undefined);
    return () => void handle?.remove();
  }, []);
}

/**
 * While the main screens are mounted on an iPhone with iOS 26+, shows the
 * native Liquid Glass tab bar and keeps it in sync with the app. The web tab
 * bar hides itself when `nativeTabBar` is true, and stays as the fallback.
 */
export function useNativeTabBar() {
  const lang = useStore((s) => s.settings.lang);
  const tab = useUi((s) => s.tab);
  const sheetOpen = useUi((s) => s.sheet !== null);
  const native = useUi((s) => s.nativeTabBar);

  // create (and re-create when the language changes: labels + RTL order)
  useEffect(() => {
    if (!isIOS) return;
    let handle: PluginListenerHandle | undefined;
    let cancelled = false;
    const t = DICTS[lang];
    GlassTabBar.show({
      tabs: TABS.map((id) => ({ id, symbol: SYMBOLS[id], label: t[LABEL[id]] })),
      selected: useUi.getState().tab,
      rtl: lang === 'ar',
    })
      .then(async () => {
        if (cancelled) return;
        handle = await GlassTabBar.addListener('tabSelected', ({ tab: next }) => {
          if ((TABS as readonly string[]).includes(next)) useUi.getState().setTab(next as Tab);
        });
        useUi.getState().setNativeTabBar(true);
      })
      .catch(() => useUi.getState().setNativeTabBar(false)); // older iOS: keep the web tab bar
    return () => {
      cancelled = true;
      handle?.remove();
      GlassTabBar.setHidden({ hidden: true }).catch(() => undefined);
    };
  }, [lang]);

  useEffect(() => {
    if (native) GlassTabBar.select({ tab }).catch(() => undefined);
  }, [tab, native]);

  // sheets cover the navigation layer
  useEffect(() => {
    if (native) GlassTabBar.setHidden({ hidden: sheetOpen }).catch(() => undefined);
  }, [sheetOpen, native]);

  // minimize on scroll down, expand on scroll up (Apple's tab bar behaviour)
  useEffect(() => {
    if (!native) return;
    const last = new WeakMap<EventTarget, number>();
    let minimized = false;
    const set = (m: boolean) => {
      if (m === minimized) return;
      minimized = m;
      GlassTabBar.setMinimized({ minimized: m }).catch(() => undefined);
    };
    const onScroll = (e: Event) => {
      const el = e.target as HTMLElement | null;
      if (!el || typeof el.scrollTop !== 'number') return;
      const y = el.scrollTop;
      const prev = last.get(el) ?? 0;
      last.set(el, y);
      if (y < 24) set(false);
      else if (y - prev > 6) set(true);
      else if (prev - y > 6) set(false);
    };
    document.addEventListener('scroll', onScroll, { capture: true, passive: true });
    set(false);
    return () => document.removeEventListener('scroll', onScroll, { capture: true });
  }, [native, tab]);
}
