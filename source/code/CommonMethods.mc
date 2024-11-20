using Toybox.System;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Time.Gregorian;

using ThemeController as Theme;

module CommonMethods {

    // App settings
    var useLightTheme;
    var showSolarIntensity;

    // Settings names
    const SETTING_ID_LIGHT_THEME = "LightThemeActive";
    const SETTING_ID_SHOW_SOLAR  = "ShowSolarIntensity";

    // Clip for partial updates, so only pixels where second hand is will actually be changed
    var _curClip;    

    // Called in app's constructor, and also when settings change
    function populateAndApplyAppSettings(){

        //var app = Application.getApp();

        // Re-read properties from XML file (only set solar to true if device supports and setting is true)
        useLightTheme = Application.Properties.getValue(SETTING_ID_LIGHT_THEME);

        showSolarIntensity = Toybox.System.Stats has :solarIntensity 
                                && Toybox.System.getSystemStats().solarIntensity != null 
                                && Application.Properties.getValue(SETTING_ID_SHOW_SOLAR);

        // Set theme to current value
        Theme.setTheme(useLightTheme);

        Toybox.System.println("\nSettings:\n\tLight Theme:\t" + useLightTheme + "\n\tShow Solar:\t" + showSolarIntensity + "\n");
    }   

    function setPropertyValue(key, value){
        //var app = Application.getApp();
        Application.Properties.setValue(key, value);
    }                      

    // Draw the watch face background onto the given draw context
    function writeBufferToDisplay(screenDc, screenBuffer) { 
        // Write the entire display buffer to the display
        screenDc.drawBitmap(0, 0, screenBuffer);    
    }

    function resetColorsForRendering(dc) {
        dc.setColor(ThemeController.FONT_COLOR, Graphics.COLOR_TRANSPARENT);
    }

    function getTinyFont(dc){
        var width = dc.getWidth();
        if (width < 240){
            return Graphics.FONT_XTINY;
        } else {
            return Graphics.FONT_TINY;
        }
    }

    function getBeersEarnedFont(dc){
        //var app = Application.getApp();
        var isInstinct2 = Application.Properties.getValue("IsInstinct2");
        var width = dc.getWidth();

        if (isInstinct2){
            return Graphics.FONT_LARGE;
        } else if (width < 240){
            return Graphics.FONT_XTINY;
        } else {
            return Graphics.FONT_TINY;
        }

    }

    function printExceptionToConsole(ex, message){

            var greg    = Gregorian.info(Toybox.Time.now(), Toybox.Time.FORMAT_MEDIUM);
            var dateStr = Toybox.Lang.format("$1$ $2$ $3$:$4$:$5$", [greg.month, greg.day, greg.hour, greg.min.format("%02d"), greg.sec.format("%02d")]);

            Toybox.System.println(message);
            Toybox.System.println(dateStr);
            Toybox.System.println("\t\tMessage: " + ex.getErrorMessage());
            ex.printStackTrace();

    }

    // Set the clip based on the passed-in set of coordinates
    function setDrawingClip(dc, rectanglePoints) {
        // Clear existing clip
        dc.clearClip();
    
        // Update the cliping rectangle to polygon
        _curClip        = getBoundingBox(rectanglePoints);
        var bboxWidth  = _curClip[1][0] - _curClip[0][0] + 1;
        var bboxHeight = _curClip[1][1] - _curClip[0][1] + 1;
        
        // Set new clip with new coordinates
        dc.setClip(_curClip[0][0], _curClip[0][1], bboxWidth, bboxHeight);        
    }

    // Clear drawing clip
    function clearDrawingClip(dc) {
        dc.clearClip();
        _curClip = null;
    }

    // Compute a bounding box from the passed in points
    function getBoundingBox(points) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }

    public function drawLabelAndRecangle(dc, x, y, label, color){

        var rectanglePoints = [
                [x - 60, y],
                [x + 60, y],
                [x + 60, y + 69],
                [x - 60, y + 69]
        ];

        CommonMethods.setDrawingClip(dc, rectanglePoints);

        // Colored outline rect
        Theme.setColor(dc, color);
        dc.fillRoundedRectangle(x - 60, y, 120, 40, 4);

        // Black "fill" inside rect
        Theme.setColor(dc, 0x000000);
        dc.fillRoundedRectangle(x - 58, y + 2, 116, 36, 4);

        // Colored label text
        Theme.setColor(dc, color);
        dc.drawText(x, y + 38, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        Theme.resetColors(dc);
        CommonMethods.clearDrawingClip(dc);
    }

    function convertToFahrenheit(degreesCelcius){

        var temp = (degreesCelcius * 9) / 5 + 32;
        var str = temp.toString() as Toybox.Lang.String;
        var formattedString = "";

        for (var i = 0; i < str.length(); i++){
            var curChar = str.substring(i, i + 1);
            if (curChar.equals(".")){
                break;
            }
            formattedString = formattedString + curChar;
        }
        return formattedString;
    }


    public function getFormattedStringForNumber(num){

        var numString = num.toString() as Toybox.Lang.String;
        var stringLength = numString.length();
        var formattedString = "";

        var maxIndex = stringLength - 1;
        for (var i = maxIndex; i >= 0; i--) {

            if (((stringLength - i) % 3 == 1) && i < maxIndex){
                formattedString = "," + formattedString;
            }

            var curChar = numString.substring(i, i + 1);
            formattedString = curChar + formattedString;
        }

        return formattedString;
    }


}