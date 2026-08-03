#!/usr/bin/env python3
"""Move public/fonts/ascii.ttf onto an exact pixel grid by rescaling it to 1152 units per em.

ascii.ttf is a pixel design: 18 pixels to the em, 10 to the advance. At the 1024 units
per em it was drawn at, neither of those divides evenly. A pixel is 1024/18 = 56.889 units,
so every grid line is rounded to the nearest unit, and the advance is stored as 569 where
the exact value is 568.889. That last one is the one that shows: each column is 0.02% wider
than it should be, so glyph origins drift along a line, and the ones that drift past a
subpixel boundary rasterize differently to their neighbours. At a device pixel ratio of 2
it costs about a fifth of the columns in a 40 column line.

1152 = 18 x 64, so a pixel becomes exactly 64 units, the advance exactly 640, and the
ascent and descent exactly 896 and -256 (14 and 4 pixels, still summing to a whole em so
lines butt together at line-height 1). Nothing about the design changes: every coordinate
in the font already sits within a unit of the half pixel grid, so scaling by 1152/1024 and
snapping to the nearest 32 units reproduces the same drawing exactly.

Run from the repo root, before scripts/add-box-drawing-glyphs.py:

    python3 scripts/rescale-ascii-font.py

It rewrites public/fonts/ascii.ttf in place and does nothing if the font has already been
rescaled.
"""

import array
import os
import sys

from fontTools.ttLib import TTFont

FONT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "public",
    "fonts",
    "ascii.ttf",
)

OLD_UPEM = 1024
NEW_UPEM = 1152
PIXEL = NEW_UPEM // 18  # 64 units per design pixel
GRID = PIXEL // 2  # the font also puts points on half pixels
SCALE = NEW_UPEM / OLD_UPEM

# Everything outside the glyph outlines that is measured in font units.
SCALED_FIELDS = {
    "hhea": ["ascent", "descent", "lineGap", "advanceWidthMax", "xMaxExtent"],
    "OS/2": [
        "xAvgCharWidth",
        "ySubscriptXSize",
        "ySubscriptYSize",
        "ySubscriptXOffset",
        "ySubscriptYOffset",
        "ySuperscriptXSize",
        "ySuperscriptYSize",
        "ySuperscriptXOffset",
        "ySuperscriptYOffset",
        "yStrikeoutSize",
        "yStrikeoutPosition",
        "sTypoAscender",
        "sTypoDescender",
        "sTypoLineGap",
        "usWinAscent",
        "usWinDescent",
        "sxHeight",
        "sCapHeight",
    ],
    "post": ["underlinePosition", "underlineThickness"],
}


def snap(value):
    """Scale a coordinate and put it back on the grid the design is drawn on."""
    return int(round(value * SCALE / GRID)) * GRID


def main():
    font = TTFont(FONT)
    head = font["head"]
    if head.unitsPerEm == NEW_UPEM:
        print(f"already {NEW_UPEM} units per em, nothing to do")
        return 0
    if head.unitsPerEm != OLD_UPEM:
        sys.exit(f"expected {OLD_UPEM} units per em, found {head.unitsPerEm}")

    glyf, hmtx = font["glyf"], font["hmtx"]
    for name in font.getGlyphOrder():
        glyph = glyf[name]
        if glyph.numberOfContours < 0:
            sys.exit(f"{name} is a composite glyph, its offsets would need scaling too")
        if glyph.numberOfContours > 0:
            glyph.coordinates = type(glyph.coordinates)(
                [(snap(x), snap(y)) for x, y in glyph.coordinates]
            )
            glyph.recalcBounds(glyf)
        advance = hmtx[name][0]
        hmtx[name] = (
            snap(advance),
            glyph.xMin if glyph.numberOfContours > 0 else 0,
        )

    for table, fields in SCALED_FIELDS.items():
        for field in fields:
            setattr(font[table], field, snap(getattr(font[table], field)))

    if "cvt " in font:
        # Kept as an array.array, so rebuild it as one rather than as a list
        cvt = font["cvt "].values
        font["cvt "].values = array.array(cvt.typecode, [snap(v) for v in cvt])

    os2, hhea = font["OS/2"], font["hhea"]
    # fsSelection asks for the typographic metrics, so they have to agree with the others or
    # the baseline lands in a different place depending on which set an engine reads.
    os2.sTypoAscender, os2.sTypoDescender = hhea.ascent, hhea.descent
    os2.usWinAscent, os2.usWinDescent = hhea.ascent, -hhea.descent
    if hhea.ascent - hhea.descent != NEW_UPEM:
        sys.exit(
            f"ascent {hhea.ascent} and descent {hhea.descent} have to span exactly one em,"
            " otherwise lines stop butting together at line-height 1"
        )

    head.unitsPerEm = NEW_UPEM
    font.save(FONT)
    print(
        f"rescaled to {NEW_UPEM} units per em"
        f" ({PIXEL} units per pixel, advance {hmtx['H'][0]},"
        f" ascent {hhea.ascent}, descent {hhea.descent}) -> {FONT}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
