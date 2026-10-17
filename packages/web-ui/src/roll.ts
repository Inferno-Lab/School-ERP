export interface Digit { isD: boolean; notD: boolean; y: number; c: string }

/** Splits "18,42,300" into digits that roll on a strip and characters that do not. */
export function rollDigits(value: string | number): Digit[] {
  return String(value).split('').map((c) => {
    const d = /\d/.test(c);
    return { isD: d, notD: !d, y: d ? Number(c) * 1.1 : 0, c };
  });
}
