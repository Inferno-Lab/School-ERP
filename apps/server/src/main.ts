import 'reflect-metadata';
import { AppModule, loadEnv as loadApiEnv } from '@edunest/api';
import { ConsoleModule, loadEnv as loadConsoleEnv, prepareRegistry } from '@edunest/console-api';
import { ApiExceptionFilter } from '@edunest/nest-kit';
import { PoolManager, Registry } from '@edunest/tenancy';
import cors from '@fastify/cors';
import { Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';

/**
 * One process for the test track and small installs: the school API and the console API side by side,
 * sharing one registry connection and one set of school pools. Large installs run them apart.
 */
const apiEnv = loadApiEnv();
const consoleEnv = loadConsoleEnv();
await prepareRegistry(consoleEnv);
const shared = { registry: new Registry({ url: apiEnv.REGISTRY_DATABASE_URL, secret: apiEnv.SECRETS_KEY }), pools: new PoolManager() };

@Module({ imports: [AppModule.register(apiEnv, shared), ConsoleModule.register(consoleEnv, shared)] })
class ServerModule {}

const app = await NestFactory.create<NestFastifyApplication>(ServerModule, new FastifyAdapter({ trustProxy: true, bodyLimit: 3_000_000 }), { logger: ['error', 'warn', 'log'] });
app.useGlobalFilters(new ApiExceptionFilter());
await app.register(cors as never, {
  origin: apiEnv.CORS_ORIGINS === '*' ? true : apiEnv.CORS_ORIGINS.split(',').map((s) => s.trim()),
  allowedHeaders: ['content-type', 'authorization', 'x-school'],
  exposedHeaders: ['content-disposition', 'retry-after'],
  maxAge: 86400,
});
app.enableShutdownHooks();
await app.listen(apiEnv.PORT, apiEnv.HOST);
