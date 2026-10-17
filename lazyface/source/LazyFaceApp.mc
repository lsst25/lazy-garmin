import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class LazyFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new LazyFaceView() ];
    }

    // On-device settings: hold Up > Watch Face > Customize.
    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new FaceSettingsMenu(), new FaceSettingsDelegate()];
    }

    // Redraw at once when the display enters or leaves always-on mode, so
    // LazyFaceView.isLowPower() sees the new mode.
    function onDisplayModeChanged() as Void {
        WatchUi.requestUpdate();
    }

    // Settings changed from the phone.
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

}

function getApp() as LazyFaceApp {
    return Application.getApp() as LazyFaceApp;
}
