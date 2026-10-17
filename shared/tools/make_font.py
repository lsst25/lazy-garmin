"""Convert a TTF into a BMFont (.fnt text + grayscale .png) for Connect IQ.

Usage (from an app folder):
    make fonts
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent  # shared/
TTF = ROOT / "tools/fonts/JetBrainsMonoNerdFont-Medium.ttf"
OUT = ROOT / "resources/fonts"

TEXT_CHARS = " 0123456789%:-/.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
ICON_CHARS = "".join(chr(c) for c in [
    0xF004,  # fa-heart
    0xEE14,  # fa-shoe_prints
    0xF240, 0xF241, 0xF242, 0xF243, 0xF244,  # fa-battery_full .. empty
    0xF017,  # fa-clock_o
    0xF04B,  # fa-play
    0xF04C,  # fa-pause
    0x25CF,  # ● (recording dot)
])

# (resource name, pixel size)
FONTS = [
    ("text_medium", 30),
    ("text_small", 24),
]

ATLAS_WIDTH = 512
PADDING = 2


def build(name: str, size: int) -> None:
    font = ImageFont.truetype(str(TTF), size)
    ascent, descent = font.getmetrics()
    chars = TEXT_CHARS + ICON_CHARS

    glyphs = []
    x = y = PADDING
    row_height = 0
    for ch in chars:
        left, top, right, bottom = font.getbbox(ch, anchor="la")
        width, height = max(right - left, 0), max(bottom - top, 0)
        if x + width + PADDING > ATLAS_WIDTH:
            x = PADDING
            y += row_height + PADDING
            row_height = 0
        # Connect IQ clips each glyph to its advance width, and Nerd Font icons
        # are wider than one cell, so never let the advance be narrower than the glyph.
        advance = max(round(font.getlength(ch)), left + width)
        glyphs.append((ch, x, y, width, height, left, top, advance))
        x += width + PADDING
        row_height = max(row_height, height)

    atlas_height = 1
    while atlas_height < y + row_height + PADDING:
        atlas_height *= 2

    image = Image.new("L", (ATLAS_WIDTH, atlas_height), 0)
    draw = ImageDraw.Draw(image)
    for ch, gx, gy, _w, _h, left, top, _adv in glyphs:
        draw.text((gx - left, gy - top), ch, font=font, fill=255, anchor="la")
    image.save(OUT / f"{name}.png")

    lines = [
        f'info face="JetBrainsMono" size={size} bold=0 italic=0 charset="" unicode=1 '
        f"stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing={PADDING},{PADDING}",
        f"common lineHeight={ascent + descent} base={ascent} scaleW={ATLAS_WIDTH} "
        f"scaleH={atlas_height} pages=1 packed=0",
        f'page id=0 file="{name}.png"',
        f"chars count={len(glyphs)}",
    ]
    for ch, gx, gy, w, h, left, top, adv in glyphs:
        lines.append(
            f"char id={ord(ch)} x={gx} y={gy} width={w} height={h} "
            f"xoffset={left} yoffset={top} xadvance={adv} page=0 chnl=15"
        )
    (OUT / f"{name}.fnt").write_text("\n".join(lines) + "\n")
    print(f"{name}: {len(glyphs)} glyphs, atlas {ATLAS_WIDTH}x{atlas_height}")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for font_name, font_size in FONTS:
        build(font_name, font_size)
