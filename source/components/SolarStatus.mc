using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class SolarStatus {

    // Reference to solar intensity sun icon
    private var sunIcon;   

    // The screen dimensions
    private var screenWidth;
    private var screenHeight;      

    // Sun's size & location
    private var sunDiameter = 16;    
    private var centerSunX;
    private var centerSunY;  

    private var sunX;
    private var sunY;    

    // Boundary for clipping
    private var sunPoints;       


    function initialize(dc) {
        // Load bitmap resource
        sunIcon = WatchUi.loadResource(Rez.Drawables.SunIcon);

        // dc dimensions
        var screenWidth  = dc.getWidth();
        var screenHeight = dc.getHeight();

        // set Sun's location
        centerSunX = screenWidth / 2;
        centerSunY = screenHeight - 60;

        // Get upper-left location for sun
        sunX = centerSunX - 16;
        sunY = centerSunY - 15;

        // set boundary for icon, for clipping
        var sunPixelSize = 32;
        sunPoints = [ 
                        [sunX, sunY], 
                        [sunX + sunPixelSize, sunY], 
                        [sunX + sunPixelSize, sunY + sunPixelSize], 
                        [sunX, sunY + sunPixelSize] 
                    ];

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

        // Update the cliping rectangle to the location of the icon
        CommonMethods.setDrawingClip(dc, sunPoints);

        // Draw sun
        dc.drawBitmap(sunX, sunY, sunIcon);

        // Draw power level
        Theme.setColor(dc, ThemeController.LOW_COLOR);
        dc.drawText(centerSunX, centerSunY - 9, Graphics.FONT_XTINY, solar, Graphics.TEXT_JUSTIFY_CENTER);

        // Clear the clip
        CommonMethods.clearDrawingClip(dc);

        Theme.resetColors(dc);
    }
}