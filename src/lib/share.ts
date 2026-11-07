import { Capacitor } from '@capacitor/core';
import { Share } from '@capacitor/share';
import { Directory, Encoding, Filesystem } from '@capacitor/filesystem';
import { formatMoney, type CurrencyCode, type Lang } from './currency';
import { DICTS, monthName } from './i18n';
import { balanceOf, byItem, inMonth, sumOf, type Profile, type Tx } from './store';

interface Input {
  profile: Profile;
  txs: Tx[];
  lang: Lang;
  currency: CurrencyCode;
  usdRate: number;
  now?: Date;
}

export function buildSummary({ profile, txs, lang, currency, usdRate, now = new Date() }: Input): string {
  const t = DICTS[lang];
  const money = (v: number, signed = false) => formatMoney(v, currency, usdRate, lang, { signed });
  const month = inMonth(txs, now.getFullYear(), now.getMonth());
  const lines: string[] = [];
  const title = profile.name ? `${t.shareTitle} — ${profile.name}` : t.shareTitle;
  lines.push(`📊 ${title}`);
  lines.push(`${monthName(now.getMonth(), lang)} ${now.getFullYear()}`);
  lines.push('');
  lines.push(`💰 ${t.remaining}: ${money(balanceOf(profile, txs))}`);
  lines.push(`📉 ${t.monthSpend}: ${money(sumOf(month, 'expense'))}`);
  lines.push(`📈 ${t.monthIncome}: ${money(sumOf(month, 'income'))}`);
  lines.push(`🧾 ${t.totalExpenses}: ${money(sumOf(txs, 'expense'))}`);

  const items = byItem(txs, 'expense');
  if (items.length) {
    lines.push('');
    lines.push(`— ${t.byItem} —`);
    for (const c of items) lines.push(`• ${c.label || t.expense}: ${money(c.total)}`);
  }

  if (txs.length) {
    lines.push('');
    lines.push(`— ${t.allTransactions} —`);
    for (const tx of txs) {
      const d = new Date(tx.date);
      const date = `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
      const amount = money(tx.type === 'expense' ? -tx.amount : tx.amount, true);
      const what = tx.note.trim() || (tx.type === 'expense' ? t.expense : t.incomeOne);
      lines.push(`${date}  ${what}  ${amount}`);
    }
  }
  return lines.join('\n');
}

export function buildCsv({ txs, lang, currency, usdRate }: Input): string {
  const t = DICTS[lang];
  const esc = (s: string) => `"${s.replace(/"/g, '""')}"`;
  const head = [t.amount, t.note, 'date', 'type'].map(esc).join(',');
  const rows = txs.map((tx) =>
    [
      formatMoney(tx.type === 'expense' ? -tx.amount : tx.amount, currency, usdRate, lang),
      tx.note,
      tx.date,
      tx.type,
    ]
      .map((v) => esc(String(v)))
      .join(','),
  );
  return '﻿' + [head, ...rows].join('\n');
}

/** Opens the system share sheet with a text summary and a CSV attachment. */
export async function shareExpenses(input: Input): Promise<'shared' | 'copied' | 'failed'> {
  const text = buildSummary(input);
  const title = DICTS[input.lang].shareTitle;
  try {
    if (Capacitor.isNativePlatform()) {
      let files: string[] | undefined;
      try {
        const res = await Filesystem.writeFile({
          path: 'masarifi.csv',
          data: buildCsv(input),
          directory: Directory.Cache,
          encoding: Encoding.UTF8,
        });
        files = [res.uri];
      } catch {
        files = undefined;
      }
      await Share.share({ title, text, files, dialogTitle: title });
      return 'shared';
    }
    if (navigator.share) {
      await navigator.share({ title, text });
      return 'shared';
    }
    await navigator.clipboard.writeText(text);
    return 'copied';
  } catch {
    return 'failed';
  }
}
