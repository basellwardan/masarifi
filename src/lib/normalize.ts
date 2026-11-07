const INDIC: Record<string, string> = {
  '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4', '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
};

/** Lowercase, unify Arabic letter variants and digits, drop diacritics. */
export function normalize(text: string): string {
  return text
    .toLowerCase()
    .replace(/[٠-٩۰-۹]/g, (d) => INDIC[d] ?? d)
    .replace(/[ً-ْـ]/g, '') // harakat + tatweel
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/٫/g, '.')
    .replace(/(\d),(?=\d{3}\b)/g, '$1') // 50,000 -> 50000
    .replace(/[،,؟?!:;"'()]/g, ' ')
    .replace(/\.(?!\d)/g, ' ') // sentence dots, but keep 2.5
    .replace(/\s+/g, ' ')
    .trim();
}
