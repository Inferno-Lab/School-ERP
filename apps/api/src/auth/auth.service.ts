import { Inject, Injectable } from '@nestjs/common';
import { newId } from '@edunest/db';
import { initials, type LoginChallenge, type LoginRequest, type LoginResponse, type Permission, type SessionUser, type TokenPair } from '@edunest/contracts';
import { hashPassword, maskEmail, maskPhone, randomCode, randomToken, sha256, signJwt, verifyPassword, constantTimeEqual } from '@edunest/security';
import { ENV, type Env } from '../env.js';
import { ApiError } from '@edunest/nest-kit';
import { AuditService, Messenger, SettingsService } from '../school/support.js';
import type { TenantCtx } from '../tenancy/tenant.js';

const ACCESS_SECONDS = 15 * 60;
const REFRESH_DAYS = 30;
const MAX_PASSWORD_TRIES = 5;
const LOCK_MINUTES = 15;
const OTP_TRIES = 3;
const OTP_MINUTES = 10;
export const DEMO_CODE = '424242';

interface UserRow {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  password_hash: string | null;
  status: string;
  failed_logins: number;
  locked_until: Date | null;
}

let dummyHash: Promise<string> | undefined;

@Injectable()
export class AuthService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly settings: SettingsService,
    private readonly messenger: Messenger,
    private readonly audit: AuditService,
  ) {}

  /** Step one: check the password. Returns a code challenge, or tokens when the school has two-step sign-in off. */
  async login(t: TenantCtx, body: LoginRequest, userAgent?: string): Promise<LoginResponse> {
    const ident = body.identifier.trim();
    const byEmail = ident.includes('@');
    const digits = ident.replace(/\D/g, '');
    const { rows } = await t.pool.query<UserRow>(
      byEmail
        ? 'select id, name, email, phone, password_hash, status, failed_logins, locked_until from users where lower(email) = $1 limit 1'
        : "select id, name, email, phone, password_hash, status, failed_logins, locked_until from users where right(regexp_replace(coalesce(phone,''), '\\D', '', 'g'), 10) = right($1, 10) and length($1) >= 8 limit 1",
      [byEmail ? ident.toLowerCase() : digits],
    );
    const user = rows[0];
    if (user?.locked_until && user.locked_until > new Date()) {
      const retryAfter = Math.ceil((user.locked_until.getTime() - Date.now()) / 1000);
      throw new ApiError('locked', `Too many wrong attempts. Try again in ${Math.ceil(retryAfter / 60)} minutes, or reset your password by SMS.`, { retryAfter });
    }
    dummyHash ??= hashPassword('not-a-real-password');
    const ok = await verifyPassword(body.password, user?.password_hash ?? (await dummyHash));
    if (!user || !ok || user.status !== 'active') {
      if (user) {
        const failed = user.failed_logins + 1;
        const lock = failed >= MAX_PASSWORD_TRIES;
        await t.pool.query('update users set failed_logins = $2, locked_until = $3 where id = $1', [user.id, lock ? 0 : failed, lock ? new Date(Date.now() + LOCK_MINUTES * 60_000) : null]);
        if (lock) throw new ApiError('locked', `Too many wrong attempts. Try again in ${LOCK_MINUTES} minutes, or reset your password by SMS.`, { retryAfter: LOCK_MINUTES * 60 });
        throw new ApiError('unauthenticated', 'That password isn’t right. Check it, or reset it by SMS.', { attemptsLeft: MAX_PASSWORD_TRIES - failed, fields: { password: 'That password isn’t right.' } });
      }
      throw new ApiError('unauthenticated', 'We couldn’t find an account with those details.', { fields: { identifier: 'We couldn’t find an account with those details.' } });
    }
    await t.pool.query('update users set failed_logins = 0, locked_until = null where id = $1', [user.id]);

    const doc = await this.settings.doc(t);
    if (doc.values['security.twoFactor'] === false) {
      return { step: 'done', tokens: await this.issue(t, user.id, userAgent) };
    }
    const demo = doc.values['demo.mode'] === true;
    const code = demo ? DEMO_CODE : randomCode(6);
    const id = newId('otp');
    const channel: 'sms' | 'email' = user.phone ? 'sms' : 'email';
    await t.pool.query('insert into otp_challenges (id, user_id, code_hash, channel, expires_at) values ($1,$2,$3,$4,$5)', [id, user.id, sha256(`${id}:${code}`), channel, new Date(Date.now() + OTP_MINUTES * 60_000)]);
    await this.messenger.send(t, {
      channel, to: (channel === 'sms' ? user.phone : user.email) ?? '', subject: channel === 'email' ? 'Your EduNest sign-in code' : undefined,
      body: `Your EduNest sign-in code for ${t.info.shortName} is ${code}. It expires in ${OTP_MINUTES} minutes.`,
    });
    const challenge: LoginChallenge = {
      challengeId: id, channel, maskedTo: channel === 'sms' ? maskPhone(user.phone!) : maskEmail(user.email!),
      expiresInSeconds: OTP_MINUTES * 60, ...(demo ? { demoCode: DEMO_CODE } : {}),
    };
    return { step: 'otp', challenge };
  }

  async verify(t: TenantCtx, challengeId: string, code: string, userAgent?: string): Promise<TokenPair> {
    const { rows } = await t.pool.query<{ id: string; user_id: string; code_hash: string; attempts: number; expires_at: Date; used_at: Date | null }>(
      'select id, user_id, code_hash, attempts, expires_at, used_at from otp_challenges where id = $1', [challengeId]);
    const row = rows[0];
    if (!row || row.used_at || row.expires_at < new Date()) throw new ApiError('unauthenticated', 'That code has expired. Go back and sign in again.', { fields: { code: 'That code has expired.' } });
    if (row.attempts >= OTP_TRIES) throw new ApiError('locked', 'Too many wrong codes. Go back and sign in again to get a new one.');
    if (!constantTimeEqual(sha256(`${challengeId}:${code}`), row.code_hash)) {
      await t.pool.query('update otp_challenges set attempts = attempts + 1 where id = $1', [challengeId]);
      throw new ApiError('unauthenticated', 'That code isn’t right.', { attemptsLeft: OTP_TRIES - row.attempts - 1, fields: { code: 'That code isn’t right.' } });
    }
    await t.pool.query('update otp_challenges set used_at = now() where id = $1', [challengeId]);
    return this.issue(t, row.user_id, userAgent);
  }

  async refresh(t: TenantCtx, refreshToken: string): Promise<TokenPair> {
    const [sid, secret] = refreshToken.split('.');
    const { rows } = await t.pool.query<{ id: string; user_id: string; refresh_hash: string; expires_at: Date; revoked_at: Date | null }>(
      'select id, user_id, refresh_hash, expires_at, revoked_at from sessions where id = $1', [sid ?? '']);
    const s = rows[0];
    if (!s || !secret || s.revoked_at || s.expires_at < new Date()) throw new ApiError('unauthenticated', 'Your session has ended. Sign in again.');
    if (!constantTimeEqual(sha256(secret), s.refresh_hash)) {
      // An old token was replayed: someone has a copy. End every session of this user.
      await t.pool.query('update sessions set revoked_at = now() where user_id = $1 and revoked_at is null', [s.user_id]);
      throw new ApiError('unauthenticated', 'Your session has ended. Sign in again.');
    }
    const next = randomToken(32);
    await t.pool.query('update sessions set refresh_hash = $2, expires_at = $3 where id = $1', [s.id, sha256(next), new Date(Date.now() + REFRESH_DAYS * 86_400_000)]);
    return this.tokens(t, s.user_id, s.id, `${s.id}.${next}`);
  }

  async logout(t: TenantCtx, sid: string): Promise<void> {
    await t.pool.query('update sessions set revoked_at = now() where id = $1', [sid]);
  }

  async me(t: TenantCtx, userId: string): Promise<SessionUser> {
    return this.sessionUser(t, userId);
  }

  private async issue(t: TenantCtx, userId: string, userAgent?: string): Promise<TokenPair> {
    const sid = newId('ses');
    const secret = randomToken(32);
    await t.pool.query('insert into sessions (id, user_id, refresh_hash, user_agent, expires_at) values ($1,$2,$3,$4,$5)', [sid, userId, sha256(secret), userAgent?.slice(0, 200) ?? null, new Date(Date.now() + REFRESH_DAYS * 86_400_000)]);
    await t.pool.query('update users set last_login_at = now() where id = $1', [userId]);
    const pair = await this.tokens(t, userId, sid, `${sid}.${secret}`);
    await this.audit.record(t, { actorId: userId, actorName: pair.user.name, action: 'auth.signed_in', entity: 'user', entityId: userId });
    return pair;
  }

  private async tokens(t: TenantCtx, userId: string, sid: string, refreshToken: string): Promise<TokenPair> {
    const user = await this.sessionUser(t, userId);
    const accessToken = signJwt({ sub: userId, aud: t.info.slug, sid, name: user.name, perms: user.permissions }, this.env.JWT_SECRET, ACCESS_SECONDS);
    return { accessToken, refreshToken, expiresInSeconds: ACCESS_SECONDS, user };
  }

  private async sessionUser(t: TenantCtx, userId: string): Promise<SessionUser> {
    const { rows } = await t.pool.query<{ id: string; name: string; email: string | null; phone: string | null; key: string | null; role_name: string | null; permissions: string[] | null }>(
      `select u.id, u.name, u.email, u.phone, r.key, r.name as role_name, r.permissions
       from users u left join user_roles ur on ur.user_id = u.id left join roles r on r.id = ur.role_id where u.id = $1`, [userId]);
    const first = rows[0];
    if (!first) throw new ApiError('unauthenticated', 'Your session has ended. Sign in again.');
    const perms = new Set<string>();
    rows.forEach((r) => r.permissions?.forEach((p) => perms.add(p)));
    return {
      id: first.id, name: first.name, email: first.email, phone: first.phone, initials: initials(first.name),
      roles: rows.map((r) => r.key).filter((x): x is string => !!x), roleNames: rows.map((r) => r.role_name).filter((x): x is string => !!x),
      permissions: [...perms] as Permission[],
    };
  }
}
