import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// The API address is read at build time; the dev server proxies it so the browser makes same-origin calls.
export default defineConfig({
  // The combined test server hosts the console under /console/; everywhere else it sits at the root.
  base: process.env.CONSOLE_BASE ?? '/',
  plugins: [react()],
  server: { port: 5174, proxy: { '/console': 'http://localhost:4000', '/v1': 'http://localhost:4000' } },
  build: { sourcemap: true, target: 'es2022' },
});
