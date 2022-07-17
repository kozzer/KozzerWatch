using Toybox.WatchUi;

class KozzerBeerEarnedView extends WatchUi.View {

    // UI colors
    const BACKGROUND_COLOR  = 0x111111;     // Very dark gray 
    const FONT_COLOR        = 0xDEDEDE;     // Light

    var beersEarned = 0;
    
    function initialize(numBeersEarned) {
        View.initialize();
        beersEarned = numBeersEarned;
    }

    // Resources are loaded here
    function onLayout(dc) {
        //Clear any clip that may currently be set by the partial update
        dc.clearClip();
        //setLayout(Rez.Layouts.MainLayout(dc));
    }

    // onShow() is called when this View is brought to the foreground
    function onShow() {
    }

    // onUpdate() is called periodically to update the View
    function onUpdate(dc) {
        View.onUpdate(dc);

        var width  = dc.getWidth();
        var height = dc.getHeight();

        // Fill the screen with a black rectangle
        dc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
        dc.fillRectangle(0, 0, width, height);

        // Set color for text
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);

        // Draw text
        var beer = beersEarned == 1 ? " beer" : " beers";
        var beerString = "You can have " + beersEarned.toString() + beer + " today!";
        dc.drawText(width / 2, (height / 4) + 12, Graphics.FONT_SMALL, beerString, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, (height / 2) - 7, Graphics.FONT_MEDIUM, "YOU'VE EARNED ANOTHER BEER", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, (height * 0.62) + 12, Graphics.FONT_SMALL, "Enjoy!", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // onHide() is called when this View is removed from the screen
    function onHide() {
    }
}