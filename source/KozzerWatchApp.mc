using Toybox.Application;
using Toybox.Time;
using Toybox.Communications;
using Toybox.System;


// Entry point
class BeersEarned extends Application.AppBase
{
    private var _mainWatchFaceView;

    function initialize() {
        AppBase.initialize(); 
        CommonMethods.populateAndApplyAppSettings();      
    }

    function onStart(state) { }

    function onStop(state)  { }

    // Main watch face 
    function getInitialView() {

        _mainWatchFaceView = new KozzerWatchView();

        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [_mainWatchFaceView, new KozzerWatchDelegate()];
        } else {
            return [_mainWatchFaceView];
        }
    }

    // Goal screen
    function getGoalView(goal) {
        return [new KozzerGoalView(goal)];
    }

    // Settings screen
    function getSettingsView() {
        return [new KozzerSettingsView(), new KozzerSettingsDelegate()];   
    }

    function onSettingsChanged() {

        Toybox.System.println("About to read new settings after change...");
        CommonMethods.populateAndApplyAppSettings();

        Toybox.System.println("New settings applied, now requesting UI update...");

        WatchUi.requestUpdate();

        Toybox.System.println("done");
    }
}