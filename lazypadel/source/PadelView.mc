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

    // Set label in the divider: center as a fraction of the width, and the
    // space between the label and the line on each side.
    private const DIVIDER_LABEL_X = 0.33;
    private const DIVIDER_LABEL_GAP = 8;

    private const TEAM_NAMES = ["us", "them"];

    // Colors from the settings, reloaded in onShow so changes show on return
    // from the settings menu.
    private var _theme as Theme;
    private var _teamColors as Array<Number> = [0, 0];

    private var _match as PadelMatch;
    private var _recorder as Recorder;
    private var _timer as Timer.Timer?;
    // Asks once per app start whether to resume a saved match.
    private var _resumeOffered as Boolean = false;
    private var _fontMedium as FontResource?;
    private var _fontSmall as FontResource?;

    function initialize(match as PadelMatch, recorder as Recorder) {
        View.initialize();
        _theme = new Theme(0);
        _match = match;
        _recorder = recorder;
    }

    function onLayout(dc as Dc) as Void {
        _fontMedium = WatchUi.loadResource(Rez.Fonts.TextMedium) as FontResource;
        _fontSmall = WatchUi.loadResource(Rez.Fonts.TextSmall) as FontResource;
    }

    // Redraw every second for the clock and heart rate.
    function onShow() as Void {
        loadColors();
        TouchSetting.apply();
        var timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
        _timer = timer;
        if (!_resumeOffered) {
            // Push the question just after the view is shown, not inside onShow.
            _resumeOffered = true;
            new Timer.Timer().start(method(:offerResume), 50, false);
        }
    }

    function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
            _timer = null;
        }
    }

    function offerResume() as Void {
        MatchState.offerResume(_match);
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    private function loadColors() as Void {
        _theme = new Theme(PadelSettings.themeIndex());
        var accents = PadelSettings.teamAccents();
        _teamColors = [_theme.accent(accents[0]), _theme.accent(accents[1])];
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var fontMedium = _fontMedium as FontResource;
        var fontSmall = _fontSmall as FontResource;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(_theme.background, _theme.background);
        dc.clear();

        // Finished sets
        dc.setColor(_theme.gray, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.15, fontSmall, getSetsText(), center);

        drawTeamRow(dc, 1, height * 0.345, fontMedium, fontSmall);

        drawDivider(dc, height * 0.485, fontSmall);

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
        dc.setColor(_teamColors[team], Graphics.COLOR_TRANSPARENT);
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
        var color = _teamColors[team];
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 0.22, centerY - 22, fontSmall, TEAM_NAMES[team], center);
        dc.setColor(_theme.text, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 0.22, centerY + 14, fontMedium, _match.lastSetGames()[team].toString(), center);

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
            (advantage != null && advantage != team) ? _theme.dim : color);
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
            Pill.draw(dc, width / 2, centerY, fontSmall, ICON_PLAY.toChar().toString() + " START", _theme.gray, _theme.darkest);
            return;
        }

        var recording = _recorder.isRecording();
        var textColor = recording ? _theme.text : _theme.gray;
        var heartRate = _recorder.heartRate();
        IconText.draw(dc, width * 0.36, centerY, fontMedium,
            recording ? ICON_HEART : ICON_PAUSE, recording ? _theme.heart : _theme.gray,
            heartRate != null ? heartRate.toString() : "--", textColor);
        IconText.draw(dc, width * 0.64, centerY, fontMedium,
            ICON_CLOCK, recording ? _teamColors[0] : _theme.gray, getClockString(), textColor);
    }

    // Finished sets: "6-4  3-6".
    private function getSetsText() as String {
        var text = "";
        for (var i = 0; i < _match.setScores.size(); i++) {
            var score = _match.setScores[i];
            text += (i > 0 ? "  " : "") + score[0].toString() + "-" + score[1].toString();
        }
        return text;
    }

    // Line between the teams, with the set being played in it, a little left
    // of the center: "──set 3──────" (or "tie-break"). No label once the match is over.
    private function drawDivider(dc as Dc, centerY as Numeric, font as FontResource) as Void {
        var left = dc.getWidth() * 0.12;
        var right = dc.getWidth() * 0.88;
        var y = centerY - 1;
        dc.setColor(_theme.dim, Graphics.COLOR_TRANSPARENT);
        if (_match.isFinished()) {
            dc.fillRectangle(left, y, right - left, 2);
            return;
        }

        var label = _match.tiebreak ? "tie-break" : "set " + (_match.setScores.size() + 1).toString();
        var labelX = dc.getWidth() * DIVIDER_LABEL_X;
        var halfGap = dc.getTextWidthInPixels(label, font) / 2 + DIVIDER_LABEL_GAP;
        dc.fillRectangle(left, y, labelX - halfGap - left, 2);
        dc.fillRectangle(labelX + halfGap, y, right - labelX - halfGap, 2);
        dc.setColor(_theme.gray, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, centerY, font, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Current time, in the watch's 12/24-hour format (or `make run TIME=..`).
    private function getClockString() as String {
        if (DEBUG_TIME != null) {
            return DEBUG_TIME as String;
        }
        var clockTime = System.getClockTime();
        return Lang.format("$1$:$2$", [Clock.displayHour(clockTime.hour), clockTime.min.format("%02d")]);
    }
}
