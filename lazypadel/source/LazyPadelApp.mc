import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class LazyPadelApp extends Application.AppBase {

    private var _match as PadelMatch;
    private var _recorder as Recorder;

    function initialize() {
        AppBase.initialize();
        _match = new PadelMatch();
        _recorder = new Recorder();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new PadelView(_match, _recorder), new PadelDelegate(_match, _recorder)];
    }
}

function getApp() as LazyPadelApp {
    return Application.getApp() as LazyPadelApp;
}
