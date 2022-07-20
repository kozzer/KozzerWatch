using Toybox;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class KozzerSettingsView extends WatchUi.View {

    // UI colors
    const BACKGROUND_COLOR  = 0x111111;     // Very dark gray 
    const FONT_COLOR        = 0xDEDEDE;     // Light

    const SETTING_ID_LIGHT_THEME = "LightThemeActive";
    const SETTING_ID_SHOW_SOLAR  = "ShowSolarIntensity";

    const CHECK_ID_LIGHT_THEME   = "chkLightTheme";
    const CHECK_ID_SHOW_SOLAR    = "chkShowSolarIntensity";   

    private var _delegate;

    function initialize() {
        View.initialize();
        populateAppSettings();
        _delegate = new KozzerSettingsDelegate();
    }

    function populateAppSettings(){
        var app = Application.getApp();
        CommonMethods.useLightTheme      = app.Properties.getValue(SETTING_ID_LIGHT_THEME) as Boolean;
        CommonMethods.showSolarIntensity = app.Properties.getValue(SETTING_ID_SHOW_SOLAR) as Boolean;
    }

    function onLayout(dc) {
        //Clear any clip that may currently be set by the partial update
        dc.clearClip();

        // Add checkbox options (both settings are boolean)
        var menu = new WatchUi.CheckboxMenu({:title=>"Settings"});
        var check = new WatchUi.CheckboxMenuItem(
            "Theme",
            "Use light theme",
            CHECK_ID_LIGHT_THEME,
            CommonMethods.useLightTheme,
            null
        );
        menu.addItem(check);
        menu.addItem(new WatchUi.CheckboxMenuItem(
            "Solar",
            "Show Intensity?",
            CHECK_ID_SHOW_SOLAR,
            CommonMethods.showSolarIntensity,
            null
        ));
        WatchUi.pushView(menu, _delegate, WatchUi.SLIDE_BLINK);
        return true;
    }

    // onShow() is called when this View is brought to the foreground
    function onShow() { 
        return true;
    }

    // onUpdate() is called periodically to update the View
    function onUpdate(dc) { 
        return true;
    }

    // onHide() is called when this View is removed from the screen
    function onHide() { 
        return true;
    }

}

class KozzerSettingsDelegate extends WatchUi.BehaviorDelegate {
    // Handles user input and interaction

    function initialize(){
        BehaviorDelegate.initialize();
    }

     function onSelect(selectEvent){

        var app = Application.getApp();
        var chk = selectEvent as CheckboxMenuItem;
        var checkBoxId = chk.getId();
        var checkBoxChecked = chk.isChecked();

        if (checkBoxId.equals("chkLightTheme")){
            CommonMethods.useLightTheme = checkBoxChecked;
            app.Properties.setValue("LightThemeActive", checkBoxChecked);           
        } else if (checkBoxId.equals(CHECK_ID_SHOW_SOLAR)){
            CommonMethods.showSolarIntensity = checkBoxChecked;
            app.Properties.setValue(SETTING_ID_SHOW_SOLAR, checkBoxChecked);
        }

        System.println(checkBoxId + " - " + checkBoxChecked);
        return true;
    }

    function onBack(){
        return true;
    }

    function onSelectable(event) {
        return true;
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

    function onTap(clickEvent) {
        System.println(clickEvent.getType());      // e.g. CLICK_TYPE_TAP = 0
        return true;
    }

    function onSwipe(swipeEvent) {
        System.println(swipeEvent.getDirection()); // e.g. SWIPE_DOWN = 2
        return true;
    }
}