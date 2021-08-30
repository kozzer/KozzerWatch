using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application.Storage as Storage;

var partialUpdatesAllowed = false;          // Outside class so the Delegate class below can access the value    

class KozzerWatchView extends WatchUi.WatchFace
{
    // Application properties
    var useLightTheme      = false;
    var notifyOnBeerEarned = false;

    // General class-level fields
    var isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var bluetoothIcon;                      // Reference to bluetooth icon png
    var screenBuffer;                       // Buffer for the entire screen
    var curClip;                            // Clip for partial updates, so only pixels where second hand is will actually be changed
    var screenCenterPoint;                  // Center x,y point of screen
    var fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()
    
    // Battery icon dimensions - hard-coded
    const batteryWidth  = 32;
    const batteryHeight = 16;
    const batteryRadius = 3;
    const moveBarHeight = 4;

    // UI colors -- default to light theme
    var BACKGROUND_COLOR  = 0xDEDEDE;     // Light gray 
    var FONT_COLOR        = 0x111111;     // Very dark gray 
    var MUG_COLOR         = 0xAA9977;     // Amberish-gray
    var FADED_MUG_COLOR   = 0x999999;     // Medium gray
    var RED_COLOR         = 0xFF0000;     // Red
    var CLOCK_HAND_LINE   = 0x808080;
    var BLUE_COLOR        = 0x0055FF;     // Blue
    var FULL_COLOR        = 0x009900;     // Green
    var MOST_COLOR        = 0xB3E500;     // Yellow-Green
    var SOME_COLOR        = 0xFF4400;     // Orange
    var LOW_COLOR         = 0xFF0000;     // Red
    var BEER_COLOR        = 0xFF9328;     // Amber

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        fullScreenRefresh     = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate ); // Will be set to true until KozzerWatchViewDelegate.onPowerBudgetExceeded() is fired
    
        // Get settings - then set theme 
        populateAppSettings();
        setTheme();
    }

    function populateAppSettings(){
        // useLightTheme      = Storage.getValue("LightThemeActive");
        // notifyOnBeerEarned = Storage.getValue("NotifyOnBeerEarned");

        System.println("light: " + useLightTheme + ", nofify: " + notifyOnBeerEarned);
    }

    function setTheme(){

        // Colors common to both themes
        MUG_COLOR        = 0x353225;     // Amberish-gray
        FADED_MUG_COLOR  = 0x777777;     // Medium gray
        CLOCK_HAND_LINE  = 0x808080;     // Gray
        RED_COLOR        = 0xFF0000;     // Red
        LOW_COLOR        = RED_COLOR;

        if (useLightTheme){

            // Light theme (default)
            BACKGROUND_COLOR  = 0xDEDEDE;     // Light gray 
            FONT_COLOR        = 0x111111;     // Very dark gray 
            BLUE_COLOR        = 0x0055FF;     // Blue
            FULL_COLOR        = 0x00AA99;     // Green
            MOST_COLOR        = 0x99CC00;     // Dark Yellow
            SOME_COLOR        = 0xFF4400;     // Orange
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

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Initialize bluetooth icon
        bluetoothIcon = WatchUi.loadResource(Rez.Drawables.BluetoothIcon);

        // Set up buffer for whole screen
        screenBuffer = new Graphics.BufferedBitmap({ 
            :width   => dc.getWidth(), 
            :height  => dc.getHeight() });

        // Clear any clip
        clearDrawingClip(dc);

        // Set center point of watchface
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // Handle the full screen refresh/update event, called once per minute or upon request
    function onUpdate(dc) {

        // Set an alias for the passed-in screen dc for clarity
        var screenDc     = dc;
        var screenWidth  = screenDc.getWidth();
        var screenHeight = screenDc.getHeight();
    
        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        // Clear the clip
        clearDrawingClip(screenDc);
        
        // Draw background color to screen buffer
        var bufferDc = screenBuffer.getDc();
        bufferDc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
        bufferDc.fillRectangle(0, 0, bufferDc.getWidth(), bufferDc.getHeight());

        // Reset colors for rendering our info items (font, background)
        resetColorsForRendering(bufferDc);
        
        // Draw the date on the top
        drawDateString(bufferDc, screenWidth / 2, 14);

        // Draw move bar under date string
        drawMoveBar(bufferDc);

        // Battery - Draw the battery status
        drawBatteryStatus(bufferDc);

        // Get activity monitor info for steps data
        var stepsInfo = ActivityMonitor.getInfo();
               
        // Daily Steps 
        drawNumberOfStepsText(bufferDc, stepsInfo, screenHeight);

        // Daily Miles 
        // Commented this out to be replaced by beers earned
        // drawStepMilesTotal(bufferDc, info);
 
        // Draw beers earned + mug
        drawBeersEarned(bufferDc, stepsInfo);

        // Always output the offscreen buffer to the main display in onUpdate() - once per minute
        writeBufferToDisplay(screenDc, screenBuffer);

        // Check bluetooth status and write icon appropriately
        setBluetoothIcon(screenDc);

        // Draw the clock - ticks around edge, hour hand, minute hand, center of clock (second hand handled below)
        drawClock(screenDc);

        // Only draw the second hand if partial updates are currently allowed, OR if the watch is awake
        if (partialUpdatesAllowed) {
            // Partial update draws second hand and bluetooth icon
            onPartialUpdate(screenDc);
        } else if (isAwake) {
            // If awake & partial updates not allowed draw second hand 
            drawSecondHand(screenDc);
        }

        fullScreenRefresh = false;
    }


    // Handle the partial update event - 1/second, write to buffer not screen
    //  This method only really does the second hand using clipping
    function onPartialUpdate(dc) {

        // Only write buffer if not coming from onUpdate(), since writeBufferToDisplay() is already called there
        if(!fullScreenRefresh) {

            // Re-write buffer to display 
            writeBufferToDisplay(dc, screenBuffer);

            // If active, draw icon
            setBluetoothIcon(dc);

            // Now draw clock over the top of any bt icon (uses clipping)
            drawClock(dc);        
        }

        // Draw second hand and bluetooth icon if connected
        drawSecondHand(dc);
    }
   
    // Draw the date string into the provided buffer at the specified location
    private function drawDateString(dc, x, y) {
        var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);       // Greg is 16th century new hotness, Julian is old and busted
        var dateStr = Lang.format("$1$ $2$", [greg.month, greg.day]);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawMoveBar(dc){
        // Get location of the blue bar
        var barX = dc.getWidth() / 2 - 39;      // Total 78px wide, so 39px left of center
        var barY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 15;

        // Get Move bar status
        var barLevel = ActivityMonitor.getInfo().moveBarLevel;

        // Draw bars based on bar level
        if (barLevel >= 1) {
            dc.setColor(BLUE_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, 27, moveBarHeight);
            barX += 30;
        }
        if (barLevel >= 2){
            dc.setColor(FULL_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 3){
            dc.setColor(MOST_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 4){
            dc.setColor(SOME_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 5){
            dc.setColor(LOW_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
        }
    }
    
    // Draw icon onto given dc
    private function setBluetoothIcon(dc){

        // Only do anything if bluetooth is active
        if (System.getDeviceSettings().phoneConnected) {  
            
            // Get location of points for icon location
            var iconX = dc.getWidth() / 2 - 12;
            var iconY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 24;
            var iconPoints = [ [iconX, iconY], [iconX+24, iconY], [iconX+24, iconY+24], [iconX, iconY+24] ];
        
            // Update the cliping rectangle to the location of the icon
            setDrawingClip(dc, iconPoints);
            
            // Actually write the icon to the dc
            dc.drawBitmap(iconX, iconY, bluetoothIcon);

            // Clear the clip
            clearDrawingClip(dc);
        }
    }

    private function drawNumberOfStepsText(dc, info, screenHeight)
    {
        var dataString = info.steps.toString();
        var stepPerc   = ((info.steps * 100) / info.stepGoal).toNumber();

        setStepsDisplayLevelColor(dc, stepPerc);
        dc.drawText(14, screenHeight / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_LEFT);
        resetColorsForRendering(dc);
    }

    private function drawStepMilesTotal(dc, info)
    {
        // Daily miles walked based on centimeters traveled
        var milesWalked = (info.distance.toFloat() / 160934).format("%3.1f") + "m";  // 160,934 cm per mile
        dc.drawText(screenWidth - 14, screenHeight / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, milesWalked, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    // Draw battery icon with % indicated
    private function drawBatteryStatus(dc) {   
    
        // Get battery % from system
        var batteryPerc = (System.getSystemStats().battery + 0.5).toNumber();
        
        // dc dimensions
        var width  = dc.getWidth();
        var height = dc.getHeight();
               
        // Put it bottom center
        var batteryX = ((width / 2)  - (batteryWidth / 2)) - (batteryHeight / 12);
        var batteryY = (height - 28) - (batteryHeight / 2);

        // Reset colors to font / background
        resetColorsForRendering(dc);
        
        // Draw outline
        dc.drawRoundedRectangle(batteryX, batteryY, batteryWidth, batteryHeight, batteryRadius);

        // Draw positive-end nub (on right)
        dc.fillRectangle((batteryX + batteryWidth), (batteryY + (batteryHeight / 4)), (batteryHeight / 6), (batteryHeight / 2)); 

        // Change to color-coded fill
        setBatteryDisplayLevelColor(dc, batteryPerc);
        
        // Draw filled (only fill based on %)
        dc.fillRoundedRectangle(batteryX + 2, batteryY + 2, ((batteryWidth * batteryPerc) / 100) - 4, batteryHeight - 4, batteryRadius - 1);
    }

    // Draw beer mug, with right level of beer
    private function drawBeersEarned(dc, info){

        // Get beers earned status via steps
        var qualifyingSteps = getQualifyingSteps(info);
        var stepsPerBeer    = 2500;
        var beersEarned     = Math.floor(qualifyingSteps / stepsPerBeer).format("%d");     // Whole beers already earned
        var mugLevel        = ((qualifyingSteps % stepsPerBeer) * 100) / stepsPerBeer;     // 0-100 percent

        // dc dimensions
        var width  = dc.getWidth();
        var height = dc.getHeight();

        // Use battery size as basis for mug size (X / Y flipped)
        var mugWidth  = batteryHeight + 1;
        var mugHeight = batteryWidth - 6;

        // Put it center right
        var mugX = width - 32;
        var mugY = (height / 2) - (mugHeight / 2);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);
        
        // Drag main part of mug
        dc.drawRoundedRectangle(mugX,     mugY, mugWidth,     mugHeight,     batteryRadius);
        dc.drawRoundedRectangle(mugX - 1, mugY, mugWidth + 2, mugHeight + 1, batteryRadius);

        // Drag handle on left side
        var handleX = mugX - 5;
        var handleY = mugY + 7;
        dc.drawRoundedRectangle(handleX,   handleY,   6, 12, batteryRadius);
        dc.drawRoundedRectangle(handleX-1, handleY-1, 7, 14, batteryRadius);

        // Draw beer inside mug, proper amount for how much of next beer earned
        var beerHeight = (mugHeight * (mugLevel.toFloat() / 100));
        var beerX = mugX + 1;
        var beerY = mugY + mugHeight - beerHeight - 1;
        dc.setColor(BEER_COLOR, BEER_COLOR);

        //System.println("mugLevel = " + mugLevel + "%, beerX = " + beerX + ", beerY = " + beerY + ", beerHeight = " + beerHeight);

        // Bulk of beer via rounded rectangle, but I want the top to be flat not rounded, so the line takes care of that
        dc.fillRoundedRectangle(beerX, beerY, mugWidth - 2, beerHeight, batteryRadius - 1);
        dc.drawLine(beerX, beerY, beerX + (mugWidth - 2), beerY);

        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        setMugForeColor(dc, info);

        // Draw another line at the bottom of the mug for a base
        var baseY = mugY + mugHeight - 2;
        dc.drawLine(mugX, baseY, mugX + mugWidth, baseY);
        baseY = baseY + 1;
        dc.drawLine(mugX, baseY, mugX + mugWidth, baseY);

        // Last step Draw Num Beers earned, to go inside
        dc.drawText(mugX + 8, mugY - 1, Graphics.FONT_XTINY, beersEarned, Graphics.TEXT_JUSTIFY_CENTER);

        resetColorsForRendering(dc);
    }

    private function getQualifyingSteps(info){
        // The first 10,000 steps don't count -- don't be lazy!
        var qualifyingSteps = info.steps - 10000;
        return qualifyingSteps >= 0 ? qualifyingSteps : 0;
    }

    private function setMugForeColor(dc, info){
        // Reset colors to font / background, or faded gray if not yet at 10,000 steps
        if (info.steps > 10000){
            dc.setColor(MUG_COLOR, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(FADED_MUG_COLOR, Graphics.COLOR_TRANSPARENT);
        }
    }

    // Draw the watch face background onto the given draw context
    private function writeBufferToDisplay(screenDc, screenBuffer) { 
        // Write the entire display buffer to the display
        screenDc.drawBitmap(0, 0, screenBuffer);    
    }

    private function resetColorsForRendering(dc) {
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
    }
    
    private function setStepsDisplayLevelColor(dc, perc){
        if (System.getClockTime().hour < 14) {
            // Only show step value colors if >= 2pm
            resetColorsForRendering(dc);
        } else if (perc > 100) {
            // Step goal!
            dc.setColor(FULL_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 60) {
            // 60+% of step goal
            dc.setColor(MOST_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 30) {
            // 30-59% step goal
            dc.setColor(SOME_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 0) {
            // 1-29% step goal
            dc.setColor(LOW_COLOR,  Graphics.COLOR_TRANSPARENT);
        } else {
            // 0% - Default to normal font color for 0 steps
            resetColorsForRendering(dc);
        }
    }

    private function setBatteryDisplayLevelColor(dc, perc){
        if (perc > 40) {
            dc.setColor(FULL_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 30) {
            dc.setColor(MOST_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 20) {
            dc.setColor(SOME_COLOR, Graphics.COLOR_TRANSPARENT);
        } else { 
            dc.setColor(LOW_COLOR,  Graphics.COLOR_TRANSPARENT);
        } 
    }

    private function drawClock(dc){
        resetColorsForRendering(dc);
        var clockTime = System.getClockTime();
        drawHashMarks(dc);
        drawHourHand(dc, clockTime);
        drawMinuteHand(dc, clockTime);
        drawClockCenter(dc, dc.getWidth(), dc.getHeight());
    }

    private function drawHourHand(dc, clockTime){
        // Draw the hour hand - convert it to minutes and compute the angle
        var hourHandAngle  = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle      = hourHandAngle / (12 * 60.0);
        hourHandAngle      = hourHandAngle * Math.PI * 2;
        var hourHandPoints = generateHandCoordinates(screenCenterPoint, hourHandAngle, 70, 14, 7);

        // Update the cliping rectangle to the new location of the hour hand
        setDrawingClip(dc, hourHandPoints);

        // Draw hour hand
        dc.fillPolygon(hourHandPoints);

        // Clear the clip
        clearDrawingClip(dc);

        //Reset colors
        resetColorsForRendering(dc);
    }

    private function drawMinuteHand(dc, clockTime) {
        var minuteHandAngle  = (clockTime.min / 60.0) * Math.PI * 2;
        var minuteHandPoints = generateHandCoordinates(screenCenterPoint, minuteHandAngle, 100, 20, 5);

        // Update the cliping rectangle to the new location of the minute hand
        setDrawingClip(dc, minuteHandPoints);

        // Draw hour hand
        dc.fillPolygon(minuteHandPoints);

        // Clear the clip
        clearDrawingClip(dc);
    }
    
    private function drawSecondHand(dc) {
        var clockTime        = System.getClockTime();
        var secondHand       = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, 100, 20, 2);
        
        // Update the cliping rectangle to the new location of the second hand
        setDrawingClip(dc, secondHandPoints);

        // Draw the second hand to the screen
        dc.setColor(RED_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(secondHandPoints);

        // Clear the clip
        clearDrawingClip(dc);
    }

    private function drawClockCenter(dc, width, height) {
        // Draw the circle in the middle
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.fillCircle(width / 2, height / 2, 7);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawCircle(width / 2, height / 2, 7);

        // Reset colors
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
    }

    // Get 4-element array of 2-element ints that indicate the x,y points of clock hand polygon
    private function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength], [width / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }

    // Draws the clock tick marks around the outside edges of the screen
    private function drawHashMarks(dc) {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        // Forerunner 645 Music has a round face
        var sX, sY;
        var eX, eY;
        var outerRad = width / 2;
        var innerRad = outerRad - 10;

        // draw tick marks around circumference
        for (var i = Math.PI / 6; i <= 12 * Math.PI / 6; i += (Math.PI / 6)) {
            sY = outerRad + innerRad * Math.sin(i);
            eY = outerRad + outerRad * Math.sin(i);
            sX = outerRad + innerRad * Math.cos(i);
            eX = outerRad + outerRad * Math.cos(i);
            dc.drawLine(sX, sY, eX, eY);
        }
    }
    
    // Clear drawing clip
    private function clearDrawingClip(dc) {
        dc.clearClip();
        curClip = null;
    }
    
    // Set the clip based on the passed-in set of coordinates
    private function setDrawingClip(dc, rectanglePoints) {
        // Clear existing clip
        dc.clearClip();
    
        // Update the cliping rectangle to polygon
        curClip        = getBoundingBox(rectanglePoints);
        var bboxWidth  = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        
        // Set new clip with new coordinates
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);        
    }
    

    // Compute a bounding box from the passed in points
    private function getBoundingBox(points) {
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

    // This method is called when the device re-enters sleep mode.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    function onExitSleep() {
        isAwake = true;
    }
}

class KozzerWatchDelegate extends WatchUi.WatchFaceDelegate {

    function initialize(){
        WatchFaceDelegate.initialize();
    }

    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}
