using Toybox.System;
using Toybox.WatchUi;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class BeerMug {

    private const STEPS_PER_BEER = 2500;
    private const CORNER_RADIUS  = 3;

    private var _isInstinct2;
    private var _mugWidth;      
    private var _mugHeight;     
    private var _mugX;
    private var _mugY;

    private var _mugPoints;

    function initialize(dc){

        setLayoutBasedOnDevice(dc);

        _mugPoints = [
                        [_mugX - 7, _mugY],
                        [_mugX + _mugWidth, _mugY],
                        [_mugX + _mugWidth, _mugY + _mugHeight],
                        [_mugX - 7, _mugY + _mugHeight]
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
        dc.drawRoundedRectangle(_mugX,     _mugY, _mugWidth,     _mugHeight,     CORNER_RADIUS);
        dc.drawRoundedRectangle(_mugX - 1, _mugY, _mugWidth + 2, _mugHeight + 1, CORNER_RADIUS);

        // Drag handle on left side
        drawHandle(dc);

        // Draw beer inside mug, proper amount for how much of next beer earned
        var beerHeight = (_mugHeight * (mugLevel.toFloat() / 100));
        var beerX = _mugX + 1;
        var beerY = _mugY + _mugHeight - beerHeight - 1;
        Theme.setBothColors(dc, ThemeController.BEER_COLOR);

        //System.println("mugLevel = " + mugLevel + "%, beerX = " + beerX + ", beerY = " + beerY + ", beerHeight = " + beerHeight);

        // Bulk of beer via rounded rectangle, but I want the top to be flat not rounded, so the line takes care of that
        dc.fillRoundedRectangle(beerX, beerY, _mugWidth - 2, beerHeight, CORNER_RADIUS - 1);
        dc.drawLine(beerX, beerY, beerX + (_mugWidth - 2), beerY);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);

        // Draw another line at the bottom of the mug for a base
        var baseY = _mugY + _mugHeight - 2;
        dc.drawLine(_mugX, baseY, _mugX + _mugWidth, baseY);
        baseY = baseY + 1;
        dc.drawLine(_mugX, baseY, _mugX + _mugWidth, baseY);

        // Last step Draw Num Beers earned, to go inside
        var beersEarnedNumX;
        if (_isInstinct2){
            beersEarnedNumX = _mugX + 12;
        } else {
            beersEarnedNumX = _mugX + 8;
        }

        dc.drawText(beersEarnedNumX, adjustYForText(dc, _mugY), CommonMethods.getBeersEarnedFont(dc), beersEarned, Graphics.TEXT_JUSTIFY_CENTER);

        Theme.resetColors(dc);

        CommonMethods.clearDrawingClip(dc);
    }

    private function setLayoutBasedOnDevice(dc){
        //var app = Application.getApp();
        _isInstinct2 = Application.Properties.getValue("IsInstinct2");
        if (_isInstinct2){
            _mugWidth   = 26;
            _mugHeight  = 39;
            _mugX       = dc.getWidth() - 38;
            _mugY       = 8;
        } else {
            _mugWidth  = 17;
            _mugHeight = 26;
            _mugX      = dc.getWidth() - 32;
            _mugY      = (dc.getHeight() / 2) - (_mugHeight / 2);
        }
    }

    private function drawHandle(dc){
        // Drag handle on left side
        var handleX = _mugX - 5;
        var handleY = _mugY + 7;

        var handleWidth;
        var handleHeight;

        if(_isInstinct2){
            handleWidth = 6;
            handleHeight = 25;
            dc.drawRoundedRectangle(handleX-2, handleY-1, handleWidth+1, handleHeight+1, CORNER_RADIUS);
        } else {
            handleWidth = 6;
            handleHeight = 12;
        }

        dc.drawRoundedRectangle(handleX,   handleY,   handleWidth,   handleHeight,   CORNER_RADIUS);
        dc.drawRoundedRectangle(handleX-1, handleY-1, handleWidth+1, handleHeight+1, CORNER_RADIUS);
    }

    private function adjustYForText(dc, _mugY){
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