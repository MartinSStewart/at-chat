#!/usr/bin/env python3
"""Add the missing box drawing, block and shade glyphs to public/fonts/ascii.ttf.

ascii.ttf is a pixel font. Every existing glyph is built from axis aligned
rectangles on a fixed grid:

  * the em is 1024 units tall and is exactly 18 design pixels
  * the advance is 569 units and is exactly 10 design pixels
  * the baseline sits on a grid line, so the cell covers rows 13 (top)
    down to -4 (bottom) and columns 0 (left) to 9 (right)
  * strokes are 1 design pixel thick (`H` has 1px stems, `-` is a 1px bar)
  * `|`, `+` and `-` put their strokes on column 4 and row 4, so the box
    drawing lines use the same centre and line up with them

COLUMN_EDGE / ROW_EDGE below are the exact unit coordinates the existing
glyphs already use, so new strokes land on the same pixels as the letters.
The one exception is the top edge: the font's own topmost grid line is 796,
but the cell has to be exactly 1024 units tall for `│` and `█` to join up
with the line above (baselines are 1em apart at line-height 1), so row 13
is stretched by one unit to 797 = -227 + 1024.

Run from the repo root:

    python3 scripts/add-box-drawing-glyphs.py

It rewrites public/fonts/ascii.ttf in place and is safe to re-run: glyphs
that already exist are regenerated rather than duplicated.
"""

import os
import sys

from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

FONT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "public",
    "fonts",
    "ascii.ttf",
)

ADVANCE = 569

# x of the left edge of column c, for c in 0..10
COLUMN_EDGE = [0, 57, 114, 171, 228, 284, 341, 398, 455, 512, 569]

# y of the bottom edge of row r, for r in -4..14
ROW_EDGE = {
    -4: -227,
    -3: -170,
    -2: -114,
    -1: -57,
    0: 0,
    1: 57,
    2: 114,
    3: 170,
    4: 227,
    5: 284,
    6: 341,
    7: 398,
    8: 455,
    9: 512,
    10: 569,
    11: 626,
    12: 682,
    13: 739,
    14: 797,
}

LEFT, RIGHT = 0, 9  # first and last column of the cell
BOTTOM, TOP = -4, 13  # first and last row of the cell
MID_C, MID_R = 4, 4  # the column/row `|`, `-` and `+` draw on
LO_C, HI_C = 3, 5  # the two columns of a double vertical
LO_R, HI_R = 3, 5  # the two rows of a double horizontal


def h(row, c0, c1):
    """A horizontal 1px bar along `row`, covering columns c0..c1 inclusive."""
    return (c0, c1, row, row)


def v(col, r0, r1):
    """A vertical 1px bar along `col`, covering rows r0..r1 inclusive."""
    return (col, col, r0, r1)


# Every glyph is a union of cell rectangles (c0, c1, r0, r1), all inclusive.
# Names follow the font's existing uniXXXX convention.
BOX_DRAWING = {
    # --- single ---
    0x2500: [h(MID_R, LEFT, RIGHT)],
    0x2502: [v(MID_C, BOTTOM, TOP)],
    0x250C: [h(MID_R, MID_C, RIGHT), v(MID_C, BOTTOM, MID_R)],
    0x2510: [h(MID_R, LEFT, MID_C), v(MID_C, BOTTOM, MID_R)],
    0x2514: [h(MID_R, MID_C, RIGHT), v(MID_C, MID_R, TOP)],
    0x2518: [h(MID_R, LEFT, MID_C), v(MID_C, MID_R, TOP)],
    0x251C: [v(MID_C, BOTTOM, TOP), h(MID_R, MID_C, RIGHT)],
    0x2524: [v(MID_C, BOTTOM, TOP), h(MID_R, LEFT, MID_C)],
    0x252C: [h(MID_R, LEFT, RIGHT), v(MID_C, BOTTOM, MID_R)],
    0x2534: [h(MID_R, LEFT, RIGHT), v(MID_C, MID_R, TOP)],
    0x253C: [h(MID_R, LEFT, RIGHT), v(MID_C, BOTTOM, TOP)],
    # --- double ---
    0x2550: [h(LO_R, LEFT, RIGHT), h(HI_R, LEFT, RIGHT)],
    0x2551: [v(LO_C, BOTTOM, TOP), v(HI_C, BOTTOM, TOP)],
    0x2554: [
        h(HI_R, LO_C, RIGHT),
        v(LO_C, BOTTOM, HI_R),
        h(LO_R, HI_C, RIGHT),
        v(HI_C, BOTTOM, LO_R),
    ],
    0x2557: [
        h(HI_R, LEFT, HI_C),
        v(HI_C, BOTTOM, HI_R),
        h(LO_R, LEFT, LO_C),
        v(LO_C, BOTTOM, LO_R),
    ],
    0x255A: [
        h(LO_R, LO_C, RIGHT),
        v(LO_C, LO_R, TOP),
        h(HI_R, HI_C, RIGHT),
        v(HI_C, HI_R, TOP),
    ],
    0x255D: [
        h(LO_R, LEFT, HI_C),
        v(HI_C, LO_R, TOP),
        h(HI_R, LEFT, LO_C),
        v(LO_C, HI_R, TOP),
    ],
    0x2560: [
        v(LO_C, BOTTOM, TOP),
        v(HI_C, BOTTOM, LO_R),
        v(HI_C, HI_R, TOP),
        h(LO_R, HI_C, RIGHT),
        h(HI_R, HI_C, RIGHT),
    ],
    0x2563: [
        v(HI_C, BOTTOM, TOP),
        v(LO_C, BOTTOM, LO_R),
        v(LO_C, HI_R, TOP),
        h(LO_R, LEFT, LO_C),
        h(HI_R, LEFT, LO_C),
    ],
    0x2566: [
        h(HI_R, LEFT, RIGHT),
        h(LO_R, LEFT, LO_C),
        h(LO_R, HI_C, RIGHT),
        v(LO_C, BOTTOM, LO_R),
        v(HI_C, BOTTOM, LO_R),
    ],
    0x2569: [
        h(LO_R, LEFT, RIGHT),
        h(HI_R, LEFT, LO_C),
        h(HI_R, HI_C, RIGHT),
        v(LO_C, HI_R, TOP),
        v(HI_C, HI_R, TOP),
    ],
    0x256C: [
        v(LO_C, BOTTOM, LO_R),
        v(HI_C, BOTTOM, LO_R),
        v(LO_C, HI_R, TOP),
        v(HI_C, HI_R, TOP),
        h(LO_R, LEFT, LO_C),
        h(LO_R, HI_C, RIGHT),
        h(HI_R, LEFT, LO_C),
        h(HI_R, HI_C, RIGHT),
    ],
    # --- double vertical, single horizontal ---
    0x2553: [h(MID_R, LO_C, RIGHT), v(LO_C, BOTTOM, MID_R), v(HI_C, BOTTOM, MID_R)],
    0x2556: [h(MID_R, LEFT, HI_C), v(LO_C, BOTTOM, MID_R), v(HI_C, BOTTOM, MID_R)],
    0x2559: [h(MID_R, LO_C, RIGHT), v(LO_C, MID_R, TOP), v(HI_C, MID_R, TOP)],
    0x255C: [h(MID_R, LEFT, HI_C), v(LO_C, MID_R, TOP), v(HI_C, MID_R, TOP)],
    0x255F: [v(LO_C, BOTTOM, TOP), v(HI_C, BOTTOM, TOP), h(MID_R, HI_C, RIGHT)],
    0x2562: [v(LO_C, BOTTOM, TOP), v(HI_C, BOTTOM, TOP), h(MID_R, LEFT, LO_C)],
    0x2565: [h(MID_R, LEFT, RIGHT), v(LO_C, BOTTOM, MID_R), v(HI_C, BOTTOM, MID_R)],
    0x2568: [h(MID_R, LEFT, RIGHT), v(LO_C, MID_R, TOP), v(HI_C, MID_R, TOP)],
    0x256B: [v(LO_C, BOTTOM, TOP), v(HI_C, BOTTOM, TOP), h(MID_R, LEFT, RIGHT)],
    # --- single vertical, double horizontal ---
    0x2552: [v(MID_C, BOTTOM, HI_R), h(LO_R, MID_C, RIGHT), h(HI_R, MID_C, RIGHT)],
    0x2555: [v(MID_C, BOTTOM, HI_R), h(LO_R, LEFT, MID_C), h(HI_R, LEFT, MID_C)],
    0x2558: [v(MID_C, LO_R, TOP), h(LO_R, MID_C, RIGHT), h(HI_R, MID_C, RIGHT)],
    0x255B: [v(MID_C, LO_R, TOP), h(LO_R, LEFT, MID_C), h(HI_R, LEFT, MID_C)],
    0x255E: [v(MID_C, BOTTOM, TOP), h(LO_R, MID_C, RIGHT), h(HI_R, MID_C, RIGHT)],
    0x2561: [v(MID_C, BOTTOM, TOP), h(LO_R, LEFT, MID_C), h(HI_R, LEFT, MID_C)],
    0x2564: [h(LO_R, LEFT, RIGHT), h(HI_R, LEFT, RIGHT), v(MID_C, BOTTOM, LO_R)],
    0x2567: [h(LO_R, LEFT, RIGHT), h(HI_R, LEFT, RIGHT), v(MID_C, HI_R, TOP)],
    0x256A: [h(LO_R, LEFT, RIGHT), h(HI_R, LEFT, RIGHT), v(MID_C, BOTTOM, TOP)],
}


def shade(keep):
    """Dither the whole cell, keeping the pixels `keep(col, row)` selects.

    The pattern has to survive tiling: cells are 10 columns wide and 18 rows
    tall, both even, so anything with a period of 2 continues unbroken into
    the neighbouring cell and the line above and below. That rules out the
    4x4 CP437 patterns (4 divides neither 10 nor 18) and leaves a 2x2 dither,
    which gives the same 25% / 50% / 75% progression.
    """
    rects = []
    for r in range(BOTTOM, TOP + 1):
        run = None
        for c in range(LEFT, RIGHT + 2):
            on = c <= RIGHT and keep(c, r)
            if on and run is None:
                run = c
            elif not on and run is not None:
                rects.append((run, c - 1, r, r))
                run = None
    return rects


BLOCKS = {
    0x2588: [(LEFT, RIGHT, BOTTOM, TOP)],  # full block
    0x2591: shade(lambda c, r: c % 2 == 0 and r % 2 == 0),  # light shade, 25%
    0x2592: shade(lambda c, r: (c + r) % 2 == 0),  # medium shade, 50%
    0x2593: shade(lambda c, r: not (c % 2 == 0 and r % 2 == 0)),  # dark shade, 75%
}


def build(rects):
    """Turn cell rectangles into a TrueType glyph.

    Contours are wound clockwise (up the left edge, across the top, down the
    right edge), the same direction the existing glyphs use.
    """
    pen = TTGlyphPen(None)
    for c0, c1, r0, r1 in rects:
        x0, x1 = COLUMN_EDGE[c0], COLUMN_EDGE[c1 + 1]
        y0, y1 = ROW_EDGE[r0], ROW_EDGE[r1 + 1]
        pen.moveTo((x0, y0))
        pen.lineTo((x0, y1))
        pen.lineTo((x1, y1))
        pen.lineTo((x1, y0))
        pen.closePath()
    return pen.glyph()


def main():
    font = TTFont(FONT)
    glyf = font["glyf"]
    hmtx = font["hmtx"]

    wanted = dict(BOX_DRAWING)
    wanted.update(BLOCKS)

    order = list(font.getGlyphOrder())
    cmaps = [t for t in font["cmap"].tables if t.format == 4]
    if not cmaps:
        sys.exit("expected a format 4 cmap subtable")

    added = 0
    for codepoint, rects in sorted(wanted.items()):
        name = "uni%04X" % codepoint
        if name not in order:
            order.append(name)
            added += 1
        font.setGlyphOrder(order)
        glyf.glyphOrder = order
        glyf[name] = build(rects)
        glyf[name].recalcBounds(glyf)
        hmtx[name] = (ADVANCE, glyf[name].xMin)
        for table in cmaps:
            table.cmap[codepoint] = name

    font["maxp"].numGlyphs = len(order)

    # FontForge wrote bounding boxes that are off by a unit on 51 glyphs (`G`
    # records xMin 56 but its outline starts at 57). Saving recalculates them,
    # which leaves hmtx's left side bearing disagreeing with xMin, and a
    # rasterizer that trusts the side bearing then shifts those glyphs a unit
    # left. Point the side bearings back at the real outlines so every glyph
    # lands on the pixel grid the box drawing strokes are aligned to.
    for name in order:
        glyph = glyf[name]
        glyph.recalcBounds(glyf)
        if glyph.numberOfContours:
            hmtx[name] = (hmtx[name][0], glyph.xMin)
    font["head"].flags |= 1 << 1  # xMin == lsb for every glyph

    os2 = font["OS/2"]
    os2.usLastCharIndex = max(os2.usLastCharIndex, max(wanted))
    os2.ulUnicodeRange2 |= (1 << (47 - 32)) | (1 << (48 - 32))  # box drawing, blocks

    font.save(FONT)
    print(f"{added} glyphs added, {len(wanted) - added} regenerated -> {FONT}")


if __name__ == "__main__":
    main()
