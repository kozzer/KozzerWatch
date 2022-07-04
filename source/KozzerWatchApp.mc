using Toybox.Application;
using Toybox.Time;
using Toybox.Communications;


// Entry point
class KozzerWatch extends Application.AppBase
{
    var useLightTheme;
    var notifyOnBeerEarned;

    function initialize() {
        AppBase.initialize();

        useLightTheme = getProperty("LightThemeActive");
        notifyOnBeerEarned = getProperty("NotifyOnBeerEarned");
        
        System.println("App:  light: " + useLightTheme + ", notify: " + notifyOnBeerEarned);

    }

    function onStart(state) { }

    function onStop(state)  { }

    // Main watch face 
    function getInitialView() {

        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new KozzerWatchView(useLightTheme, notifyOnBeerEarned), new KozzerWatchDelegate()];
        } else {
            return [new KozzerWatchView(useLightTheme, notifyOnBeerEarned)];
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
}