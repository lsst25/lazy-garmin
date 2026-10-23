import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// App-level touch on/off (menu > Settings > Touch), saved across restarts. Needed because
// DeviceSettings.isTouchScreen stays true on the fr965 when touch is turned
// off in the watch settings, so the app can't follow that setting.
module TouchSetting {

    const STORAGE_KEY = "touch";

    // Off by default.
    function isEnabled() as Boolean {
        var value = Application.Storage.getValue(STORAGE_KEY);
        return value instanceof Boolean ? value : false;
    }

    function setEnabled(enabled as Boolean) as Void {
        Application.Storage.setValue(STORAGE_KEY, enabled);
        apply();
    }

    // Turns touch events off at the system level where supported (API 5.2+).
    // Only allowed in the foreground: it throws OperationNotAllowedException
    // when the view comes back while a notification or call alert is still
    // closing (this crashed the app). The taps are also filtered in
    // PadelDelegate, so a failed call here is harmless; the next onShow retries.
    function apply() as Void {
        if (WatchUi has :configureTouchEvents) {
            try {
                WatchUi.configureTouchEvents({ :enabled => isEnabled() });
            } catch (e) {
            }
        }
    }
}
