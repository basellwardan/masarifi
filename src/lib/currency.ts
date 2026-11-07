// Amounts are always stored in the NEW Syrian pound (1 new = 100 old).
export type CurrencyCode = 'syp_new' | 'syp_old' | 'usd';
export type Lang = 'ar' | 'en';

export const OLD_PER_NEW = 100;
export const DEFAULT_USD_RATE = 110; // new SYP per 1 USD, editable in Settings

export const CURRENCY_ORDER: CurrencyCode[] = ['syp_new', 'syp_old', 'usd'];

/** Convert a stored new-SYP value into the display currency. */
export function fromNew(valueNew: number, cur: CurrencyCode, usdRate: number): number {
  if (cur === 'syp_old') return valueNew * OLD_PER_NEW;
  if (cur === 'usd') return usdRate > 0 ? valueNew / usdRate : 0;
  return valueNew;
}

/** Convert an amount typed/spoken in `cur` into new SYP for storage. */
export function toNew(value: number, cur: CurrencyCode, usdRate: number): number {
  if (cur === 'syp_old') return value / OLD_PER_NEW;
  if (cur === 'usd') return value * usdRate;
  return value;
}

export function fractionDigits(cur: CurrencyCode): number {
  return cur === 'syp_old' ? 0 : 2;
}

export function symbol(cur: CurrencyCode, lang: Lang): string {
  if (cur === 'usd') return '$';
  if (lang === 'ar') return cur === 'syp_old' ? 'ل.س قديمة' : 'ل.س';
  return cur === 'syp_old' ? 'old SYP' : 'SYP';
}

export interface MoneyParts {
  sign: string;
  int: string;
  frac: string; // includes the decimal separator, or ''
  symbol: string;
  symbolFirst: boolean;
}

const FORMATTERS = new Map<number, Intl.NumberFormat>();
function formatter(digits: number): Intl.NumberFormat {
  let f = FORMATTERS.get(digits);
  if (!f) {
    f = new Intl.NumberFormat('en-US', { minimumFractionDigits: digits, maximumFractionDigits: digits });
    FORMATTERS.set(digits, f);
  }
  return f;
}

/** Latin digits in both languages so amounts read like the reference UI. */
export function moneyParts(
  valueNew: number,
  cur: CurrencyCode,
  usdRate: number,
  lang: Lang,
  opts: { signed?: boolean } = {},
): MoneyParts {
  const v = fromNew(valueNew, cur, usdRate);
  const digits = fractionDigits(cur);
  const fmt = formatter(digits);
  const parts = fmt.formatToParts(Math.abs(v));
  let int = '';
  let frac = '';
  for (const p of parts) {
    if (p.type === 'integer' || p.type === 'group') int += p.value;
    else if (p.type === 'decimal' || p.type === 'fraction') frac += p.value;
  }
  const rounded = Number(Math.abs(v).toFixed(digits));
  let sign = '';
  if (v < 0 && rounded !== 0) sign = '-';
  else if (opts.signed && v > 0) sign = '+';
  return { sign, int, frac, symbol: symbol(cur, lang), symbolFirst: cur === 'usd' };
}

export function formatMoney(
  valueNew: number,
  cur: CurrencyCode,
  usdRate: number,
  lang: Lang,
  opts: { signed?: boolean } = {},
): string {
  const p = moneyParts(valueNew, cur, usdRate, lang, opts);
  return p.symbolFirst ? `${p.sign}${p.symbol}${p.int}${p.frac}` : `${p.sign}${p.int}${p.frac} ${p.symbol}`;
}
