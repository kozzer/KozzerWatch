using Toybox.Application;
using Toybox.Time;
using Toybox.Communications;


// Entry point
class KozzerWatch extends Application.AppBase
{
    private var _mainWatchFaceView;

    function initialize() {
        AppBase.initialize();       
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
        if ( AppBase has :getSettingsView){
            return [new KozzerSettingsView(), new KozzerSettingsDelegate()];
        } else {
            return null;
        }       
    }

    function onSettingsChanged() {
        _mainWatchFaceView.populateAndApplyAppSettings();
        WatchUi.requestUpdate();
    }
}