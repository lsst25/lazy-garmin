import Toybox.Lang;
import Toybox.Test;

// Run with `make test` (simulator must be able to start).

function winPoints(match as PadelMatch, team as Number, count as Number) as Void {
    for (var i = 0; i < count; i++) {
        match.addPoint(team);
    }
}

function winGames(match as PadelMatch, team as Number, count as Number) as Void {
    for (var i = 0; i < count; i++) {
        winPoints(match, team, 4);
    }
}

(:test)
function testPointLabels(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winPoints(match, 0, 3);
    winPoints(match, 1, 1);
    return match.pointLabel(0).equals("40") && match.pointLabel(1).equals("15");
}

(:test)
function testGoldenPointWinsAtDeuce(logger as Logger) as Boolean {
    var match = new PadelMatch();
    match.goldenPoint = true;
    winPoints(match, 0, 3);
    winPoints(match, 1, 3);
    var result = match.addPoint(1);
    return result == :game && match.games[1] == 1 && match.points[0] == 0;
}

(:test)
function testAdvantageByDefault(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winPoints(match, 0, 3);
    winPoints(match, 1, 3);
    match.addPoint(0);
    var advantage = match.advantage();
    var hasAdvantage = advantage != null && advantage == 0 && match.pointLabel(0).equals("40");
    match.addPoint(1); // back to deuce
    var deuce = match.advantage() == null && match.pointLabel(0).equals("40") && match.pointLabel(1).equals("40");
    match.addPoint(1);
    var result = match.addPoint(1);
    return hasAdvantage && deuce && result == :game && match.games[1] == 1;
}

(:test)
function testSetAt6To4(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 1, 4);
    winGames(match, 0, 5);
    var result = match.addPoint(0);
    result = winGamePoints(match, 0, result);
    return result == :set && match.sets[0] == 1 && match.setScores[0][0] == 6 && match.setScores[0][1] == 4;
}

function winGamePoints(match as PadelMatch, team as Number, last as Symbol) as Symbol {
    var result = last;
    while (result == :point) {
        result = match.addPoint(team);
    }
    return result;
}

(:test)
function testTiebreakAt6To6(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 5);
    winGames(match, 1, 6);
    winGames(match, 0, 1);
    if (!match.tiebreak) {
        return false;
    }
    winPoints(match, 0, 6);
    winPoints(match, 1, 6);
    match.addPoint(0); // 7-6, not won yet
    var stillTiebreak = match.tiebreak && match.pointLabel(0).equals("7");
    match.addPoint(0); // 8-6
    return stillTiebreak && !match.tiebreak && match.setScores[0][0] == 7 && match.setScores[0][1] == 6;
}

(:test)
function testMatchWonInTwoSets(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 12);
    var winner = match.winner();
    var ignored = match.addPoint(1);
    return match.isFinished() && winner != null && winner == 0 && ignored == :none;
}

(:test)
function testUndoAcrossSet(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 6);
    if (match.sets[0] != 1) {
        return false;
    }
    match.undo();
    return match.sets[0] == 0 && match.games[0] == 5 && match.pointLabel(0).equals("40")
        && match.setScores.size() == 0;
}

(:test)
function testServeSideAlternates(logger as Logger) as Boolean {
    var match = new PadelMatch();
    var first = match.currentServer() == 0 && match.serveFromRight();
    match.addPoint(1);
    var second = match.currentServer() == 0 && !match.serveFromRight();
    match.addPoint(0);
    return first && second && match.serveFromRight();
}

(:test)
function testServerChangesEachGame(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 1);
    var afterOne = match.currentServer() == 1 && match.serveFromRight();
    winGames(match, 1, 1);
    return afterOne && match.currentServer() == 0;
}

(:test)
function testTiebreakServeRotation(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 5);
    winGames(match, 1, 6);
    winGames(match, 0, 1); // 12 games played: team 0 serves first again
    // Expected tie-break servers: A, B, B, A, A, B
    var expected = [0, 1, 1, 0, 0, 1];
    for (var i = 0; i < expected.size(); i++) {
        if (match.currentServer() != expected[i]) {
            return false;
        }
        match.addPoint(i % 2);
    }
    // Finish the tie-break 7-x for team 0; team 1 received first, so it serves next.
    winPoints(match, 0, 7);
    return !match.tiebreak && match.sets[0] == 1 && match.currentServer() == 1;
}

(:test)
function testSwapServerIsUndoable(logger as Logger) as Boolean {
    var match = new PadelMatch();
    match.swapServer();
    var swapped = match.currentServer() == 1;
    match.undo();
    return swapped && match.currentServer() == 0;
}

(:test)
function testScoreSummary(logger as Logger) as Boolean {
    var match = new PadelMatch();
    var empty = match.scoreSummary().equals("");
    winGames(match, 0, 6);          // 6-0
    winGames(match, 1, 2);          // 0-2 in set 2
    var inProgress = match.scoreSummary();
    var games = match.lastSetGames();
    logger.debug("summary: " + inProgress);
    return empty && inProgress.equals("6-0 0-2") && match.totalGames(0) == 6 && match.totalGames(1) == 2
        && games[0] == 0 && games[1] == 2;
}

(:test)
function testScoreSummaryFinished(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 12);
    var games = match.lastSetGames();
    return match.scoreSummary().equals("6-0 6-0") && games[0] == 6 && games[1] == 0;
}

// Records a short match and saves it. Checks that the FIT field calls run
// (types, sizes) without errors; the test run writes no FIT file to inspect.
(:test)
function testRecorderSavesScore(logger as Logger) as Boolean {
    var match = new PadelMatch();
    var recorder = new Recorder();
    recorder.toggle(match);
    for (var i = 0; i < 6; i++) {
        winGames(match, 0, 1);
    }
    recorder.syncLaps(match);
    recorder.syncLaps(match); // no second lap for the same set
    winGames(match, 1, 2);
    recorder.save(match);
    return !recorder.hasSession();
}

(:test)
function testContinuePlayingAfterMatch(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 12);
    if (!match.isFinished()) {
        return false;
    }
    match.continuePlaying();
    var open = !match.isFinished() && match.winner() == null;
    winGames(match, 1, 5);
    var result = winGamePoints(match, 1, match.addPoint(1));
    var third = result == :set && match.setScores.size() == 3 && match.scoreSummary().equals("6-0 6-0 0-6");
    return open && third;
}

(:test)
function testUndoContinuePlaying(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 12);
    match.continuePlaying();
    match.undo();
    return match.isFinished() && match.addPoint(1) == :none;
}

// Uses the simulator's storage: clears the history first.
(:test)
function testMatchHistoryAddRemove(logger as Logger) as Boolean {
    MatchHistory.clear();
    var match = new PadelMatch();
    winGames(match, 0, 6);
    MatchHistory.add(match, 3600 + 12 * 60);
    var entries = MatchHistory.getAll();
    var first = entries.size() == 1 && MatchHistory.scoreLabel(entries[0]).equals("6-0");
    var detail = MatchHistory.detailLabel(entries[0]);
    logger.debug("detail: " + detail);
    var hasResult = detail.find(" · won · 1:12") != null; // sets 1-0, 72 minutes
    MatchHistory.remove(entries[0][0] as Number);
    return first && hasResult && MatchHistory.getAll().size() == 0;
}

// Free play with 9 sets: the score is longer than the 32-byte FIT field and
// must be cut, not crash the save. Laps close lazily, once per set.
(:test)
function testRecorderLongFreePlayScore(logger as Logger) as Boolean {
    var match = new PadelMatch();
    var recorder = new Recorder();
    recorder.toggle(match);
    winGames(match, 0, 12);
    match.continuePlaying();
    for (var set = 0; set < 7; set++) {
        recorder.syncLaps(match);
        winGames(match, set % 2, 6);
    }
    logger.debug("score: " + match.scoreSummary() + " (" + match.scoreSummary().length() + " chars)");
    recorder.save(match);
    return match.setScores.size() == 9 && match.scoreSummary().length() > 31 && !recorder.hasSession();
}

// Recording started mid-match, and an undo across a closed lap: neither may
// crash, and save must still work.
(:test)
function testRecorderMidMatchStartAndUndo(logger as Logger) as Boolean {
    var match = new PadelMatch();
    winGames(match, 0, 6);              // set 1 before the recording
    var recorder = new Recorder();
    recorder.toggle(match);
    recorder.syncLaps(match);           // no lap for set 1
    winGames(match, 1, 6);              // set 2
    recorder.syncLaps(match);           // lap for set 2
    match.addPoint(0);
    match.undo();
    match.undo();                       // back into set 2
    recorder.syncLaps(match);           // clamps, no lap
    winPoints(match, 1, 1);             // set 2 won again
    recorder.syncLaps(match);
    recorder.save(match);
    return match.setScores.size() == 2 && !recorder.hasSession();
}

// Save after a change, then restore into a new match: score, serve, settings
// and undo history must come back.
(:test)
function testMatchStateRoundTrip(logger as Logger) as Boolean {
    var match = new PadelMatch();
    match.goldenPoint = true;
    winGames(match, 0, 6);
    winGames(match, 1, 2);
    winPoints(match, 0, 2);
    match.swapServer();
    MatchState.save(match);

    var restored = MatchState.load();
    MatchState.clear();
    if (restored == null) {
        return false;
    }
    var same = restored.scoreSummary().equals(match.scoreSummary())
        && restored.pointLabel(0).equals("30") && restored.currentServer() == match.currentServer()
        && restored.goldenPoint;
    var undone = restored.undo() && restored.undo(); // the undo history came back
    return same && undone && MatchState.load() == null;
}

(:test)
function testMatchStateNothingToSave(logger as Logger) as Boolean {
    MatchState.save(new PadelMatch());
    return MatchState.load() == null;
}
