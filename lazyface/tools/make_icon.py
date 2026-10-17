"""Draw the lazyface launcher icon: tmux block clock "10" over "13".

Usage (from the lazyface folder):
    uv run --with pillow python tools/make_icon.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "resources/drawables/launcher_icon.png"
SIZE = 65   # fr965 launcher icon size
SCALE = 4   # draw the circle large, then downscale for a smooth edge
BLOCK = 4   # block size in final pixels (digits are drawn after the downscale, so they stay sharp)

SUMI_INK_1 = "#1F1F28"
SUMI_INK_4 = "#54546D"
CRYSTAL_BLUE = "#7E9CD8"

# tmux clock-mode glyphs (5x5, MSB left), same as shared/source/BlockText.mc
GLYPHS = {
    "0": [0x1F, 0x11, 0x11, 0x11, 0x1F],
    "1": [0x01, 0x01, 0x01, 0x01, 0x01],
    "3": [0x1F, 0x01, 0x1F, 0x01, 0x1F],
}


def columns(glyph):
    mask = 0
    for row in glyph:
        mask |= row
    used = [c for c in range(5) if (mask >> (4 - c)) & 1]
    return used[0], used[-1] - used[0] + 1


def draw_text(d, text, center_x, top):
    """Draw block text (trimmed glyphs, 1 block gap) centered on center_x, in final pixels."""
    widths = [columns(GLYPHS[ch])[1] for ch in text]
    total = sum(widths) + len(text) - 1
    x = center_x - (total * BLOCK) // 2
    for ch in text:
        glyph = GLYPHS[ch]
        left, width = columns(glyph)
        for r, row in enumerate(glyph):
            for c in range(5):
                if (row >> (4 - c)) & 1:
                    bx = x + (c - left) * BLOCK
                    by = top + r * BLOCK
                    d.rectangle([bx, by, bx + BLOCK - 1, by + BLOCK - 1], fill=CRYSTAL_BLUE)
        x += (width + 1) * BLOCK


def main() -> None:
    big = SIZE * SCALE
    icon = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    d.ellipse([0, 0, big - 1, big - 1], fill=SUMI_INK_1, outline=SUMI_INK_4, width=SCALE)
    icon = icon.resize((SIZE, SIZE), Image.LANCZOS)
    d = ImageDraw.Draw(icon)
    digit_height = 5 * BLOCK
    gap = BLOCK
    top = (SIZE - (2 * digit_height + gap)) // 2
    draw_text(d, "10", SIZE // 2, top)
    draw_text(d, "13", SIZE // 2, top + digit_height + gap)
    icon.save(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
