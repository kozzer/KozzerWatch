using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class StepsCount {

    private var screenHeight;
    private var tinyFont;
    private var fontHeight;

    private var stepsX;
    private var stepsY;

    private var stepsPoints;

    function initialize(dc) {
        screenHeight = dc.getHeight();
        tinyFont = CommonMethods.getTinyFont(dc);
        fontHeight = Graphics.getFontHeight(tinyFont);

        stepsX = 14;
        stepsY = (screenHeight / 2) - (fontHeight / 2);
        stepsPoints = [
                        [stepsX, stepsY],
                        [stepsX + 100, stepsY],
                        [stepsX + 100, stepsY + fontHeight],
                        [stepsX, stepsY + fontHeight]
                     ];
    }

    function drawOnScreen(dc, info)
    {
        var dataString = info.steps.toString();
        var stepPerc   = ((info.steps * 100) / info.stepGoal).toNumber();

        setStepsDisplayLevelColor(dc, stepPerc);

        CommonMethods.setDrawingClip(dc, stepsPoints);

        dc.drawText(stepsX, stepsY, tinyFont, dataString, Graphics.TEXT_JUSTIFY_LEFT);

        CommonMethods.clearDrawingClip(dc);

        Theme.resetColors(dc);
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