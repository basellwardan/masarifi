import { useStore } from './store';
import type { Lang } from './currency';

const ar = {
  appName: 'مصاريفي',
  tagline: 'كل ليرة بمكانها.\nتابع مصاريفك بالليرة الجديدة ببساطة.',
  start: 'ابدأ',
  next: 'التالي',
  back: 'رجوع',
  done: 'تم',
  yourName: 'شو اسمك؟',
  namePlaceholder: 'اكتب اسمك',
  addPhoto: 'أضف صورة',
  startingBalance: 'كم معك هلق؟',
  startingHint: 'رصيدك الحالي، بتقدر تعدله لاحقاً',
  allSet: 'كلشي جاهز',
  allSetHint: 'سجّل مصاريفك بالكتابة أو بصوتك من زر المايك.',
  letsGo: 'يلا نبدأ',
  loading: 'عم نجهّز مصاريفك…',
  balance: 'الرصيد',
  thisMonth: 'هذا الشهر',
  deposit: 'إيداع',
  withdraw: 'سحب',
  recent: 'آخر العمليات',
  viewAll: 'عرض الكل',
  noTx: 'لسا ما في عمليات',
  noTxHint: 'اضغط إيداع أو سحب، أو احكي بالمايك',
  today: 'اليوم',
  yesterday: 'مبارح',
  transactions: 'العمليات',
  all: 'الكل',
  expenses: 'المصاريف',
  income: 'الدخل',
  monthSpend: 'مصاريف الشهر',
  monthIncome: 'دخل الشهر',
  stats: 'الإحصائيات',
  noStats: 'ما في مصاريف بهالشهر',
  voice: 'إدخال صوتي',
  tapToSpeak: 'اضغط واحكي',
  listening: 'عم اسمعك…',
  voiceHint: 'مثلاً: "صرفت خمسين ألف على البقالة"',
  voiceExamples: ['دفعت 25 تكسي', 'قبضت الراتب ألفين ونص', 'قهوة بعشرين ليرة'],
  didntCatch: 'ما فهمت المبلغ، جرّب مرة تانية',
  micUnavailable: 'التعرّف على الصوت غير متاح على هالجهاز',
  micDenied: 'لازم تسمح باستخدام المايك',
  confirm: 'تأكيد',
  edit: 'تعديل',
  cancel: 'إلغاء',
  save: 'حفظ',
  delete: 'حذف',
  amount: 'المبلغ',
  category: 'الفئة',
  note: 'ملاحظة',
  notePlaceholder: 'أضف ملاحظة (اختياري)',
  notePlaceholderExpense: 'على شو صرفت؟ مثلاً: قهوة مع الشباب',
  notePlaceholderIncome: 'من وين إجت المصاري؟ مثلاً: الراتب',
  others: 'أخرى',
  swipeHint: 'اسحب البطاقة لتغيير الشهر',
  addExpense: 'سحب / مصروف',
  addIncome: 'إيداع / دخل',
  expense: 'مصروف',
  incomeOne: 'دخل',
  settings: 'الإعدادات',
  language: 'اللغة',
  currency: 'العملة',
  syp_new: 'ليرة سورية جديدة',
  syp_old: 'ليرة سورية قديمة',
  usd: 'دولار أمريكي',
  usdRate: 'سعر الدولار',
  usdRateHint: 'كم ليرة جديدة بالدولار',
  oldNote: '1 ليرة جديدة = 100 ليرة قديمة',
  share: 'مشاركة مصاريفي',
  shareHint: 'كل المصاريف مع الرصيد المتبقي',
  profile: 'الملف الشخصي',
  name: 'الاسم',
  editBalance: 'الرصيد الافتتاحي',
  reset: 'مسح كل البيانات',
  resetConfirm: 'متأكد؟ رح تنمسح كل العمليات',
  about: 'حول التطبيق',
  version: 'الإصدار',
  notifications: 'الإشعارات',
  noNotifications: 'ما في إشعارات جديدة',
  spentMoreThan: 'صرفت هالشهر أكتر من دخلك',
  topCategory: 'أكتر شي صرفت عليه',
  pickMonth: 'اختر الشهر',
  remaining: 'الرصيد المتبقي',
  totalExpenses: 'مجموع المصاريف',
  totalIncome: 'مجموع الدخل',
  byItem: 'على شو انصرفت',
  allTransactions: 'كل العمليات',
  shareTitle: 'مصاريفي',
  copied: 'انسخ الملخص',
  saved: 'انحفظ',
  deleted: 'انحذف',
  undo: 'تراجع',
};

type Dict = typeof ar;

const en: Dict = {
  appName: 'My Expenses',
  tagline: 'Every pound in its place.\nTrack your spending in the new Syrian pound.',
  start: 'Get started',
  next: 'Next',
  back: 'Back',
  done: 'Done',
  yourName: "What's your name?",
  namePlaceholder: 'Your name',
  addPhoto: 'Add photo',
  startingBalance: 'How much do you have now?',
  startingHint: 'Your current balance, you can change it later',
  allSet: "You're all set",
  allSetHint: 'Log expenses by typing or with your voice from the mic button.',
  letsGo: "Let's go",
  loading: 'Getting your expenses ready…',
  balance: 'Balance',
  thisMonth: 'this month',
  deposit: 'Deposit',
  withdraw: 'Withdraw',
  recent: 'Recent Transactions',
  viewAll: 'View All',
  noTx: 'No transactions yet',
  noTxHint: 'Tap Deposit or Withdraw, or use the mic',
  today: 'Today',
  yesterday: 'Yesterday',
  transactions: 'Transactions',
  all: 'All',
  expenses: 'Expenses',
  income: 'Income',
  monthSpend: 'Spent this month',
  monthIncome: 'Income this month',
  stats: 'Statistics',
  noStats: 'No expenses this month',
  voice: 'Voice entry',
  tapToSpeak: 'Tap and speak',
  listening: 'Listening…',
  voiceHint: 'e.g. "Spent 50 thousand on groceries"',
  voiceExamples: ['Taxi 2500', 'Received salary 1.5 million', 'Coffee 20 thousand'],
  didntCatch: "Didn't catch the amount, try again",
  micUnavailable: 'Speech recognition is not available on this device',
  micDenied: 'Microphone permission is required',
  confirm: 'Confirm',
  edit: 'Edit',
  cancel: 'Cancel',
  save: 'Save',
  delete: 'Delete',
  amount: 'Amount',
  category: 'Category',
  note: 'Note',
  notePlaceholder: 'Add a note (optional)',
  notePlaceholderExpense: 'What was it for? e.g. coffee with friends',
  notePlaceholderIncome: 'Where did it come from? e.g. salary',
  others: 'Others',
  swipeHint: 'Swipe the card to change the month',
  addExpense: 'Withdraw / Expense',
  addIncome: 'Deposit / Income',
  expense: 'Expense',
  incomeOne: 'Income',
  settings: 'Settings',
  language: 'Language',
  currency: 'Currency',
  syp_new: 'New Syrian pound',
  syp_old: 'Old Syrian pound',
  usd: 'US dollar',
  usdRate: 'Dollar rate',
  usdRateHint: 'New SYP per 1 USD',
  oldNote: '1 new pound = 100 old pounds',
  share: 'Share my expenses',
  shareHint: 'All expenses with the remaining balance',
  profile: 'Profile',
  name: 'Name',
  editBalance: 'Opening balance',
  reset: 'Erase all data',
  resetConfirm: 'Are you sure? All transactions will be deleted',
  about: 'About',
  version: 'Version',
  notifications: 'Notifications',
  noNotifications: 'No new notifications',
  spentMoreThan: 'You spent more than you earned this month',
  topCategory: 'What you spent the most on',
  pickMonth: 'Pick a month',
  remaining: 'Remaining balance',
  totalExpenses: 'Total expenses',
  totalIncome: 'Total income',
  byItem: 'Where it went',
  allTransactions: 'All transactions',
  shareTitle: 'My Expenses',
  copied: 'Summary copied',
  saved: 'Saved',
  deleted: 'Deleted',
  undo: 'Undo',
};

export const DICTS: Record<Lang, Dict> = { ar, en };
export type { Dict };

export function useT(): Dict {
  const lang = useStore((s) => s.settings.lang);
  return DICTS[lang];
}

export function useLang(): Lang {
  return useStore((s) => s.settings.lang);
}

const AR_MONTHS = [
  'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
];

/** Levantine month names in Arabic (كانون الثاني …), English otherwise. */
export function monthName(month: number, lang: Lang, short = false): string {
  if (lang === 'ar') return AR_MONTHS[month];
  return new Date(2020, month, 1).toLocaleString('en-US', { month: short ? 'short' : 'long' });
}

export function formatTxDate(iso: string, lang: Lang, t: Dict): string {
  const d = new Date(iso);
  const now = new Date();
  const time = d.toLocaleTimeString(lang === 'ar' ? 'ar-SY-u-nu-latn' : 'en-GB', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const dayDiff = Math.round(
    (new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() -
      new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()) /
      86400000,
  );
  const sep = lang === 'ar' ? '،' : ',';
  if (dayDiff === 0) return `${t.today}${sep} ${time}`;
  if (dayDiff === 1) return `${t.yesterday}${sep} ${time}`;
  const date =
    lang === 'ar'
      ? `${d.getDate()} ${monthName(d.getMonth(), 'ar')}`
      : `${monthName(d.getMonth(), 'en', true)} ${d.getDate()}`;
  return `${date}${sep} ${time}`;
}

export function formatDayHeader(iso: string, lang: Lang, t: Dict): string {
  const d = new Date(iso);
  const now = new Date();
  const same = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  const y = new Date(now);
  y.setDate(now.getDate() - 1);
  if (same(d, now)) return t.today;
  if (same(d, y)) return t.yesterday;
  return lang === 'ar'
    ? `${d.getDate()} ${monthName(d.getMonth(), 'ar')} ${d.getFullYear()}`
    : `${monthName(d.getMonth(), 'en')} ${d.getDate()}, ${d.getFullYear()}`;
}
