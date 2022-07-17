using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class StepsCount {

    private var screenHeight;

    function initialize(viewHeight) {
        screenHeight = viewHeight;
    }

    function drawOnScreen(dc, info)
    {
        var dataString = info.steps.toString();
        var stepPerc   = ((info.steps * 100) / info.stepGoal).toNumber();

        setStepsDisplayLevelColor(dc, stepPerc);
        var tinyFont = CommonMethods.getTinyFont(dc);
        dc.drawText(14, screenHeight / 2 - Graphics.getFontHeight(tinyFont) / 2, tinyFont, dataString, Graphics.TEXT_JUSTIFY_LEFT);

        Theme.resetColors(dc);
    }

    private function drawStepMilesTotal(dc, info)
    {
        // Daily miles walked based on centimeters traveled
        var milesWalked = (info.distance.toFloat() / 160934).format("%3.1f") + "m";  // 160,934 cm per mile
        var font = CommonMethods.getTinyFont(dc);
        dc.drawText(screenWidth - 14, screenHeight / 2 - Graphics.getFontHeight(font) / 2, font, milesWalked, Graphics.TEXT_JUSTIFY_RIGHT);
    }
 
    
    private function setStepsDisplayLevelColor(dc, perc){
        if (System.getClockTime().hour < 14) {
            // Only show step value colors if >= 2pm
            Theme.resetColors(dc);
        } else if (perc > 100) {
            // Step goal!
            Theme.setColor(dc, Theme.FULL_COLOR);
        } else if (perc > 60) {
            // 60+% of step goal
            Theme.setColor(dc, Theme.MOST_COLOR);
        } else if (perc > 30) {
            // 30-59% step goal
            Theme.setColor(dc, Theme.SOME_COLOR);
        } else if (perc > 0) {
            // 1-29% step goal
            Theme.setColor(dc, Theme.LOW_COLOR);
        } else {
            // 0% - Default to normal font color for 0 steps
            Theme.resetColors(dc);
        }
    }
}