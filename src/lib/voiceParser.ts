import { stems, type TxType } from './categories';
import type { CurrencyCode } from './currency';
import { normalize } from './normalize';

export { normalize };

export interface ParsedVoice {
  type: TxType;
  /** amount in the currency given by `unit` (or the user's default when null) */
  amount: number | null;
  unit: CurrencyCode | null;
  /** everything the user said, kept as the transaction's description */
  note: string;
}

// ---- number words ---------------------------------------------------------
const SMALL: Record<string, number> = {
  // Arabic (MSA + Levantine spellings, already normalized)
  صفر: 0,
  واحد: 1, وحده: 1, واحده: 1,
  اثنين: 2, اثنان: 2, اتنين: 2, تنين: 2,
  ثلاث: 3, ثلاثه: 3, تلات: 3, تلاته: 3, تلت: 3,
  اربع: 4, اربعه: 4,
  خمس: 5, خمسه: 5,
  ست: 6, سته: 6, سد: 6,
  سبع: 7, سبعه: 7,
  ثمان: 8, ثماني: 8, ثمانيه: 8, تمن: 8, تمنه: 8, تماني: 8, تمانيه: 8,
  تسع: 9, تسعه: 9,
  عشر: 10, عشره: 10,
  احدعش: 11, حدعش: 11, احدعشر: 11, حداشر: 11,
  اثنعش: 12, اطنعش: 12, اتنعش: 12, اثناعشر: 12,
  ثلطعش: 13, تلطعش: 13, تلتعش: 13,
  اربعطعش: 14, اربعتعش: 14,
  خمسطعش: 15, خمستعش: 15,
  ستطعش: 16, سطعش: 16,
  سبعطعش: 17, سبعتعش: 17,
  تمنطعش: 18, تمانطعش: 18,
  تسعطعش: 19, تسعتعش: 19,
  عشرين: 20, عشرون: 20,
  ثلاثين: 30, تلاتين: 30, ثلاثون: 30,
  اربعين: 40, اربعون: 40,
  خمسين: 50, خمسون: 50,
  ستين: 60, ستون: 60,
  سبعين: 70, سبعون: 70,
  ثمانين: 80, تمانين: 80, ثمانون: 80,
  تسعين: 90, تسعون: 90,
  // English
  zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9,
  ten: 10, eleven: 11, twelve: 12, thirteen: 13, fourteen: 14, fifteen: 15, sixteen: 16,
  seventeen: 17, eighteen: 18, nineteen: 19, twenty: 20, thirty: 30, forty: 40, fifty: 50,
  sixty: 60, seventy: 70, eighty: 80, ninety: 90,
};

const HUNDREDS: Record<string, number> = {
  ميه: 100, مئه: 100, مايه: 100, مية: 100, مائه: 100, hundred: 100,
  ميتين: 200, مئتين: 200, مئتان: 200, ميتان: 200,
  ثلاثميه: 300, تلتميه: 300, ثلاثمئه: 300, تلتمية: 300,
  اربعميه: 400, اربعمئه: 400,
  خمسميه: 500, خمسمئه: 500,
  ستميه: 600, ستمئه: 600,
  سبعميه: 700, سبعمئه: 700,
  ثمانميه: 800, تمنميه: 800, ثمانمئه: 800, تمانميه: 800,
  تسعميه: 900, تسعمئه: 900,
};

const SCALES: Record<string, number> = {
  الف: 1000, الاف: 1000, الوف: 1000, thousand: 1000, thousands: 1000, k: 1000,
  الفين: 2000, الفان: 2000,
  مليون: 1e6, ملايين: 1e6, مليونين: 2e6, million: 1e6, millions: 1e6, m: 1e6,
  مليار: 1e9, billion: 1e9,
};

const HALF = new Set(['نص', 'نصف', 'half']);
const QUARTER = new Set(['ربع', 'quarter']);
const FILLER = new Set(['و', 'and', 'a']);

type NumTok =
  | { kind: 'lit'; v: number }
  | { kind: 'small'; v: number }
  | { kind: 'hundred'; v: number }
  | { kind: 'scale'; v: number; word: string }
  | { kind: 'half' }
  | { kind: 'quarter' }
  | { kind: 'filler' };

function classify(raw: string): NumTok | null {
  const forms = [raw];
  // conjunction / preposition glued to the number: وخمسين، بعشرين، بـ50
  if (/^[وب]/.test(raw) && raw.length > 1) forms.push(raw.slice(1));
  if (/^(وب|بال)/.test(raw)) forms.push(raw.slice(2));
  for (const t of forms) {
    if (/^\d+(\.\d+)?$/.test(t)) return { kind: 'lit', v: parseFloat(t) };
    const m = /^(\d+(?:\.\d+)?)(k|m)$/.exec(t);
    if (m) return { kind: 'lit', v: parseFloat(m[1]) * (m[2] === 'k' ? 1000 : 1e6) };
    if (t in SMALL) return { kind: 'small', v: SMALL[t] };
    if (t in HUNDREDS) return { kind: 'hundred', v: HUNDREDS[t] };
    if (t in SCALES && t !== 'k' && t !== 'm') return { kind: 'scale', v: SCALES[t], word: t };
    if (HALF.has(t)) return { kind: 'half' };
    if (QUARTER.has(t)) return { kind: 'quarter' };
  }
  if (FILLER.has(raw)) return { kind: 'filler' };
  return null;
}

/** Parse the first spoken/written amount in a normalized token list. */
export function parseAmount(tokens: string[]): number | null {
  let total = 0;
  let current = 0;
  let lastMag = 1; // magnitude of the last group, for "ونص" / "وربع"
  let started = false;

  for (let i = 0; i < tokens.length; i++) {
    const tok = classify(tokens[i]);
    if (!tok) {
      if (started) break;
      continue;
    }
    if (tok.kind === 'filler') continue;
    if (!started && (tok.kind === 'half' || tok.kind === 'quarter')) continue;
    started = true;
    switch (tok.kind) {
      case 'lit':
        current += tok.v;
        lastMag = 1;
        break;
      case 'small':
        current += tok.v;
        lastMag = 1;
        break;
      case 'hundred':
        if (tok.v === 100 && current > 0 && current < 10) current *= 100;
        else current += tok.v;
        lastMag = 100;
        break;
      case 'scale': {
        const multiplicand = current > 0 ? current : 1;
        // "الفين" / "مليونين" already carry their count
        const isDual = tok.word === 'الفين' || tok.word === 'الفان' || tok.word === 'مليونين';
        total += isDual && current === 0 ? tok.v : multiplicand * (isDual ? tok.v / 2 : tok.v);
        current = 0;
        lastMag = isDual ? tok.v / 2 : tok.v;
        break;
      }
      case 'half':
        current += lastMag / 2;
        break;
      case 'quarter':
        current += lastMag / 4;
        break;
    }
  }
  const value = total + current;
  return started && value > 0 ? value : null;
}

// ---- intent and currency ---------------------------------------------------
/** Words that mean money came in (verbs first, then nouns). */
const INCOME_WORDS = [
  'قبضت', 'قبضنا', 'استلمت', 'استلمنا', 'وصلني', 'وصلتني', 'وصلنا', 'اجاني', 'اجتني', 'اجتنا', 'جاني',
  'ربحت', 'كسبت', 'اودعت', 'ايداع', 'دخل', 'نزل', 'راتب', 'معاش', 'حواله', 'مكافاه', 'عيديه',
  'received', 'receive', 'got', 'earned', 'deposit', 'deposited', 'salary', 'income',
];
/** Words that mean money went out. */
const EXPENSE_WORDS = [
  'صرفت', 'صرفنا', 'دفعت', 'دفعنا', 'اشتريت', 'شريت', 'اشترينا', 'سحبت', 'عطيت', 'اعطيت', 'سددت', 'حولت',
  'دفع', 'مصروف', 'مصاريف', 'spent', 'spend', 'paid', 'pay', 'bought', 'buy', 'withdrew', 'withdraw',
];
const USD_WORDS = ['دولار', 'دولارات', 'دولارين', 'usd', 'dollar', 'dollars', '$'];
const OLD_WORDS = ['قديم', 'قديمه', 'old'];
const NEW_WORDS = ['جديد', 'جديده', 'new'];

function firstIndex(tokens: string[], words: string[]): number {
  const set = new Set(words);
  return tokens.findIndex((t) => stems(t).some((s) => set.has(s)));
}

function hasAny(tokens: string[], words: string[]): boolean {
  return firstIndex(tokens, words) !== -1;
}

/**
 * Income or withdraw from the words alone: whichever kind of word comes first
 * wins ("دفعت من الراتب" is a withdraw, "قبضت الراتب" is income). With neither,
 * it is a withdraw.
 */
export function detectType(tokens: string[]): TxType {
  const inc = firstIndex(tokens, INCOME_WORDS);
  const exp = firstIndex(tokens, EXPENSE_WORDS);
  if (inc === -1) return 'expense';
  if (exp === -1) return 'income';
  return inc < exp ? 'income' : 'expense';
}

export function parseVoice(text: string): ParsedVoice {
  const norm = normalize(text.replace(/\$/g, ' $ '));
  const tokens = norm.split(' ').filter(Boolean);

  const type = detectType(tokens);

  let unit: CurrencyCode | null = null;
  if (hasAny(tokens, USD_WORDS)) unit = 'usd';
  else if (hasAny(tokens, OLD_WORDS)) unit = 'syp_old';
  else if (hasAny(tokens, NEW_WORDS)) unit = 'syp_new';

  // "دولارين" = two dollars with no number
  let amount = parseAmount(tokens);
  if (amount === null && tokens.some((t) => stems(t).includes('دولارين'))) amount = 2;

  return { type, amount, unit, note: text.trim().replace(/\s+/g, ' ') };
}
