import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Saved matches (menu > History), newest first, stored on the watch.
// Entry: [id (epoch seconds), score summary, sets us, sets them, duration seconds].
module MatchHistory {

    const STORAGE_KEY = "history";
    const MAX_ENTRIES = 50;

    function getAll() as Array<Array> {
        var value = Application.Storage.getValue(STORAGE_KEY);
        return value instanceof Array ? value as Array<Array> : [] as Array<Array>;
    }

    function add(match as PadelMatch, durationSeconds as Number) as Void {
        var entries = getAll();
        var entry = [Time.now().value(), match.scoreSummary(), match.sets[0], match.sets[1], durationSeconds];
        entries = [entry].addAll(entries) as Array<Array>;
        if (entries.size() > MAX_ENTRIES) {
            entries = entries.slice(0, MAX_ENTRIES);
        }
        Application.Storage.setValue(STORAGE_KEY, entries);
    }

    function remove(id as Number) as Void {
        var kept = [] as Array<Array>;
        var entries = getAll();
        for (var i = 0; i < entries.size(); i++) {
            if (entries[i][0] != id) {
                kept.add(entries[i]);
            }
        }
        Application.Storage.setValue(STORAGE_KEY, kept);
    }

    function clear() as Void {
        Application.Storage.deleteValue(STORAGE_KEY);
    }

    // "6-4 3-6 7-5", or "0-0" for a match saved before the first game.
    function scoreLabel(entry as Array) as String {
        var score = entry[1] as String;
        return score.length() > 0 ? score : "0-0";
    }

    // "sat 17 oct 21:35 · won · 1:12"
    function detailLabel(entry as Array) as String {
        var info = Gregorian.info(new Time.Moment(entry[0] as Number), Time.FORMAT_MEDIUM);
        var date = Lang.format("$1$ $2$ $3$ $4$:$5$",
            [info.day_of_week, info.day, info.month, info.hour, info.min.format("%02d")]).toLower();

        var setsUs = entry[2] as Number;
        var setsThem = entry[3] as Number;
        var result = setsUs > setsThem ? "won" : setsUs < setsThem ? "lost" : "draw";

        var minutes = (entry[4] as Number) / 60;
        var duration = Lang.format("$1$:$2$", [minutes / 60, (minutes % 60).format("%02d")]);
        return date + " · " + result + " · " + duration;
    }
}
