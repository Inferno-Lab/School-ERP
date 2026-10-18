import { createConsoleApp } from './app.js';
import { loadEnv } from './env.js';

const env = loadEnv();
const app = await createConsoleApp(env);
await app.listen(env.PORT, env.HOST);
