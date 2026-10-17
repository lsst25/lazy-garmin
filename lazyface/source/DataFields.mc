import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

// Data the face can show in its field slots. The index in NAMES is what the
// "fieldLeft" / "fieldRight" / "fieldBottom" properties store, so only append
// to these lists. Most values come from Garmin's system complications.
module DataFields {

    enum {
        NONE, HEART_RATE, STEPS, CALORIES, DISTANCE, FLOORS, INTENSITY, BODY_BATTERY,
        STRESS, BATTERY, BATTERY_DAYS, NOTIFICATIONS, SUNRISE, SUNSET, TEMPERATURE,
        ALTITUDE, RECOVERY, PULSE_OX, RESPIRATION, VO2MAX, NEXT_EVENT,
        RUN_DISTANCE
    }

    const NAMES = [
        "None", "Heart rate", "Steps", "Calories", "Distance", "Floors", "Intensity min",
        "Body Battery", "Stress", "Battery", "Battery days", "Notifications", "Sunrise",
        "Sunset", "Temperature", "Altitude", "Recovery", "Pulse Ox", "Respiration",
        "VO2 max", "Next event", "Run distance"
    ];

    // Nerd Font icons (all in shared/tools/make_font.py ICON_CHARS).
    const ICONS = [
        0, 0xF004, 0xEE14, 0xF06D, 0xF018, 0xF1AD, 0xF2F2,
        0x26A1, 0xEE9C, 0xF240, 0xEE9E, 0xF0F3, 0xE34C,
        0xE34D, 0xE350, 0xEF08, 0xF252, 0xF043, 0xEEAA,
        0xEEB2, 0xF073, 0xEF0C
    ];

    // Icon colors as Theme.ACCENT_NAMES indexes; -1 = theme.heart, -2 = theme.steps.
    const COLORS = [
        0, -1, -2, 4, 1, 7, 3,
        0, 6, 2, 2, 3, 3,
        4, 5, 7, 0, 5, 1,
        2, 0, 1
    ];

    function iconColor(field as Number, theme as Theme) as Number {
        var color = COLORS[field];
        return color == -1 ? theme.heart : color == -2 ? theme.steps : theme.accent(color);
    }

    // Icon to draw; the battery icon follows the charge level.
    function icon(field as Number) as Number {
        if (field == BATTERY) {
            var battery = System.getSystemStats().battery;
            return ICONS[BATTERY] + (battery >= 88 ? 0 : battery >= 63 ? 1 : battery >= 38 ? 2 : battery >= 10 ? 3 : 4);
        }
        return ICONS[field];
    }

    // Formatted value, or "--" when the watch has no data.
    function value(field as Number) as String {
        var text = null;
        if (field == HEART_RATE) {
            text = format(heartRate());
        } else if (field == STEPS) {
            text = format(ActivityMonitor.getInfo().steps);
        } else if (field == CALORIES) {
            text = format(ActivityMonitor.getInfo().calories);
        } else if (field == DISTANCE) {
            var cm = ActivityMonitor.getInfo().distance;
            text = cm != null ? distance(cm / 100.0) : null;
        } else if (field == FLOORS) {
            text = format(ActivityMonitor.getInfo().floorsClimbed);
        } else if (field == INTENSITY) {
            text = format(complication(Complications.COMPLICATION_TYPE_INTENSITY_MINUTES));
        } else if (field == BODY_BATTERY) {
            text = format(complication(Complications.COMPLICATION_TYPE_BODY_BATTERY));
        } else if (field == STRESS) {
            text = format(complication(Complications.COMPLICATION_TYPE_STRESS));
        } else if (field == BATTERY) {
            text = System.getSystemStats().battery.format("%d") + "%";
        } else if (field == BATTERY_DAYS) {
            var stats = System.getSystemStats();
            text = (stats has :batteryInDays && stats.batteryInDays != null)
                ? stats.batteryInDays.format("%d") + "d" : null;
        } else if (field == NOTIFICATIONS) {
            text = format(System.getDeviceSettings().notificationCount);
        } else if (field == SUNRISE) {
            text = timeOfDay(complication(Complications.COMPLICATION_TYPE_SUNRISE));
        } else if (field == SUNSET) {
            text = timeOfDay(complication(Complications.COMPLICATION_TYPE_SUNSET));
        } else if (field == TEMPERATURE) {
            text = temperature(complication(Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE));
        } else if (field == ALTITUDE) {
            text = altitude(complication(Complications.COMPLICATION_TYPE_ALTITUDE));
        } else if (field == RECOVERY) {
            var minutes = complication(Complications.COMPLICATION_TYPE_RECOVERY_TIME);
            text = minutes != null ? ((minutes as Number) / 60).format("%d") + "h" : null;
        } else if (field == PULSE_OX) {
            var spo2 = complication(Complications.COMPLICATION_TYPE_PULSE_OX);
            text = spo2 != null ? format(spo2) + "%" : null;
        } else if (field == RESPIRATION) {
            text = format(complication(Complications.COMPLICATION_TYPE_RESPIRATION_RATE));
        } else if (field == VO2MAX) {
            text = format(complication(Complications.COMPLICATION_TYPE_VO2MAX_RUN));
        } else if (field == NEXT_EVENT) {
            if (Complications has :COMPLICATION_TYPE_CALENDAR_EVENTS) {
                var event = complication(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);
                text = event != null ? event.toString() : null;
            }
        } else if (field == RUN_DISTANCE) {
            if (Complications has :COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE) {
                var meters = complication(Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE);
                text = meters != null ? distance((meters as Numeric).toFloat()) : null;
            }
        }
        return text != null ? text : "--";
    }

    function heartRate() as Number? {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        if (ActivityMonitor has :getHeartRateHistory) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
    }

    // Value of a system complication, or null when unavailable.
    function complication(type as Complications.Type) {
        try {
            return Complications.getComplication(new Complications.Id(type)).value;
        } catch (e) {
            return null;
        }
    }

    function format(value) as String? {
        if (value == null) {
            return null;
        }
        return value instanceof Number ? value.toString() : (value as Numeric).format("%d");
    }

    // km or mi (watch setting), one decimal.
    function distance(meters as Float) as String {
        if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
            return (meters / 1609.344).format("%.1f") + "mi";
        }
        return (meters / 1000).format("%.1f") + "km";
    }

    // Celsius in, °C or °F (watch setting) out.
    function temperature(celsius) as String? {
        if (celsius == null) {
            return null;
        }
        var degrees = (celsius as Numeric).toFloat();
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
            degrees = degrees * 9 / 5 + 32;
        }
        return degrees.format("%d") + "°";
    }

    // Meters in, m or ft (watch setting) out.
    function altitude(meters) as String? {
        if (meters == null) {
            return null;
        }
        var value = (meters as Numeric).toFloat();
        if (System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE) {
            return (value * 3.28084).format("%d") + "ft";
        }
        return value.format("%d") + "m";
    }

    // Seconds since midnight in, watch-formatted time out.
    function timeOfDay(seconds) as String? {
        if (seconds == null) {
            return null;
        }
        var minutes = (seconds as Number) / 60;
        var hour = minutes / 60;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return hour.toString() + ":" + (minutes % 60).format("%02d");
    }
}
