import Toybox.Lang;
import Toybox.WatchUi;

// Menu > Settings: look and input. Properties: "theme" (Theme.THEME_NAMES),
// "usColor" / "themColor" (Theme.ACCENT_NAMES). Touch is in TouchSetting.
module PadelSettings {

    function themeIndex() as Number {
        return Choices.index("theme", Theme.THEME_NAMES.size(), 0);
    }

    // Team colors as accent indexes: [us, them].
    function teamAccents() as Array<Number> {
        return [
            Choices.index("usColor", Theme.ACCENT_NAMES.size(), Theme.BLUE),
            Choices.index("themColor", Theme.ACCENT_NAMES.size(), Theme.ORANGE)
        ];
    }

    function show() as Void {
        var menu = new WatchUi.Menu2({ :title => "Settings" });
        menu.addItem(Choices.item("Theme", "theme", Theme.THEME_NAMES, 0));
        menu.addItem(Choices.item("Us color", "usColor", Theme.ACCENT_NAMES, Theme.BLUE));
        menu.addItem(Choices.item("Them color", "themColor", Theme.ACCENT_NAMES, Theme.ORANGE));
        menu.addItem(new WatchUi.ToggleMenuItem("Touch", null, :touch, TouchSetting.isEnabled(), null));
        WatchUi.pushView(menu, new PadelSettingsDelegate(), WatchUi.SLIDE_LEFT);
    }
}

class PadelSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :touch) {
            TouchSetting.setEnabled((item as WatchUi.ToggleMenuItem).isEnabled());
        } else if ((id as String).equals("theme")) {
            Choices.openPicker(item, Theme.THEME_NAMES, 0);
        } else {
            Choices.openPicker(item, Theme.ACCENT_NAMES,
                (id as String).equals("usColor") ? Theme.BLUE : Theme.ORANGE);
        }
    }
}
