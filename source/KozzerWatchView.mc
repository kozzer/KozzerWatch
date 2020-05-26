using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class KozzerWatchView extends WatchUi.WatchFace
{
    // General class-level fields
    var isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var btIcon;                             // Reference to bluetooth icon png
    var offscreenBuffer;                    // Watch-screen-sized buffer where everything is written to (actually written to screen when appropriate)
    var curClip;                            // Clip for partial updates, so only pixels where second hand is will actually be changed
    var screenCenterPoint;                  // Center x,y point of screen
    var fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()
    var partialUpdatesAllowed;              // Is true until the KozzerWatchViewDelegate.onPowerBudgetExceeded() is fired
    
    // Battery icon dimensions - hard-coded
    const batteryWidth      = 32;
    const batteryHeight     = 16;
    const batteryRadius     = 3;

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
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // load the bt Icon into memory.
        btIcon = WatchUi.loadResource(Rez.Drawables.BluetoothDarkIcon);

        // Set up screen buffer for partial updates
        offscreenBuffer = new Graphics.BufferedBitmap({
            :width  => dc.getWidth(),
            :height => dc.getHeight()
        });
        
        // Clear any clip
        curClip = null;

        // Set center point of watchface
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // Handle the full screen refresh/update event, called once per minute or upon request
    function onUpdate(dc) {
    
        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        // Clear the clip
        dc.clearClip();
        curClip = null;
        
        // Get dimensions of actual screen
        var screenWidth = dc.getWidth();
        
        // Get current system clock time
        var clockTime   = System.getClockTime();
    
        // Get draw context & dimensions for offscreen buffer
        var bufferDc    = offscreenBuffer.getDc();
        var width       = bufferDc.getWidth();
        var height      = bufferDc.getHeight();
        
        // Fill the entire background with color
        bufferDc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
        bufferDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Reset colors for rendering our info items (font, background)
        resetColorsForRendering(bufferDc);

        // Draw the clock - ticks around edge, hour hand, minute hand, center of clock (second hand handled below)
        drawHashMarks(bufferDc);
        drawHourHand(bufferDc, clockTime);
        drawMinuteHand(bufferDc, clockTime);
        drawClockCenter(bufferDc, width, height);

        // Draw the date on the top
        drawDateString( bufferDc, width / 2, 14 );

        // Battery - Draw the battery percentage directly to the main screen.
        drawBatteryStatus(bufferDc);
        
        // Draw the bluetooth icon if phone is connected
        if (null != btIcon && System.getDeviceSettings().phoneConnected) {
            bufferDc.drawBitmap( width * 0.75, height / 4 - 6, btIcon);
        }
        
        // Daily Steps
        var info       = ActivityMonitor.getInfo();
        var dataString = info.steps.toString() + "s";
        var stepPerc   = ((info.steps * 100) / info.stepGoal).toNumber();
        setStepsDisplayLevelColor(bufferDc, stepPerc);
        bufferDc.drawText(14, height / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_LEFT);
        resetColorsForRendering(bufferDc);

        // Daily Miles 
        dataString = (info.distance.toFloat() / 160934).format("%3.1f") + "m";  // 160,934 cm per mile
        bufferDc.drawText(width - 14, height / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_RIGHT);

        // Always output the offscreen buffer to the main display in onUpdate() - once per minute
        writeBufferToDisplay(dc);

        // Only draw the second hand if partial updates are currently allowed, OR if the watch is awake
        if( partialUpdatesAllowed ) {
            // Partial update draws second hand to clipped area, so draw second hand using clip
            onPartialUpdate( dc );
        } else if ( isAwake ) {
            // If awake & partial updates not allowed, we don't need clipping
            drawSecondHand( dc, false );
        }

        fullScreenRefresh = false;
    }


    // Handle the partial update event - 1/second, write to buffer not screen
    //  This method only really does the second hand using clipping
    function onPartialUpdate( dc ) {

        // Get current system clock time
        var clockTime   = System.getClockTime();

        // Only call this if not coming from onUpdate(), since drawBackgrounbd() is already called there
        if(!fullScreenRefresh) {
            writeBufferToDisplay( dc );
        }

        // Draw second hand, and use clip to save power (limits # of pixels that change)
        drawSecondHand( dc, clockTime, true );
    }
    
   
    // Draw the date string into the provided buffer at the specified location
    function drawDateString( dc, x, y ) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$", [info.month, info.day]);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw battery icon with % indicated
    function drawBatteryStatus( dc ) {   
    
        // Get battery % from system
        var batteryPerc = (System.getSystemStats().battery + 0.5).toNumber();
        setBatteryDisplayLevelColor(dc, batteryPerc);
        
        // dc dimensions
        var width  = dc.getWidth();
        var height = dc.getHeight();
               
        // Put it bottom center
        var batteryX = (width / 2)   - (batteryWidth / 2);
        var batteryY = (height - 20) - (batteryHeight / 2);
        
        // Draw outline
        dc.drawRoundedRectangle(batteryX,     batteryY,     batteryWidth,     batteryHeight,     batteryRadius);
        dc.drawRoundedRectangle(batteryX + 1, batteryY + 1, batteryWidth - 2, batteryHeight - 2, batteryRadius);
        
        // Draw filled (only fill based on %)
        dc.fillRoundedRectangle(batteryX, batteryY, (batteryWidth * batteryPerc) / 100, batteryHeight, batteryRadius);
        
        // Draw positive-end nub (on right)
        dc.fillRectangle((batteryX + batteryWidth), (batteryY + (batteryHeight / 4)), (batteryHeight / 4), (batteryHeight / 2)); 
    }


    // Draw the watch face background onto the given draw context
    function writeBufferToDisplay(dc) { 
        // Write the entire display buffer to the display
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }        
    }

    function resetColorsForRendering(dc) {
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
    }
    
    function setStepsDisplayLevelColor(dc, perc){
        if (perc > 100) {
            dc.setColor(FULL_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 60) {
            dc.setColor(MOST_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 30) {
            dc.setColor(SOME_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 0) {
            dc.setColor(LOW_COLOR,  Graphics.COLOR_TRANSPARENT);
        } else {
            // Default to normal font color for 0 steps
            resetColorsForRendering(dc);
        }
    }

    function setBatteryDisplayLevelColor(dc, perc){
        if (perc > 60) {
            dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 40) {
            dc.setColor(FULL_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc > 25) {
            dc.setColor(MOST_COLOR, Graphics.COLOR_TRANSPARENT);
        } else if (perc >= 15) {
            dc.setColor(SOME_COLOR, Graphics.COLOR_TRANSPARENT);
        } else { 
            dc.setColor(LOW_COLOR,  Graphics.COLOR_TRANSPARENT);
        } 
    }

    function drawHourHand(dc, clockTime){
        // Draw the hour hand. Convert it to minutes and compute the angle.
        var hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle     = hourHandAngle / (12 * 60.0);
        hourHandAngle     = hourHandAngle * Math.PI * 2;
        dc.fillPolygon(generateHandCoordinates(screenCenterPoint, hourHandAngle, 70, 14, 7));
    }

    function drawMinuteHand(dc, clockTime) {
        var minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        dc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, 100, 20, 5));
    }
    
    function drawSecondHand(dc, clockTime, setClip) {
        var secondHand       = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, 100, 20, 2);
        
        if ( setClip ) {
            // Update the cliping rectangle to the new location of the second hand
            curClip        = getBoundingBox( secondHandPoints );
            var bboxWidth  = curClip[1][0] - curClip[0][0] + 1;
            var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
            dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);
        }

        // Draw the second hand to the screen
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(secondHandPoints);
    }

    function drawClockCenter(dc, width, height) {
        // Draw the circle in the middle
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.fillCircle(width / 2, height / 2, 7);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawCircle(width / 2, height / 2, 7);

        // Reset colors
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
    }

    // Get 4 points of clock hand polygon
    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
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

    // Draws the clock tick marks around the outside edges of the screen.
    function drawHashMarks(dc) {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        // FR 645M has a round fact
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

    // Compute a bounding box from the passed in points
    function getBoundingBox( points ) {
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
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }
}

class KozzerWatchDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}
