/*
    This script selects a single ROI from the ROI manager using the ROI's
    	name as the argument.
*/


/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Select_roi" {
    args = getArgument(); // args = "roiName"
    if (lengthOf(args) == 0) {
    	exit("Select_roi.ijm requires an ROI name as its argument.");
    }
    if (roiManager("Count") < 1) {
    	exit("Select_roi.ijm requires at least one ROI in the ROI manager.");
    }

    foundMatch = false;
	for (i = 0; i < roiManager("Count"); i++) {
		roiManager("Select", i);
		name = Roi.getName();
		if (matches(name, args)) {
			submaskRoiIndex = i;
			foundMatch = true;
			i = roiManager("Count");
		}
	}

	if(foundMatch == false) {
		exit("Select_roi.ijm could not find \"" + args + "\" in the ROI manager.");
	}
}