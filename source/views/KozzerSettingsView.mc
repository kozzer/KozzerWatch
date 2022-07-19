using Toybox;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class KozzerSettingsView extends WatchUi.View {

    // App settings
    var _useLightTheme;
    var _showSolarIntensity;

    // UI colors
    const BACKGROUND_COLOR  = 0x111111;     // Very dark gray 
    const FONT_COLOR        = 0xDEDEDE;     // Light

    function initialize() {
        View.initialize();
        populateAppSettings();
    }

    function populateAppSettings(){
        _useLightTheme      = Properties.getValue("LightThemeActive");
        _showSolarIntensity = Properties.getValue("ShowSolarIntensity");
    }

    function onLayout(dc) {
        //Clear any clip that may currently be set by the partial update
        dc.clearClip();

        // Add checkbox options (both settings are boolean)
        var menu = new WatchUi.CheckboxMenu({:title=>"Kozzer Watch Settings"});
        var delegate;
        var check = new WatchUi.CheckboxMenuItem(
            "Theme",
            "Use light theme",
            "chkLightTheme",
            _useLightTheme,
            { }
        );
        menu.addItem(check);
        menu.addItem(new WatchUi.CheckboxMenuItem(
            "Beer Notification",
            "Nofity when beer earned",
            "chkBeerNotify",
            _showSolarIntensity,
            { }
        ));
        delegate = new KozzerSettingsDelegate();
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_BLINK);
        return true;
    }

    // onShow() is called when this View is brought to the foreground
    function onShow() { }

    // onUpdate() is called periodically to update the View
    function onUpdate(dc) { }

    // onHide() is called when this View is removed from the screen
    function onHide() { }

}

class KozzerSettingsDelegate extends WatchUi.InputDelegate {
    // Handles user input and interaction

    function initialize(){
        InputDelegate.initialize();
    }

    // onKey -- press and release of physical button
    function onKey(keyEvent) {
        
        System.println(keyEvent.getKey());         // e.g. KEY_MENU = 7

        // ********************************************************
        //
        // Figure out what to do here to navigate and apply changes 
        //
        // ********************************************************

        return true;
    }
}