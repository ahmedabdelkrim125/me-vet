#!/usr/bin/env python3
"""Fix Arabic glyph collisions in the fonts embedded in generated PDFs.

Why: package:pdf (3.12.x) maps every isolated Arabic presentation form
(U+FE80..FEFC, and the Persian forms in U+FB50..FBFF) to the glyph of the base
letter, and even maps U+064A to U+FEEF (which is really the isolated form of
U+0649). So two different code points share one glyph. When both end up in the
same PDF, the font subsetter gives the second one a WRONG glyph and letters come
out garbled (e.g. "رشدى" next to "الحديدي").

Fix: give every Arabic presentation-form code point its own private copy of the
glyph (and U+FEEF a copy of the right one, uni0649), so no two code points ever
share a glyph.

Usage: python3 tool/fix_pdf_fonts.py   (needs: pip install fonttools)
Safe to re-run.
"""
import copy
from collections import defaultdict
from pathlib import Path
from fontTools.ttLib import TTFont

FONTS = ["Cairo-Regular.ttf", "Cairo-Bold.ttf"]
ROOT = Path(__file__).resolve().parent.parent / "assets" / "fonts"
SUFFIX = ".pdfdup"
PRESENTATION = list(range(0xFB50, 0xFE00)) + list(range(0xFE70, 0xFEFD))
# base letter -> isolated form, exactly as package:pdf's ttf_parser remaps them
# (it wrongly sends U+064A to U+FEEF; the real isolated YEH is U+FEF1).
LIB_ISOLATED = {
    0x0621: 0xFE80, 0x0622: 0xFE81, 0x0623: 0xFE83, 0x0624: 0xFE85, 0x0625: 0xFE87,
    0x0626: 0xFE89, 0x0627: 0xFE8D, 0x0628: 0xFE8F, 0x0629: 0xFE93, 0x062A: 0xFE95,
    0x062B: 0xFE99, 0x062C: 0xFE9D, 0x062D: 0xFEA1, 0x062E: 0xFEA5, 0x062F: 0xFEA9,
    0x0630: 0xFEAB, 0x0631: 0xFEAD, 0x0632: 0xFEAF, 0x0633: 0xFEB1, 0x0634: 0xFEB5,
    0x0635: 0xFEB9, 0x0636: 0xFEBD, 0x0637: 0xFEC1, 0x0638: 0xFEC5, 0x0639: 0xFEC9,
    0x063A: 0xFECD, 0x0641: 0xFED1, 0x0642: 0xFED5, 0x0643: 0xFED9, 0x0644: 0xFEDD,
    0x0645: 0xFEE1, 0x0646: 0xFEE5, 0x0647: 0xFEE9, 0x0648: 0xFEED, 0x064A: 0xFEEF,
}
# real isolated forms that the lib may emit but the font does not carry
EXTRA_ISOLATED = {0x0649: 0xFEEF, 0x064A: 0xFEF1}


def patch(path: Path) -> int:
    font = TTFont(path)
    cmap = font.getBestCmap()
    glyf, hmtx = font["glyf"], font["hmtx"]
    order = list(font.getGlyphOrder())

    # codes the font lacks natively get a private copy of their base letter
    wanted = {}
    for base, iso in {**LIB_ISOLATED, **EXTRA_ISOLATED}.items():
        if iso not in cmap or iso == 0xFEEF:
            wanted[iso] = cmap[base]
    users = defaultdict(list)
    for code, name in cmap.items():
        users[name].append(code)
    for code in PRESENTATION:
        name = wanted.get(code) or cmap.get(code)
        if name is None or name.endswith(SUFFIX):
            continue
        # anything sharing a glyph with a base letter / another form gets a private copy
        if code in wanted or len(users[name]) > 1:
            new = f"{name}.{code:04X}{SUFFIX}"
            if new not in glyf.keys():
                glyf[new] = copy.deepcopy(glyf[name])
                hmtx[new] = hmtx[name]
                order.append(new)
            wanted[code] = new
        wanted.setdefault(code, name)
    changed = {c: n for c, n in wanted.items() if cmap.get(c) != n and n.endswith(SUFFIX)}
    if not changed:
        return 0
    font.setGlyphOrder(order)
    for table in font["cmap"].tables:
        if table.isUnicode():
            table.cmap.update(changed)
    font["maxp"].numGlyphs = len(order)
    font.save(path)
    return len(changed)


for name in FONTS:
    n = patch(ROOT / name)
    print(f"{name}: {'patched ' + str(n) + ' code points' if n else 'already ok'}")
