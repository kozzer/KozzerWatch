using Toybox;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

const TOGGLE_NAME_LIGHT_THEME = "lightTheme";
const TOGGLE_NAME_SHOW_SOLAR  = "showSolar";


class KozzerSettingsView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");

        CommonMethods.populateAndApplyAppSettings();

        // Always show light theme toggle
        Menu2.addItem(new WatchUi.ToggleMenuItem("Theme", "Use light theme?", TOGGLE_NAME_LIGHT_THEME, CommonMethods.useLightTheme, null));

        // Only show solar toggle if device supports it
        if (Toybox.System.Stats has :solarIntensity){
            Menu2.addItem(new WatchUi.ToggleMenuItem("Solar", "Show solar intensity?", TOGGLE_NAME_SHOW_SOLAR, CommonMethods.showSolarIntensity, null));
        }
    }

}

class KozzerSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize(){
        Menu2InputDelegate.initialize();
    }

     function onSelect(item){

        // Get item Id and toggle setting
        var id = item.getId();
        if (id.equals(TOGGLE_NAME_LIGHT_THEME)){
            CommonMethods.useLightTheme = !CommonMethods.useLightTheme;
            CommonMethods.setPropertyValue(CommonMethods.SETTING_ID_LIGHT_THEME, CommonMethods.useLightTheme);  
        } else if (id.equals(TOGGLE_NAME_SHOW_SOLAR)){
            CommonMethods.showSolarIntensity = !CommonMethods.showSolarIntensity;
            CommonMethods.setPropertyValue(CommonMethods.SETTING_ID_SHOW_SOLAR, CommonMethods.showSolarIntensity);  
        }
    }

    function onBack(){
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        CommonMethods.populateAndApplyAppSettings();
        return false;
    }

}