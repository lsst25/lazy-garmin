import Toybox.Lang;

// Padel score: points (0/15/30/40/advantage, or golden point at deuce), games,
// sets with a tie-break at 6-6, best of three sets.
// Team 0 is "us", team 1 is "them".
class PadelMatch {

    const GAMES_PER_SET = 6;
    const SETS_TO_WIN = 2;
    const TIEBREAK_POINTS = 7;
    const MAX_HISTORY = 200;
    const POINT_LABELS = ["0", "15", "30", "40"];

    var goldenPoint as Boolean = false;

    var points as Array<Number> = [0, 0];
    var games as Array<Number> = [0, 0];
    var sets as Array<Number> = [0, 0];
    var tiebreak as Boolean = false;
    // Finished sets as [us, them] game counts.
    var setScores as Array<Array<Number>> = [];

    // Team serving the current game (outside tie-breaks), and the team that
    // served the first tie-break point.
    var server as Number = 0;
    var tiebreakFirstServer as Number = 0;

    // Set after "Continue playing": the match no longer ends, sets keep counting.
    var freePlay as Boolean = false;

    // Snapshots for undo: [p0, p1, g0, g1, s0, s1, tiebreak, setScores.size(),
    // server, tiebreakFirstServer, freePlay].
    private var _history as Array<Array> = [];

    function initialize() {
    }

    function reset() as Void {
        points = [0, 0];
        games = [0, 0];
        sets = [0, 0];
        tiebreak = false;
        setScores = [];
        server = 0;
        tiebreakFirstServer = 0;
        freePlay = false;
        _history = [];
    }

    function isFinished() as Boolean {
        return !freePlay && (sets[0] >= SETS_TO_WIN || sets[1] >= SETS_TO_WIN);
    }

    // 0 or 1 when the match is over, else null.
    function winner() as Number? {
        if (!isFinished()) {
            return null;
        } else if (sets[0] >= SETS_TO_WIN) {
            return 0;
        } else if (sets[1] >= SETS_TO_WIN) {
            return 1;
        }
        return null;
    }

    // Adds a point for the team. Returns what it completed:
    // :none (match already over), :point, :game, :set or :match.
    function addPoint(team as Number) as Symbol {
        if (isFinished()) {
            return :none;
        }
        saveSnapshot();

        var other = 1 - team;
        points[team] += 1;

        if (tiebreak) {
            if (points[team] >= TIEBREAK_POINTS && points[team] - points[other] >= 2) {
                return winGame(team);
            }
            return :point;
        }

        var wonGame = goldenPoint
            ? points[team] >= 4
            : points[team] >= 4 && points[team] - points[other] >= 2;
        if (wonGame) {
            return winGame(team);
        }
        // Back to deuce after an advantage is lost.
        if (points[team] == points[other] && points[team] > 3) {
            points = [3, 3];
        }
        return :point;
    }

    function undo() as Boolean {
        if (_history.size() == 0) {
            return false;
        }
        var s = _history[_history.size() - 1];
        _history = _history.slice(0, -1);
        points = [s[0] as Number, s[1] as Number];
        games = [s[2] as Number, s[3] as Number];
        sets = [s[4] as Number, s[5] as Number];
        tiebreak = s[6] as Boolean;
        setScores = setScores.slice(0, s[7] as Number);
        server = s[8] as Number;
        tiebreakFirstServer = s[9] as Number;
        freePlay = s[10] as Boolean;
        return true;
    }

    // Team with the advantage (after deuce, no golden point), else null.
    function advantage() as Number? {
        if (tiebreak) {
            return null;
        } else if (points[0] > 3) {
            return 0;
        } else if (points[1] > 3) {
            return 1;
        }
        return null;
    }

    // Score label for the team's current points: "0".."40", or the tie-break
    // count. Advantage still shows "40"; see advantage().
    function pointLabel(team as Number) as String {
        if (tiebreak) {
            return points[team].toString();
        }
        return POINT_LABELS[points[team] > 3 ? 3 : points[team]];
    }

    // Whole score for the activity summary, us-them: "6-4 3-6 7-6", plus the
    // games of an unfinished set ("6-4 2-1").
    function scoreSummary() as String {
        var parts = [] as Array<String>;
        for (var i = 0; i < setScores.size(); i++) {
            parts.add(setScores[i][0].toString() + "-" + setScores[i][1].toString());
        }
        if (!isFinished() && (games[0] > 0 || games[1] > 0)) {
            parts.add(games[0].toString() + "-" + games[1].toString());
        }
        var text = "";
        for (var i = 0; i < parts.size(); i++) {
            text += (i > 0 ? " " : "") + parts[i];
        }
        return text;
    }

    // Games won by the team over the whole match.
    function totalGames(team as Number) as Number {
        var total = games[team];
        for (var i = 0; i < setScores.size(); i++) {
            total += setScores[i][team];
        }
        return total;
    }

    // Games of the last set played, [us, them]: the final set once the match
    // is over, else the set in progress.
    function lastSetGames() as Array<Number> {
        if (isFinished()) {
            return setScores[setScores.size() - 1];
        }
        return [games[0], games[1]];
    }

    // Team serving the current point. In a tie-break the first point is
    // served by one team, then each team serves two points in turn.
    function currentServer() as Number {
        if (!tiebreak) {
            return server;
        }
        var played = points[0] + points[1];
        return ((played + 1) / 2) % 2 == 1 ? 1 - tiebreakFirstServer : tiebreakFirstServer;
    }

    // The server serves from the right side (deuce court) when the points
    // played in the game are even, else from the left (seen from the server).
    function serveFromRight() as Boolean {
        return (points[0] + points[1]) % 2 == 0;
    }

    // Keep playing after the match is won (menu > Continue playing). Undoable.
    function continuePlaying() as Void {
        saveSnapshot();
        freePlay = true;
    }

    // Fixes who serves (e.g. the other team started). Undoable.
    function swapServer() as Void {
        saveSnapshot();
        server = 1 - server;
        tiebreakFirstServer = 1 - tiebreakFirstServer;
    }

    private function winGame(team as Number) as Symbol {
        var other = 1 - team;
        points = [0, 0];
        games[team] += 1;

        if (tiebreak) {
            // The team that received first in the tie-break serves next.
            server = 1 - tiebreakFirstServer;
            return winSet(team);
        }
        server = 1 - server;
        if (games[team] >= GAMES_PER_SET && games[team] - games[other] >= 2) {
            return winSet(team);
        }
        if (games[team] == GAMES_PER_SET && games[other] == GAMES_PER_SET) {
            tiebreak = true;
            tiebreakFirstServer = server;
        }
        return :game;
    }

    private function winSet(team as Number) as Symbol {
        setScores.add([games[0], games[1]]);
        sets[team] += 1;
        games = [0, 0];
        tiebreak = false;
        return isFinished() ? :match : :set;
    }

    private function saveSnapshot() as Void {
        if (_history.size() >= MAX_HISTORY) {
            _history = _history.slice(1, null);
        }
        _history.add([points[0], points[1], games[0], games[1], sets[0], sets[1], tiebreak, setScores.size(),
            server, tiebreakFirstServer, freePlay]);
    }
}
