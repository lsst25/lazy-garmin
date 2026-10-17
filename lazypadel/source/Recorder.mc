import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Sensor;

// Records the match as a padel activity (FIT file, saved to Garmin Connect).
// The score goes into FIT developer fields: the whole score in the session
// (activity summary) and one lap per set. Field ids match
// resources/fit/fit_contributions.xml.
class Recorder {

    private const FIELD_SCORE = 0;
    private const FIELD_SETS_WON = 1;
    private const FIELD_SETS_LOST = 2;
    private const FIELD_GAMES_WON = 3;
    private const FIELD_GAMES_LOST = 4;
    private const FIELD_LAP_SCORE = 10;
    private const FIELD_LAP_GAMES_WON = 11;
    private const FIELD_LAP_GAMES_LOST = 12;

    // The score string is one developer field: keep it within 32 bytes.
    private const SCORE_MAX_CHARS = 31;

    private var _session as ActivityRecording.Session?;
    // Finished sets that already have their own lap.
    private var _lapsClosed as Number = 0;
    private var _fields as Dictionary<Number, FitContributor.Field> = {};

    function initialize() {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
    }

    function hasSession() as Boolean {
        return _session != null;
    }

    function isRecording() as Boolean {
        var session = _session;
        return session != null && session.isRecording();
    }

    // Start button: start the first time, then pause / resume.
    function toggle(match as PadelMatch) as Void {
        var session = _session;
        if (session == null) {
            // Sets finished before the recording started get no lap.
            _lapsClosed = match.setScores.size();
            session = ActivityRecording.createSession({
                :name => "Padel",
                :sport => Activity.SPORT_RACKET,
                :subSport => Activity.SUB_SPORT_PADEL
            });
            createFields(session);
            _session = session;
        }
        if (session.isRecording()) {
            session.stop();
        } else {
            session.start();
        }
    }

    // Closes one lap for each finished set without a lap yet. Called before
    // each point (not at the set point), so a set point undone before the next
    // point never reaches the FIT file. The break between sets counts in the
    // previous set's lap.
    function syncLaps(match as PadelMatch) as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        closeLapsBefore(session, match, match.setScores.size());
    }

    function onMatchReset() as Void {
        _lapsClosed = 0;
    }

    function save(match as PadelMatch) as Void {
        var session = _session;
        if (session != null) {
            // Close the laps of all finished sets but the last; the open lap
            // gets the last finished set, or the set in progress.
            var count = match.setScores.size();
            closeLapsBefore(session, match, count - 1);
            var lastLap = [match.games[0], match.games[1]];
            if (_lapsClosed < count) {
                lastLap = match.setScores[_lapsClosed];
            } else if (match.isFinished()) {
                lastLap = match.lastSetGames(); // recording started after the match ended
            }
            writeLapScore(lastLap);

            var score = match.scoreSummary();
            if (score.length() > SCORE_MAX_CHARS) {
                score = score.substring(0, SCORE_MAX_CHARS) as String;
            }
            setField(FIELD_SCORE, score);
            setField(FIELD_SETS_WON, match.sets[0]);
            setField(FIELD_SETS_LOST, match.sets[1]);
            setField(FIELD_GAMES_WON, match.totalGames(0));
            setField(FIELD_GAMES_LOST, match.totalGames(1));

            if (session.isRecording()) {
                session.stop();
            }
            session.save();
            _session = null;
            _fields = {};
            _lapsClosed = 0;
        }
    }

    function discard() as Void {
        var session = _session;
        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            session.discard();
            _session = null;
            _fields = {};
            _lapsClosed = 0;
        }
    }

    // Timer time of the session in seconds (pauses excluded).
    function elapsedSeconds() as Number {
        var info = Activity.getActivityInfo();
        if (_session == null || info == null || info.timerTime == null) {
            return 0;
        }
        return (info.timerTime as Number) / 1000;
    }

    function heartRate() as Number? {
        var info = Activity.getActivityInfo();
        return info != null ? info.currentHeartRate : null;
    }

    private function createFields(session as ActivityRecording.Session) as Void {
        var summary = { :mesgType => FitContributor.MESG_TYPE_SESSION };
        var lap = { :mesgType => FitContributor.MESG_TYPE_LAP };
        _fields = {
            // 31 chars = 8 sets ("d-d "); longer free-play scores are cut in save().
            FIELD_SCORE => session.createField("score", FIELD_SCORE, FitContributor.DATA_TYPE_STRING,
                { :mesgType => FitContributor.MESG_TYPE_SESSION, :count => SCORE_MAX_CHARS + 1 }),
            FIELD_SETS_WON => session.createField("sets_won", FIELD_SETS_WON, FitContributor.DATA_TYPE_UINT8, summary),
            FIELD_SETS_LOST => session.createField("sets_lost", FIELD_SETS_LOST, FitContributor.DATA_TYPE_UINT8, summary),
            FIELD_GAMES_WON => session.createField("games_won", FIELD_GAMES_WON, FitContributor.DATA_TYPE_UINT8, summary),
            FIELD_GAMES_LOST => session.createField("games_lost", FIELD_GAMES_LOST, FitContributor.DATA_TYPE_UINT8, summary),
            FIELD_LAP_SCORE => session.createField("set_score", FIELD_LAP_SCORE, FitContributor.DATA_TYPE_STRING,
                { :mesgType => FitContributor.MESG_TYPE_LAP, :count => 8 }),
            FIELD_LAP_GAMES_WON => session.createField("set_games_won", FIELD_LAP_GAMES_WON, FitContributor.DATA_TYPE_UINT8, lap),
            FIELD_LAP_GAMES_LOST => session.createField("set_games_lost", FIELD_LAP_GAMES_LOST, FitContributor.DATA_TYPE_UINT8, lap)
        };
    }

    private function closeLapsBefore(session as ActivityRecording.Session, match as PadelMatch,
            count as Number) as Void {
        // An undo across a closed lap removes finished sets: a replayed set
        // then gets a new lap (the old lap keeps its score; FIT laps can't be removed).
        if (_lapsClosed > match.setScores.size()) {
            _lapsClosed = match.setScores.size();
        }
        while (_lapsClosed < count) {
            writeLapScore(match.setScores[_lapsClosed]);
            session.addLap();
            _lapsClosed += 1;
        }
    }

    private function writeLapScore(games as Array<Number>) as Void {
        setField(FIELD_LAP_SCORE, games[0].toString() + "-" + games[1].toString());
        setField(FIELD_LAP_GAMES_WON, games[0]);
        setField(FIELD_LAP_GAMES_LOST, games[1]);
    }

    private function setField(id as Number, value as Numeric or String) as Void {
        var field = _fields[id];
        if (field != null) {
            field.setData(value);
        }
    }
}
