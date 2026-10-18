import { Body, Controller, Get, HttpCode, Post, Req } from '@nestjs/common';
import { LoginRequest, RefreshRequest, VerifyRequest, type EffectiveConfig, type LoginResponse, type SessionUser, type TokenPair } from '@edunest/contracts';
import type { FastifyRequest } from 'fastify';
import { ApiError, ZodPipe } from '@edunest/nest-kit';
import { SettingsService } from '../school/support.js';
import { Tenant, type AuthedUser, type TenantCtx } from '../tenancy/tenant.js';
import { AuthService } from './auth.service.js';
import { CurrentUser, Public } from './guards.js';

/** At most `limit` calls per `windowMs` for a key. Enough to blunt guessing; a shared store would replace it with many servers. */
class Limiter {
  private readonly hits = new Map<string, number[]>();
  constructor(private readonly limit: number, private readonly windowMs: number) {}
  check(key: string): void {
    const now = Date.now();
    const recent = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowMs);
    if (recent.length >= this.limit) {
      const retryAfter = Math.ceil((this.windowMs - (now - recent[0]!)) / 1000);
      throw new ApiError('rate_limited', 'Too many tries from this device. Wait a moment and try again.', { retryAfter });
    }
    recent.push(now);
    this.hits.set(key, recent);
    if (this.hits.size > 5000) for (const [k, v] of this.hits) if (!v.some((t) => now - t < this.windowMs)) this.hits.delete(k);
  }
}

const loginLimit = new Limiter(30, 60_000);

@Controller('v1/auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public() @Post('login') @HttpCode(200)
  login(@Tenant() t: TenantCtx, @Body(new ZodPipe(LoginRequest)) body: LoginRequest, @Req() req: FastifyRequest): Promise<LoginResponse> {
    loginLimit.check(`${t.info.slug}|${req.ip}`);
    return this.auth.login(t, body, req.headers['user-agent']);
  }

  @Public() @Post('verify') @HttpCode(200)
  verify(@Tenant() t: TenantCtx, @Body(new ZodPipe(VerifyRequest)) body: VerifyRequest, @Req() req: FastifyRequest): Promise<TokenPair> {
    loginLimit.check(`${t.info.slug}|${req.ip}|v`);
    return this.auth.verify(t, body.challengeId, body.code, req.headers['user-agent']);
  }

  @Public() @Post('refresh') @HttpCode(200)
  refresh(@Tenant() t: TenantCtx, @Body(new ZodPipe(RefreshRequest)) body: RefreshRequest): Promise<TokenPair> {
    return this.auth.refresh(t, body.refreshToken);
  }

  @Post('logout') @HttpCode(204)
  async logout(@Tenant() t: TenantCtx, @CurrentUser() u: AuthedUser): Promise<void> {
    await this.auth.logout(t, u.sid);
  }
}

@Controller('v1')
export class MeController {
  constructor(
    private readonly auth: AuthService,
    private readonly settings: SettingsService,
  ) {}

  @Get('me')
  async me(@Tenant() t: TenantCtx, @CurrentUser() u: AuthedUser): Promise<SessionUser> {
    // A console support session has no account in the school: describe it as what it is.
    if (u.id.startsWith('support:')) return { id: u.id, name: u.name, email: null, phone: null, initials: 'ES', roles: ['support'], roleNames: ['EduNest support'], permissions: u.permissions as SessionUser['permissions'] };
    return this.auth.me(t, u.id);
  }

  /** The settings the apps and admin start from: platform defaults, plan, locks and school choices, cut to this user. */
  @Get('config')
  config(@Tenant() t: TenantCtx, @CurrentUser() u: AuthedUser): Promise<EffectiveConfig> {
    return this.settings.effective(t, u.permissions);
  }

  /** Branding for the sign-in page, before anyone has signed in. */
  @Public() @Get('brand')
  async brand(@Tenant() t: TenantCtx): Promise<{ name: string; shortName: string; color: string; logoText: string; tagline: string; demoMode: boolean; language: string }> {
    const cfg = await this.settings.effective(t);
    return { ...cfg.school, demoMode: cfg.settings['demo.mode'] === true };
  }
}
