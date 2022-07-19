using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class StepsCount {

    private var _screenHeight;
    private var _tinyFont;
    private var _fontHeight;

    private var _stepsX;
    private var _stepsY;

    private var _stepsPoints;

    function initialize(dc) {
        _screenHeight = dc.getHeight();
        _tinyFont     = CommonMethods.getTinyFont(dc);
        _fontHeight   = Graphics.getFontHeight(_tinyFont);

        _stepsX = 14;
        _stepsY = (_screenHeight / 2) - (_fontHeight / 2);
        _stepsPoints = [
                        [_stepsX, _stepsY],
                        [_stepsX + 100, _stepsY],
                        [_stepsX + 100, _stepsY + _fontHeight],
                        [_stepsX, _stepsY + _fontHeight]
                     ];
    }

    function drawOnScreen(dc, info)
    {
        var dataString = info.steps.toString();
        var stepPerc   = ((info.steps * 100) / info.stepGoal).toNumber();

        setStepsDisplayLevelColor(dc, stepPerc);

        CommonMethods.setDrawingClip(dc, _stepsPoints);

        dc.drawText(_stepsX, _stepsY, _tinyFont, dataString, Graphics.TEXT_JUSTIFY_LEFT);

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