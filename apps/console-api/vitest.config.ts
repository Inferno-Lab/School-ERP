import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';

// Nest injects by constructor type, so tests need real decorator metadata (esbuild does not emit it).
export default defineConfig({
  plugins: [swc.vite({ jsc: { target: 'es2023', parser: { syntax: 'typescript', decorators: true }, transform: { legacyDecorator: true, decoratorMetadata: true, useDefineForClassFields: false } }, module: { type: 'es6' } })],
  test: { include: ['test/**/*.test.ts', 'src/**/*.test.ts'], hookTimeout: 240_000, testTimeout: 60_000, fileParallelism: false },
});
