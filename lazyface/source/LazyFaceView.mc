import Toybox.Activity;
import Toybox.ActivityMonitor;
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

    private const ICON_HEART = 0xF004;
    private const ICON_STEPS = 0xEE14;
    private const ICON_BATTERY_FULL = 0xF240; // 0xF240..0xF244 = full..empty

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

        // Heart rate and steps
        var heartRate = getHeartRate();
        IconText.draw(dc, width * 0.31, height * 0.70, fontMedium, ICON_HEART, theme.heart,
            heartRate != null ? heartRate.toString() : "--", theme.text);

        var steps = ActivityMonitor.getInfo().steps;
        IconText.draw(dc, width * 0.69, height * 0.70, fontMedium, ICON_STEPS, theme.steps,
            steps != null ? steps.toString() : "--", theme.text);

        // Battery, drawn as a tmux status-left pill
        drawBatteryPill(dc, centerX, height * 0.855, fontSmall, theme, accent);
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

    private function drawBatteryPill(dc as Dc, centerX as Numeric, centerY as Numeric, font as FontResource,
            theme as Theme, accent as Number) as Void {
        var battery = System.getSystemStats().battery;
        var level = battery >= 88 ? 0 : battery >= 63 ? 1 : battery >= 38 ? 2 : battery >= 10 ? 3 : 4;
        var text = (ICON_BATTERY_FULL + level).toChar().toString() + " " + battery.format("%d") + "%";

        var pillWidth = dc.getTextWidthInPixels(text, font) + 28;
        var pillHeight = dc.getFontHeight(font) + 4;
        dc.setColor(battery < 20 ? Theme.LOW_BATTERY : accent, Graphics.COLOR_TRANSPARENT);
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

    private function getHeartRate() as Number? {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null && activityInfo.currentHeartRate != null) {
            return activityInfo.currentHeartRate;
        }
        if (ActivityMonitor has :getHeartRateHistory) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
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
