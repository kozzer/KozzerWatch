using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class MoveBar {

    // Move Bar
    private const moveBarHeight = 4;

    function initialize(){
        // Nothing here
    }

    function drawOnScreen(dc) {
        // Get location of the blue bar
        var barX = dc.getWidth() / 2 - 39;      // Total 78px wide, so 39px left of center
        var barY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 15;

        // Get Move bar status
        var barLevel = ActivityMonitor.getInfo().moveBarLevel;

        // Draw bars based on bar level
        if (barLevel >= 1) {
            Theme.setColor(dc, Theme.BLUE_COLOR);
            dc.fillRectangle(barX, barY, 27, moveBarHeight);
            barX += 30;
        }
        if (barLevel >= 2){
            Theme.setColor(dc, Theme.FULL_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 3){
            Theme.setColor(dc, Theme.MOST_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 4){
            Theme.setColor(dc, Theme.SOME_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 5){
            Theme.setColor(dc, Theme.LOW_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
        }
    }

}