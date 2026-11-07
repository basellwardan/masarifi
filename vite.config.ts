import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: { target: 'es2020', outDir: 'dist' },
  server: { port: 5180 },
  test: { environment: 'node' },
} as never);
