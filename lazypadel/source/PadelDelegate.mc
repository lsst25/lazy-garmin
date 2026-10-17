import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Buttons (fr965):
//   Up            point for "them" (top row)
//   Down          point for "us" (bottom row)
//   Start         start / resume recording; while recording: pause and open
//                 the menu (like native Garmin activities)
//   Back          undo the last point (menu when there is nothing to undo)
//   Hold Up       menu: continue playing (match over), resume, save, discard,
//                 exit, history, swap server, reset, golden point, settings
//                 (theme, team colors, touch)
// Touch (only when menu > Settings > Touch is on): tap the top half for "them", the
// bottom half for "us".
class PadelDelegate extends WatchUi.BehaviorDelegate {

    private var _match as PadelMatch;
    private var _recorder as Recorder;

    function initialize(match as PadelMatch, recorder as Recorder) {
        BehaviorDelegate.initialize();
        _match = match;
        _recorder = recorder;
    }

    function onPreviousPage() as Boolean {
        return addPoint(1);
    }

    function onNextPage() as Boolean {
        return addPoint(0);
    }

    // Swipes would otherwise become onNextPage / onPreviousPage (= points).
    function onSwipe(event as WatchUi.SwipeEvent) as Boolean {
        return !TouchSetting.isEnabled(); // true = swallow
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        if (!TouchSetting.isEnabled()) {
            return true; // swallow the tap (otherwise it may become onSelect)
        }
        var y = event.getCoordinates()[1];
        return addPoint(y < System.getDeviceSettings().screenHeight / 2 ? 1 : 0);
    }

    function onSelect() as Boolean {
        if (_recorder.isRecording()) {
            _recorder.toggle(_match);
            buzz(300);
            return onMenu();
        }
        _recorder.toggle(_match);
        buzz(150);
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        if (_match.undo()) {
            buzz(40);
            WatchUi.requestUpdate();
            return true;
        }
        return onMenu();
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({ :title => "lazypadel" });
        if (_match.isFinished()) {
            menu.addItem(new WatchUi.MenuItem("Continue playing", null, :continue, null));
        }
        if (_recorder.hasSession()) {
            if (!_recorder.isRecording()) {
                menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
            }
            menu.addItem(new WatchUi.MenuItem("Save & exit", null, :save, null));
            menu.addItem(new WatchUi.MenuItem("Discard & exit", null, :discard, null));
        } else {
            menu.addItem(new WatchUi.MenuItem("Exit", null, :exit, null));
        }
        menu.addItem(new WatchUi.MenuItem("History", null, :history, null));
        menu.addItem(new WatchUi.MenuItem("Swap server", null, :swapServer, null));
        menu.addItem(new WatchUi.MenuItem("Reset score", null, :reset, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Golden point", null, :golden, _match.goldenPoint, null));
        menu.addItem(new WatchUi.MenuItem("Settings", "Theme, colors, touch", :settings, null));
        WatchUi.pushView(menu, new PadelMenuDelegate(_match, _recorder), WatchUi.SLIDE_UP);
        return true;
    }

    private function addPoint(team as Number) as Boolean {
        if (!_match.isFinished()) {
            // Closes the lap of a set that ended on the previous point. Doing it
            // here, not at the set point, keeps a set point that is undone before
            // the next point out of the FIT file.
            _recorder.syncLaps(_match);
        }
        var result = _match.addPoint(team);
        if (result == :point) {
            buzz(40);
        } else if (result == :game) {
            buzz(200);
        } else if (result == :set || result == :match) {
            buzz(600);
        }
        WatchUi.requestUpdate();
        return true;
    }

    private function buzz(durationMs as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(60, durationMs)]);
        }
    }
}

class PadelMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _match as PadelMatch;
    private var _recorder as Recorder;

    function initialize(match as PadelMatch, recorder as Recorder) {
        Menu2InputDelegate.initialize();
        _match = match;
        _recorder = recorder;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :continue) {
            _match.continuePlaying();
            if (_recorder.hasSession() && !_recorder.isRecording()) {
                _recorder.toggle(_match); // Start paused the recording to open this menu
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :resume) {
            _recorder.toggle(_match);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :exit) {
            System.exit();
        } else if (id == :history) {
            HistoryMenu.show();
        } else if (id == :save) {
            MatchHistory.add(_match, _recorder.elapsedSeconds());
            _recorder.save(_match);
            System.exit();
        } else if (id == :discard) {
            WatchUi.pushView(new WatchUi.Confirmation("Discard activity?"),
                new ConfirmDelegate(method(:discardAndExit)), WatchUi.SLIDE_UP);
        } else if (id == :swapServer) {
            _match.swapServer();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :reset) {
            WatchUi.pushView(new WatchUi.Confirmation("Reset score?"),
                new ConfirmDelegate(method(:resetScore)), WatchUi.SLIDE_UP);
        } else if (id == :settings) {
            PadelSettings.show();
        } else if (id == :golden) {
            _match.goldenPoint = (item as WatchUi.ToggleMenuItem).isEnabled();
        }
    }

    function discardAndExit() as Void {
        _recorder.discard();
        System.exit();
    }

    function resetScore() as Void {
        _match.reset();
        _recorder.onMatchReset();
        WatchUi.popView(WatchUi.SLIDE_DOWN); // close the menu under the confirmation
    }
}

// Runs the action when the user confirms with "yes".
class ConfirmDelegate extends WatchUi.ConfirmationDelegate {

    private var _action as Method() as Void;

    function initialize(action as Method() as Void) {
        ConfirmationDelegate.initialize();
        _action = action;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _action.invoke();
        }
        return true;
    }
}
