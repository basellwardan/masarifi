// Renders the logo into the source images @capacitor/assets expects
// (assets/icon-*.png, assets/splash*.png) and public/logo.svg.
// Usage: npm run icons && npx capacitor-assets generate --android
import { mkdirSync, writeFileSync } from 'node:fs';
import sharp from 'sharp';

const LEFT =
  'M24 16 L38.5 16 A20.5 20.5 0 0 1 59 36.5 L59 98 A6 6 0 0 1 53 104 L24 104 A8 8 0 0 1 16 96 L16 24 A8 8 0 0 1 24 16 Z';
const RIGHT =
  'M67 16 L96 16 A8 8 0 0 1 104 24 L104 96 A8 8 0 0 1 96 104 L81.5 104 A20.5 20.5 0 0 1 61 83.5 L61 22 A6 6 0 0 1 67 16 Z';

const defs = `
<defs>
  <linearGradient id="a" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#5ED6DE"/><stop offset="0.38" stop-color="#2F8FD6"/>
    <stop offset="0.66" stop-color="#0D2E7A"/><stop offset="1" stop-color="#3CC6D4"/>
  </linearGradient>
  <linearGradient id="b" x1="0" y1="1" x2="0" y2="0">
    <stop offset="0" stop-color="#5ED6DE"/><stop offset="0.38" stop-color="#2F8FD6"/>
    <stop offset="0.66" stop-color="#0D2E7A"/><stop offset="1" stop-color="#3CC6D4"/>
  </linearGradient>
  <linearGradient id="s" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#fff" stop-opacity="0.28"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#061541"/><stop offset="0.55" stop-color="#0A2463"/><stop offset="1" stop-color="#1D56B0"/>
  </linearGradient>
</defs>`;

const mark = (scale) => `
<g transform="translate(60 60) scale(${scale}) translate(-60 -60) rotate(45 60 60)">
  <path d="${LEFT}" fill="url(#a)"/><path d="${LEFT}" fill="url(#s)"/>
  <path d="${RIGHT}" fill="url(#b)"/><path d="${RIGHT}" fill="url(#s)"/>
</g>`;

const svg = (body, bg = '') =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="1024" height="1024">${defs}${bg}${body}</svg>`;

// glass tile on the navy gradient, like the in-app logo
const glassTile = `<rect x="22" y="22" width="76" height="76" rx="24" fill="#fff" fill-opacity="0.12" stroke="#fff" stroke-opacity="0.28" stroke-width="0.8"/>`;

mkdirSync('assets', { recursive: true });
mkdirSync('public', { recursive: true });

const bgRect = '<rect width="120" height="120" fill="url(#bg)"/>';
const full = svg(glassTile + mark(0.56), bgRect);
const foreground = svg(glassTile + mark(0.56)); // transparent, inside the adaptive safe zone
const background = svg('', bgRect);

writeFileSync('public/logo.svg', svg(mark(1)).replace(' width="1024" height="1024"', ''));

await sharp(Buffer.from(full)).png().toFile('assets/icon-only.png');
await sharp(Buffer.from(foreground)).png().toFile('assets/icon-foreground.png');
await sharp(Buffer.from(background)).png().toFile('assets/icon-background.png');

const splash = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="2732" height="2732">${defs}
  <rect width="1000" height="1000" fill="#071A4A"/>
  <svg x="420" y="420" width="160" height="160" viewBox="0 0 120 120">${mark(1)}</svg></svg>`;
await sharp(Buffer.from(splash)).png().toFile('assets/splash.png');
await sharp(Buffer.from(splash)).png().toFile('assets/splash-dark.png');
console.log('icons written to assets/ and public/logo.svg');
