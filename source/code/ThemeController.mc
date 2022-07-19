using Toybox.Graphics;
using Toybox.WatchUi;

module ThemeController {

    // Boolean flag indicating which theme
    var _useLightTheme;

    // UI color palette
    var BACKGROUND_COLOR;  
    var FONT_COLOR;        
    var MUG_COLOR;         
    var FADED_MUG_COLOR;   
    var RED_COLOR;         
    var CLOCK_HAND_LINE;   
    var BLUE_COLOR;        
    var FULL_COLOR;        
    var MOST_COLOR;        
    var SOME_COLOR;        
    var LOW_COLOR;         
    var BEER_COLOR;  

    function setTheme(lightTheme){
        
        // Save new value
        _useLightTheme = lightTheme;

        // Colors common to both themes
        MUG_COLOR        = 0x353225;     // Amberish-gray
        FADED_MUG_COLOR  = 0x777777;     // Medium gray
        CLOCK_HAND_LINE  = 0x808080;     // Gray
        RED_COLOR        = 0xFF0000;     // Red
        LOW_COLOR        = RED_COLOR;

        if (_useLightTheme){

            // Light theme (default)
            BACKGROUND_COLOR  = 0xDEDEDE;     // Light gray 
            FONT_COLOR        = 0x111111;     // Very dark gray 
            BLUE_COLOR        = 0x0026FF;     // Blue
            FULL_COLOR        = 0x00C44E;     // Green
            MOST_COLOR        = 0xDBCC00;     // Dark Yellow
            SOME_COLOR        = 0xFF6A00;     // Orange
            BEER_COLOR        = 0xFF9328;     // Amber

        } else {

            // Dark theme
            BACKGROUND_COLOR  = 0x111111;     // Very dark gray 
            FONT_COLOR        = 0xDEDEDE;     // Very light gray 
            BLUE_COLOR        = 0x1166FF;     // Blue
            FULL_COLOR        = 0x00FF00;     // Green
            MOST_COLOR        = 0xFFFF00;     // Yellow
            SOME_COLOR        = 0xFF9900;     // Orange
            BEER_COLOR        = SOME_COLOR;
        }
    }   

    // Sets main forecolor/fontcolor to passed-in value
    function setColor(dc, newColor) {
        dc.setColor(newColor, Graphics.COLOR_TRANSPARENT);
    }

    // Sets both forecolor and backcolor to passed-in value
    function setBothColors(dc, newColor) {
        dc.setColor(newColor, newColor);
    }

    // Resets to main forecolor/fontcolor
    function resetColors(dc) {
        setColor(dc, FONT_COLOR);
    }

}