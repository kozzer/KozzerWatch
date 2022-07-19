using Toybox.ActivityMonitor;
using Toybox.Application;
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
    // Flag indicating whether solar status should be displayed
    var _showSolarIntensity;

    // General class-level fields
    var _isAwake;                            // Flag indicating whether watch is awake or in sleep mode
    var _fullScreenRefresh;                  // Flag used in onUpdate() & onPartialUpdate()   
    var _screenBuffer;                       // Buffer for the entire screen

    // UI Components
    var _mainClock;                          // Reference to Watchface's main analog clock
    var _dateTitle;                          // Reference to DateTitle object
    var _bluetoothIcon;                      // Reference to BluetoothIcon object
    var _moveBar;                            // Reference to MoveBar object
    var _stepsCount;                         // Reference to StepsCount object
    var _batteryStatus;                      // Reference to BatteryStatus object
    var _beerMug;                            // Reference to BeerMug object
    var _solarStatus;                        // Reference to SolarStatus object

    // Initialize variables for this view
    function initialize() {

        // Call base class constructor
        WatchFace.initialize();

        // Get and apply app settings 
        populateAndApplyAppSettings();

        // Set class-level flags
        _fullScreenRefresh     = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate ); // Will be set to true until KozzerWatchViewDelegate.onPowerBudgetExceeded() is fired
    }


    // Called in constructor, and also from App class when settings change
    function populateAndApplyAppSettings(){

        // Clear cached property values
        Application.getApp().clearProperties();

        // Re-read properties from XML file (only set solar to true if device supports and setting is true)
        var useLightTheme  = Application.getApp().Properties.getValue("LightThemeActive");
        _showSolarIntensity = Toybox.System.Stats has :solarIntensity 
                                && Toybox.System.getSystemStats().solarIntensity != null 
                                && Application.getApp().Properties.getValue("ShowSolarIntensity");

        Theme.setTheme(useLightTheme);
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
        _bluetoothIcon = new BluetoothIcon(dc);
        _moveBar       = new MoveBar(dc);
        _stepsCount    = new StepsCount(dc);
        _batteryStatus = new BatteryStatus(dc);
        _beerMug       = new BeerMug(dc);

        // Only initialize Solar Status if flag is true
        if (_showSolarIntensity){
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
    }

    function writeBufferThenDrawForPartialUpdate(dc, buffer){

        // (Re-)write buffer to display, then set the more changeable stuff
        CommonMethods.writeBufferToDisplay(dc, buffer);

        // If active, draw icon
        _bluetoothIcon.drawOnScreen(dc);

        // Draw solar info to buffer if available and enabled
        if (_showSolarIntensity) { 
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
