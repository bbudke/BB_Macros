/*
    This script measures all the fibers in a single image. The results are
    	placed in a text file in the temp directory.
*/


/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Measure_fibers_image" {
	if (nImages != 1) exit("Measure_fibers_image.ijm requires a single open image.");
	if (roiManager("Count") < 1) exit("Measure_fibers_image.ijm requires at least one ROI.");

	ROI_list = newArray();
	for (this_ROI = 0; this_ROI < roiManager("Count"); this_ROI++) {
		roiManager("Select", this_ROI);
		ROI_name = Roi.getName();
		ROI_list = Array.concat(ROI_list, ROI_name);
	}

	SCALE_UNIT_PER_PX = 0.06;
	SCALE_UNIT = fromCharCode(0xb5) + "m";

	run("Set Scale...", "distance=1 known=" + SCALE_UNIT_PER_PX + 
		" unit=" + SCALE_UNIT + " global");

	result_header = "image\t" +
			        "fiber\t" +
			        "segment\t" +
			        "color\t" +
			        "length\t" +
			        "unit";
    result = File.open(getDirectory("temp") + "Measure_fibers_result.txt");
    print(result, result_header);
    for (this_ROI = 0; this_ROI < ROI_list.length; this_ROI++) {
    	runMacro(getDirectory("plugins") +
    		"BB Macros" + File.separator() +
    		"Utilities" + File.separator() +
    		"Select_roi.ijm", ROI_list[this_ROI]);
    	runMacro(getDirectory("plugins") +
    		"BB Macros" + File.separator() +
    		"Fibers Modules" + File.separator() +
    		"Measure_fiber.ijm", ROI_list[this_ROI]);
    	this_ROI_result = File.openAsString(getDirectory("temp") +
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
}