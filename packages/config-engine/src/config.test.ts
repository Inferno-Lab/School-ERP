import { describe, expect, it } from 'vitest';
import { closeModules, contrastRatio, dependents, resolveConfig, validateSettingsChanges, DEFAULT_PLANS } from './index.js';

const entitlement = (modules: string[], locks: string[] = [], overrides = {}) => ({
  plan: 'standard', modules, limits: { students: 100, storageGb: 1, smsPerMonth: 10 }, locks, overrides, version: 1,
});

describe('modules', () => {
  it('always keeps core modules and adds requirements', () => {
    expect(closeModules(['fees'])).toEqual(['people', 'fees']);
    expect(closeModules(['nonsense'])).toEqual(['people']);
  });
  it('reports what a switch-off would break', () => {
    expect(dependents('people', ['people', 'fees', 'notices'])).toEqual(['fees']);
  });
  it('every plan resolves to itself (no unknown modules)', () => {
    for (const p of DEFAULT_PLANS) expect(closeModules(p.modules)).toEqual(expect.arrayContaining(p.modules));
  });
});

describe('resolveConfig', () => {
  const settings = { version: 2, values: { 'school.name': 'Greenfield', 'school.shortName': 'GIS', 'brand.color': '#123456' }, locked: [], updatedAt: null };
  it('limits modules to the plan and filters the menu by permission', () => {
    const cfg = resolveConfig({ settings, entitlement: entitlement(['fees', 'notices']), audience: { permissions: ['students.read'] } });
    expect(cfg.modules).toEqual(['people', 'fees', 'notices']);
    expect(cfg.nav.map((n) => n.label)).toEqual(['Students']);
  });
  it('a school cannot switch on a module the plan does not include', () => {
    const cfg = resolveConfig({ settings: { ...settings, values: { ...settings.values, 'modules.enabled': ['people', 'fees', 'transport'] } }, entitlement: entitlement(['fees']) });
    expect(cfg.modules).toEqual(['people', 'fees']);
  });
  it('platform locks beat school values', () => {
    const cfg = resolveConfig({ settings, entitlement: entitlement(['fees'], ['brand.color'], { 'brand.color': '#ABCDEF' }) });
    expect(cfg.school.color).toBe('#ABCDEF');
  });
});

describe('validateSettingsChanges', () => {
  it('rejects unknown, locked and invalid values without applying any', () => {
    const r = validateSettingsChanges({ 'brand.color': 'red', 'school.name': 'Ok name', nope: 1, 'fees.lateFeePct': 5 }, ['fees.lateFeePct']);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.problems.map((p) => p.key).sort()).toEqual(['brand.color', 'fees.lateFeePct', 'nope']);
  });
  it('closes the module list', () => {
    const r = validateSettingsChanges({ 'modules.enabled': ['fees'] }, []);
    expect(r.ok && r.values['modules.enabled']).toEqual(['people', 'fees']);
  });
});

describe('contrastRatio', () => {
  it('matches known values', () => {
    expect(contrastRatio('#000000', '#FFFFFF')).toBeCloseTo(21, 0);
    expect(contrastRatio('#6A4CF5', '#FFFFFF')).toBeGreaterThan(4.5);
  });
});
