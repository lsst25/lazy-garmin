import Toybox.Lang;
import Toybox.WatchUi;

// On-device settings (hold Up > Watch Face > Customize). Side-loaded apps
// can't be configured from the phone, so this is the way to change them.
// Properties: "theme" (Theme.THEME_NAMES), "accent" (Theme.ACCENT_NAMES),
// "fieldLeft" / "fieldRight" / "fieldBottom" (DataFields.NAMES).
class FaceSettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "lazyface" });
        addItem(Choices.item("Theme", "theme", Theme.THEME_NAMES, 0));
        addItem(Choices.item("Clock color", "accent", Theme.ACCENT_NAMES, Theme.BLUE));
        addItem(Choices.item("Left field", "fieldLeft", DataFields.NAMES, DataFields.HEART_RATE));
        addItem(Choices.item("Right field", "fieldRight", DataFields.NAMES, DataFields.STEPS));
        addItem(Choices.item("Bottom field", "fieldBottom", DataFields.NAMES, DataFields.BATTERY));
    }
}

class FaceSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        Choices.openPicker(item as ChoiceItem);
    }
}
