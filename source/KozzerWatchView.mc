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

using ThemeController as Theme;

var partialUpdatesAllowed = false;          // Outside class so the Delegate class below can access the value    

class KozzerWatchView extends WatchUi.WatchFace
{
    var showSolarIntensity;

    // General class-level fields
    var isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var bluetoothIcon;                      // Reference to BluetoothIcon object
    var sunIcon;                            // Reference to solar intensity sun icon
    var screenBuffer;                       // Buffer for the entire screen
    var screenCenterPoint;                  // Center x,y point of screen
    var fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()
    
    // Graphic Dimensions - hard-coded
    // Battery
    const batteryWidth  = 32;
    const batteryHeight = 16;
    const batteryRadius = 3;
    // Move Bar
    const moveBarHeight = 4;

    // Initialize variables for this view
    function initialize() {

        // Call base class constructor
        WatchFace.initialize();

        // Get and apply app settings 
        populateAndApplyAppSettings();

        fullScreenRefresh     = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate ); // Will be set to true until KozzerWatchViewDelegate.onPowerBudgetExceeded() is fired
    }

    function populateAndApplyAppSettings(){

        // Clear cached property values
        Application.getApp().clearProperties();

        // Re-read properties from XML file
        var useLightTheme  = Application.getApp().Properties.getValue("LightThemeActive");
        showSolarIntensity = Application.getApp().Properties.getValue("ShowSolarIntensity");

        Theme.setTheme(useLightTheme);

        System.println("Properties: light: " + useLightTheme + ", solar: " + showSolarIntensity);
    }

 

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Initialize bluetooth icon
        bluetoothIcon = new BluetoothIcon();

        // Initialize sun icon if available and active
        if (Toybox.System.Stats has :solarIntensity && showSolarIntensity){
            sunIcon = WatchUi.loadResource(Rez.Drawables.SunIcon);
        }

        // Set up buffer for whole screen 
        if (Graphics has :createBufferedBitmap){
            var bufferRef = Graphics.createBufferedBitmap({ 
                :width   => dc.getWidth(), 
                :height  => dc.getHeight() });
            screenBuffer = bufferRef.get();
        } else {
            screenBuffer = new Graphics.BufferedBitmap({ 
                :width   => dc.getWidth(), 
                :height  => dc.getHeight() });
        }

        // Clear any clip
        CommonMethods.clearDrawingClip(dc);

        // Set center point of watchface
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // Handle the full screen refresh/update event, called once per minute or upon request
    function onUpdate(dc) {

        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        // Set an alias for the passed-in screen dc for clarity
        var screenDc     = dc;
        var screenWidth  = screenDc.getWidth();
        var screenHeight = screenDc.getHeight();
    
        // Clear the clip
        CommonMethods.clearDrawingClip(screenDc);
        
        // Draw background color to screen buffer
        var bufferDc = screenBuffer.getDc();
        Theme.setBothColors(bufferDc, Theme.BACKGROUND_COLOR);
        bufferDc.fillRectangle(0, 0, bufferDc.getWidth(), bufferDc.getHeight());

        // Reset colors for rendering our info items (font, background)
        Theme.resetColors(bufferDc);
        
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

        // Draw solar info if available and enabled
        if (Toybox.System.Stats has :solarIntensity && showSolarIntensity) { 
            drawSolarIntensity(bufferDc);
        }

        // Always output the offscreen buffer to the main display in onUpdate() - once per minute
        CommonMethods.writeBufferToDisplay(screenDc, screenBuffer);

        // Check bluetooth status and write icon appropriately
        bluetoothIcon.drawOnScreen(screenDc);

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
            CommonMethods.writeBufferToDisplay(dc, screenBuffer);

            // If active, draw icon
            bluetoothIcon.drawOnScreen(dc);

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
            Theme.setColor(dc, Theme.BLUE_COLOR);
            dc.fillRectangle(barX, barY, 27, moveBarHeight);
            barX += 30;
        }
        if (barLevel >= 2){
            Theme.setColor(dc, Theme.FULL_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 3){
            Theme.setColor(dc, Theme.MOST_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 4){
            Theme.setColor(dc, Theme.SOME_COLOR);
            dc.fillRectangle(barX, barY, 9, moveBarHeight);
            barX += 12;
        }
        if (barLevel >= 5){
            Theme.setColor(dc, Theme.LOW_COLOR);
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
            CommonMethods.setDrawingClip(dc, iconPoints);
            
            // Actually write the icon to the dc
            dc.drawBitmap(iconX, iconY, bluetoothIcon);

            // Clear the clip
            CommonMethods.clearDrawingClip(dc);
        }
    }

    private function drawNumberOfStepsText(dc, info, screenHeight)
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
        Theme.resetColors(dc);
        
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
        Theme.setBothColors(dc, ThemeController.BEER_COLOR);

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
        dc.drawText(mugX + 8, adjustMugY(dc, mugY), CommonMethods.getTinyFont(dc), beersEarned, Graphics.TEXT_JUSTIFY_CENTER);

        Theme.resetColors(dc);
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


    private function drawSolarIntensity(dc)
    {  
        // Get system stats object
        var stats = Toybox.System.getSystemStats();
        var solar = stats.solarIntensity;

        // If solar is 0, just return
        if (solar == 0) {
            return;
        }
        
        // dc dimensions
        var width  = dc.getWidth();
        var height = dc.getHeight();
               
        // Put it above battery status
        var sunDiameter = 16;
        var sunX = width / 2;
        var sunY = height - 60;

        // Draw sun
        dc.drawBitmap(sunX - 16, sunY - 15, sunIcon);

        // Draw power level
        Theme.setColor(dc, ThemeController.LOW_COLOR);
        dc.drawText(sunX, sunY - 9, Graphics.FONT_XTINY, solar, Graphics.TEXT_JUSTIFY_CENTER);

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

    private function setBatteryDisplayLevelColor(dc, perc){
        if (perc > 40) {
            Theme.setColor(dc, Theme.FULL_COLOR);
        } else if (perc > 30) {
            Theme.setColor(dc, Theme.MOST_COLOR);
        } else if (perc > 20) {
            Theme.setColor(dc, Theme.SOME_COLOR);
        } else { 
            Theme.setColor(dc, Theme.LOW_COLOR);
        } 
    }

    private function drawClock(dc){
        Theme.resetColors(dc);
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
        CommonMethods.setDrawingClip(dc, hourHandPoints);

        // Draw hour hand
        dc.fillPolygon(hourHandPoints);

        // Clear the clip
        CommonMethods.clearDrawingClip(dc);

        //Reset colors
        Theme.resetColors(dc);
    }

    private function drawMinuteHand(dc, clockTime) {
        var minuteHandAngle  = (clockTime.min / 60.0) * Math.PI * 2;
        var minuteHandPoints = generateHandCoordinates(screenCenterPoint, minuteHandAngle, 100, 20, 5);

        // Update the cliping rectangle to the new location of the minute hand
        CommonMethods.setDrawingClip(dc, minuteHandPoints);

        // Draw hour hand
        dc.fillPolygon(minuteHandPoints);

        // Clear the clip
        CommonMethods.clearDrawingClip(dc);
    }
    
    private function drawSecondHand(dc) {
        var clockTime        = System.getClockTime();
        var secondHand       = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, 100, 20, 2);
        
        // Update the cliping rectangle to the new location of the second hand
        CommonMethods.setDrawingClip(dc, secondHandPoints);

        // Draw the second hand to the screen
        Theme.setColor(dc, ThemeController.RED_COLOR);
        dc.fillPolygon(secondHandPoints);

        // Clear the clip
        CommonMethods.clearDrawingClip(dc);
    }

    private function drawClockCenter(dc, width, height) {
        // Draw the circle in the middle
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.fillCircle(width / 2, height / 2, 7);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawCircle(width / 2, height / 2, 7);

        // Reset colors
        Theme.resetColors(dc);
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
