using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class BeerMug {

    private const STEPS_PER_BEER = 2500;
    private const MUG_WIDTH      = 17;
    private const MUG_HEIGHT     = 26;
    private const CORNER_RADIUS  = 3;

    private var _mugX;
    private var _mugY;

    private var _mugPoints;

    function initialize(dc){
        // Put it center right
        _mugX = dc.getWidth() - 32;
        _mugY = (dc.getHeight() / 2) - (MUG_HEIGHT / 2);

        _mugPoints = [
                        [_mugX - 7, _mugY],
                        [_mugX + MUG_WIDTH, _mugY],
                        [_mugX + MUG_WIDTH, _mugY + MUG_HEIGHT],
                        [_mugX - 7, _mugY + MUG_HEIGHT]
                    ];
    }

    function drawOnScreen(dc, info){

        // Get beers earned status via steps
        var qualifyingSteps = getQualifyingSteps(info);
        var beersEarned     = Math.floor(qualifyingSteps / STEPS_PER_BEER).format("%d");     // Whole beers already earned
        var mugLevel        = ((qualifyingSteps % STEPS_PER_BEER) * 100) / STEPS_PER_BEER;     // 0-100 percent

        CommonMethods.setDrawingClip(dc, _mugPoints);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);
        
        // Drag main part of mug
        dc.drawRoundedRectangle(_mugX,     _mugY, MUG_WIDTH,     MUG_HEIGHT,     CORNER_RADIUS);
        dc.drawRoundedRectangle(_mugX - 1, _mugY, MUG_WIDTH + 2, MUG_HEIGHT + 1, CORNER_RADIUS);

        // Drag handle on left side
        var handleX = _mugX - 5;
        var handleY = _mugY + 7;
        dc.drawRoundedRectangle(handleX,   handleY,   6, 12, CORNER_RADIUS);
        dc.drawRoundedRectangle(handleX-1, handleY-1, 7, 14, CORNER_RADIUS);

        // Draw beer inside mug, proper amount for how much of next beer earned
        var beerHeight = (MUG_HEIGHT * (mugLevel.toFloat() / 100));
        var beerX = _mugX + 1;
        var beerY = _mugY + MUG_HEIGHT - beerHeight - 1;
        Theme.setBothColors(dc, ThemeController.BEER_COLOR);

        //System.println("mugLevel = " + mugLevel + "%, beerX = " + beerX + ", beerY = " + beerY + ", beerHeight = " + beerHeight);

        // Bulk of beer via rounded rectangle, but I want the top to be flat not rounded, so the line takes care of that
        dc.fillRoundedRectangle(beerX, beerY, MUG_WIDTH - 2, beerHeight, CORNER_RADIUS - 1);
        dc.drawLine(beerX, beerY, beerX + (MUG_WIDTH - 2), beerY);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);

        // Draw another line at the bottom of the mug for a base
        var baseY = _mugY + MUG_HEIGHT - 2;
        dc.drawLine(_mugX, baseY, _mugX + MUG_WIDTH, baseY);
        baseY = baseY + 1;
        dc.drawLine(_mugX, baseY, _mugX + MUG_WIDTH, baseY);

        // Last step Draw Num Beers earned, to go inside
        dc.drawText(_mugX + 8, adjust_mugY(dc, _mugY), CommonMethods.getTinyFont(dc), beersEarned, Graphics.TEXT_JUSTIFY_CENTER);

        Theme.resetColors(dc);

        CommonMethods.clearDrawingClip(dc);
    }

    private function adjust_mugY(dc, _mugY){
        var width = dc.getWidth();
        if (width < 220){
            return _mugY + 3;
        } else if (width >= 280) {
            return _mugY - 4;
        } else if (width >= 260) {
            return _mugY - 2;
        } else {
            return _mugY - 1;
        }
    }


    private function getQualifyingSteps(info){
        // The first 10,000 steps don't count -- don't be lazy!
        var qualifyingSteps = info.steps - info.stepGoal;
        return qualifyingSteps >= 0 ? qualifyingSteps : 0;
    }

    private function setMugForeColor(dc, info){
        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        if (info.steps > info.stepGoal){
            Theme.setColor(dc, Theme.MUG_COLOR);
        } else {
            Theme.setColor(dc, Theme.FADED_MUG_COLOR);
        }
    }


}