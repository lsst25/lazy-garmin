import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Menu items that pick one of a list of names, stored as an index in an
// application property (e.g. theme, colors). The item's id is the property key.
module Choices {

    // Stored index for the property, or the fallback when unset.
    function index(key as String, count as Number, fallback as Number) as Number {
        var value = Application.Properties.getValue(key);
        return (value instanceof Number && value >= 0 && value < count) ? value : fallback;
    }

    // "Theme / Wave": label with the current choice as the sub-label.
    function item(label as String, key as String, names as Array<String>, fallback as Number) as WatchUi.MenuItem {
        return new WatchUi.MenuItem(label, names[index(key, names.size(), fallback)], key, null);
    }

    // Opens the list of names for the item; picking one saves it.
    function openPicker(item as WatchUi.MenuItem, names as Array<String>, fallback as Number) as Void {
        var key = item.getId() as String;
        var picker = new WatchUi.Menu2({ :title => item.getLabel() });
        for (var i = 0; i < names.size(); i++) {
            picker.addItem(new WatchUi.MenuItem(names[i], null, i, null));
        }
        picker.setFocus(index(key, names.size(), fallback));
        WatchUi.pushView(picker, new ChoicePickerDelegate(key, item), WatchUi.SLIDE_LEFT);
    }
}

// Saves the picked index and updates the sub-label of the parent item.
class ChoicePickerDelegate extends WatchUi.Menu2InputDelegate {

    private var _key as String;
    private var _parentItem as WatchUi.MenuItem;

    function initialize(key as String, parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _key = key;
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        Application.Properties.setValue(_key, item.getId() as Number);
        _parentItem.setSubLabel(item.getLabel());
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
