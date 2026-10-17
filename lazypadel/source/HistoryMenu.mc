import Toybox.Lang;
import Toybox.WatchUi;

// Menu > History: saved matches, newest first. Select a match to delete it;
// "Delete all" at the end clears the history. Both ask for confirmation.
module HistoryMenu {

    function show() as Void {
        var menu = new WatchUi.Menu2({ :title => "History" });
        var entries = MatchHistory.getAll();
        if (entries.size() == 0) {
            menu.addItem(emptyItem());
        } else {
            for (var i = 0; i < entries.size(); i++) {
                var entry = entries[i];
                menu.addItem(new WatchUi.MenuItem(MatchHistory.scoreLabel(entry),
                    MatchHistory.detailLabel(entry), entry[0] as Number, null));
            }
            menu.addItem(new WatchUi.MenuItem("Delete all", null, :deleteAll, null));
        }
        WatchUi.pushView(menu, new HistoryMenuDelegate(menu), WatchUi.SLIDE_LEFT);
    }

    function emptyItem() as WatchUi.MenuItem {
        return new WatchUi.MenuItem("No matches yet", "Save & exit adds one", :empty, null);
    }
}

class HistoryMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :empty) {
            return;
        }
        if (id == :deleteAll) {
            WatchUi.pushView(new WatchUi.Confirmation("Delete all matches?"),
                new DeleteAllDelegate(), WatchUi.SLIDE_UP);
            return;
        }
        WatchUi.pushView(new WatchUi.Confirmation("Delete " + item.getLabel() + "?"),
            new DeleteMatchDelegate(_menu, id as Number), WatchUi.SLIDE_UP);
    }
}

class DeleteMatchDelegate extends WatchUi.ConfirmationDelegate {

    private var _menu as WatchUi.Menu2;
    private var _id as Number;

    function initialize(menu as WatchUi.Menu2, id as Number) {
        ConfirmationDelegate.initialize();
        _menu = menu;
        _id = id;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            MatchHistory.remove(_id);
            var index = _menu.findItemById(_id);
            if (index >= 0) {
                _menu.deleteItem(index);
            }
            if (MatchHistory.getAll().size() == 0) {
                // Only "Delete all" is left: show the empty state instead.
                _menu.deleteItem(0);
                _menu.addItem(HistoryMenu.emptyItem());
            }
        }
        return true;
    }
}

class DeleteAllDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            MatchHistory.clear();
            // Close the confirmation's parent (the history list) too.
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
