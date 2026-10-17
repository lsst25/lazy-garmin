import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Score screen, seen like a court from your side: "them" on top (Up button),
// "us" at the bottom (Down button):
//
//          6-4  3-6          <- finished sets (us-them)
//   them 2   <40>            <- games, points (tmux block digits), <> = advantage
//   ────────────────
//   us   3    40
//       ♥ 142   🕐 21:35      <- heart rate, clock (a START pill before the start)
class PadelView extends WatchUi.View {

    private const ICON_HEART = 0xF004;
    private const ICON_CLOCK = 0xF017;
    private const ICON_PLAY = 0xF04B;
    private const ICON_PAUSE = 0xF04C;

    // Points digits: 5 x 5 blocks of BLOCK_WIDTH x BLOCK_HEIGHT pixels.
    private const BLOCK_WIDTH = 12;
    private const BLOCK_HEIGHT = 20;
    // Advantage chevrons, as tall as the digits; CHEVRON_STROKE is horizontal.
    private const CHEVRON_WIDTH = 40;
    private const CHEVRON_STROKE = 18;
    private const CHEVRON_GAP = 14;

    // Serve indicator: a thick arc on the bezel in the server's corner.
    private const SERVE_ARC_WIDTH = 16;
    private const SERVE_ARC_MARGIN = 8; // degrees kept free next to the axes

    private const TEAM_NAMES = ["us", "them"];
    private const TEAM_COLORS = [Kanagawa.CRYSTAL_BLUE, Kanagawa.SURIMI_ORANGE];

    private var _match as PadelMatch;
    private var _recorder as Recorder;
    private var _timer as Timer.Timer?;
    private var _fontMedium as FontResource?;
    private var _fontSmall as FontResource?;

    function initialize(match as PadelMatch, recorder as Recorder) {
        View.initialize();
        _match = match;
        _recorder = recorder;
    }

    function onLayout(dc as Dc) as Void {
        _fontMedium = WatchUi.loadResource(Rez.Fonts.TextMedium) as FontResource;
        _fontSmall = WatchUi.loadResource(Rez.Fonts.TextSmall) as FontResource;
    }

    // Redraw every second for the clock and heart rate.
    function onShow() as Void {
        TouchSetting.apply();
        var timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
        _timer = timer;
    }

    function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var fontMedium = _fontMedium as FontResource;
        var fontSmall = _fontSmall as FontResource;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Kanagawa.SUMI_INK_1, Kanagawa.SUMI_INK_1);
        dc.clear();

        // Finished sets
        dc.setColor(Kanagawa.FUJI_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.15, fontSmall, getSetsText(), center);

        drawTeamRow(dc, 1, height * 0.345, fontMedium, fontSmall);

        dc.setColor(Kanagawa.SUMI_INK_4, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(width * 0.12, height * 0.485, width * 0.76, 2);

        drawTeamRow(dc, 0, height * 0.625, fontMedium, fontSmall);

        if (!_match.isFinished()) {
            drawServeArc(dc);
        }

        drawStatus(dc, height * 0.805, fontMedium, fontSmall);
    }

    // Arc in the server's corner, seen from our side of the court: "us" are at
    // the bottom facing away, so their right is screen right; "them" face us,
    // so their right is screen left.
    //   us/right -> bottom-right   us/left -> bottom-left
    //   them/right -> top-left     them/left -> top-right
    private function drawServeArc(dc as Dc) as Void {
        var team = _match.currentServer();
        var screenRight = (team == 0) == _match.serveFromRight();
        // Quadrant start angle (0 = 3 o'clock, counter-clockwise).
        var start = team == 0
            ? (screenRight ? 270 : 180)
            : (screenRight ? 0 : 90);

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var radius = centerX - SERVE_ARC_WIDTH / 2 - 1;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setPenWidth(SERVE_ARC_WIDTH);
        dc.setColor(TEAM_COLORS[team], Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, radius, Graphics.ARC_COUNTER_CLOCKWISE,
            start + SERVE_ARC_MARGIN, start + 90 - SERVE_ARC_MARGIN);
        dc.setPenWidth(1);
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(false);
        }
    }

    // Left: team name and games. Right: points in block digits.
    private function drawTeamRow(dc as Dc, team as Number, centerY as Numeric,
            fontMedium as FontResource, fontSmall as FontResource) as Void {
        var width = dc.getWidth();
        var color = TEAM_COLORS[team];
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 0.22, centerY - 22, fontSmall, TEAM_NAMES[team], center);
        dc.setColor(Kanagawa.FUJI_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 0.22, centerY + 14, fontMedium, _match.games[team].toString(), center);

        var winner = _match.winner();
        if (winner != null) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width * 0.6, centerY, fontMedium, winner == team ? "won" : "lost", center);
            return;
        }
        // Advantage: "<40>" for the leader, the other 40 dimmed.
        var advantage = _match.advantage();
        var label = _match.pointLabel(team);
        var pointsX = width * 0.6;
        BlockText.draw(dc, label, pointsX, centerY, BLOCK_WIDTH, BLOCK_HEIGHT,
            (advantage != null && advantage != team) ? Kanagawa.SUMI_INK_4 : color);
        if (advantage != null && advantage == team) {
            var offset = BlockText.width(label, BLOCK_WIDTH) / 2 + CHEVRON_GAP + CHEVRON_WIDTH / 2;
            drawChevron(dc, pointsX - offset, centerY, false, color);
            drawChevron(dc, pointsX + offset, centerY, true, color);
        }
    }

    // Smooth "<" or ">" centered on (centerX, centerY), drawn as two slanted
    // strokes (convex quads) so it isn't pixelated like the block digits.
    private function drawChevron(dc as Dc, centerX as Numeric, centerY as Numeric,
            pointsRight as Boolean, color as Number) as Void {
        var height = 5 * BLOCK_HEIGHT;
        var top = centerY - height / 2;
        var bottom = centerY + height / 2;
        var dir = pointsRight ? 1 : -1;
        var back = centerX - dir * CHEVRON_WIDTH / 2;   // open side
        var tip = centerX + dir * CHEVRON_WIDTH / 2;    // pointed side
        var stroke = dir * CHEVRON_STROKE;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[back, top], [back + stroke, top], [tip, centerY], [tip - stroke, centerY]]);
        dc.fillPolygon([[tip - stroke, centerY], [tip, centerY], [back + stroke, bottom], [back, bottom]]);
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(false);
        }
    }

    // Bottom status. Before the start: a "START" pill (hint for the START
    // key, not a touch button). Then two big fields, like the watch face:
    // heart rate and clock time (courts are booked until a fixed time, so the
    // clock beats elapsed time). Paused: pause icon, everything gray.
    private function drawStatus(dc as Dc, centerY as Numeric, fontMedium as FontResource,
            fontSmall as FontResource) as Void {
        var width = dc.getWidth();
        if (!_recorder.hasSession()) {
            drawPill(dc, width / 2, centerY, fontSmall, ICON_PLAY.toChar().toString() + " START", Kanagawa.FUJI_GRAY);
            return;
        }

        var recording = _recorder.isRecording();
        var textColor = recording ? Kanagawa.FUJI_WHITE : Kanagawa.FUJI_GRAY;
        var heartRate = _recorder.heartRate();
        IconText.draw(dc, width * 0.36, centerY, fontMedium,
            recording ? ICON_HEART : ICON_PAUSE, recording ? Kanagawa.PEACH_RED : Kanagawa.FUJI_GRAY,
            heartRate != null ? heartRate.toString() : "--", textColor);
        IconText.draw(dc, width * 0.64, centerY, fontMedium,
            ICON_CLOCK, recording ? Kanagawa.CRYSTAL_BLUE : Kanagawa.FUJI_GRAY, getClockString(), textColor);
    }

    // tmux status-left style pill.
    private function drawPill(dc as Dc, centerX as Numeric, centerY as Numeric, font as FontResource,
            text as String, color as Number) as Void {
        var pillWidth = dc.getTextWidthInPixels(text, font) + 28;
        var pillHeight = dc.getFontHeight(font) + 4;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(centerX - pillWidth / 2, centerY - pillHeight / 2, pillWidth, pillHeight, pillHeight / 2);
        dc.setColor(Kanagawa.SUMI_INK_0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // "6-4  3-6", plus the set being played: "set 2", or "tie-break".
    private function getSetsText() as String {
        var text = "";
        for (var i = 0; i < _match.setScores.size(); i++) {
            var score = _match.setScores[i];
            text += score[0].toString() + "-" + score[1].toString() + "  ";
        }
        if (_match.isFinished()) {
            return text;
        }
        return text + (_match.tiebreak ? "tie-break" : "set " + (_match.setScores.size() + 1).toString());
    }

    // Current time, in the watch's 12/24-hour format.
    private function getClockString() as String {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return Lang.format("$1$:$2$", [hour, clockTime.min.format("%02d")]);
    }
}
