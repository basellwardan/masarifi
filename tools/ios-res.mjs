// Writes the iOS app icon (1024px, no transparency, as Apple requires) and the
// launch splash images from the logo: node tools/ios-res.mjs
import { join } from 'node:path';
import sharp from 'sharp';

const ASSETS = 'ios/App/App/Assets.xcassets';
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

// app icon: full-bleed navy gradient (iOS rounds the corners itself)
const icon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="1024" height="1024">${defs}<rect width="120" height="120" fill="url(#bg)"/>${mark(0.62)}</svg>`;
await sharp(Buffer.from(icon)).flatten({ background: '#071A4A' }).removeAlpha().png()
  .toFile(join(ASSETS, 'AppIcon.appiconset/AppIcon-512@2x.png'));

// launch screen: navy with the bare mark, same as the in-app loading screen
const logo = await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="640" height="640">${defs}${mark(1)}</svg>`)).png().toBuffer();
for (const name of ['splash-2732x2732.png', 'splash-2732x2732-1.png', 'splash-2732x2732-2.png']) {
  await sharp({ create: { width: 2732, height: 2732, channels: 3, background: '#071A4A' } })
    .composite([{ input: logo, gravity: 'center' }])
    .png()
    .toFile(join(ASSETS, 'Splash.imageset', name));
}
console.log('ios icon and splash written');
