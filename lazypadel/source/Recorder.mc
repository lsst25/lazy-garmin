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

    private var _session as ActivityRecording.Session?;
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
    function toggle() as Void {
        var session = _session;
        if (session == null) {
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

    // A set just ended: close its lap with the set score.
    function onSetFinished(match as PadelMatch) as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        var setScore = match.setScores[match.setScores.size() - 1];
        writeLapScore(setScore);
        session.addLap();
    }

    function save(match as PadelMatch) as Void {
        var session = _session;
        if (session != null) {
            // The last lap is the final set, or the set in progress.
            writeLapScore(match.lastSetGames());
            setField(FIELD_SCORE, match.scoreSummary());
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
            // "7-6 6-7 7-6" is 11 chars; leave room for longer scores.
            FIELD_SCORE => session.createField("score", FIELD_SCORE, FitContributor.DATA_TYPE_STRING,
                { :mesgType => FitContributor.MESG_TYPE_SESSION, :count => 24 }),
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
