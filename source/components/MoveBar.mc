using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class MoveBar {

    // Move Bar
    private const moveBarHeight = 4;
    private const moveBarWidth = 78;
    private var   barX;
    private var   barY;

    private var barPoints;

    function initialize(dc){
        // Get location of the blue bar
        barX = ((dc.getWidth() / 2) - (moveBarWidth / 2));      // Total 78px wide, so 39px left of center
        barY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 15;

        barPoints = [
                        [barX, barY], 
                        [barX + moveBarWidth, barY], 
                        [barX + moveBarWidth, barY + moveBarHeight], 
                        [barX, barY + moveBarHeight]
                    ];
    }

    function drawOnScreen(dc) {

        // Get Move bar status
        var barLevel = ActivityMonitor.getInfo().moveBarLevel;

        var drawBarX = barX;

        CommonMethods.setDrawingClip(dc, barPoints);

        // Draw bars based on bar level
        if (barLevel >= 1) {
            Theme.setColor(dc, Theme.BLUE_COLOR);
            dc.fillRectangle(drawBarX, barY, 27, moveBarHeight);
            drawBarX += 30;
        }
        if (barLevel >= 2){
            Theme.setColor(dc, Theme.FULL_COLOR);
            dc.fillRectangle(drawBarX, barY, 9, moveBarHeight);
            drawBarX += 12;
        }
        if (barLevel >= 3){
            Theme.setColor(dc, Theme.MOST_COLOR);
            dc.fillRectangle(drawBarX, barY, 9, moveBarHeight);
            drawBarX += 12;
        }
        if (barLevel >= 4){
            Theme.setColor(dc, Theme.SOME_COLOR);
            dc.fillRectangle(drawBarX, barY, 9, moveBarHeight);
            drawBarX += 12;
        }
        if (barLevel >= 5){
            Theme.setColor(dc, Theme.LOW_COLOR);
            dc.fillRectangle(drawBarX, barY, 9, moveBarHeight);
        }

        CommonMethods.clearDrawingClip(dc);
    }

}