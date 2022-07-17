using Toybox.System;
using Toybox.WatchUi;

class BluetoothIcon {

    // Reference to bluetooth icon png
    var iconBitmap;                      

    function initialize(){
        // Initialize bluetooth icon
        iconBitmap = WatchUi.loadResource(Rez.Drawables.BluetoothIcon);
    }

    // Draw icon onto given dc
    public function drawOnScreen(dc){

        // Only do anything if bluetooth is active
        if (System.getDeviceSettings().phoneConnected) {  
            
            // Get location of points for icon location
            var iconX = dc.getWidth() / 2 - 12;
            var iconY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 24;
            var iconPoints = [ [iconX, iconY], [iconX+24, iconY], [iconX+24, iconY+24], [iconX, iconY+24] ];
        
            // Update the cliping rectangle to the location of the icon
            CommonMethods.setDrawingClip(dc, iconPoints);
            
            // Actually write the icon to the dc
            dc.drawBitmap(iconX, iconY, iconBitmap);

            // Clear the clip
            CommonMethods.clearDrawingClip(dc);
        }
    }
}