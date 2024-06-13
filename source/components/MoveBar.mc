using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class MoveBar {

    // Move Bar
    private const _moveBarHeight = 4;
    private const _moveBarWidth = 78;
    private var   _barX;
    private var   _barY;

    private var _barPoints;

    function initialize(dc){
        // Get location of the blue bar
        _barX = ((dc.getWidth() / 2) - (_moveBarWidth / 2));      // Total 78px wide, so 39px left of center
        _barY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 12;

        _barPoints = [
                        [_barX, _barY], 
                        [_barX + _moveBarWidth, _barY], 
                        [_barX + _moveBarWidth, _barY + _moveBarHeight], 
                        [_barX, _barY + _moveBarHeight]
                    ];
    }

    function drawOnScreen(dc) {

        // Get Move bar status
        var barLevel = ActivityMonitor.getInfo().moveBarLevel;

        var drawBarX = _barX;

        CommonMethods.setDrawingClip(dc, _barPoints);
        //var app = Application.getApp();
        var isInstinct2 = Application.Properties.getValue("IsInstinct2");

        // Draw bars based on bar level
        if (barLevel >= 1) {
            Theme.setColor(dc, Theme.BLUE_COLOR);
            dc.fillRectangle(drawBarX, _barY, 27, _moveBarHeight);
            drawBarX += 30;
        }
        if (barLevel >= 2){
            Theme.setColor(dc, Theme.FULL_COLOR);
            dc.fillRectangle(drawBarX, _barY, 9, _moveBarHeight);
            drawBarX += 12;
        }
        if (barLevel >= 3){
            if (isInstinct2){
                Theme.setColor(dc, Theme.FULL_COLOR);
            } else {
                Theme.setColor(dc, Theme.MOST_COLOR);
            }
            dc.fillRectangle(drawBarX, _barY, 9, _moveBarHeight);
            drawBarX += 12;
        }
        if (barLevel >= 4){
            if (isInstinct2){
                Theme.setColor(dc, Theme.FULL_COLOR);
            } else {
                Theme.setColor(dc, Theme.SOME_COLOR);
            }
            dc.fillRectangle(drawBarX, _barY, 9, _moveBarHeight);
            drawBarX += 12;
        }
        if (barLevel >= 5){
            if (isInstinct2){
                Theme.setColor(dc, Theme.FULL_COLOR);
            } else {
                Theme.setColor(dc, Theme.LOW_COLOR);
            }
            dc.fillRectangle(drawBarX, _barY, 9, _moveBarHeight);
        }

        CommonMethods.clearDrawingClip(dc);
    }

}