import type { LucideIcon } from 'lucide-react';
import {
  ArrowDownLeft,
  ArrowUpRight,
  Bus,
  Coffee,
  Dumbbell,
  Gift,
  GraduationCap,
  HeartPulse,
  House,
  Receipt,
  Send,
  Shirt,
  ShoppingCart,
  Wallet,
} from 'lucide-react';
import { normalize } from './normalize';

export type TxType = 'expense' | 'income';

/**
 * There are no user-facing categories: every transaction is described by the
 * text the user typed or said. These keyword groups only pick a fitting icon
 * for that text (normalized Arabic/English words).
 */
const ICON_HINTS: { icon: LucideIcon; keywords: string[] }[] = [
  { icon: ShoppingCart, keywords: ['بقاله', 'سوبرماركت', 'ماركت', 'خضره', 'خضار', 'فواكه', 'فاكهه', 'لحمه', 'لحم', 'خبز', 'سمانه', 'مونه', 'grocery', 'groceries', 'market', 'supermarket', 'bread'] },
  { icon: Shirt, keywords: ['تياب', 'ثياب', 'ملابس', 'لباس', 'قميص', 'بنطلون', 'كنزه', 'جاكيت', 'صباط', 'حذاء', 'كندره', 'clothes', 'shoes', 'shirt', 'jacket'] },
  { icon: HeartPulse, keywords: ['دوا', 'دواء', 'ادويه', 'صيدليه', 'دكتور', 'طبيب', 'مشفى', 'مستشفى', 'تحاليل', 'عياده', 'اسنان', 'pharmacy', 'doctor', 'medicine', 'hospital'] },
  { icon: Dumbbell, keywords: ['نادي', 'جيم', 'رياضه', 'كوره', 'مسبح', 'gym', 'sport', 'football'] },
  { icon: Coffee, keywords: ['مطعم', 'قهوه', 'كافيه', 'كافي', 'اركيله', 'نركيله', 'اكل', 'غدا', 'عشا', 'فطور', 'شاورما', 'فلافل', 'بيتزا', 'سندويش', 'عصير', 'restaurant', 'coffee', 'cafe', 'lunch', 'dinner', 'breakfast', 'food', 'pizza'] },
  { icon: Bus, keywords: ['تكسي', 'تاكسي', 'سرفيس', 'سرافيس', 'باص', 'بنزين', 'مازوت', 'سفر', 'مواصلات', 'تذكره', 'طياره', 'taxi', 'bus', 'fuel', 'petrol', 'travel', 'ticket', 'uber'] },
  { icon: Receipt, keywords: ['كهربا', 'كهرباء', 'مياه', 'نت', 'انترنت', 'فاتوره', 'فواتير', 'رصيد', 'موبايل', 'امبير', 'امبيرات', 'اشتراك', 'bill', 'bills', 'internet', 'electricity', 'water', 'phone'] },
  { icon: House, keywords: ['ايجار', 'اجار', 'بيت', 'غاز', 'جره', 'اثاث', 'تصليح', 'منظفات', 'rent', 'home', 'house', 'furniture'] },
  { icon: GraduationCap, keywords: ['جامعه', 'كتب', 'كتاب', 'قسط', 'دروس', 'مدرسه', 'دوره', 'محاضرات', 'نوطه', 'university', 'school', 'books', 'course', 'tuition'] },
  { icon: Gift, keywords: ['هديه', 'هدايا', 'عيديه', 'gift', 'gifts', 'present'] },
  { icon: Wallet, keywords: ['راتب', 'معاش', 'salary', 'paycheck', 'wage'] },
  { icon: Send, keywords: ['حواله', 'حوالات', 'remittance', 'transfer'] },
];

const PREFIXES = ['وبال', 'بال', 'وال', 'لل', 'ال', 'عال', 'ب', 'و', 'ل', 'ع'];

/** A token plus its forms without glued prefixes (بالبقالة → بقاله). */
export function stems(token: string): string[] {
  const out = [token];
  for (const p of PREFIXES) {
    if (token.startsWith(p) && token.length - p.length >= 2) out.push(token.slice(p.length));
  }
  return out;
}

const iconCache = new Map<string, LucideIcon>();

/** Icon for a transaction text; falls back to an in/out arrow. */
export function iconFor(text: string, type: TxType): LucideIcon {
  const key = `${type}|${text}`;
  const hit = iconCache.get(key);
  if (hit) return hit;
  const tokens = normalize(text).split(' ').filter(Boolean);
  let icon: LucideIcon = type === 'expense' ? ArrowUpRight : ArrowDownLeft;
  outer: for (const h of ICON_HINTS) {
    for (const t of tokens) {
      const forms = stems(t);
      if (h.keywords.some((k) => forms.includes(k))) {
        icon = h.icon;
        break outer;
      }
    }
  }
  iconCache.set(key, icon);
  return icon;
}
