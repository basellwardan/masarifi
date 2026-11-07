// Writes launcher icons + splash images into android/app/src/main/res from the
// logo (run after `npx cap add android`): node tools/android-res.mjs
import { readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import sharp from 'sharp';

const RES = 'android/app/src/main/res';
const LEFT =
  'M24 16 L38.5 16 A20.5 20.5 0 0 1 59 36.5 L59 98 A6 6 0 0 1 53 104 L24 104 A8 8 0 0 1 16 96 L16 24 A8 8 0 0 1 24 16 Z';
const RIGHT =
  'M67 16 L96 16 A8 8 0 0 1 104 24 L104 96 A8 8 0 0 1 96 104 L81.5 104 A20.5 20.5 0 0 1 61 83.5 L61 22 A6 6 0 0 1 67 16 Z';
const defs = `<defs>
  <linearGradient id="a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5ED6DE"/><stop offset="0.38" stop-color="#2F8FD6"/><stop offset="0.66" stop-color="#0D2E7A"/><stop offset="1" stop-color="#3CC6D4"/></linearGradient>
  <linearGradient id="b" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#5ED6DE"/><stop offset="0.38" stop-color="#2F8FD6"/><stop offset="0.66" stop-color="#0D2E7A"/><stop offset="1" stop-color="#3CC6D4"/></linearGradient>
  <linearGradient id="s" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.28"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/></linearGradient>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#061541"/><stop offset="0.55" stop-color="#0A2463"/><stop offset="1" stop-color="#1D56B0"/></linearGradient>
</defs>`;
const mark = (scale) =>
  `<g transform="translate(60 60) scale(${scale}) translate(-60 -60) rotate(45 60 60)"><path d="${LEFT}" fill="url(#a)"/><path d="${LEFT}" fill="url(#s)"/><path d="${RIGHT}" fill="url(#b)"/><path d="${RIGHT}" fill="url(#s)"/></g>`;
const bg = '<rect width="120" height="120" fill="url(#bg)"/>';
const svg = (body, px) =>
  Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="${px}" height="${px}">${defs}${body}</svg>`);

const DENS = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };

for (const [d, f] of Object.entries(DENS)) {
  const dir = join(RES, `mipmap-${d}`);
  const legacy = Math.round(48 * f);
  const layer = Math.round(108 * f);
  // legacy square icon with rounded corners
  await sharp(svg(`<clipPath id="r"><rect width="120" height="120" rx="26"/></clipPath><g clip-path="url(#r)">${bg}${mark(0.62)}</g>`, legacy))
    .png()
    .toFile(join(dir, 'ic_launcher.png'));
  await sharp(svg(`<clipPath id="c"><circle cx="60" cy="60" r="60"/></clipPath><g clip-path="url(#c)">${bg}${mark(0.6)}</g>`, legacy))
    .png()
    .toFile(join(dir, 'ic_launcher_round.png'));
  // adaptive layers: mark kept inside the 66dp safe zone
  await sharp(svg(mark(0.5), layer)).png().toFile(join(dir, 'ic_launcher_foreground.png'));
  await sharp(svg(bg, layer)).png().toFile(join(dir, 'ic_launcher_background.png'));
}

const adaptive = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`;
writeFileSync(join(RES, 'mipmap-anydpi-v26/ic_launcher.xml'), adaptive);
writeFileSync(join(RES, 'mipmap-anydpi-v26/ic_launcher_round.xml'), adaptive);

// pre-Android-12 splash images: navy with the centred mark
for (const dir of readdirSync(RES).filter((n) => n.startsWith('drawable'))) {
  const file = join(RES, dir, 'splash.png');
  if (!existsSync(file)) continue;
  const { width, height } = await sharp(file).metadata();
  const s = Math.round(Math.min(width, height) * 0.28);
  const logo = await sharp(svg(mark(1), s)).png().toBuffer();
  await sharp({ create: { width, height, channels: 4, background: '#071A4A' } })
    .composite([{ input: logo, gravity: 'center' }])
    .png()
    .toFile(file + '.tmp');
  await sharp(file + '.tmp').toFile(file);
  (await import('node:fs')).unlinkSync(file + '.tmp');
}
console.log('android icons and splash written');
