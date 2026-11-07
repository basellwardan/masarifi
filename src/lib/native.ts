import { Capacitor } from '@capacitor/core';
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { StatusBar, Style } from '@capacitor/status-bar';

export const isNative = Capacitor.isNativePlatform();

export function tap(style: 'light' | 'medium' = 'light') {
  if (!isNative) return;
  Haptics.impact({ style: style === 'light' ? ImpactStyle.Light : ImpactStyle.Medium }).catch(() => undefined);
}

export async function setupStatusBar() {
  if (!isNative) return;
  try {
    await StatusBar.setOverlaysWebView({ overlay: true });
    await StatusBar.setStyle({ style: Style.Dark }); // light icons over the navy hero
    await StatusBar.setBackgroundColor({ color: '#00000000' });
  } catch {
    /* ignore */
  }
}
