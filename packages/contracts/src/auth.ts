import { z } from 'zod';
import { Permission } from './permissions.js';

export const LoginRequest = z.object({
  identifier: z.string().trim().min(3, 'Enter your email or phone').max(120),
  password: z.string().min(1, 'Enter your password').max(200),
});
export type LoginRequest = z.infer<typeof LoginRequest>;

/** Step one succeeds with a challenge; the code goes to the user's phone or email (or the sandbox inbox on test). */
export const LoginChallenge = z.object({
  challengeId: z.string(),
  channel: z.enum(['sms', 'email']),
  maskedTo: z.string(),
  expiresInSeconds: z.number().int(),
  /** Present only on schools in demo mode, so the sign-in page can offer to fill it in. */
  demoCode: z.string().optional(),
});
export type LoginChallenge = z.infer<typeof LoginChallenge>;

export type LoginResponse =
  | { step: 'otp'; challenge: LoginChallenge }
  | { step: 'done'; tokens: TokenPair };

export const VerifyRequest = z.object({
  challengeId: z.string().min(1),
  code: z.string().regex(/^\d{6}$/, 'The code is 6 digits'),
});
export type VerifyRequest = z.infer<typeof VerifyRequest>;

export const RefreshRequest = z.object({ refreshToken: z.string().min(20) });
export type RefreshRequest = z.infer<typeof RefreshRequest>;

export interface SessionUser {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  initials: string;
  roles: string[];
  roleNames: string[];
  permissions: Permission[];
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresInSeconds: number;
  user: SessionUser;
}

export interface AccessClaims {
  sub: string;
  /** School slug (school tokens) or "console" for control-plane tokens. */
  aud: string;
  sid: string;
  name: string;
  perms: string[];
}
