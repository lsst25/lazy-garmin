import Toybox.Lang;
import Toybox.Test;

// Reads every field once in the simulator: catches runtime type errors in
// the formatting code. Run with `make test`.
(:test)
function testAllFieldsFormat(logger as Logger) as Boolean {
    for (var field = 0; field < DataFields.NAMES.size(); field++) {
        var value = DataFields.value(field);
        logger.debug(DataFields.NAMES[field] + ": " + value);
        if (value.length() == 0) {
            return false;
        }
    }
    return DataFields.NAMES.size() == DataFields.ICONS.size() && DataFields.NAMES.size() == DataFields.COLORS.size();
}
