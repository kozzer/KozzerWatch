using Toybox.System;
using Toybox.WatchUi;

class BluetoothIcon {

    // Reference to bluetooth icon png
    var iconBitmap;  

    // Icon location and bounding rectangle
    var iconX;     
    var iconY;     
    var iconPoints;                    

    function initialize(dc){
        // Initialize bluetooth icon
        iconBitmap = WatchUi.loadResource(Rez.Drawables.BluetoothIcon);

        // Get location of points for icon location
        iconX      = dc.getWidth() / 2 - 12;
        iconY      = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 24;
        iconPoints = [ [iconX, iconY], [iconX+24, iconY], [iconX+24, iconY+24], [iconX, iconY+24] ];
    }

    // Draw icon onto given dc
    public function drawOnScreen(dc){
        
        // Only do anything if bluetooth is active
        if (System.getDeviceSettings().phoneConnected) {  
 
            // Update the cliping rectangle to the location of the icon
            CommonMethods.setDrawingClip(dc, iconPoints);
            
            // Actually write the icon to the dc
            dc.drawBitmap(iconX, iconY, iconBitmap);

            // Clear the clip
            CommonMethods.clearDrawingClip(dc);
        }
    }
}