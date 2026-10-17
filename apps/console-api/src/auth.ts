import { Body, Controller, Get, HttpCode, Inject, Injectable, Post, Req } from '@nestjs/common';
import { LoginRequest, VerifyRequest, consolePermissions, initials, type ConsoleLoginResponse, type ConsoleRole, type ConsoleTokens } from '@edunest/contracts';
import { newId } from '@edunest/db';
import { ApiError, ZodPipe } from '@edunest/nest-kit';
import { constantTimeEqual, hashPassword, maskEmail, randomCode, randomToken, sha256, signJwt, verifyPassword } from '@edunest/security';
import type { FastifyRequest } from 'fastify';
import { Db, Me, Public, type ConsoleUser } from './core.js';
import { ENV, type Env } from './env.js';
import { Sandbox } from './sandbox.js';

const ACCESS_SECONDS = 15 * 60;
const REFRESH_DAYS = 14;
let dummy: Promise<string> | undefined;

class Limiter {
  private readonly hits = new Map<string, number[]>();
  constructor(private readonly limit: number, private readonly windowMs: number) {}
  check(key: string): void {
    const now = Date.now();
    const recent = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowMs);
    if (recent.length >= this.limit) throw new ApiError('rate_limited', 'Too many tries. Wait a moment and try again.', { retryAfter: Math.ceil((this.windowMs - (now - recent[0]!)) / 1000) });
    recent.push(now);
    this.hits.set(key, recent);
  }
}
const limiter = new Limiter(30, 60_000);

@Injectable()
export class ConsoleAuth {
  constructor(
    private readonly db: Db,
    private readonly sandbox: Sandbox,
    @Inject(ENV) private readonly env: Env,
  ) {}

  async login(body: LoginRequest): Promise<ConsoleLoginResponse> {
    const { rows } = await this.db.pool.query<{ id: string; name: string; email: string; password_hash: string | null; status: string; roles: ConsoleRole[] }>(
      'select id, name, email, password_hash, status, roles from console_users where lower(email) = $1', [body.identifier.trim().toLowerCase()]);
    const u = rows[0];
    dummy ??= hashPassword('not-a-real-password');
    const ok = await verifyPassword(body.password, u?.password_hash ?? (await dummy));
    if (!u || !ok || u.status !== 'active') {
      throw new ApiError('unauthenticated', u ? 'That password isn’t right. Check it, or ask a super admin to reset it.' : 'We couldn’t find a console account with that email.', {
        fields: u ? { password: 'That password isn’t right.' } : { identifier: 'We couldn’t find a console account with that email.' },
      });
    }
    const code = this.env.DEMO_CODE ?? randomCode(6);
    const id = newId('cot');
    await this.db.pool.query('insert into console_otp (id, user_id, code_hash, expires_at) values ($1,$2,$3,$4)', [id, u.id, sha256(`${id}:${code}`), new Date(Date.now() + 10 * 60_000)]);
    await this.sandbox.put({ schoolSlug: 'console', channel: 'email', to: u.email, subject: 'Your EduNest console code', body: `Your sign-in code is ${code}. It expires in 10 minutes.` });
    return { step: 'otp', challenge: { challengeId: id, channel: 'email', maskedTo: maskEmail(u.email), expiresInSeconds: 600, ...(this.env.DEMO_CODE ? { demoCode: this.env.DEMO_CODE } : {}) } };
  }

  async verify(body: VerifyRequest): Promise<ConsoleTokens> {
    const { rows } = await this.db.pool.query<{ id: string; user_id: string; code_hash: string; attempts: number; expires_at: Date; used_at: Date | null }>('select * from console_otp where id = $1', [body.challengeId]);
    const r = rows[0];
    if (!r || r.used_at || r.expires_at < new Date()) throw new ApiError('unauthenticated', 'That code has expired. Go back and sign in again.', { fields: { code: 'That code has expired.' } });
    if (r.attempts >= 3) throw new ApiError('locked', 'Too many wrong codes. Go back and sign in again.');
    if (!constantTimeEqual(sha256(`${body.challengeId}:${body.code}`), r.code_hash)) {
      await this.db.pool.query('update console_otp set attempts = attempts + 1 where id = $1', [r.id]);
      throw new ApiError('unauthenticated', 'That code isn’t right.', { attemptsLeft: 2 - r.attempts, fields: { code: 'That code isn’t right.' } });
    }
    await this.db.pool.query('update console_otp set used_at = now() where id = $1', [r.id]);
    return this.issue(r.user_id);
  }

  async refresh(token: string): Promise<ConsoleTokens> {
    const [sid, secret] = token.split('.');
    const { rows } = await this.db.pool.query<{ id: string; user_id: string; refresh_hash: string; expires_at: Date; revoked_at: Date | null }>('select * from console_sessions where id = $1', [sid ?? '']);
    const s = rows[0];
    if (!s || !secret || s.revoked_at || s.expires_at < new Date()) throw new ApiError('unauthenticated', 'Your session has ended. Sign in again.');
    if (!constantTimeEqual(sha256(secret), s.refresh_hash)) {
      await this.db.pool.query('update console_sessions set revoked_at = now() where user_id = $1 and revoked_at is null', [s.user_id]);
      throw new ApiError('unauthenticated', 'Your session has ended. Sign in again.');
    }
    const next = randomToken(32);
    await this.db.pool.query('update console_sessions set refresh_hash = $2, expires_at = $3 where id = $1', [s.id, sha256(next), new Date(Date.now() + REFRESH_DAYS * 86_400_000)]);
    return this.tokens(s.user_id, s.id, `${s.id}.${next}`);
  }

  async logout(sid: string): Promise<void> {
    await this.db.pool.query('update console_sessions set revoked_at = now() where id = $1', [sid]);
  }

  private async issue(userId: string): Promise<ConsoleTokens> {
    const sid = newId('cse');
    const secret = randomToken(32);
    await this.db.pool.query('insert into console_sessions (id, user_id, refresh_hash, expires_at) values ($1,$2,$3,$4)', [sid, userId, sha256(secret), new Date(Date.now() + REFRESH_DAYS * 86_400_000)]);
    await this.db.pool.query('update console_users set last_seen_at = now() where id = $1', [userId]);
    return this.tokens(userId, sid, `${sid}.${secret}`);
  }

  private async tokens(userId: string, sid: string, refreshToken: string): Promise<ConsoleTokens> {
    const { rows } = await this.db.pool.query<{ id: string; name: string; email: string; roles: ConsoleRole[] }>('select id, name, email, roles from console_users where id = $1', [userId]);
    const u = rows[0];
    if (!u) throw new ApiError('unauthenticated', 'Your session has ended. Sign in again.');
    const accessToken = signJwt({ sub: u.id, aud: 'console', sid, name: u.name, email: u.email, roles: u.roles }, this.env.JWT_SECRET, ACCESS_SECONDS);
    return { accessToken, refreshToken, expiresInSeconds: ACCESS_SECONDS, user: { id: u.id, name: u.name, email: u.email, initials: initials(u.name), roles: u.roles, permissions: consolePermissions(u.roles) } };
  }
}

@Controller('console/v1/auth')
export class AuthController {
  constructor(private readonly auth: ConsoleAuth) {}

  @Public() @Post('login') @HttpCode(200)
  login(@Body(new ZodPipe(LoginRequest)) body: LoginRequest, @Req() req: FastifyRequest): Promise<ConsoleLoginResponse> {
    limiter.check(`l|${req.ip}`);
    return this.auth.login(body);
  }

  @Public() @Post('verify') @HttpCode(200)
  verify(@Body(new ZodPipe(VerifyRequest)) body: VerifyRequest, @Req() req: FastifyRequest): Promise<ConsoleTokens> {
    limiter.check(`v|${req.ip}`);
    return this.auth.verify(body);
  }

  @Public() @Post('refresh') @HttpCode(200)
  refresh(@Body() body: { refreshToken?: string }): Promise<ConsoleTokens> {
    if (!body?.refreshToken) throw new ApiError('validation', 'Missing refresh token.');
    return this.auth.refresh(body.refreshToken);
  }

  @Post('logout') @HttpCode(204)
  async logout(@Me() me: ConsoleUser): Promise<void> {
    await this.auth.logout(me.sid);
  }

  @Get('me')
  me(@Me() me: ConsoleUser): ConsoleUser {
    return me;
  }
}
