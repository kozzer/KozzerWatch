using Toybox.Graphics;

module CommonMethods {

    var curClip;                            // Clip for partial updates, so only pixels where second hand is will actually be changed

    // Draw the watch face background onto the given draw context
    function writeBufferToDisplay(screenDc, screenBuffer) { 
        // Write the entire display buffer to the display
        screenDc.drawBitmap(0, 0, screenBuffer);    
    }

    function resetColorsForRendering(dc) {
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
    }

    function getTinyFont(dc){
        var width = dc.getWidth();
        if (width < 240){
            return Graphics.FONT_XTINY;
        } else {
            return Graphics.FONT_TINY;
        }
    }

    // Set the clip based on the passed-in set of coordinates
    function setDrawingClip(dc, rectanglePoints) {
        // Clear existing clip
        dc.clearClip();
    
        // Update the cliping rectangle to polygon
        curClip        = getBoundingBox(rectanglePoints);
        var bboxWidth  = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        
        // Set new clip with new coordinates
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);        
    }

    // Clear drawing clip
    function clearDrawingClip(dc) {
        dc.clearClip();
        curClip = null;
    }

    // Compute a bounding box from the passed in points
    function getBoundingBox(points) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }
}