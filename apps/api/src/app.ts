import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import cors from '@fastify/cors';
import type { PoolManager, Registry } from '@edunest/tenancy';
import { AppModule } from './app.module.js';
import { loadEnv, type Env } from './env.js';

/** Builds the school API. The console server passes its own registry and pools so both share one set of connections. */
export async function createApp(env: Env = loadEnv(), shared?: { registry: Registry; pools: PoolManager }): Promise<NestFastifyApplication> {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule.register(env, shared),
    new FastifyAdapter({ trustProxy: true, bodyLimit: 3_000_000 }),
    { logger: env.NODE_ENV === 'test' ? ['error'] : ['error', 'warn', 'log'] },
  );
  await app.register(cors as never, {
    origin: env.CORS_ORIGINS === '*' ? true : env.CORS_ORIGINS.split(',').map((s) => s.trim()),
    allowedHeaders: ['content-type', 'authorization', 'x-school'],
    exposedHeaders: ['content-disposition', 'retry-after'],
    maxAge: 86400,
  });
  app.enableShutdownHooks();
  return app;
}
