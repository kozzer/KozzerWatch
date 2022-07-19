using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class KozzerGoalView extends WatchUi.View {
    private var _goalString;

    // UI colors
    const BACKGROUND_COLOR  = 0x111111;     // Very dark gray 
    const FONT_COLOR        = 0xDEDEDE;     // Light

    // goal is Application.GOAL_TYPE_? enumeration value 
    function initialize(goal) {
        View.initialize();

        _goalString = "GOAL!";

        if(goal == Application.GOAL_TYPE_STEPS) {
            _goalString = "STEPS " + _goalString;
        }
        else if(goal == Application.GOAL_TYPE_FLOORS_CLIMBED) {
            _goalString = "STAIRS " + _goalString;
        }
        else if(goal == Application.GOAL_TYPE_ACTIVE_MINUTES) {
            _goalString = "ACTIVE " + _goalString;
        }
    }

    function onLayout(dc) {
        //Clear any clip that may currently be set by the partial update
        dc.clearClip();
    }

    // Update the clock face graphics during update
    function onUpdate(dc) {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        // Fill the screen with a black rectangle
        dc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
        dc.fillRectangle(0, 0, width, height);

        // Set color for text
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);

        // Draw text
        dc.drawText(width / 2, (height / 4) + 12, Graphics.FONT_SMALL, "You did a good job!", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, (height / 2) - 7, Graphics.FONT_LARGE, _goalString, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, (height * 0.62) + 12, Graphics.FONT_SMALL, "Keep it up!", Graphics.TEXT_JUSTIFY_CENTER);
    }
}