import { describe, expect, it } from 'vitest';
import { parseVoice } from './voiceParser';

describe('parseVoice (Arabic)', () => {
  it.each([
    ['صرفت خمسين ألف على البقالة', 'expense', 50000, null],
    ['دفعت ٢٥٠٠ تكسي', 'expense', 2500, null],
    ['اشتريت قميص بعشرين دولار', 'expense', 20, 'usd'],
    ['قبضت الراتب مليون ونص', 'income', 1500000, null],
    ['استلمت حوالة من أخي ١٥٠ دولار', 'income', 150, 'usd'],
    ['وصلتني حوالة ١٥٠ دولار', 'income', 150, 'usd'],
    ['ميتين وخمسين ليرة قهوة', 'expense', 250, null],
    ['تلت آلاف وخمسمية بالصيدلية', 'expense', 3500, null],
    ['خمس مية ليرة خبز', 'expense', 500, null],
    ['ألفين ليرة قديمة سرفيس', 'expense', 2000, 'syp_old'],
    ['فاتورة الكهربا ٣٥ ألف ونص', 'expense', 35500, null],
    ['دفعت 12,500 للجامعة.', 'expense', 12500, null],
    ['مية ونص فلافل', 'expense', 150, null],
    // the first money word decides the direction
    ['دفعت من الراتب خمسين ألف إيجار', 'expense', 50000, null],
    ['قبضت مية دولار ودفعت منهم شي', 'income', 100, 'usd'],
  ])('%s', (text, type, amount, unit) => {
    const r = parseVoice(text);
    expect(r.type).toBe(type);
    expect(r.amount).toBe(amount);
    expect(r.unit).toBe(unit);
  });

  it('keeps everything the user said as the description', () => {
    expect(parseVoice('  صرفت خمسين ليرة   على قهوة ').note).toBe('صرفت خمسين ليرة على قهوة');
  });
});

describe('parseVoice (English)', () => {
  it.each([
    ['spent 45 dollars on coffee', 'expense', 45, 'usd'],
    ['received salary two million', 'income', 2000000, null],
    ['taxi three thousand five hundred', 'expense', 3500, null],
    ['groceries 1.5k', 'expense', 1500, null],
  ])('%s', (text, type, amount, unit) => {
    const r = parseVoice(text);
    expect(r.type).toBe(type);
    expect(r.amount).toBe(amount);
    expect(r.unit).toBe(unit);
  });

  it('returns null amount when nothing is said', () => {
    expect(parseVoice('قهوة').amount).toBeNull();
  });
});
