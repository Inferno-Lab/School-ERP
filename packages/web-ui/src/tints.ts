/** Avatar colours, [background, text], chosen from a name so a person always has the same one. */
export const TINTS: [string, string][] = [
  ['#E3EAFE', '#2449C8'], ['#FDECEC', '#B42318'], ['#DFF6EC', '#0B7A53'], ['#FFF3D1', '#8A5A00'], ['#EEEAFF', '#4A31C9'],
  ['#E0F2FE', '#0369A1'], ['#FCE7F3', '#BE185D'], ['#ECFCCB', '#4D7C0F'], ['#F4F2FA', '#575270'], ['#FFE9E2', '#B8381A'],
];

export function tintFor(seed: string): { bg: string; fg: string } {
  let h = 0;
  for (const c of seed) h = (h * 31 + c.charCodeAt(0)) >>> 0;
  const [bg, fg] = TINTS[h % TINTS.length]!;
  return { bg, fg };
}

/** Colours for the approval tones used on the dashboard. */
export const TONES: Record<string, { bg: string; fg: string }> = {
  blue: { bg: '#E3EAFE', fg: '#2449C8' }, mint: { bg: '#DFF6EC', fg: '#0B7A53' }, amber: { bg: '#FFF3D1', fg: '#8A5A00' },
  violet: { bg: '#EEEAFF', fg: '#4A31C9' }, coral: { bg: '#FFE9E2', fg: '#B8381A' },
};
