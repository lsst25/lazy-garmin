import Toybox.Lang;
import Toybox.WatchUi;

// On-device settings (hold Up > Watch Face > Customize). Side-loaded apps
// can't be configured from the phone, so this is the way to change them.
// Properties: "theme" (Theme.THEME_NAMES), "accent" (Theme.ACCENT_NAMES).
class FaceSettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "lazyface" });
        addItem(Choices.item("Theme", "theme", Theme.THEME_NAMES, 0));
        addItem(Choices.item("Clock color", "accent", Theme.ACCENT_NAMES, Theme.BLUE));
    }
}

class FaceSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var isTheme = (item.getId() as String).equals("theme");
        Choices.openPicker(item, isTheme ? Theme.THEME_NAMES : Theme.ACCENT_NAMES, isTheme ? 0 : Theme.BLUE);
    }
}
