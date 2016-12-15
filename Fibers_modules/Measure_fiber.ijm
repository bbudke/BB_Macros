/*
    This script measures a single linear selection, such as a two-color
        DNA fiber. The results are placed in a text file in the temp
        directory. The macro can take no arguments, in which one ROI
        must be selected, or it can take an ROI name as its argument.
*/

var temp_directory_fibers    = getDirectory("temp") +
                               "BB_macros" + File.separator() +
                               "Fibers" + File.separator();

/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Measure_fiber" {
    args = getArgument(); // args = "roiName"

    if (nImages < 1) exit("Measure_fiber.ijm requires at least on open image.");
    image = getTitle();
    if (bitDepth != 24) exit("Measure_fiber.ijm requires an RGB image.");

    if (lengthOf(args) == 0) {
        if (selectionType() == -1){
            exit("Measure_fiber.ijm requires a selection.");
        }
        roiManager("Add");
        roiManager("Select", roiManager("Count") - 1);
        fiber = Roi.getName();
    } else {
        runMacro(
            getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Utilities" + File.separator() +
            "Select_roi.ijm", 
            args
        );
        fiber = args;
    }

    result = File.open(temp_directory_fibers +
                       "Measure_fiber_result.txt");
    print(result,
        "image\t" +
        "fiber\t" +
        "segment\t" +
        "point_1_x\t" +
        "point_1_y\t" +
        "point_2_x\t" +
        "point_2_y\t" +
        "red_val\t" +
        "green_val\t" +
        "color\t" +
        "length\t" +
        "unit"
        );
    run("Set Measurements...", "mean redirect=None decimal=3");
    getPixelSize(unit, pw, ph);
    getSelectionCoordinates(x, y);
    run("Select None");
    run("Clear Results");
    for (thisPoint = 0; thisPoint < x.length - 1; thisPoint++) {
        nextPoint = thisPoint + 1;
        segment = thisPoint + 1;
        makeLine(x[thisPoint], y[thisPoint], x[nextPoint], y[nextPoint]);
        run("RGB Measure");
        length = getResult("Length", 0);
        for (resultsRow = 0; resultsRow < nResults(); resultsRow++) {
            if (getResultLabel(resultsRow) == "Red") {
                redVal = getResult("Mean", resultsRow);
            } else if (getResultLabel(resultsRow) == "Green") {
                greenVal = getResult("Mean", resultsRow);
            }
        }
        run("Select None");
        run("Clear Results");
        if (redVal > greenVal) color = "Red"; else color = "Green";
        print(result,
            image + "\t" +
            fiber + "\t" +
            segment + "\t" +
            x[thisPoint] + "\t" +
            y[thisPoint] + "\t" +
            x[nextPoint] + "\t" +
            y[nextPoint] + "\t" +
            redVal + "\t" +
            greenVal + "\t" +
            color + "\t" +
            length + "\t" +
            unit
            );
    }
    File.close(result);
}

/*
--------------------------------------------------------------------------------
    FUNCTIONS
--------------------------------------------------------------------------------
*/