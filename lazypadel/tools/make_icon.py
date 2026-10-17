"""Draw the lazypadel launcher icon: the app's advantage mark "<40>".

Block digits (tmux clock style, as in shared/source/BlockText.mc) with smooth
chevrons (as in PadelView.drawChevron), crystalBlue on sumiInk.

Usage (from the lazypadel folder):
    uv run --with pillow python tools/make_icon.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "resources/drawables/launcher_icon.png"
SIZE = 65   # fr965 launcher icon size
SCALE = 4   # draw large, then downscale for smooth edges

SUMI_INK_1 = "#1F1F28"
SUMI_INK_4 = "#54546D"
CRYSTAL_BLUE = "#7E9CD8"

BLOCK = 3           # digit block size in final pixels
CHEVRON_HEIGHT = 15  # = digit height (5 blocks)
CHEVRON_WIDTH = 8
CHEVRON_STROKE = 3.5
CHEVRON_GAP = 3

GLYPHS = {
    "0": [0x1F, 0x11, 0x11, 0x11, 0x1F],
    "4": [0x11, 0x11, 0x1F, 0x01, 0x01],
}


def draw_blocks(d, text, center_x, top):
    """Block text (trimmed glyphs, 1 block gap) centered on center_x. Returns its width."""
    spans = []
    for ch in text:
        mask = 0
        for row in GLYPHS[ch]:
            mask |= row
        used = [c for c in range(5) if (mask >> (4 - c)) & 1]
        spans.append((used[0], used[-1] - used[0] + 1))
    total = (sum(width for _, width in spans) + len(text) - 1) * BLOCK
    x = center_x - total / 2
    for ch, (left, width) in zip(text, spans):
        for r, row in enumerate(GLYPHS[ch]):
            for c in range(5):
                if (row >> (4 - c)) & 1:
                    bx, by = (x + (c - left) * BLOCK) * SCALE, (top + r * BLOCK) * SCALE
                    d.rectangle([bx, by, bx + BLOCK * SCALE - 1, by + BLOCK * SCALE - 1], fill=CRYSTAL_BLUE)
        x += (width + 1) * BLOCK
    return total


def draw_chevron(d, center_x, center_y, points_right):
    """Two slanted strokes, like PadelView.drawChevron."""
    x0 = center_x - CHEVRON_WIDTH / 2
    top, bottom = center_y - CHEVRON_HEIGHT / 2, center_y + CHEVRON_HEIGHT / 2
    w, t = CHEVRON_WIDTH, CHEVRON_STROKE
    mirror = (lambda x: x) if points_right else (lambda x: 2 * center_x - x)
    for poly in ([(x0, top), (x0 + t, top), (x0 + w, center_y), (x0 + w - t, center_y)],
                 [(x0 + w - t, center_y), (x0 + w, center_y), (x0 + t, bottom), (x0, bottom)]):
        d.polygon([(mirror(x) * SCALE, y * SCALE) for x, y in poly], fill=CRYSTAL_BLUE)


def main() -> None:
    big = SIZE * SCALE
    icon = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    d.ellipse([0, 0, big - 1, big - 1], fill=SUMI_INK_1, outline=SUMI_INK_4, width=SCALE)

    center = SIZE / 2
    width = draw_blocks(d, "40", center, center - CHEVRON_HEIGHT / 2)
    offset = width / 2 + CHEVRON_GAP + CHEVRON_WIDTH / 2
    draw_chevron(d, center - offset, center, points_right=False)
    draw_chevron(d, center + offset, center, points_right=True)

    icon.resize((SIZE, SIZE), Image.LANCZOS).save(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
