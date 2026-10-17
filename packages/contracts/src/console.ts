import { z } from 'zod';
import { RESERVED_SLUGS, SLUG_RE } from './common.js';

export const CONSOLE_ROLES = ['super_admin', 'support', 'release_manager', 'finance', 'compliance', 'auditor'] as const;
export const ConsoleRole = z.enum(CONSOLE_ROLES);
export type ConsoleRole = z.infer<typeof ConsoleRole>;

export const SchoolStatus = z.enum(['onboarding', 'live', 'suspended', 'offboarding', 'archived']);
export type SchoolStatus = z.infer<typeof SchoolStatus>;

/** Where a cell runs. A cell has exactly one target; the blueprint steps are the same on every target. */
export const DeployTarget = z.enum(['local', 'free-test', 'aws-cell']);
export type DeployTarget = z.infer<typeof DeployTarget>;

export const Slug = z
  .string()
  .trim()
  .toLowerCase()
  .regex(SLUG_RE, 'Use 4 to 32 letters, numbers or dashes, starting with a letter')
  .refine((s) => !(RESERVED_SLUGS as readonly string[]).includes(s), 'That address is reserved');

export const STEP_KEYS = [
  'database',
  'keys',
  'storage',
  'edge',
  'migrate',
  'seed',
  'entitlements',
  'admin-user',
  'build-profile',
  'build-app',
  'invites',
  'activate',
] as const;
export const StepKey = z.enum(STEP_KEYS);
export type StepKey = z.infer<typeof StepKey>;

export const BlueprintStep = z.object({
  key: StepKey,
  label: z.string().min(2).max(80),
  optional: z.boolean().default(false),
  enabled: z.boolean().default(true),
  params: z.record(z.string(), z.unknown()).default({}),
});
export type BlueprintStep = z.infer<typeof BlueprintStep>;

export const BlueprintInput = z.object({
  key: z.string().regex(/^[a-z][a-z0-9-]{2,40}$/),
  name: z.string().min(3).max(80),
  target: DeployTarget,
  plan: z.string().nullable().default(null),
  steps: z.array(BlueprintStep).min(1).max(20),
});
export type BlueprintInput = z.infer<typeof BlueprintInput>;

export interface BlueprintRow extends BlueprintInput {
  id: string;
  version: number;
  active: boolean;
  createdBy: string;
  createdAt: string;
}

/** The order the steps must keep. A blueprint may drop optional steps and change params, not reorder past this. */
export function stepOrderProblem(steps: { key: StepKey; enabled?: boolean }[]): string | null {
  let last = -1;
  for (const s of steps) {
    const at = STEP_KEYS.indexOf(s.key);
    if (at <= last) return `“${s.key}” is out of order. Steps must follow: ${STEP_KEYS.join(', ')}.`;
    last = at;
  }
  const keys = steps.map((s) => s.key);
  for (const required of ['database', 'migrate', 'entitlements', 'admin-user', 'activate'] as StepKey[]) {
    const s = steps.find((x) => x.key === required);
    if (!s || !keys.includes(required)) return `The “${required}” step is required.`;
    if (s.enabled === false) return `The “${required}” step cannot be switched off.`;
  }
  return null;
}

export interface PlanRow {
  key: string;
  name: string;
  perStudentYear: number;
  modules: string[];
  limits: { students: number; storageGb: number; smsPerMonth: number };
}

export const WizardBasics = z.object({
  name: z.string().trim().min(3, 'Enter the school’s full name').max(80),
  shortName: z.string().trim().min(2, 'Enter a short name').max(20),
  slug: Slug,
  board: z.enum(['CBSE', 'ICSE', 'State', 'IB', 'Other']).default('CBSE'),
  address: z.string().trim().max(240).default(''),
  city: z.string().trim().max(60).default(''),
  contactName: z.string().trim().min(2).max(80),
  contactPhone: z.string().trim().min(8).max(20),
  contactEmail: z.string().trim().email('Enter a valid email'),
  gstin: z.string().trim().max(20).default(''),
  language: z.enum(['en', 'hi', 'mr']).default('en'),
});

export const WizardPlan = z.object({
  plan: z.string().min(1, 'Choose a plan'),
  modules: z.array(z.string()).min(1, 'Switch on at least one module'),
  addOns: z.array(z.string()).default([]),
  locks: z.array(z.string()).default([]),
  students: z.number().int().min(1).max(20000).default(500),
});

export const WizardBranding = z.object({
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/, 'Use a colour like #6A4CF5'),
  logoText: z.string().trim().min(1).max(2),
  appName: z.string().trim().min(2).max(30),
  tagline: z.string().trim().max(120).default(''),
});

export const WizardPlacement = z.object({
  target: DeployTarget,
  cell: z.string().min(1),
  addressing: z.enum(['subdomain', 'path']).default('path'),
  customDomain: z.string().trim().max(120).default(''),
});

export const WizardAdmin = z.object({
  name: z.string().trim().min(2, 'Enter the admin’s name').max(80),
  email: z.string().trim().email('Enter a valid email'),
  phone: z.string().trim().min(8, 'Enter a phone number').max(20),
  invite: z.enum(['sms', 'email', 'both']).default('both'),
  roles: z.array(z.string()).default(['principal']),
});

export const WizardData = z.object({ start: z.enum(['empty', 'demo', 'import']).default('demo') });

export const WizardPayload = z.object({
  basics: WizardBasics,
  plan: WizardPlan,
  branding: WizardBranding,
  placement: WizardPlacement,
  admin: WizardAdmin,
  data: WizardData,
});
export type WizardPayload = z.infer<typeof WizardPayload>;

export const WIZARD_STEPS = ['basics', 'plan', 'branding', 'placement', 'admin', 'data'] as const;
export type WizardStepKey = (typeof WIZARD_STEPS)[number];

export interface WizardDraftRow {
  id: string;
  name: string;
  step: number;
  data: Partial<Record<WizardStepKey, unknown>>;
  updatedBy: string;
  updatedAt: string;
}

export interface ReviewItem {
  label: string;
  detail: string;
}
export interface WizardReview {
  summary: ReviewItem[];
  willDo: { key: StepKey; label: string; detail: string; optional: boolean }[];
  capacity: { cell: string; schools: number; max: number; ok: boolean };
  needsApproval: boolean;
  problems: string[];
}

export type StepStatus = 'pending' | 'running' | 'done' | 'failed' | 'skipped';
export interface RunStepRow {
  key: StepKey;
  label: string;
  status: StepStatus;
  optional: boolean;
  startedAt: string | null;
  finishedAt: string | null;
  log: { at: string; level: 'info' | 'warn' | 'error'; text: string }[];
  error: string | null;
}
export interface ProvisionRunRow {
  id: string;
  schoolId: string;
  schoolName: string;
  blueprintKey: string;
  blueprintVersion: number;
  target: DeployTarget;
  dryRun: boolean;
  status: 'queued' | 'running' | 'succeeded' | 'failed';
  startedAt: string;
  finishedAt: string | null;
  steps: RunStepRow[];
}

export interface SchoolRow {
  id: string;
  slug: string;
  name: string;
  shortName: string;
  color: string;
  logoText: string;
  status: SchoolStatus;
  plan: string;
  cell: string;
  target: DeployTarget;
  region: string;
  versions: { api: string; admin: string; app: string };
  configVersion: number;
  students: number;
  health: 'ok' | 'degraded' | 'down' | 'unknown';
  healthMs: number | null;
  onboarding: { done: number; total: number };
  lastIncident: string | null;
  adminUrl: string;
  createdAt: string;
}

export interface SchoolDetail extends SchoolRow {
  contact: { name: string; phone: string; email: string };
  gstin: string;
  entitlement: {
    modules: string[];
    limits: { students: number; storageGb: number; smsPerMonth: number };
    locks: string[];
    version: number;
  };
  usage: { students: number; storageGb: number; sms: number; staff: number };
  checklist: { key: string; label: string; done: boolean; hint: string }[];
  runs: ProvisionRunRow[];
  builds: BuildRow[];
}

export interface BuildRow {
  id: string;
  schoolId: string;
  platform: 'android' | 'ios';
  version: string;
  status: 'queued' | 'building' | 'done' | 'failed' | 'unavailable';
  url: string | null;
  note: string;
  createdAt: string;
}

export const ACTIONS = [
  'school.create',
  'school.suspend',
  'school.resume',
  'school.erase',
  'entitlements.push',
  'release.wave',
  'migration.run',
  'domain.set',
  'build.app',
  'backup.take',
] as const;
export const ActionKey = z.enum(ACTIONS);
export type ActionKey = z.infer<typeof ActionKey>;

export const ActionRequest = z.object({
  action: ActionKey,
  schoolId: z.string(),
  params: z.record(z.string(), z.unknown()).default({}),
  dryRun: z.boolean().default(false),
  /** Danger actions need the school code typed exactly. */
  confirmCode: z.string().optional(),
});
export type ActionRequest = z.infer<typeof ActionRequest>;

export interface ActionRow {
  id: string;
  action: ActionKey;
  schoolId: string | null;
  schoolName: string | null;
  status: 'pending_approval' | 'running' | 'done' | 'failed' | 'rejected';
  requestedBy: string;
  approvedBy: string | null;
  dryRun: boolean;
  summary: string;
  createdAt: string;
  finishedAt: string | null;
}

export interface PolicyDoc {
  approvals: Record<string, { needed: boolean; roles: ConsoleRole[] }>;
  waves: { name: string; matches: 'internal' | 'pilot' | 'rest'; batch: number }[];
  halt: { errorRatePct: number; p95Ms: number };
  freeze: boolean;
  naming: { slugPattern: string; bundlePrefix: string };
  maintenanceWindow: string;
}

export interface ReleaseRow {
  id: string;
  version: string;
  notes: string;
  status: 'draft' | 'rolling' | 'halted' | 'done' | 'rolled_back';
  createdBy: string;
  createdAt: string;
  waves: {
    name: string;
    status: 'pending' | 'rolling' | 'done' | 'halted';
    schools: { id: string; name: string; state: 'pending' | 'rolling' | 'done' | 'failed' }[];
  }[];
  haltReason: string | null;
}

export interface MigrationRow {
  tag: string;
  kind: 'expand' | 'backfill' | 'contract';
  schools: { id: string; name: string; state: 'pending' | 'applied' | 'failed'; ms: number | null; error: string | null }[];
}

export interface FleetSummary {
  schools: number;
  live: number;
  onboarding: number;
  healthy: number;
  degraded: number;
  requests24h: { at: string; value: number; previous: number }[];
  cells: { key: string; target: DeployTarget; schools: number; max: number; region: string }[];
  incident: { id: string; title: string; state: 'open' | 'resolved'; startedAt: string } | null;
  release: ReleaseRow | null;
}

export interface SandboxMessage {
  id: string;
  schoolSlug: string;
  channel: 'sms' | 'email' | 'whatsapp' | 'push';
  to: string;
  subject: string | null;
  body: string;
  createdAt: string;
}

export interface ConsoleUserRow {
  id: string;
  name: string;
  email: string;
  roles: ConsoleRole[];
  status: 'active' | 'invited' | 'disabled';
  lastSeenAt: string | null;
}

export interface ConsoleSession {
  id: string;
  name: string;
  email: string;
  initials: string;
  roles: ConsoleRole[];
}

export interface FlagRow {
  key: string;
  label: string;
  scope: 'fleet' | 'school';
  schoolId: string | null;
  enabled: boolean;
  updatedBy: string;
  updatedAt: string;
}

export interface SupportSessionRow {
  id: string;
  schoolId: string;
  schoolName: string;
  reason: string;
  status: 'requested' | 'active' | 'ended' | 'expired';
  expiresAt: string | null;
  startedBy: string;
}

export interface InvoiceRowC {
  id: string;
  schoolId: string;
  schoolName: string;
  period: string;
  amount: number;
  status: 'draft' | 'sent' | 'paid' | 'overdue';
}
