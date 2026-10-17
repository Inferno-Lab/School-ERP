import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/registry/schema.ts',
  out: './migrations/registry',
});
