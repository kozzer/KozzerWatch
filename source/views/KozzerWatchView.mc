using Toybox.ActivityMonitor;
using Toybox.Application as Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;

using Toybox.WatchUi;
using Toybox.Application.Storage as Storage;

using ThemeController as Theme;

var partialUpdatesAllowed = false;          // Outside class so the Delegate class below can access the value    

class KozzerWatchView extends WatchUi.WatchFace
{
    // General class-level fields
    var _isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var _fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()   
    var _screenBuffer;                       // Buffer for the entire screen

    // UI Components
    var _mainClock;                          // Reference to Watchface's main analog clock
    var _dateTitle;                          // Reference to DateTitle object
    var _moveBar;                            // Reference to MoveBar object
    var _weather;                            // Reference to Weather object
    var _stepsCount;                         // Reference to StepsCount object
    var _bluetoothIcon;                      // Reference to BluetoothIcon object
    var _batteryStatus;                      // Reference to BatteryStatus object
    var _beerMug;                            // Reference to BeerMug object
    var _solarStatus;                        // Reference to SolarStatus object

    // Instinct 2
    var _isInstinct2;                        // Flag indicating whether this is running on the Instinct 2                 

    // Initialize variables for this view
    function initialize() {

        // Call base class constructor
        WatchFace.initialize();

        // Set class-level flags
        _isInstinct2          = Application.Properties.getValue("IsInstinct2");
        _fullScreenRefresh    = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate ); // Will be set to true until KozzerWatchViewDelegate.onPowerBudgetExceeded() is fired
    }




    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Initialize UI components
        initializeUIComponents(dc);

        // Create screen buffer object
        createScreenBuffer(dc);

        // Clear any clip
        CommonMethods.clearDrawingClip(dc);
    }

    // Handle the full screen refresh/update event, called once per minute or upon request
    function onUpdate(dc) {

        // We always want to refresh the full screen when we get a regular onUpdate call.
        _fullScreenRefresh = true;

        // Set an alias for the passed-in screen dc for clarity
        var screenDc = dc;
    
        // Clear the clip
        CommonMethods.clearDrawingClip(screenDc);
        
        // Draw background color to screen buffer
        var bufferDc = _screenBuffer.getDc();
        Theme.setBothColors(bufferDc, Theme.BACKGROUND_COLOR);
        bufferDc.fillRectangle(0, 0, bufferDc.getWidth(), bufferDc.getHeight());

        // Reset colors for rendering our info items (font, background)
        Theme.resetColors(bufferDc);
        
        // Draw UI elements to buffer
        drawUIComponents(bufferDc);

        // Always write buffer to display in onUpdate() - once per minute
        writeBufferThenDrawForPartialUpdate(screenDc, _screenBuffer);

        // Only draw the second hand if partial updates are currently allowed, OR if the watch is awake
        if (partialUpdatesAllowed) {
            // Partial update draws second hand and bluetooth icon
            onPartialUpdate(screenDc);
        } else if (_isAwake) {
            // If awake & partial updates not allowed draw second hand 
            _mainClock.drawSecondHand(screenDc);
        }

        _fullScreenRefresh = false;
    }


    // Handle the partial update event - 1/second
    function onPartialUpdate(dc) {

        // Only write buffer if not coming from onUpdate(), since writeBufferToDisplay() is already called there
        if(!_fullScreenRefresh) {
            // Writes buffer, then draws bluetooth and clock
            writeBufferThenDrawForPartialUpdate(dc, _screenBuffer);
        }

        // Draw second hand and bluetooth icon if connected
        _mainClock.drawSecondHand(dc);
    }

    private function createScreenBuffer(dc){
        // Set up buffer for whole screen 
        if (Graphics has :createBufferedBitmap){
            var bufferRef = Graphics.createBufferedBitmap({ 
                :width   => dc.getWidth(), 
                :height  => dc.getHeight() });
            _screenBuffer = bufferRef.get();
        } else {
            _screenBuffer = new Graphics.BufferedBitmap({ 
                :width   => dc.getWidth(), 
                :height  => dc.getHeight() });
        }
    }
   
    // This method is called when the device re-enters sleep mode.
    function onEnterSleep() {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    function onExitSleep() {
        _isAwake = true;
    }

    function initializeUIComponents(dc){
        // Created instance of each UI component
        _mainClock     = new MainClock(dc);
        _dateTitle     = new DateTitle(dc);
        _moveBar       = new MoveBar(dc);
        _stepsCount    = new StepsCount(dc);
        _bluetoothIcon = new BluetoothIcon(dc);
        _batteryStatus = new BatteryStatus(dc);
        _beerMug       = new BeerMug(dc);

        // No weather for Instinct2 (for now) ... color palette issues
        if (_isInstinct2 == false){
            _weather = new Weather(dc);
        }

        // Only initialize Solar Status if flag is true
        if (CommonMethods.showSolarIntensity){
            _solarStatus = new SolarStatus(dc);
        }
    }

    function drawUIComponents(dc) {
        // Get steps info
        var stepsInfo = ActivityMonitor.getInfo();

        // Draw UI components onto the passed-in DC (buffer)
        _dateTitle.drawOnScreen(dc);
        _moveBar.drawOnScreen(dc);
        _batteryStatus.drawOnScreen(dc);
        _stepsCount.drawOnScreen(dc, stepsInfo);
        _beerMug.drawOnScreen(dc, stepsInfo);

        // No weather for Instinct2 (for now) ... color palette issues
        if (_isInstinct2 == false){
            _weather.drawOnScreen(dc);
        }
    }

    function writeBufferThenDrawForPartialUpdate(dc, buffer){

        // (Re-)write buffer to display, then set the more changeable stuff
        CommonMethods.writeBufferToDisplay(dc, buffer);

        // If active, draw icon
        _bluetoothIcon.drawOnScreen(dc);

        // Draw solar info to buffer if available and enabled
        if (CommonMethods.showSolarIntensity) { 
            _solarStatus.drawOnScreen(dc);
        }

        // Now draw clock over the top of any bt icon (uses clipping to save battery)
        _mainClock.drawClock(dc); 
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
