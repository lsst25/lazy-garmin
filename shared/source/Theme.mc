import Toybox.Lang;

// Colors from the dark Kanagawa variants (https://github.com/rebelot/kanagawa.nvim).
// A theme gives the base colors; accent(index) picks one of ACCENT_NAMES in
// that theme's shade. Apps store the indexes in their own properties.
class Theme {

    static const THEME_NAMES = ["Wave", "Dragon"];
    static const ACCENT_NAMES = ["Blue", "Aqua", "Green", "Yellow", "Orange", "Red", "Pink", "Violet"];

    // Indexes in ACCENT_NAMES.
    static const BLUE = 0;
    static const ORANGE = 4;

    // Per theme: [background, darkest (text on pills), text, secondary text,
    // gray (labels, paused), dim (dividers, inactive), heart red, steps green].
    private static const BASES = [
        [0x1F1F28, 0x16161D, 0xDCD7BA, 0xC8C093, 0x727169, 0x54546D, 0xFF5D62, 0x98BB6C], // Wave
        [0x181616, 0x0D0C0C, 0xC5C9C5, 0xA6A69C, 0x737C73, 0x625E5A, 0xC4746E, 0x87A987]  // Dragon
    ];

    // Per theme, in ACCENT_NAMES order.
    private static const ACCENTS = [
        [0x7E9CD8, 0x7AA89F, 0x98BB6C, 0xE6C384, 0xFFA066, 0xE46876, 0xD27E99, 0x957FB8], // Wave
        [0x8BA4B0, 0x8EA4A2, 0x87A987, 0xC4B28A, 0xB6927B, 0xC4746E, 0xA292A3, 0x8992A7]  // Dragon
    ];

    // Same in every theme.
    static const LOW_BATTERY = 0xC34043;
    static const LOW_POWER = 0x2D4F67; // always-on clock: dim, on black (AMOLED burn-in)

    var background as Number;
    var darkest as Number;
    var text as Number;
    var secondary as Number;
    var gray as Number;
    var dim as Number;
    var heart as Number;
    var steps as Number;
    private var _accents as Array<Number>;

    function initialize(themeIndex as Number) {
        var index = clamp(themeIndex, THEME_NAMES.size());
        var base = BASES[index];
        background = base[0];
        darkest = base[1];
        text = base[2];
        secondary = base[3];
        gray = base[4];
        dim = base[5];
        heart = base[6];
        steps = base[7];
        _accents = ACCENTS[index];
    }

    function accent(index as Number) as Number {
        return _accents[clamp(index, ACCENT_NAMES.size())];
    }

    // A stored index, or 0 when missing or out of range.
    static function clamp(value, count as Number) as Number {
        return (value instanceof Number && value >= 0 && value < count) ? value : 0;
    }
}
