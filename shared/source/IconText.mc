import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module IconText {

    const GAP = 10; // pixels between icon and text

    // Draws "<icon> <text>" centered on (centerX, centerY): the icon (a Nerd
    // Font code point) in its own color, the text in textColor.
    function draw(dc as Dc, centerX as Numeric, centerY as Numeric, font as FontResource,
            icon as Number, iconColor as Number, text as String, textColor as Number) as Void {
        var iconText = icon.toChar().toString();
        // A fixed gap instead of a space: a space is a full monospace cell
        // (18 px at 30 px), which makes the field too wide on a round screen.
        var iconWidth = dc.getTextWidthInPixels(iconText, font) + GAP;
        var startX = centerX - (iconWidth + dc.getTextWidthInPixels(text, font)) / 2;
        var justify = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, centerY, font, iconText, justify);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + iconWidth, centerY, font, text, justify);
    }
}
