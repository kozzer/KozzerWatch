using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class SolarStatus {

    // Reference to solar intensity sun icon
    private var _sunIcon;   

    // The screen dimensions
    private var _screenWidth;
    private var _screenHeight;      

    // Sun's size & location
    private var _sunDiameter = 16;    
    private var _center_sunX;
    private var _center_sunY;  

    private var _sunX;
    private var _sunY;    

    // Boundary for clipping
    private var _sunPoints;       


    function initialize(dc) {
        // Load bitmap resource
        _sunIcon = WatchUi.loadResource(Rez.Drawables.SunIcon);

        // dc dimensions
        var _screenWidth  = dc.getWidth();
        var _screenHeight = dc.getHeight();

        // set Sun's location
        _center_sunX = _screenWidth / 2;
        _center_sunY = _screenHeight - 60;

        // Get upper-left location for sun
        _sunX = _center_sunX - 16;
        _sunY = _center_sunY - 15;

        // set boundary for icon, for clipping
        var sunPixelSize = 32;
        _sunPoints = [ 
                        [_sunX, _sunY], 
                        [_sunX + sunPixelSize, _sunY], 
                        [_sunX + sunPixelSize, _sunY + sunPixelSize], 
                        [_sunX, _sunY + sunPixelSize] 
                     ];

    }
  
    function drawOnScreen(dc)
    {  
        // Get system stats object
        var stats = Toybox.System.getSystemStats();
        var solar = stats.solarIntensity;

        // If solar is 0, just return
        if (solar <= 0) {
            return;
        }

        // Update the cliping rectangle to the location of the icon
        CommonMethods.setDrawingClip(dc, _sunPoints);

        // Draw sun
        dc.drawBitmap(_sunX, _sunY, _sunIcon);

        // Draw power level
        Theme.setColor(dc, ThemeController.LOW_COLOR);
        dc.drawText(_center_sunX, _center_sunY - 9, Graphics.FONT_XTINY, solar, Graphics.TEXT_JUSTIFY_CENTER);

        // Clear the clip
        CommonMethods.clearDrawingClip(dc);

        Theme.resetColors(dc);
    }
}