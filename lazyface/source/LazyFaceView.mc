import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Kanagawa-themed digital watch face. The time uses the tmux clock-mode
// block digits; the other text uses JetBrains Mono (Nerd Font for icons).
// On AMOLED screens (fr965) the low-power mode draws only a dim, shifting
// clock on black to respect Garmin's burn-in rules.
class LazyFaceView extends WatchUi.WatchFace {


    private var _isAwake as Boolean = true;
    private var _burnInProtection as Boolean = false;
    private var _fontMedium as FontResource?;
    private var _fontSmall as FontResource?;

    function initialize() {
        WatchFace.initialize();
        var settings = System.getDeviceSettings();
        _burnInProtection = (settings has :requiresBurnInProtection) && settings.requiresBurnInProtection;
    }

    function onLayout(dc as Dc) as Void {
        _fontMedium = WatchUi.loadResource(Rez.Fonts.TextMedium) as FontResource;
        _fontSmall = WatchUi.loadResource(Rez.Fonts.TextSmall) as FontResource;
    }

    function onUpdate(dc as Dc) as Void {
        if (!_isAwake && _burnInProtection) {
            drawLowPower(dc);
            return;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var fontMedium = _fontMedium as FontResource;
        var fontSmall = _fontSmall as FontResource;

        // Read every update so setting changes show at once (once a minute).
        var theme = new Theme(Choices.index("theme", Theme.THEME_NAMES.size(), 0));
        var accent = theme.accent(Choices.index("accent", Theme.ACCENT_NAMES.size(), Theme.BLUE));
        dc.setColor(theme.background, theme.background);
        dc.clear();

        // Date
        dc.setColor(theme.secondary, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.20, fontMedium, getDateString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Time
        BlockText.draw(dc, getTimeString(), centerX, height * 0.45, 14, 26, accent);

        // Data field slots (Customize > Left / Right / Bottom field)
        var fieldCount = DataFields.NAMES.size();
        drawField(dc, width * 0.31, height * 0.70, fontMedium, theme,
            Choices.index("fieldLeft", fieldCount, DataFields.HEART_RATE));
        drawField(dc, width * 0.69, height * 0.70, fontMedium, theme,
            Choices.index("fieldRight", fieldCount, DataFields.STEPS));
        drawPillField(dc, centerX, height * 0.855, fontSmall, theme, accent,
            Choices.index("fieldBottom", fieldCount, DataFields.BATTERY));
    }

    // Low-power (always-on) mode: black background, small dim clock that
    // moves a few pixels every minute so no pixel stays lit for long.
    private function drawLowPower(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var minute = System.getClockTime().min;
        var offsetX = ((minute % 5) - 2) * 6;
        var offsetY = (((minute / 5) % 5) - 2) * 6;
        BlockText.draw(dc, getTimeString(), dc.getWidth() / 2 + offsetX, dc.getHeight() / 2 + offsetY, 7, 13, Theme.LOW_POWER);
    }

    private function drawField(dc as Dc, centerX as Numeric, centerY as Numeric, font as FontResource,
            theme as Theme, field as Number) as Void {
        if (field == DataFields.NONE) {
            return;
        }
        IconText.draw(dc, centerX, centerY, font, DataFields.icon(field), DataFields.iconColor(field, theme),
            DataFields.value(field), theme.text);
    }

    // The bottom slot, drawn as a tmux status-left pill in the clock color
    // (red when the battery field shows a low battery).
    private function drawPillField(dc as Dc, centerX as Numeric, centerY as Numeric, font as FontResource,
            theme as Theme, accent as Number, field as Number) as Void {
        if (field == DataFields.NONE) {
            return;
        }
        var text = DataFields.icon(field).toChar().toString() + " " + DataFields.value(field);
        var lowBattery = field == DataFields.BATTERY && System.getSystemStats().battery < 20;

        var pillWidth = dc.getTextWidthInPixels(text, font) + 28;
        var pillHeight = dc.getFontHeight(font) + 4;
        dc.setColor(lowBattery ? Theme.LOW_BATTERY : accent, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(centerX - pillWidth / 2, centerY - pillHeight / 2, pillWidth, pillHeight, pillHeight / 2);

        dc.setColor(theme.darkest, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // tmux style: zero-padded 24-hour time, or unpadded 12-hour time.
    private function getTimeString() as String {
        if (DEBUG_TIME != null) {
            return DEBUG_TIME as String;
        }
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        if (System.getDeviceSettings().is24Hour) {
            return Lang.format("$1$:$2$", [hour.format("%02d"), clockTime.min.format("%02d")]);
        }
        hour = hour % 12;
        if (hour == 0) {
            hour = 12;
        }
        return Lang.format("$1$:$2$", [hour, clockTime.min.format("%02d")]);
    }

    private function getDateString() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]).toLower();
    }

    function onExitSleep() as Void {
        _isAwake = true;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

}
