"""Builds the iPhone app's fonts from the same @fontsource files the Android
build uses, so text looks the same on both.

    pip install fonttools
    python tools/ios-fonts.py

Inter (Latin) is copied as-is; IBM Plex Sans Arabic is shipped by fontsource as
separate Arabic and Latin subsets, which are merged into one TTF per weight
(the Android CSS falls back from its Arabic subset to its Latin one).
"""
from pathlib import Path

from fontTools.merge import Merger
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FS = ROOT / "node_modules" / "@fontsource"
OUT = ROOT / "ios-native" / "Masarifi" / "Fonts"
OUT.mkdir(parents=True, exist_ok=True)
TMP = OUT / ".tmp"
TMP.mkdir(exist_ok=True)


def woff_to_ttf(src: Path, dst: Path) -> None:
    font = TTFont(src)
    font.flavor = None
    font.save(dst)


for w in (400, 500, 600, 700, 800):
    dst = OUT / f"Inter-{w}.ttf"
    woff_to_ttf(FS / "inter" / "files" / f"inter-latin-{w}-normal.woff", dst)
    f = TTFont(dst)
    print(dst.name, f["name"].getDebugName(6), "ss01" in {r.FeatureTag for r in f["GSUB"].table.FeatureList.FeatureRecord})

for w in (400, 500, 600, 700):
    parts = []
    for subset in ("arabic", "latin"):
        p = TMP / f"plex-{subset}-{w}.ttf"
        woff_to_ttf(FS / "ibm-plex-sans-arabic" / "files" / f"ibm-plex-sans-arabic-{subset}-{w}-normal.woff", p)
        parts.append(str(p))
    merged = Merger().merge(parts)
    dst = OUT / f"IBMPlexSansArabic-{w}.ttf"
    merged.save(dst)
    f = TTFont(dst)
    print(dst.name, f["name"].getDebugName(6), len(f.getGlyphOrder()), "glyphs")

for p in TMP.iterdir():
    p.unlink()
TMP.rmdir()
