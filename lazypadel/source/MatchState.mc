import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// The match in progress, saved to storage after every change, so a crash or
// a closed app doesn't lose the score: on the next start the app offers to
// resume it. Cleared on Save / Discard / Exit and after "no" to resume.
module MatchState {

    const STORAGE_KEY = "currentMatch";

    function save(match as PadelMatch) as Void {
        if (match.hasProgress()) {
            Application.Storage.setValue(STORAGE_KEY, match.toStorage());
        } else {
            clear();
        }
    }

    // The saved match, or null when there is none (or it can't be read).
    function load() as PadelMatch? {
        var match = new PadelMatch();
        return match.fromStorage(Application.Storage.getValue(STORAGE_KEY)) ? match : null;
    }

    function clear() as Void {
        Application.Storage.deleteValue(STORAGE_KEY);
    }

    // At app start: if a match was left unfinished, ask to resume it.
    function offerResume(match as PadelMatch) as Void {
        var saved = load();
        if (saved == null) {
            return;
        }
        var score = saved.scoreSummary();
        var question = "Resume match" + (score.length() > 0 ? " " + score : "") + "?";
        WatchUi.pushView(new WatchUi.Confirmation(question), new ResumeDelegate(match), WatchUi.SLIDE_UP);
    }
}

class ResumeDelegate extends WatchUi.ConfirmationDelegate {

    private var _match as PadelMatch;

    function initialize(match as PadelMatch) {
        ConfirmationDelegate.initialize();
        _match = match;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _match.fromStorage(Application.Storage.getValue(MatchState.STORAGE_KEY));
        } else {
            MatchState.clear();
        }
        WatchUi.requestUpdate();
        return true;
    }
}
