/*
    This script measures all the fibers in a single image. The results are
        placed in a text file in the temp directory.
*/

var temp_directory_fibers    = getDirectory("temp") +
                               "BB_macros" + File.separator() +
                               "Fibers" + File.separator();

/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Measure_fibers_image" {
    if (nImages != 1) exit("Measure_fibers_image.ijm requires " +
        "a single open image.");
    if (roiManager("Count") < 1) exit("Measure_fibers_image.ijm requires " +
        "at least one ROI.");

    ROI_list = newArray();
    for (this_ROI = 0; this_ROI < roiManager("Count"); this_ROI++) {
        roiManager("Select", this_ROI);
        ROI_name = Roi.getName();
        if (indexOf(ROI_name, "FIBER") != -1)
            ROI_list = Array.concat(ROI_list, ROI_name);
    }
    if (ROI_list.length < 1) exit("The ROI list must contain ROIs " +
        "whose names include 'FIBER'.");

    SCALE_UNIT_PER_PX = 0.06;
    SCALE_UNIT = fromCharCode(0xb5) + "m";

    run("Set Scale...", "distance=1 known=" + SCALE_UNIT_PER_PX + 
        " unit=" + SCALE_UNIT + " global");

    result_header = "image\t" +
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
                    "unit";
    result = File.open(temp_directory_fibers +
                       "Measure_fibers_result.txt");
    print(result, result_header);

    // Run Measure_fiber for each FIBER in the ROI list.
    for (this_ROI = 0; this_ROI < ROI_list.length; this_ROI++) {
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Utilities" + File.separator() +
            "Select_roi.ijm", ROI_list[this_ROI]);
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Fibers_modules" + File.separator() +
            "Measure_fiber.ijm", ROI_list[this_ROI]);
        this_ROI_result = File.openAsString(temp_directory_fibers +
                                            "Measure_fiber_result.txt");
        this_ROI_result = split(this_ROI_result, "\n");
        this_ROI_result_header = Array.slice(this_ROI_result, 0, 1);
        this_ROI_result_data = Array.slice(this_ROI_result, 1, this_ROI_result.length);
        if (!matches(result_header, this_ROI_result_header[0])) {
            exit("The result headers for the result.txt files for\n" +
                 "Measure_fiber.ijm and Measure_fibers_image.ijm\n" +
                 "do not match.");
        }
        for (this_row = 0; this_row < this_ROI_result_data.length; this_row++) {
            print(result, this_ROI_result_data[this_row]);
        }
    }
    File.close(result);
    roiManager("Show None");
    if (isOpen("Results"))     { selectWindow("Results");     run("Close"); }
}