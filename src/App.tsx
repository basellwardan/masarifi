import { App as CapApp } from '@capacitor/app';
import { AnimatePresence, MotionConfig, motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { AddSheet } from './components/AddSheet';
import { MonthSheet, NotificationsSheet } from './components/Sheets';
import { TabBar } from './components/TabBar';
import { Toast } from './components/Toast';
import { useIOSAccessibility } from './lib/glassTabBar';
import { isNative, setupStatusBar } from './lib/native';
import { useStore } from './lib/store';
import { useUi, type Tab } from './lib/ui';
import { Home } from './screens/Home';
import { Settings } from './screens/Settings';
import { Splash } from './screens/Splash';
import { Stats } from './screens/Stats';
import { Transactions } from './screens/Transactions';
import { Voice } from './screens/Voice';
import { Welcome } from './screens/Welcome';

const SCREENS: Record<Tab, () => React.JSX.Element> = {
  home: Home,
  tx: Transactions,
  stats: Stats,
  voice: Voice,
  settings: Settings,
};

const MIN_SPLASH_MS = 1500;

export default function App() {
  const hydrated = useStore((s) => s.hydrated);
  const onboarded = useStore((s) => s.onboarded);
  const lang = useStore((s) => s.settings.lang);
  const { tab, direction, sheet } = useUi();
  const [minDone, setMinDone] = useState(false);
  useIOSAccessibility();

  useEffect(() => {
    setupStatusBar();
    const id = setTimeout(() => setMinDone(true), MIN_SPLASH_MS);
    return () => clearTimeout(id);
  }, []);

  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
  }, [lang]);

  // Android back: close a sheet, then go Home, then leave the app.
  useEffect(() => {
    if (!isNative) return;
    const h = CapApp.addListener('backButton', () => {
      const ui = useUi.getState();
      if (ui.sheet) ui.closeSheet();
      else if (ui.tab !== 'home') ui.setTab('home');
      else CapApp.exitApp();
    });
    return () => {
      h.then((x) => x.remove());
    };
  }, []);

  const ready = hydrated && minDone;
  const Screen = SCREENS[tab];
  // slide direction follows reading direction
  const dx = 28 * direction * (lang === 'ar' ? -1 : 1);

  return (
    <MotionConfig reducedMotion="user">
      <div className="app">
        <AnimatePresence mode="wait">
          {!ready ? (
            <Splash key="splash" />
          ) : !onboarded ? (
            <Welcome key="welcome" />
          ) : (
            <motion.div
              key="main"
              className="screen"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.4 }}
            >
              {/*
                Tab switch: both screens are absolutely positioned, so they can
                cross-fade in place without measuring layout (no popLayout), and
                only transform/opacity animate, which the GPU composites cheaply.
              */}
              <AnimatePresence initial={false} custom={dx}>
                <motion.div
                  key={tab}
                  className="screen tab-screen"
                  custom={dx}
                  variants={{
                    enter: (d: number) => ({ x: d, opacity: 0 }),
                    center: { x: 0, opacity: 1 },
                    exit: (d: number) => ({ x: -d * 0.5, opacity: 0 }),
                  }}
                  initial="enter"
                  animate="center"
                  exit="exit"
                  transition={{ duration: 0.26, ease: [0.22, 1, 0.36, 1] }}
                >
                  <Screen />
                </motion.div>
              </AnimatePresence>
              <TabBar />
              <AnimatePresence>
                {sheet?.kind === 'add' && (
                  <AddSheet key="add" type={sheet.type} editId={sheet.editId} prefill={sheet.prefill} />
                )}
                {sheet?.kind === 'month' && <MonthSheet key="month" />}
                {sheet?.kind === 'notifications' && <NotificationsSheet key="notif" />}
              </AnimatePresence>
              <Toast />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </MotionConfig>
  );
}
