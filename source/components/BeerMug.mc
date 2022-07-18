using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class BeerMug {

    private const STEPS_PER_BEER = 2500;
    private const MUG_WIDTH      = 17;
    private const MUG_HEIGHT     = 26;
    private const CORNER_RADIUS  = 3;

    private var mugX;
    private var mugY;

    private var mugPoints;

    function initialize(dc){
        // Put it center right
        mugX = dc.getWidth() - 32;
        mugY = (dc.getHeight() / 2) - (MUG_HEIGHT / 2);

        mugPoints = [
                        [mugX - 7, mugY],
                        [mugX + MUG_WIDTH, mugY],
                        [mugX + MUG_WIDTH, mugY + MUG_HEIGHT],
                        [mugX - 7, mugY + MUG_HEIGHT]
                    ];
    }

    function drawOnScreen(dc, info){

        // Get beers earned status via steps
        var qualifyingSteps = getQualifyingSteps(info);
        var beersEarned     = Math.floor(qualifyingSteps / STEPS_PER_BEER).format("%d");     // Whole beers already earned
        var mugLevel        = ((qualifyingSteps % STEPS_PER_BEER) * 100) / STEPS_PER_BEER;     // 0-100 percent

        CommonMethods.setDrawingClip(dc, mugPoints);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);
        
        // Drag main part of mug
        dc.drawRoundedRectangle(mugX,     mugY, MUG_WIDTH,     MUG_HEIGHT,     CORNER_RADIUS);
        dc.drawRoundedRectangle(mugX - 1, mugY, MUG_WIDTH + 2, MUG_HEIGHT + 1, CORNER_RADIUS);

        // Drag handle on left side
        var handleX = mugX - 5;
        var handleY = mugY + 7;
        dc.drawRoundedRectangle(handleX,   handleY,   6, 12, CORNER_RADIUS);
        dc.drawRoundedRectangle(handleX-1, handleY-1, 7, 14, CORNER_RADIUS);

        // Draw beer inside mug, proper amount for how much of next beer earned
        var beerHeight = (MUG_HEIGHT * (mugLevel.toFloat() / 100));
        var beerX = mugX + 1;
        var beerY = mugY + MUG_HEIGHT - beerHeight - 1;
        Theme.setBothColors(dc, ThemeController.BEER_COLOR);

        //System.println("mugLevel = " + mugLevel + "%, beerX = " + beerX + ", beerY = " + beerY + ", beerHeight = " + beerHeight);

        // Bulk of beer via rounded rectangle, but I want the top to be flat not rounded, so the line takes care of that
        dc.fillRoundedRectangle(beerX, beerY, MUG_WIDTH - 2, beerHeight, CORNER_RADIUS - 1);
        dc.drawLine(beerX, beerY, beerX + (MUG_WIDTH - 2), beerY);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);

        // Draw another line at the bottom of the mug for a base
        var baseY = mugY + MUG_HEIGHT - 2;
        dc.drawLine(mugX, baseY, mugX + MUG_WIDTH, baseY);
        baseY = baseY + 1;
        dc.drawLine(mugX, baseY, mugX + MUG_WIDTH, baseY);

        // Last step Draw Num Beers earned, to go inside
        dc.drawText(mugX + 8, adjustMugY(dc, mugY), CommonMethods.getTinyFont(dc), beersEarned, Graphics.TEXT_JUSTIFY_CENTER);

        Theme.resetColors(dc);

        CommonMethods.clearDrawingClip(dc);
    }

    private function adjustMugY(dc, mugY){
        var width = dc.getWidth();
        if (width < 220){
            return mugY + 3;
        } else if (width >= 280) {
            return mugY - 4;
        } else if (width >= 260) {
            return mugY - 2;
        } else {
            return mugY - 1;
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