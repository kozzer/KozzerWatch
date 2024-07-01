using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;
using Toybox.Time;
using Toybox.Time.Gregorian;

using ThemeController as Theme;

class DateTitle {

    private const _dateFont = Graphics.FONT_SMALL;
    private var _dateX;
    private var _dateY;

    private var _datePoints;

    function initialize(dc) {
        _dateX = dc.getWidth() / 2;
        _dateY = 14;

        //var app = Application.getApp();
        var isInstinct2 = Application.Properties.getValue("IsInstinct2");
        if (isInstinct2){
            _dateX = dc.getWidth() - 34;
            _dateY = (dc.getHeight() / 2) - 8;
        }

        var dateHeight = Graphics.getFontHeight(_dateFont) + 1;

        _datePoints = [
                        [_dateX - 50, _dateY],
                        [_dateX + 50, _dateY],
                        [_dateX + 50, _dateY + dateHeight],
                        [_dateX - 50, _dateY + dateHeight]
                    ];
    }

    // Draw the date string into the provided buffer at the specified location
    function drawOnScreen(dc) {
        var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);       // Greg is 16th century new hotness, Julian is old and busted
        var dateStr = Lang.format("$1$ $2$", [greg.month, greg.day]);

        CommonMethods.setDrawingClip(dc, _datePoints);

        dc.drawText(_dateX, _dateY, _dateFont, dateStr, Graphics.TEXT_JUSTIFY_CENTER);

        CommonMethods.clearDrawingClip(dc);
    }

}