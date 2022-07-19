using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class BatteryStatus {

    // Graphic Dimensions - hard-coded
    private const _batteryWidth  = 32;
    private const _batteryHeight = 16;
    private const _batteryRadius = 3;

    // Battery screen location
    private var _batteryX;
    private var _batteryY;

    private var batteryPoints;

    function initialize(dc){
        // Put it bottom center
        _batteryX = ((dc.getWidth() / 2)  - (_batteryWidth / 2)) - (_batteryHeight / 12);
        _batteryY = (dc.getHeight() - 28) - (_batteryHeight / 2);

        batteryPoints = [
                            [_batteryX, _batteryY],
                            [_batteryX + _batteryWidth + 2, _batteryY],
                            [_batteryX + _batteryWidth + 2, _batteryY + _batteryHeight],
                            [_batteryX, _batteryY + _batteryHeight]
                        ];
    }

    // Draw battery icon with % indicated
    function drawOnScreen(dc) {   
    
        // Get battery % from system
        var batteryPerc = (System.getSystemStats().battery + 0.5).toNumber();

        // Reset colors to font / background
        Theme.resetColors(dc);

        CommonMethods.setDrawingClip(dc, batteryPoints);
        
        // Draw outline
        dc.drawRoundedRectangle(_batteryX, _batteryY, _batteryWidth, _batteryHeight, _batteryRadius);

        // Draw positive-end nub (on right)
        dc.fillRectangle((_batteryX + _batteryWidth), (_batteryY + (_batteryHeight / 4)), (_batteryHeight / 6), (_batteryHeight / 2)); 

        // Change to color-coded fill
        setBatteryDisplayLevelColor(dc, batteryPerc);
        
        // Draw filled (only fill based on %)
        dc.fillRoundedRectangle(_batteryX + 2, _batteryY + 2, ((_batteryWidth * batteryPerc) / 100) - 4, _batteryHeight - 4, _batteryRadius - 1);
 
        CommonMethods.clearDrawingClip(dc);
    }

    private function setBatteryDisplayLevelColor(dc, perc){
        if (perc > 40) {
            Theme.setColor(dc, Theme.FULL_COLOR);
        } else if (perc > 30) {
            Theme.setColor(dc, Theme.MOST_COLOR);
        } else if (perc > 20) {
            Theme.setColor(dc, Theme.SOME_COLOR);
        } else { 
            Theme.setColor(dc, Theme.LOW_COLOR);
        } 
    }

}