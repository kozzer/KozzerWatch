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
    // Flag indicating whether solar status should be displayed
    var showSolarIntensity;

    // General class-level fields
    var isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()   

    // UI Components
    var bluetoothIcon;                      // Reference to BluetoothIcon object
    var moveBar;                            // Reference to MoveBar object
    var stepsCount;                         // Reference to StepsCount object
    var batteryStatus;                      // Reference to BatteryStatus object
    var beerMug;                            // Reference to BeerMug object
    var solarStatus;                        // Reference to SolarStatus object


    var screenBuffer;                       // Buffer for the entire screen
    var screenCenterPoint;                  // Center x,y point of screen


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

        // Re-read properties from XML file (only set solar to true if device supports and setting is true)
        var useLightTheme  = Application.getApp().Properties.getValue("LightThemeActive");
        showSolarIntensity = Toybox.System.Stats has :solarIntensity && Application.getApp().Properties.getValue("ShowSolarIntensity");

        Theme.setTheme(useLightTheme);

        System.println("Properties: light: " + useLightTheme + ", solar: " + showSolarIntensity);
    }

 

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Initialize UI components
        bluetoothIcon = new BluetoothIcon();
        moveBar       = new MoveBar();
        stepsCount    = new StepsCount(dc.getHeight());
        batteryStatus = new BatteryStatus();
        beerMug       = new BeerMug();

        // Only initialize Solar Status if flag is true
        if (showSolarIntensity){
            solarStatus = new SolarStatus();
        }

        createScreenBuffer(dc);

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
        moveBar.drawOnScreen(bufferDc);

        // Battery - Draw the battery status
        batteryStatus.drawOnScreen(bufferDc);

        // Get activity monitor info for steps data
        var stepsInfo = ActivityMonitor.getInfo();
               
        // Daily Steps 
        stepsCount.drawOnScreen(bufferDc, stepsInfo);
 
        // Draw beers earned + mug
        beerMug.drawOnScreen(bufferDc, stepsInfo);

        // Draw solar info if available and enabled
        if (showSolarIntensity) { 
            solarStatus.drawOnScreen(bufferDc);
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

    private function createScreenBuffer(dc){
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
    }
   
    // Draw the date string into the provided buffer at the specified location
    private function drawDateString(dc, x, y) {
        var greg    = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);       // Greg is 16th century new hotness, Julian is old and busted
        var dateStr = Lang.format("$1$ $2$", [greg.month, greg.day]);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
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
