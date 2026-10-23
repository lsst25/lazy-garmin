import Toybox.Lang;

// Layout of the watch face. Positions are fractions of the screen width or
// height (0.0 = left/top, 1.0 = right/bottom); sizes are in pixels.
module FaceLayout {

    // Date
    const DATE_Y = 0.18;

    // Time (block digits)
    const TIME_Y = 0.45;
    const TIME_BLOCK_WIDTH = 14;
    const TIME_BLOCK_HEIGHT = 32;

    // Left and right data fields
    const FIELDS_Y = 0.72;
    const FIELD_LEFT_X = 0.31;
    const FIELD_RIGHT_X = 0.69;

    // Bottom data field (pill)
    const PILL_Y = 0.855;

    // Low-power (always-on) clock: block size and the shift step that moves
    // it every minute (5 x 5 positions around the center).
    const LOW_POWER_BLOCK_WIDTH = 7;
    const LOW_POWER_BLOCK_HEIGHT = 13;
    const LOW_POWER_SHIFT = 6;
}
