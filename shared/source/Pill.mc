import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// tmux status-left style pill: text on a rounded, filled background.
module Pill {

    const PADDING_X = 14;
    const PADDING_Y = 2;

    function draw(dc as Dc, centerX as Numeric, centerY as Numeric, font as FontResource,
            text as String, fillColor as Number, textColor as Number) as Void {
        var width = dc.getTextWidthInPixels(text, font) + 2 * PADDING_X;
        var height = dc.getFontHeight(font) + 2 * PADDING_Y;
        dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(centerX - width / 2, centerY - height / 2, width, height, height / 2);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
