import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/school/schema.ts',
  out: './migrations/school',
});
