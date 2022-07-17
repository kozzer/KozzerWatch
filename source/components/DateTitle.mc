using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;
using Toybox.Time;
using Toybox.Time.Gregorian;

using ThemeController as Theme;

class DateTitle {

    function initialize() {
        // Nothing here
    }

    // Draw the date string into the provided buffer at the specified location
    function drawOnScreen(dc, x, y) {
        var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);       // Greg is 16th century new hotness, Julian is old and busted
        var dateStr = Lang.format("$1$ $2$", [greg.month, greg.day]);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

}