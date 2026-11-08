import '@fontsource/inter/400.css';
import '@fontsource/inter/500.css';
import '@fontsource/inter/600.css';
import '@fontsource/inter/700.css';
import '@fontsource/inter/800.css';
import '@fontsource/ibm-plex-sans-arabic/400.css';
import '@fontsource/ibm-plex-sans-arabic/500.css';
import '@fontsource/ibm-plex-sans-arabic/600.css';
import '@fontsource/ibm-plex-sans-arabic/700.css';
import './styles/app.css';

import { Capacitor } from '@capacitor/core';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { useStore } from './lib/store';
import { useUi } from './lib/ui';

// iPhone: Liquid Glass styling layer (see app.css "iPhone: Liquid Glass")
if (Capacitor.getPlatform() === 'ios' || new URLSearchParams(location.search).has('ios')) {
  document.documentElement.classList.add('ios');
}

// Weaker phones (≤4 cores or ≤4 GB RAM) skip the remaining live blur.
const nav = navigator as Navigator & { deviceMemory?: number };
if (Capacitor.getPlatform() !== 'ios' && ((nav.hardwareConcurrency ?? 8) <= 4 || (nav.deviceMemory ?? 8) <= 4)) {
  document.documentElement.classList.add('lite');
}

if (import.meta.env.DEV) Object.assign(window, { __store: useStore, __ui: useUi });

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
