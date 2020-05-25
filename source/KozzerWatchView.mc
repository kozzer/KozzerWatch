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
    var settings;
    var isAwake;
    var btIcon;
    var offscreenBuffer;
    var dateBuffer;
    var curClip;
    var screenCenterPoint;
    var fullScreenRefresh;      // Flag used in onUpdate() & onPartialUpdate()
    var partialUpdatesAllowed;

    const BACKGROUND_COLOR  = 0x44FF44; // Light gray -- DEDEDE
    const FONT_COLOR        = 0x1111FF; // Very dark gray  -- 111111

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        fullScreenRefresh     = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Load device settings
        settings = System.getDeviceSettings();

        // load the bt Icon into memory.
        btIcon = WatchUi.loadResource(Rez.Drawables.BluetoothDarkIcon);

        // Set up screen buffer for partial updates
        offscreenBuffer = new Graphics.BufferedBitmap({
            :width=>dc.getWidth(),
            :height=>dc.getHeight()
        });

        // Buffered bitmap that's 1/2 width of face, tall as the font
        dateBuffer = new Graphics.BufferedBitmap({
            :width=>dc.getWidth() / 2,
            :height=>Graphics.getFontHeight(Graphics.FONT_MEDIUM)
        });

        curClip = null;
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var minuteHandAngle;
        var hourHandAngle;
        var secondHand;
        var targetDc = null;

        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        // Clear the clip
        dc.clearClip();
        curClip = null;

        // Get draw context for offscreen buffer
        targetDc = offscreenBuffer.getDc();

        // Get dimensions of context
        width  = targetDc.getWidth();
        height = targetDc.getHeight();

        // Fill the entire background with color
        targetDc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the tick marks around the edges of the screen
        targetDc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        drawHashMarks(targetDc);

        // Use font color to draw the hour and minute hands
        targetDc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);

        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;
        targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, hourHandAngle, 70, 14, 7));

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, 100, 20, 5));

        // Draw the circle in the middle
        targetDc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        targetDc.fillCircle(width / 2, height / 2, 7);
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        targetDc.drawCircle(width / 2, height / 2, 7);

        // Reset colors
        targetDc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);

        // Draw the bluetooth icon if phone is connected
        if (null != btIcon && settings.phoneConnected) {
            targetDc.drawBitmap( width * 0.70, height / 4 - 6, btIcon);
        }

        // Battery - Draw the battery percentage directly to the main screen.
        var dataString = (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";
        targetDc.drawText(width / 2, height - 36, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_CENTER);

        // Daily Steps
        dataString = ActivityMonitor.getInfo().steps.toString() + "s";
        targetDc.drawText(14, height / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Daily Miles 
        dataString = (ActivityMonitor.getInfo().distance / 160934).format("%3.1f") + "m";  // 160,934 cm per mile
        targetDc.drawText(width - 14, height / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2, Graphics.FONT_XTINY, dataString, Graphics.TEXT_JUSTIFY_RIGHT);

        // Draw date to buffer
        var dateDc = dateBuffer.getDc();
        dateDc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);    

        // Draw the background image buffer into the date buffer to set the background
        dateDc.drawBitmap(width / 4, height + 14, offscreenBuffer);
        drawDateString( dateDc, width / 4, 0 );

        // Output the offscreen buffers to the main display if required.
        drawBackground(dc);

        if( partialUpdatesAllowed ) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the second hand.
            onPartialUpdate( dc );
        } else if ( isAwake ) {
            // Otherwise, if we are out of sleep mode, draw the second hand
            // directly in the full update method.
            dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
            secondHand = (clockTime.sec / 60.0) * Math.PI * 2;

            dc.fillPolygon(generateHandCoordinates(screenCenterPoint, secondHand, 60, 20, 2));
        }

        fullScreenRefresh = false;
    }

    // Handle the partial update event - 1/second, write to buffer not screen
    function onPartialUpdate( dc ) {

        if(!fullScreenRefresh) {
            drawBackground(dc);
        }

        var clockTime        = System.getClockTime();
        var secondHand       = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, 100, 20, 2);

        // Update the cliping rectangle to the new location of the second hand.
        curClip        = getBoundingBox( secondHandPoints );
        var bboxWidth  = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);

        // Draw the second hand to the screen.
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(secondHandPoints);
    }

    // Draw the date string into the provided buffer at the specified location
    function drawDateString( dc, x, y ) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$", [info.month, info.day]);

        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Draw the watch face background onto the given draw context
    function drawBackground(dc) {
        var width  = dc.getWidth();
        var height = dc.getHeight();

        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }

        // Draw the date
        if( null != dateBuffer ) {
            // If the date is saved in a Buffered Bitmap, just copy it from there.
            dc.drawBitmap( width / 4, 14, dateBuffer );
        } else {
            // Otherwise, draw it from scratch.
            drawDateString( dc, width / 4, 14 );
        }
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
        var width = dc.getWidth();
        var height = dc.getHeight();

        // FR 645M has a round fact
        var sX, sY;
        var eX, eY;
        var outerRad = width / 2;
        var innerRad = outerRad - 10;

        // draw tick marks around circumference
        for (var i = Math.PI / 6; i <= 11 * Math.PI / 6; i += (Math.PI / 6)) {

            sY = outerRad + innerRad * Math.sin(i);
            eY = outerRad + outerRad * Math.sin(i);
            sX = outerRad + innerRad * Math.cos(i);
            eX = outerRad + outerRad * Math.cos(i);
            dc.drawLine(sX, sY, eX, eY);

            i += Math.PI / 6;
            sY = outerRad + innerRad * Math.sin(i);
            eY = outerRad + outerRad * Math.sin(i);
            sX = outerRad + innerRad * Math.cos(i);
            eX = outerRad + outerRad * Math.cos(i);
            dc.drawLine(sX, sY, eX, eY);

            i += Math.PI / 6;
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