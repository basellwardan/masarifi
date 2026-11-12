// Writes the native iPhone app's asset catalog (app icon, launch logo, colours)
// from the logo: node tools/native-ios-assets.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import sharp from 'sharp';

const ROOT = 'ios-native/Masarifi/Assets.xcassets';
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
const svg = (body, px) =>
  Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="${px}" height="${px}">${defs}${body}</svg>`);

const json = (dir, obj) => {
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'Contents.json'), JSON.stringify(obj, null, 2) + '\n');
};
const info = { author: 'xcode', version: 1 };

json(ROOT, { info });

// app icon: one 1024px image, no transparency (iOS applies the rounded mask and glass lighting)
const icon = join(ROOT, 'AppIcon.appiconset');
json(icon, { images: [{ filename: 'icon-1024.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }], info });
await sharp(svg(`<rect width="120" height="120" fill="url(#bg)"/>${mark(0.62)}`, 1024))
  .flatten({ background: '#071A4A' })
  .removeAlpha()
  .png()
  .toFile(join(icon, 'icon-1024.png'));

// launch screen logo (transparent, @3x)
const launch = join(ROOT, 'LaunchLogo.imageset');
json(launch, { images: [{ filename: 'launch-logo.png', idiom: 'universal', scale: '3x' }], info });
await sharp(svg(mark(1), 450)).png().toFile(join(launch, 'launch-logo.png'));

const color = (name, hex) => {
  const [r, g, b] = [1, 3, 5].map((i) => (parseInt(hex.slice(i, i + 2), 16) / 255).toFixed(3));
  json(join(ROOT, `${name}.colorset`), {
    colors: [{ color: { 'color-space': 'srgb', components: { alpha: '1.000', red: r, green: g, blue: b } }, idiom: 'universal' }],
    info,
  });
};
color('LaunchBackground', '#071A4A');
color('AccentColor', '#1D56B0');
console.log('native iOS assets written');
