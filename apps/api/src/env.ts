import { z } from 'zod';

const Env = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().default(4000),
  /** The registry database: where the school list lives. */
  REGISTRY_DATABASE_URL: z.string().min(10),
  /** Seals school connection strings at rest. */
  SECRETS_KEY: z.string().min(16),
  JWT_SECRET: z.string().min(16),
  CORS_ORIGINS: z.string().default('*'),
  APP_VERSION: z.string().default('0.1.0'),
  MESSAGING_MODE: z.enum(['sandbox']).default('sandbox'),
});
export type Env = z.infer<typeof Env>;

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  const parsed = Env.safeParse(source);
  if (!parsed.success) {
    const lines = parsed.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`).join('\n');
    throw new Error(`The server is not configured correctly:\n${lines}`);
  }
  return parsed.data;
}

export const ENV = Symbol('ENV');
