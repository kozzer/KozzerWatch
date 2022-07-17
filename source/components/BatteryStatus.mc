using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class BatteryStatus {

    // Graphic Dimensions - hard-coded
    private const batteryWidth  = 32;
    private const batteryHeight = 16;
    private const batteryRadius = 3;

    function initialize(){
        // Nothing here
    }

    // Draw battery icon with % indicated
    function drawOnScreen(dc) {   
    
        // Get battery % from system
        var batteryPerc = (System.getSystemStats().battery + 0.5).toNumber();
        
        // dc dimensions
        var width  = dc.getWidth();
        var height = dc.getHeight();
               
        // Put it bottom center
        var batteryX = ((width / 2)  - (batteryWidth / 2)) - (batteryHeight / 12);
        var batteryY = (height - 28) - (batteryHeight / 2);

        // Reset colors to font / background
        Theme.resetColors(dc);
        
        // Draw outline
        dc.drawRoundedRectangle(batteryX, batteryY, batteryWidth, batteryHeight, batteryRadius);

        // Draw positive-end nub (on right)
        dc.fillRectangle((batteryX + batteryWidth), (batteryY + (batteryHeight / 4)), (batteryHeight / 6), (batteryHeight / 2)); 

        // Change to color-coded fill
        setBatteryDisplayLevelColor(dc, batteryPerc);
        
        // Draw filled (only fill based on %)
        dc.fillRoundedRectangle(batteryX + 2, batteryY + 2, ((batteryWidth * batteryPerc) / 100) - 4, batteryHeight - 4, batteryRadius - 1);
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