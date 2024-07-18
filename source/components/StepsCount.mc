using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;
using Toybox.Time.Gregorian;

using ThemeController as Theme;

class StepsCount {

    private var _screenHeight;
    private var _stepsFont;
    private var _fontHeight;

    private var _stepsX;
    private var _stepsY;

    private var _stepsPoints;

    function initialize(dc) {

        var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$ $3$:$4$:$5$", [greg.month, greg.day, greg.hour, greg.min.format("%02d"), greg.sec.format("%02d")]);
        System.println(dateStr);

        System.println("*** in StepsCount.initialize(dc) ***");

        _screenHeight = dc.getHeight();
        _stepsFont    = CommonMethods.getTinyFont(dc);
        _fontHeight   = Graphics.getFontHeight(_stepsFont);

        var isInstinct2 = Application.Properties.getValue("IsInstinct2");
        if (isInstinct2){
            _stepsFont = Graphics.FONT_SMALL;
        } else {
            _stepsFont = CommonMethods.getTinyFont(dc);
        }

        _stepsX = 14;

        if (isInstinct2){
            _stepsY = (dc.getHeight() / 2) - 8;
        } else {
            _stepsY = (_screenHeight / 2) - (_fontHeight / 2);
        }
        
        _stepsPoints = [
                        [_stepsX, _stepsY],
                        [_stepsX + 100, _stepsY],
                        [_stepsX + 100, _stepsY + _fontHeight],
                        [_stepsX, _stepsY + _fontHeight]
                     ];

        dateStr = Lang.format("$1$ $2$ $3$:$4$:$5$", [greg.month, greg.day, greg.hour, greg.min.format("%02d"), greg.sec.format("%02d")]);
        System.println(dateStr);
        System.println("*** end of StepsCount.initialize(dc) ***");
    }

    function drawOnScreen(dc, info)
    {
        try {

            var displayString = CommonMethods.getFormattedStringForNumber(info.steps);
            var stepPerc      = ((info.steps * 100) / info.stepGoal).toNumber();

            setStepsDisplayLevelColor(dc, stepPerc);

            CommonMethods.setDrawingClip(dc, _stepsPoints);

            dc.drawText(_stepsX, _stepsY, _stepsFont, displayString, Graphics.TEXT_JUSTIFY_LEFT);

            CommonMethods.clearDrawingClip(dc);

            Theme.resetColors(dc);

        } catch (ex instanceof Toybox.Lang.Exception) {

            var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            var dateStr = Lang.format("$1$ $2$ $3$:$4$:$5$", [greg.month, greg.day, greg.hour, greg.min.format("%02d"), greg.sec.format("%02d")]);
           
            System.println("***** ERROR IN StepsCount.drawOnScreen(dc, info) ******");
            System.println(dateStr);
            System.println(ex.getErrorMessage());
            ex.printStackTrace();
        }
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