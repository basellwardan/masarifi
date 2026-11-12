import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.masarifi.app',
  appName: 'مصاريفي',
  webDir: 'dist',
  backgroundColor: '#071A4A',
  android: {
    // We draw under the status/navigation bars ourselves (the navy hero
    // reaches the top edge, like the reference screens).
    adjustMarginsForEdgeToEdge: 'disable',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 0,
      launchAutoHide: true,
      backgroundColor: '#071A4A',
    },
  },
};

export default config;
