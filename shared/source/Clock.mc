import Toybox.Lang;
import Toybox.System;

module Clock {

    // Hour 0-23 in, hour in the watch's 12/24-hour format out.
    function displayHour(hour as Number) as Number {
        if (System.getDeviceSettings().is24Hour) {
            return hour;
        }
        var h = hour % 12;
        return h == 0 ? 12 : h;
    }
}
