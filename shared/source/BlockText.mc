import Toybox.Graphics;
import Toybox.Lang;

// Big "pixel" text in the style of tmux clock-mode (window-clock.c).
// Supports 0-9, ':' and '-'; other characters are not supported.
//
// Unlike tmux, empty glyph columns are trimmed (so "1" and ":" are one block
// wide) and ':' gets the same gap on both sides.
module BlockText {

    // 5x5 grid, one 5-bit row each, most significant bit on the left.
    const DIGITS = [
        [0x1F, 0x11, 0x11, 0x11, 0x1F], // 0
        [0x01, 0x01, 0x01, 0x01, 0x01], // 1
        [0x1F, 0x01, 0x1F, 0x10, 0x1F], // 2
        [0x1F, 0x01, 0x1F, 0x01, 0x1F], // 3
        [0x11, 0x11, 0x1F, 0x01, 0x01], // 4
        [0x1F, 0x10, 0x1F, 0x01, 0x1F], // 5
        [0x1F, 0x10, 0x1F, 0x11, 0x1F], // 6
        [0x1F, 0x01, 0x01, 0x01, 0x01], // 7
        [0x1F, 0x11, 0x1F, 0x11, 0x1F], // 8
        [0x1F, 0x11, 0x1F, 0x01, 0x1F]  // 9
    ];
    const COLON = [0x00, 0x04, 0x00, 0x04, 0x00];
    const DASH = [0x00, 0x00, 0x0E, 0x00, 0x00];

    function glyphFor(ch as Char) as Array<Number> {
        if (ch == ':') {
            return COLON;
        } else if (ch == '-') {
            return DASH;
        }
        return DIGITS[ch.toNumber() - '0'.toNumber()];
    }

    // Width of the text in pixels.
    function width(text as String, blockWidth as Number) as Number {
        return (layout(text)[4] as Number) * blockWidth;
    }

    // Draws text centered on (centerX, centerY), in blocks of
    // blockWidth x blockHeight pixels.
    function draw(dc as Dc, text as String, centerX as Numeric, centerY as Numeric,
            blockWidth as Number, blockHeight as Number, color as Number) as Void {
        var info = layout(text);
        var count = text.length();
        var glyphs = info[0] as Array;
        var lefts = info[1] as Array;
        var widths = info[2] as Array;
        var gaps = info[3] as Array;
        var totalWidth = (info[4] as Number) * blockWidth;

        var glyphX = (centerX - totalWidth / 2).toNumber();
        var startY = (centerY - 5 * blockHeight / 2).toNumber();

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < count; i++) {
            var glyph = glyphs[i] as Array<Number>;
            var left = lefts[i] as Number;
            for (var row = 0; row < 5; row++) {
                // Merge adjacent blocks of a row into one rectangle.
                var runStart = -1;
                for (var col = 0; col <= 5; col++) {
                    var isOn = col < 5 && ((glyph[row] >> (4 - col)) & 1) == 1;
                    if (isOn && runStart < 0) {
                        runStart = col;
                    } else if (!isOn && runStart >= 0) {
                        dc.fillRectangle(glyphX + (runStart - left) * blockWidth, startY + row * blockHeight,
                            (col - runStart) * blockWidth, blockHeight);
                        runStart = -1;
                    }
                }
            }
            glyphX += ((widths[i] as Number) + (gaps[i] as Number)) * blockWidth;
        }
    }

    // Per glyph: [glyphs, first used column, width, gap after], plus the total
    // width in blocks.
    function layout(text as String) as Array {
        var chars = text.toCharArray();
        var count = chars.size();
        var glyphs = new [count];
        var lefts = new [count];
        var widths = new [count];
        var gaps = new [count];
        var totalWidth = 0;

        for (var i = 0; i < count; i++) {
            var glyph = glyphFor(chars[i]);
            var mask = glyph[0] | glyph[1] | glyph[2] | glyph[3] | glyph[4];
            var left = 0;
            while (((mask >> (4 - left)) & 1) == 0) {
                left++;
            }
            var right = 4;
            while (((mask >> (4 - right)) & 1) == 0) {
                right--;
            }
            glyphs[i] = glyph;
            lefts[i] = left;
            widths[i] = right - left + 1;
            // Gap after this glyph: 2 blocks around the colon, 1 otherwise.
            var isColon = chars[i] == ':';
            var nextIsColon = i + 1 < count && chars[i + 1] == ':';
            gaps[i] = (i + 1 == count) ? 0 : (isColon || nextIsColon) ? 2 : 1;
            totalWidth += widths[i] + gaps[i];
        }

        return [glyphs, lefts, widths, gaps, totalWidth];
    }
}
