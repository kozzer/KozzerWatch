using Toybox.Application;
using Toybox.Time;
using Toybox.Communications;

// Entry point
class KozzerWatch extends Application.AppBase
{
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) { }

    function onStop(state)  { }

    // Main watch face 
    function getInitialView() {
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new KozzerWatchView(), new KozzerWatchDelegate()];
        } else {
            return [new KozzerWatchView()];
        }
    }

    // Goal screen
    function getGoalView(goal) {
        return [new KozzerGoalView(goal)];
    }
}