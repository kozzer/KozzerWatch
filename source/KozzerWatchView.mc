using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

var partialUpdatesAllowed = false;          // Outside class so the Delegate class below can access the value    

class KozzerWatchView extends WatchUi.WatchFace
{
    // General class-level fields
    var isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var bluetoothIcon;                      // Reference to bluetooth icon png
    var bluetoothIsActive;                  // Flag indicating whether the phone is connected
    var screenBuffer;                       // Buffer for the entire screen
    var curClip;                            // Clip for partial updates, so only pixels where second hand is will actually be changed
    var screenCenterPoint;                  // Center x,y point of screen
    var fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()
    
    // Battery icon dimensions - hard-coded
    const batteryWidth  = 32;
    const batteryHeight = 16;
    const batteryRadius = 3;

    // UI colors
    const BACKGROUND_COLOR  = 0xDEDEDE;     // Light gray 
    const FONT_COLOR        = 0x111111;     // Very dark gray 
    const SECOND_HAND_COLOR = 0xFF0000;     // Red
    const FULL_COLOR        = 0x007700;     // Green
    const MOST_COLOR        = 0x777700;     // Yellow
    const SOME_COLOR        = 0x995500;     // Orange
    const LOW_COLOR         = 0xCC0000;     // Darker red

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        fullScreenRefresh     = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate ); // Will be set to true until KozzerWatchViewDelegate.onPowerBudgetExceeded() is fired
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Initialize bluetooth icon
        bluetoothIcon = WatchUi.loadResource(Rez.Drawables.BluetoothDarkIcon);
        // Set whether bluetooth is active
        bluetoothIsActive = System.getDeviceSettings().phoneConnected;

        // Set up buffer for whole screen
        screenBuffer = new Graphics.BufferedBitmap({ :width => dc.getWidth(), :height => dc.getHeight() });

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

        // Battery - Draw the battery status
        drawBatteryStatus(bufferDc);
               
        // Daily Steps
        var info       = ActivityMonitor.getInfo();
        var dataString = info.steps.toString();
        var stepPerc   = ((info.steps * 100) / info.stepGoal).toNumber();
        setStepsDisplayLevelColor(bufferDc, stepPerc);
        bufferDc.drawText(14, screenHeight / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_LEFT);
        resetColorsForRendering(bufferDc);

        // Daily Miles 
        dataString = (info.distance.toFloat() / 160934).format("%3.1f") + "m";  // 160,934 cm per mile
        bufferDc.drawText(screenWidth - 14, screenHeight / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_RIGHT);

        // Always output the offscreen buffer to the main display in onUpdate() - once per minute
        writeBufferToDisplay(screenDc, screenBuffer);

        // Check bluetooth status and write icon appropriately
        bluetoothIsActive = System.getDeviceSettings().phoneConnected;
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

            // If bluetooth setting changed, update our flag and change which buffer we're using
            if (bluetoothIsActive != System.getDeviceSettings().phoneConnected)
            {
                //Set flag to current value
                bluetoothIsActive = System.getDeviceSettings().phoneConnected;

                // If active, draw icon
                if (bluetoothIsActive){
                    dc.drawBitmap(dc.getWidth() / 2 - 12, Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 20, bluetoothIcon);
                } 
            }

            // Now draw clock over the top of any bt icon (uses clipping)
            drawClock(dc);        
        }

        // Draw second hand and bluetooth icon if connected
        drawSecondHand(dc);

    }
   
    // Draw the date string into the provided buffer at the specified location
    private function drawDateString(dc, x, y) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$", [info.month, info.day]);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw icon onto given dc
    private function setBluetoothIcon(dc){
            
        // Get location of points for icon location
        var iconX = dc.getWidth() / 2 - 12;
        var iconY = Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 20;
        var iconPoints = [ [iconX, iconY], [iconX+24, iconY], [iconX+24, iconY+24], [iconX, iconY+24] ];
    
        // Update the cliping rectangle to the location of the icon
        setDrawingClip(dc, iconPoints);
        
        // Actually draw icon
        if (bluetoothIsActive) {
            dc.drawBitmap(iconX, iconY, bluetoothIcon);
        } else {
            dc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
            dc.fillRectangle(iconX, iconY, 24, 24);
        }

        // Draw clock so it's "above" bt icon
        drawClock(dc);

        // Clear the clip
        clearDrawingClip(dc);
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
        dc.fillRoundedRectangle(batteryX + 2, batteryY + 2, ((batteryWidth - 4) * batteryPerc) / 100, batteryHeight - 4, batteryRadius - 1);
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
        if (perc > 60) {
            dc.setColor(FULL_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 40) {
            dc.setColor(MOST_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 25) {
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
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
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
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}
