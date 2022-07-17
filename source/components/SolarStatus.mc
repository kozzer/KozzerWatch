using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class SolarStatus {

    // Reference to solar intensity sun icon
    private var sunIcon;                          


    function initialize() {
        sunIcon = WatchUi.loadResource(Rez.Drawables.SunIcon);
    }
  
    function drawOnScreen(dc)
    {  
        // Get system stats object
        var stats = Toybox.System.getSystemStats();
        var solar = stats.solarIntensity;

        // If solar is 0, just return
        if (solar == 0) {
            return;
        }
        
        // dc dimensions
        var width  = dc.getWidth();
        var height = dc.getHeight();
               
        // Put it above battery status
        var sunDiameter = 16;
        var sunX = width / 2;
        var sunY = height - 60;

        // Draw sun
        dc.drawBitmap(sunX - 16, sunY - 15, sunIcon);

        // Draw power level
        Theme.setColor(dc, ThemeController.LOW_COLOR);
        dc.drawText(sunX, sunY - 9, Graphics.FONT_XTINY, solar, Graphics.TEXT_JUSTIFY_CENTER);

        Theme.resetColors(dc);
    }
}