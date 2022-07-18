using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;
using Toybox.Time;
using Toybox.Time.Gregorian;

using ThemeController as Theme;

class DateTitle {

    private const dateFont = Graphics.FONT_MEDIUM;
    private var dateX;
    private var dateY;

    private var datePoints;

    function initialize(dc) {
        dateX = dc.getWidth() / 2;
        dateY = 14;

        var dateHeight = Graphics.getFontHeight(dateFont) + 1;

        datePoints = [
                        [dateX - 50, dateY],
                        [dateX + 50, dateY],
                        [dateX + 50, dateY + dateHeight],
                        [dateX - 50, dateY + dateHeight]
                    ];
    }

    // Draw the date string into the provided buffer at the specified location
    function drawOnScreen(dc) {
        var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);       // Greg is 16th century new hotness, Julian is old and busted
        var dateStr = Lang.format("$1$ $2$", [greg.month, greg.day]);

        CommonMethods.setDrawingClip(dc, datePoints);

        dc.drawText(dateX, dateY, dateFont, dateStr, Graphics.TEXT_JUSTIFY_CENTER);

        CommonMethods.clearDrawingClip(dc);
    }

}