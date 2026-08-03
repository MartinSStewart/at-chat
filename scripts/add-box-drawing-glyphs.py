#!/usr/bin/env python3
"""Add the missing box drawing, block and shade glyphs to public/fonts/ascii.ttf.

ascii.ttf is a pixel font. Every existing glyph is built from axis aligned
rectangles on a fixed grid:

  * the em is 1152 units tall and is exactly 18 design pixels, so a pixel is
    64 units (see scripts/rescale-ascii-font.py, which has to run first)
  * the advance is 640 units and is exactly 10 design pixels
  * the baseline sits on a grid line, so the cell covers rows 13 (top)
    down to -4 (bottom) and columns 0 (left) to 9 (right), and its full
    height of 18 pixels is exactly one em, which is what lets the vertical
    strokes and blocks join up with the line above at line-height 1
  * strokes are 1 design pixel thick (`H` has 1px stems, `-` is a 1px bar)
  * `|`, `+` and `-` put their strokes on column 4 and row 4, so the box
    drawing lines use the same centre and line up with them

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

UPEM = 1152
PIXEL = UPEM // 18  # 64 units per design pixel, and the baseline is at 0
ADVANCE = 10 * PIXEL

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


def shade(chosen):
    """Dither the whole cell, filling the pixels `chosen(col, row)` selects.

    The shades have to survive tiling: cells are 10 columns wide and 18 rows
    tall, both even, so anything with a period of 2 continues unbroken into
    the neighbouring cell and the line above and below. That rules out the
    4x4 CP437 patterns (4 divides neither 10 nor 18) and leaves a 2x2 dither,
    which gives the same 25% / 50% / 75% progression.
    """
    return [
        (c, c, r, r)
        for r in range(BOTTOM, TOP + 1)
        for c in range(LEFT, RIGHT + 1)
        if chosen(c, r)
    ]


BLOCKS = {
    0x2588: [(LEFT, RIGHT, BOTTOM, TOP)],  # full block
    0x2591: shade(lambda c, r: c % 2 == 0 and r % 2 == 0),  # light shade, 25%
    0x2592: shade(lambda c, r: (c + r) % 2 == 0),  # medium shade, 50%
    0x2593: shade(lambda c, r: not (c % 2 == 0 and r % 2 == 0)),  # dark shade, 75%
}

SHAPES = dict(BOX_DRAWING)
SHAPES.update(BLOCKS)


def outline(rects):
    """Trace the pixel set the rectangles cover into closed loops of cell corners.

    Emitting the rectangles themselves would be simpler, but wherever two of them
    meet along an edge the rasterizer leaves a grey seam down the join, which is
    what the dark shade is made of. Tracing gives one contour per connected run of
    pixels, so no two contours ever share an edge.

    Each pixel contributes its four sides wound clockwise; a side shared with
    another filled pixel cancels against its twin, and the sides that survive are
    the outline. Winding falls out of that: outer loops come back clockwise like
    the rest of the font, and enclosed holes come back the other way, which is
    exactly what the non-zero fill wants.
    """
    filled = {
        (c, r)
        for c0, c1, r0, r1 in rects
        for c in range(c0, c1 + 1)
        for r in range(r0, r1 + 1)
    }
    edges = {}
    for c, r in filled:
        for start, end in (
            ((c, r), (c, r + 1)),
            ((c, r + 1), (c + 1, r + 1)),
            ((c + 1, r + 1), (c + 1, r)),
            ((c + 1, r), (c, r)),
        ):
            if edges.get(end) and start in edges[end]:
                edges[end].remove(start)  # cancels against the neighbour's side
                if not edges[end]:
                    del edges[end]
            else:
                edges.setdefault(start, []).append(end)

    loops = []
    while edges:
        start = next(iter(edges))
        loop, point, heading = [start], start, None
        while True:
            options = edges[point]
            if heading is None:
                step = options[0]
            else:
                # Diagonally touching pixels leave two ways out of a corner. Taking
                # the sharpest right turn keeps to the pixel we arrived on, so they
                # stay separate loops instead of one that pinches itself at a point.
                turns = [
                    (heading[1], -heading[0]),
                    heading,
                    (-heading[1], heading[0]),
                ]
                step = next(
                    p
                    for t in turns
                    for p in options
                    if (p[0] - point[0], p[1] - point[1]) == t
                )
            options.remove(step)
            if not options:
                del edges[point]
            heading = (step[0] - point[0], step[1] - point[1])
            point = step
            if point == start:
                break
            loop.append(point)
        # drop the corners that only sit in the middle of a straight run
        loops.append(
            [
                p
                for i, p in enumerate(loop)
                if (
                    (p[0] - loop[i - 1][0], p[1] - loop[i - 1][1])
                    != (loop[(i + 1) % len(loop)][0] - p[0], loop[(i + 1) % len(loop)][1] - p[1])
                )
            ]
        )
    return loops


def build(rects):
    """Turn cell rectangles into a TrueType glyph."""
    pen = TTGlyphPen(None)
    for loop in outline(rects):
        pen.moveTo((loop[0][0] * PIXEL, loop[0][1] * PIXEL))
        for c, r in loop[1:]:
            pen.lineTo((c * PIXEL, r * PIXEL))
        pen.closePath()
    return pen.glyph()


def main():
    font = TTFont(FONT)
    if font["head"].unitsPerEm != UPEM:
        sys.exit(
            f"expected {UPEM} units per em, found {font['head'].unitsPerEm}."
            " Run scripts/rescale-ascii-font.py first"
        )
    glyf = font["glyf"]
    hmtx = font["hmtx"]

    order = list(font.getGlyphOrder())
    cmaps = [t for t in font["cmap"].tables if t.format == 4]
    if not cmaps:
        sys.exit("expected a format 4 cmap subtable")

    added = 0
    for codepoint, rects in sorted(SHAPES.items()):
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
    os2.usLastCharIndex = max(os2.usLastCharIndex, max(SHAPES))
    os2.ulUnicodeRange2 |= (1 << (47 - 32)) | (1 << (48 - 32))  # box drawing, blocks

    font.save(FONT)
    print(f"{added} glyphs added, {len(SHAPES) - added} regenerated -> {FONT}")


if __name__ == "__main__":
    main()
