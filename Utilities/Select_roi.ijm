/*
    This script selects a single ROI from the ROI manager using the ROI's
        name as the argument. A second argument is either 'exact', in which
        only exact matches are considered, or 'contains', which matches the
        ROI that contains the string. In both cases, the first ROI that meets
        the matching criteria is selected; consider this when it is possible
        that the ROI manager may contain more than one ROI whose name matches
        the criteria.
*/


/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Select_roi" {
    args = getArgument(); // args = "roiName\t[exact|contains]"
    args = split(args, "\t");
    if (lengthOf(args) != 2) {
        exit("Select_roi.ijm requires an ROI name as its first argument.\n" +
             "Select_roi.ijm requires 'exact' or 'contains' as its second argument.");
    }
    if (roiManager("Count") < 1) {
        exit("Select_roi.ijm requires at least one ROI in the ROI manager.");
    }

    foundMatch = false;
    for (i = 0; i < roiManager("Count"); i++) {
        roiManager("Select", i);
        name = Roi.getName();
        if (toLowerCase(args[1]) == "exact") {
            if (matches(name, args[0])) {
                foundMatch = true;
                i = roiManager("Count");
            }
        } else if (toLowerCase(args[1]) == "contains") {
            if (indexOf(name, args[0]) != -1) {
                foundMatch = true;
                i = roiManager("Count");
            }
        } else {
            exit("The second argument to Select_roi.ijm must be either\n" +
                 "'exact' or 'contains'. '" + args[1] + "' was entered instead.");
        }
    }

    if(foundMatch == false) {
        exit("Select_roi.ijm could not find \"" + args[0] + "\" in the ROI manager.");
    }
}