using Toybox.System;
using Toybox.WatchUi;
using Toybox.Weather as Weather;
using Toybox.Graphics as Graphics;

using ThemeController as Theme;

class Weather {

    private var _screenWidth;
    private var _veryTinyFont;
    private var _fontHeight;
    private var _widgetHeight;

    private var _weatherX;
    private var _weatherY;

    private var _weatherPoints;

    function initialize(dc) {
        _screenWidth  = dc.getWidth();
        _veryTinyFont = Graphics.FONT_SYSTEM_XTINY;
        _fontHeight   = Graphics.getFontHeight(_veryTinyFont);
        _widgetHeight = (_fontHeight * 2) + 6;

        _weatherX = (_screenWidth / 2) - 72;
        _weatherY = 52;

        _weatherPoints = [
                        [_weatherX,       _weatherY],
                        [_weatherX + 144, _weatherY],
                        [_weatherX + 144, _weatherY + _widgetHeight],
                        [_weatherX,       _weatherY + _widgetHeight]
                     ];
    }

    function drawOnScreen(dc)
    {
        var conditions = Weather.getCurrentConditions();

        // Draw current, high and low temps
        drawTemperatures(dc, conditions);

        // conditions icon (should be centered on screen horizontally)
        drawIconForConditions(dc, conditions);

        CommonMethods.clearDrawingClip(dc);

        Theme.resetColors(dc);
    }

    private function drawTemperatures(dc, conditions){

        var currentTemp = CommonMethods.convertToFahrenheit(conditions.temperature).toString() + "°";
        var highTemp    = CommonMethods.convertToFahrenheit(conditions.highTemperature).toString() + "°";
        var lowTemp     = CommonMethods.convertToFahrenheit(conditions.lowTemperature).toString() + "°";

        CommonMethods.setDrawingClip(dc, _weatherPoints);

        ThemeController.setColor(dc, ThemeController.FONT_COLOR);

        // current temp, high temp, low temp
        dc.drawText(_weatherX + 30,  _weatherY + 9, Graphics.FONT_TINY, currentTemp, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_weatherX + 118, _weatherY + 6,  _veryTinyFont,      highTemp,    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_weatherX + 118, _weatherY + 24, _veryTinyFont,      lowTemp,     Graphics.TEXT_JUSTIFY_CENTER);

        // line between high and low
        dc.drawLine(_weatherX + 98, _weatherY + 26, _weatherX + 132, _weatherY + 26);
    }

    private function drawIconForConditions(dc, conditions){
        var rez = getIconForConditions(conditions);
        var icon = WatchUi.loadResource(rez);
        dc.drawBitmap(_weatherX + 56, _weatherY + 10, icon); 
    }

    private function getIconForConditions(conditions){

        var rez;

        var val = conditions.getCurrentConditions();
        if (val == null){
            // If no conditions found return tornado 
            rez = Rez.Drawables.night_clear_32;
        } else {
            switch (val.condition){
                case Weather.CONDITION_CLEAR:
                case Weather.CONDITION_FAIR: 
                    rez = Rez.Drawables.sunny_32;
                    break;
                case Weather.CONDITION_PARTLY_CLOUDY: 
                case Weather.CONDITION_MOSTLY_CLEAR: 
                case Weather.CONDITION_THIN_CLOUDS: 
                    rez = Rez.Drawables.partly_cloudy_32; 
                    break;
                case Weather.CONDITION_MOSTLY_CLOUDY: 
                case Weather.CONDITION_PARTLY_CLEAR: 
                    rez = Rez.Drawables.mostly_cloudy_32; 
                    break;
                case Weather.CONDITION_SCATTERED_SHOWERS: 
                case Weather.CONDITION_RAIN: 
                    rez = Rez.Drawables.rain_32; 
                    break;
                case Weather.CONDITION_SNOW: 
                case Weather.CONDITION_ICE: 
                    rez = Rez.Drawables.snow_32; 
                    break;
                case Weather.CONDITION_WINDY: 
                    rez = Rez.Drawables.windy_32; 
                    break;
                case Weather.CONDITION_THUNDERSTORMS: 
                case Weather.CONDITION_SQUALL: 
                case Weather.CONDITION_HURRICANE: 
                case Weather.CONDITION_TROPICAL_STORM: 
                    rez = Rez.Drawables.thunderstorm_32; 
                    break;
                case Weather.CONDITION_WINTRY_MIX: 
                    rez = Rez.Drawables.wintry_mix_32; 
                    break;
                case Weather.CONDITION_FOG: 
                    rez = Rez.Drawables.fog_32; 
                    break;
                case Weather.CONDITION_HAZY: 
                case Weather.CONDITION_MIST: 
                case Weather.CONDITION_SMOKE: 
                case Weather.CONDITION_HAZE: 
                    rez = Rez.Drawables.haze_32; 
                    break;
                case Weather.CONDITION_HAIL: 
                    rez = Rez.Drawables.hail_32; 
                    break;
                case Weather.CONDITION_SCATTERED_THUNDERSTORMS: 
                case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS: 
                    rez = Rez.Drawables.scattered_thunderstorms_32; 
                    break;
                case Weather.CONDITION_LIGHT_RAIN: 
                case Weather.CONDITION_LIGHT_SHOWERS: 
                    rez = Rez.Drawables.light_rain_32; 
                    break;
                case Weather.CONDITION_HEAVY_RAIN: 
                case Weather.CONDITION_HEAVY_SHOWERS: 
                    rez = Rez.Drawables.heavy_rain_32; 
                    break;
                case Weather.CONDITION_LIGHT_SNOW: 
                case Weather.CONDITION_CHANCE_OF_SNOW: 
                case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW: 
                case Weather.CONDITION_FLURRIES: 
                    rez = Rez.Drawables.light_snow_32; 
                    break;
                case Weather.CONDITION_HEAVY_SNOW: 
                    rez = Rez.Drawables.heavy_snow_32; 
                    break;
                case Weather.CONDITION_RAIN_SNOW: 
                case Weather.CONDITION_LIGHT_RAIN_SNOW: 
                case Weather.CONDITION_HEAVY_RAIN_SNOW: 
                case Weather.CONDITION_CHANCE_OF_RAIN_SNOW: 
                case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW: 
                case Weather.CONDITION_FREEZING_RAIN: 
                case Weather.CONDITION_SLEET: 
                case Weather.CONDITION_ICE_SNOW: 
                    rez = Rez.Drawables.wintry_mix_32; 
                    break;
                case Weather.CONDITION_CLOUDY: 
                    rez = Rez.Drawables.cloudy_32; 
                    break;
                case Weather.CONDITION_CHANCE_OF_SHOWERS: 
                case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN: 
                    rez = Rez.Drawables.rain_cloud_32; 
                    break;
                case Weather.CONDITION_DUST: 
                case Weather.CONDITION_SAND: 
                case Weather.CONDITION_SANDSTORM: 
                case Weather.CONDITION_VOLCANIC_ASH: 
                    rez = Rez.Drawables.dust_32; 
                    break;
                case Weather.CONDITION_DRIZZLE: 
                    rez = Rez.Drawables.drizzle_32; 
                    break;
                case Weather.CONDITION_TORNADO: 
                    rez = Rez.Drawables.tornado_32; 
                    break;

                case Weather.CONDITION_UNKNOWN_PRECIPITATION: 
                case Weather.CONDITION_UNKNOWN: 
                default:
                    rez = Rez.Drawables.night_clear_32; 
                    break;
            }
        }
        
        return rez;
    }
}