var working_path        = get_working_paths("working_path");
var analysis_path		= get_working_paths("analysis_path");
var obs_unit_ROI_path   = get_working_paths("obs_unit_ROI_path");

var current_image_index = -1;
var is_in_use = false;
var alerts = newArray("No corresponding ROI zip file found for this image.",
                      "At least one channel must have a color that is not 'unused'. (Hit 'Cfg')");
var color_choices = newArray("Unused",
                             "Red",
                             "Green",
                             "Blue",
                             "Gray",
                             "Cyan",
                             "Magenta",
                             "Yellow");

var temp_directory_fibers    = getDirectory("temp") +
                               "BB_macros" + File.separator() +
                               "Fibers" + File.separator();
var temp_directory_utilities = getDirectory("temp") +
                               "BB_macros" + File.separator() +
                               "Utilities" + File.separator();
var directory_txt_data		 = analysis_path +
							   "Fiber_txt_data" + File.separator();


var image_type = retrieve_configuration(1, 1);
var n_channels = retrieve_configuration(1, 2);

var currentColor = "GREEN";

/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Image Viewer Startup" {
    run("Install...", "install=[" + getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Fibers_modules" + File.separator() +
        "Image_viewer_fibers.ijm]");
    cleanup();
    setTool("point");
    run("Colors...", "foreground=white background=black selection=cyan");
    if (!File.exists(directory_txt_data)) File.makeDirectory(directory_txt_data);
}

/*
--------------------------------------------------------------------------------
    MACRO BUTTONS
--------------------------------------------------------------------------------
*/

macro "Return to Fibers Frontend Action Tool - Ca44F36d6H096f6300" {
    cleanup();
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Fibers.ijm");
}

macro "Image Viewer Configuration Action Tool - C037T0b10CT8b09fTdb09g" {

    // Get the old settings to see if the settings get changed
    // This code is almost-exactly repeated below for new settings
    all_old_settings = newArray(2 + (5 * n_channels));
    for (i = 0; i < n_channels; i++) {
        for (j = 0; j < 5; j++) {
            value = retrieve_configuration(3, (j + 1) + (5 * i));
            all_old_settings[j + (5 * i)] = value;
        }
    }
    for (i = 0; i < 2; i++) {
        value = retrieve_configuration(3, (i + 1) + (5 * n_channels));
        all_old_settings[i + (5 * n_channels)] = value;
    }

    color_defaults    = newArray(n_channels);
    mono_min_defaults = newArray(n_channels);
    mono_max_defaults = newArray(n_channels);
    heat_min_defaults = newArray(n_channels);
    heat_max_defaults = newArray(n_channels);
    for (i = 0; i < n_channels; i++) {
        value = retrieve_configuration(3, 1 + (5 * i));
        color_defaults[i]    = value;
        value = retrieve_configuration(3, 2 + (5 * i));
        mono_min_defaults[i] = value;
        value = retrieve_configuration(3, 3 + (5 * i));
        mono_max_defaults[i] = value;
        value = retrieve_configuration(3, 4 + (5 * i));
        heat_min_defaults[i] = value;
        value = retrieve_configuration(3, 5 + (5 * i));
        heat_max_defaults[i] = value;
    }
    display_choices = newArray("RGB Composite",
                               "Merged Stack",
                               "Single Monochrome Images",
                               "Single Heatmap Images");
    display_default     = retrieve_configuration(3, 1 + (5 * n_channels));
    auto_contrast_default = retrieve_configuration(3, 2 + (5 * n_channels));

    Dialog.create("Image Viewer Settings");
    Dialog.addChoice("Display images as: ", display_choices, display_default);
    Dialog.setInsets(0, 20, 0);
    Dialog.addCheckbox("Auto contrast", auto_contrast_default);
    Dialog.addMessage("If 'Auto contrast' is selected, then\n" +
                      "the monotone display min and max values\n" +
                      "below are ignored and set automatically.");
    Dialog.addMessage("Channel options");

    for (i = 0; i < n_channels; i++) {
        Dialog.setInsets(0, 20, 0);
        Dialog.addChoice("Display color: ", color_choices, color_defaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Monotone display min value: ", mono_min_defaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Monotone display max value: ", mono_max_defaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Heat map display min value: ", heat_min_defaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Heat map display max value: ", heat_max_defaults[i]);
    }
    Dialog.show();

    display_choice     = Dialog.getChoice();
    auto_contrast_choice = Dialog.getCheckbox();

    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Fibers_modules" + File.separator() +
        "Fibers_configurator.ijm",
        "change|3|" + toString(1 + (5 * n_channels)) + "|" + display_choice);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Fibers_modules" + File.separator() +
        "Fibers_configurator.ijm",
        "change|3|" + toString(2 + (5 * n_channels)) + "|" + auto_contrast_choice);

    for (i = 0; i < n_channels; i++) {
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Fibers_modules" + File.separator() +
            "Fibers_configurator.ijm", 
            "change|3|" + toString(1 + (5 * i)) + "|" + Dialog.getChoice());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Fibers_modules" + File.separator() +
            "Fibers_configurator.ijm", 
            "change|3|" + toString(2 + (5 * i)) + "|" + Dialog.getNumber());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Fibers_modules" + File.separator() +
            "Fibers_configurator.ijm", 
            "change|3|" + toString(3 + (5 * i)) + "|" + Dialog.getNumber());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Fibers_modules" + File.separator() +
            "Fibers_configurator.ijm", 
            "change|3|" + toString(4 + (5 * i)) + "|" + Dialog.getNumber());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Fibers_modules" + File.separator() +
            "Fibers_configurator.ijm", 
            "change|3|" + toString(5 + (5 * i)) + "|" + Dialog.getNumber());
    }

    // Get the new settings to see if the settings got changed
    // This code is almost-exactly repeated above for old settings
    all_new_settings = newArray(2 + (5 * n_channels));
    for (i = 0; i < n_channels; i++) {
        for (j = 0; j < 5; j++) {
            value = retrieve_configuration(3, (j + 1) + (5 * i));
            all_new_settings[j + (5 * i)] = value;
        }
    }
    for (i = 0; i < 2; i++) {
        value = retrieve_configuration(3, (i + 1) + (5 * n_channels));
        all_new_settings[i + (5 * n_channels)] = value;
    }

    changed = false;
    for (i = 0; i < all_old_settings.length; i++) {
        if (all_old_settings[i] != all_new_settings[i]) {
            changed = true;
        }
    }
    if (changed) {
        is_in_use = true;
        cleanup();
        image_list = get_file_list_from_directory(working_path, image_type);
        image_list_no_ext = newArray();
        for (i = 0; i < image_list.length; i++) {
            append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            image_list_no_ext = Array.concat(image_list_no_ext, append);
        }

        if (current_image_index > image_list.length - 1 || current_image_index < 0) {
            current_image_index = 0;
        }
        image = image_list_no_ext[current_image_index];
        display_image(image);
        is_in_use = false;
    }
}

macro "Load Previous Image (Shortcut Key is F1) Action Tool - C22dF36c6H096f6300" {
    if (!is_in_use) {
        is_in_use = true;
        cleanup();
        image_list = get_file_list_from_directory(working_path, image_type);
        image_list_no_ext = newArray();
        for (i = 0; i < image_list.length; i++) {
            append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            image_list_no_ext = Array.concat(image_list_no_ext, append);
        }
        current_image_index--;
        if (current_image_index < 0) {
            current_image_index = image_list.length - 1;
        }
        image = image_list_no_ext[current_image_index];
        display_image(image);

        if (File.exists(obs_unit_ROI_path + image + ".zip")) {
            roiManager("Open", obs_unit_ROI_path + image + ".zip");
        }
        redrawOverlay();

        is_in_use = false;
    }
}

macro "Load Image Action Tool - C037T0707LT4707OT9707ATe707DT2f08IT5f08MTcf08G" {
    is_in_use = false;
    cleanup();
    image_list = get_file_list_from_directory(working_path, image_type);
    image_list_no_ext = newArray();
    for (i = 0; i < image_list.length; i++) {
        append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
        image_list_no_ext = Array.concat(image_list_no_ext, append);
    }
    Dialog.create("Select Image");
    Dialog.addChoice("Image: ", image_list_no_ext, image_list_no_ext[0]);
    Dialog.show();
    image = Dialog.getChoice();

    for (i = 0; i < image_list_no_ext.length; i++) {
        if (image == image_list_no_ext[i]) {
            current_image_index = i;
            i = image_list_no_ext.length;
        }
    }

    if (File.exists(obs_unit_ROI_path + image + ".zip")) {
        roiManager("Open", obs_unit_ROI_path + image + ".zip");
    }
    redrawOverlay();

    display_image(image);
}

macro "Load Next Image (Shortcut Key is F2) Action Tool - C22dF06c6Hf9939f00" {
    if (!is_in_use) {
        is_in_use = true;
        cleanup();
        image_list = get_file_list_from_directory(working_path, image_type);
        image_list_no_ext = newArray();
        for (i = 0; i < image_list.length; i++) {
            append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            image_list_no_ext = Array.concat(image_list_no_ext, append);
        }
        current_image_index++;
        if (current_image_index > image_list.length - 1) {
            current_image_index = 0;
        }
        image = image_list_no_ext[current_image_index];
        display_image(image);

        if (File.exists(obs_unit_ROI_path + image + ".zip")) {
            roiManager("Open", obs_unit_ROI_path + image + ".zip");
        }
        redrawOverlay();

        is_in_use = false;
    }
}

macro "Update ROI File Action Tool - C037T0707ST5707AT9707VTe707ET0f08RT6f08OTdf08I" {
	updateROIFile();
}

/*
--------------------------------------------------------------------------------
    MACRO SHORTCUT KEYS
--------------------------------------------------------------------------------
*/

macro "Load Previous Image [f1]" {
    if (!is_in_use) {
        is_in_use = true;
        cleanup();
        image_list = get_file_list_from_directory(working_path, image_type);
        image_list_no_ext = newArray();
        for (i = 0; i < image_list.length; i++) {
            append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            image_list_no_ext = Array.concat(image_list_no_ext, append);
        }
        current_image_index--;
        if (current_image_index < 0) {
            current_image_index = image_list.length - 1;
        }
        image = image_list_no_ext[current_image_index];
        display_image(image);

        if (File.exists(obs_unit_ROI_path + image + ".zip")) {
            roiManager("Open", obs_unit_ROI_path + image + ".zip");
        }
        redrawOverlay();

        is_in_use = false;
    }
}

macro "Load Next Image [f2]" {
    if (!is_in_use) {
        is_in_use = true;
        cleanup();
        image_list = get_file_list_from_directory(working_path, image_type);
        image_list_no_ext = newArray();
        for (i = 0; i < image_list.length; i++) {
            append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            image_list_no_ext = Array.concat(image_list_no_ext, append);
        }
        current_image_index++;
        if (current_image_index > image_list.length - 1) {
            current_image_index = 0;
        }
        image = image_list_no_ext[current_image_index];
        display_image(image);

        if (File.exists(obs_unit_ROI_path + image + ".zip")) {
            roiManager("Open", obs_unit_ROI_path + image + ".zip");
        }
        redrawOverlay();

        is_in_use = false;
    }
}

macro "Set Current Color To Green [f5]" {
	currentColor = "GREEN";
	print("Segment color is now Green");
}

macro "Set Current Color To Red [f6]" {
	currentColor = "RED";
	print("Segment color is now Red");
}

macro "Set Current Color To Black [f7]" {
	currentColor = "BLACK";
	print("Segment color is now Black");
}

// Add a point selection to the ROI manager.
macro "Add Point [f9]" {
	// This is the header for the txt data file that contains information on
	//   each fiber segment.
	//						Column name		Column index
	txt_data_header = newArray("Image",			// 1
							   "Fiber",  		// 2
							   "Segment",		// 3
							   "x1",     		// 4
							   "y1",     		// 5
							   "x2",     		// 6
							   "y2",     		// 7
							   "color");  		// 8

	// Check to make sure this macro can be run in a meaningful way. If so,
	//   add the new point and rename it to something we can easily find later.
	if (IJ.getToolName() != "point") 	exit("Single point selection tool required.");
	if (selectionType != 10) 			exit("Single point selection required.");
	if (current_image_index == -1) 		exit("No images are open");
	roiManager("Add");
	roiManager("Select", roiManager("Count") - 1);
	roiManager("Rename", "TEMPORARY NEW POINT");

	// Get the name of the current image. This will be the same name as the ROI zip
	//   file and txt_data file.
    image_list = get_file_list_from_directory(working_path, image_type);
    image_list_no_ext = newArray();
    for (i = 0; i < image_list.length; i++) {
        append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
        image_list_no_ext = Array.concat(image_list_no_ext, append);
    }
    image = image_list_no_ext[current_image_index];

	// The next block of code should ultimately tell us how many Fibers have
	//   already been measured for this image. Fiber measurements are stored in
	//   a txt file in ./Analysis/Fiber_txt_data/. If no file exists, then skip this
	//   block; we are on Fiber 001. Otherwise, get the highest Fiber number from
	//   this file. The new Fiber to which we are now assigning points is the next one.
    fiber_number = 0;
    if (!File.exists(directory_txt_data + image + ".txt")) {
    	fiber_number++; // Increment to the next (first) fiber.
    } else {
    	data = File.openAsString(directory_txt_data + image + ".txt");
    	data = split(data, "\n");
    	data = Array.slice(data, 1, data.length); // Remove the header.
    	for (i = 0; i < data.length; i++) {
    		if (getFieldFromTdf(data[i], 2, true) > fiber_number) fiber_number++;
    	}
    	fiber_number++; // Increment to the next fiber.
    }
    
    // The next block of code should tell us how many segments have currently
    //   been measured. Each segment will ultimately be combined into a single
    //   polyline ROI, built from each point in numerical order as they are
    //   named in the ROI manager. Furthermore, each point ROI name contains
    //   information about segment color, which is ultimately used when the
    //   points are converted into a Fiber polyline to assign color to each
    //   segment in the data txt file. For now, just tell us what point we're on.
    point_number = 0;
    points = countROIsWithName("NEW FIBER " + IJ.pad(fiber_number, 3) + " POINT");
    point_number += points;
    point_number++; // Increment to the next point.

    // Add the next point to the ROI manager. 
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Utilities" + File.separator() +
        "Select_roi.ijm", "TEMPORARY NEW POINT");
    roiManager("Rename", "NEW FIBER " + IJ.pad(fiber_number, 3) +
    					 " POINT " + IJ.pad(point_number, 3) +
    					 " " + currentColor);
    print("Fiber " + fiber_number + " New Point " + IJ.pad(point_number, 3) + " added.");

    // Check to see that we successfully added the last point. This means that
    //   the TEMPORARY NEW POINT was renamed to something else and is no longer
    //   in the list. If not, then stop here and complain to the user.
    if (countROIsWithName("TEMPORARY NEW POINT") != 0)
    	exit ("Something went wrong here.\n" +
    		  "The TEMPORARY NEW POINT ROI should have been renamed.");

    redrawOverlay();
    updateROIFile();
}

/*
--------------------------------------------------------------------------------
    FUNCTIONS
--------------------------------------------------------------------------------
*/

function cleanup() {
    run("Close All");
    if (isOpen("Log"))         { selectWindow("Log");         run("Close"); }
    if (isOpen("Results"))     { selectWindow("Results");     run("Close"); }
    if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
}

// Displays an image with the provided argument name as the name of the image file
//   without the extension (this is retrieved from the experiment's configuration).
//   Applies all the settings from the experiment's configuration file such as
//   lookup tables.
function display_image(image) {
    setBatchMode(true);
    display_choice     = retrieve_configuration(3, 1 + (5 * n_channels));
    auto_contrast_choice = retrieve_configuration(3, 2 + (5 * n_channels));
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Utilities" + File.separator() +
        "Convert_to_tiff.ijm",
        working_path + image + image_type + "|" + image_type + "|" + "Do nothing");
    open(temp_directory_utilities + "convert_to_tiff_temp.tif");
    deleted = File.delete(temp_directory_utilities + "convert_to_tiff_temp.tif");

    alert = "";

    labels = newArray();
    colors = newArray();
    mins   = newArray();
    maxes  = newArray();
    getDimensions(width, height, channels, slices, frames);
    for (i = 0; i < n_channels; i++) {
        label = retrieve_configuration(2, (i + 1));
        color = retrieve_configuration(3, 1 + (5 * i));
        if (color != "Unused") {
            if (display_choice == "Single Monochrome Images" ||
                display_choice == "RGB Composite" ||
                display_choice == "Merged Stack") {
                min = retrieve_configuration(3, 2 + (5 * i));
                max = retrieve_configuration(3, 3 + (5 * i));
            } else if (display_choice == "Single Heatmap Images") {
                min = retrieve_configuration(3, 4 + (5 * i));
                max = retrieve_configuration(3, 5 + (5 * i));
            } else {
                exit("display_choice must be one of the three options.");
            }
            labels = Array.concat(labels, label);
            colors = Array.concat(colors, color);
            mins   = Array.concat(mins, min);
            maxes  = Array.concat(maxes, max);
            selectImage(1);
            Stack.setPosition(1 + i, 1, 1);
            run("Select All");
            run("Copy");
            newImage("Ch " + toString(i + 1) + "_image_temp", "16-bit black", width, height, 1, 1, 1);
            selectImage(nImages());
            run("Paste");
            if (display_choice == "Single Monochrome Images" ||
                display_choice == "RGB Composite" ||
                display_choice == "Merged Stack") {
                if (color == "Gray") {
                    color = "Grays";
                }
                run(color);
            } else if (display_choice == "Single Heatmap Images") {
                run("Fire");
            }
            saveAs("Tiff", temp_directory_fibers + "Ch_" + toString(i + 1) + "_image_temp.tif");
            close();
        }
    }
    run("Close All");

    temp_files = get_file_list_from_directory(temp_directory_fibers, "_image_temp.tif");
    if (temp_files.length == 0) {
        alert = alerts[1];
    }

    if (alert != alerts[1]) {
        if (display_choice == "Single Monochrome Images" || display_choice == "Single Heatmap Images") {
            for (i = 0; i < temp_files.length; i++) {
                open(temp_directory_fibers + temp_files[i]);
                deleted = File.delete(temp_directory_fibers + temp_files[i]);
                
                if (auto_contrast_choice == 1 && display_choice == "Single Monochrome Images") {
                    min_max = get_min_max();
                    setMinAndMax(min_max[0], min_max[1]);
                } else {
                    setMinAndMax(mins[i], maxes[i]);
                }

                saveAs("Tiff", temp_directory_fibers + temp_files[i]);
                run("Close All");
            }
            setBatchMode(false);
            for (i = 0; i < temp_files.length; i++) {
                open(temp_directory_fibers + temp_files[i]);
                deleted = File.delete(temp_directory_fibers + temp_files[i]);
                channel = substring(temp_files[i], 0, indexOf(temp_files[i], "_image_temp.tif"));
                title = image + " " + channel + " " + labels[i] + ".tif";
                rename(title);
                width = 480;
                height = 480;
                x = floor(i / 2) * 480;
                if (i % 2 == 0) {
                    y = 0;
                } else {
                    y = 502;
                }
                eval("script", frame_script(image + " " + channel + " " + labels[i] + ".tif", width, height, x, y));
                run("Scale to Fit");
                run("Select None");
            }

        } else if (display_choice == "RGB Composite" || display_choice == "Merged Stack") {

            temp_files = get_file_list_from_directory(temp_directory_fibers, "_image_temp.tif");
            for (i = 0; i < temp_files.length; i++) {
                open(temp_directory_fibers + temp_files[i]);
                deleted = File.delete(temp_directory_fibers + temp_files[i]);
                title = image + " " + labels[i] + ".tif";
                selectImage(nImages());
                rename(title);
                if (auto_contrast_choice == 1) {
                    min_max = get_min_max();
                    setMinAndMax(min_max[0], min_max[1]);
                } else {
                    setMinAndMax(mins[i], maxes[i]);
                }
            }

            merge_channels_str = "";
            for (i = 1; i < color_choices.length; i++) {
                for (j = 0; j < colors.length; j++) {
                    if (color_choices[i] == colors[j]) {
                        merge_channels_str = merge_channels_str + "c" + i + "=[" + image + " " + labels[j] + ".tif] ";
                        break;
                    }
                }
            }
            merge_channels_str = merge_channels_str + "create";
            if (display_choice == "RGB Composite") {
                run("Merge Channels...", merge_channels_str);
                run("RGB Color");
                selectImage(nImages());
                saveAs(temp_directory_fibers + "RGB_composite_image_temp.tif");
                run("Close All");

                open(temp_directory_fibers + "RGB_composite_image_temp.tif");
                deleted = File.delete(temp_directory_fibers + "RGB_composite_image_temp.tif");

                saveAs(temp_directory_fibers + "RGB_composite_image_temp.tif");
                run("Close All");

                setBatchMode(false);
                open(temp_directory_fibers + "RGB_composite_image_temp.tif");
                deleted = File.delete(temp_directory_fibers + "RGB_composite_image_temp.tif");
                title = image + " RGB Composite";
                rename(title);
            } else {
                run("Merge Channels...", merge_channels_str);

                selectImage(nImages());
                saveAs(temp_directory_fibers + "Merged_Stack_image_temp.tif");
                run("Close All");

                open(temp_directory_fibers + "Merged_Stack_image_temp.tif");
                deleted = File.delete(temp_directory_fibers + "Merged_Stack_image_temp.tif");

                saveAs(temp_directory_fibers + "Merged_Stack_image_temp.tif");
                run("Close All");

                setBatchMode(false);
                open(temp_directory_fibers + "Merged_Stack_image_temp.tif");
                deleted = File.delete(temp_directory_fibers + "Merged_Stack_image_temp.tif");
                title = image + " Merged Stack";
                rename(title);
            }
        }
        
    }
    roiManager("Reset");
    if (lengthOf(alert) > 0) {
        showStatus(alert);
    }
}

// Resize and move a JAVA AWT Window object.
function frame_script(title, width, height, x, y) {
    return "frame = WindowManager.getWindow(\"" + title + "\"); if (frame != null) {frame.setSize(" + width + ", " + height + "); frame.setLocation(" + x + ", " + y + ");}";
}

// Return an array with two values that correspond to the minimum and maximum display
//   values as determined by the modal pixel value and FWHM for an image.
function get_min_max() {
    run("Set Measurements...", "mean standard modal min median redirect=None decimal=3");
    run("Measure");
    min = getResult("Min");
    getHistogram(values, counts, 256, min, 4064);
    Fit.doFit("Gaussian", values, counts);
    mode = Fit.p(2);
    stdev = Fit.p(3);
    FWHM = 2*sqrt(2*log(2))*stdev;
    offset = FWHM * 0;
    min = mode + offset;
    max = mode + offset + FWHM*3;
    result = newArray(min, max);
    return result;
}

// Return an array list of filenames in a directory ending with
//   the suffix argument.
function get_file_list_from_directory(directory, suffix) {
    file_list_all = getFileList(directory);
    file_list_ext = newArray();
    for (i = 0; i < file_list_all.length; i++) {
        if (endsWith(file_list_all[i], suffix) == true) {
            file_list_ext = Array.concat(file_list_ext, file_list_all[i]);
        }
    }
    return file_list_ext;
}

// Runs the global configurator macro, which writes the resulting path
//     to a text file in the temp directory. This result is read back and
//     returned by the function and the temp file is deleted.
function get_working_paths(path_arg) {
    temp_directory_fibers = getDirectory("temp") +
                     "BB_macros" + File.separator() +
                     "Fibers" + File.separator();
    valid_path_args = newArray("working_path",
                               "analysis_path",
                               "obs_unit_ROI_path",
                               "analysis_setup_file");
    valid_arg = false;
    for (i = 0; i < valid_path_args.length; i++) {
        if (matches(path_arg, valid_path_args[i])) {
            valid_arg = true;
            i = valid_path_args.length;
        }
    }
    if (!valid_arg) {
        exit(path_arg + " is not recognized as\n" +
             "a valid argument for get_working_paths.");
    }
    if (File.exists(getDirectory("plugins") +
                    "BB_macros" + File.separator() +
                    "Fibers_modules" + File.separator() +
                    "Global_configuration_fibers.txt") == true) {
        runMacro(getDirectory("plugins") +
                 "BB_macros" + File.separator() +
                 "Fibers_modules" + File.separator() +
                 "Global_configurator_fibers.ijm", path_arg);
        retrieved = File.openAsString(temp_directory_fibers + "g_config_temp.txt");
        deleted = File.delete(temp_directory_fibers + "g_config_temp.txt");
        retrieved = split(retrieved, "\n");
        return retrieved[0];
    } else {
        exit("Global configuration not found.");
    }
}

// Retrieve a single value from this experiment's setup file,
//   or all values in that block if line_index is 'all'.
function retrieve_configuration(block_index, line_index) {
    runMacro(getDirectory("plugins") +
             "BB_macros" + File.separator() +
             "Fibers_modules" + File.separator() +
             "Fibers_configurator.ijm",
             "retrieve|" + block_index + "|" + line_index);
    retrieved = File.openAsString(temp_directory_fibers + "config_temp.txt");
    deleted = File.delete(temp_directory_fibers + "config_temp.txt");
    retrieved = split(retrieved, "\n");
    return retrieved[0];
}

// Retrieve a single value from the Fibers macro set global
//   settings, or all values in that block if line_index is
//   'all'.
function retrieve_g_configuration(block_index, line_index) {
    runMacro(getDirectory("plugins") +
             "BB_macros" + File.separator() +
             "Fibers_modules" + File.separator() +
             "Global_configurator_fibers.ijm",
             "retrieve|" + block_index + "|" + line_index);
    retrieved = File.openAsString(temp_directory_fibers + "g_config_temp.txt");
    deleted = File.delete(temp_directory_fibers + "g_config_temp.txt");
    retrieved = split(retrieved, "\n");
    return retrieved[0];
}

// Utility function to count the number of ROIs in the ROI manager
//   containing the substring 'string'. Case-sensitive. If an ROI
//   is currently selected, then return the selection to that ROI
//   when finished.
function countROIsWithName(string) {
	if (roiManager("Count") == 0) return 0;
	selectionIndex = roiManager("Index");
	counter = 0;
	for (i = 0; i < roiManager("Count"); i++) {
		roiManager("Select", i);
		name = Roi.getName();
		if (indexOf(name, string) != -1) counter++;
	}
	if (selectionIndex != -1) roiManager("Select", selectionIndex);
	return counter;
}

// Utility function to delete every ROI in the ROI manager
//   containing the substring 'string'. Case-sensitive.
function removeROIsWithName(string) {
	if (roiManager("Count") == 0) return;
	i = 0;
	do {
		roiManager("Select", i);
		name = Roi.getName();
		if (indexOf(name, string) != -1) roiManager("Delete"); else i++;
	} while (i < roiManager("Count"));
}

// Utility function to retrieve a single value from a single line
//   of tab-separated text.
function getFieldFromTdf(inputString, field, isNumberBoolean) {
	field -= 1;
	result = replace(inputString, "^(.+?\t){" + field + "}", "");
	result = replace(result, "\t.*", "");
	if (isNumberBoolean == true) { result = parseInt(result); }
	return result;
}

// Redraw the overlay, showing all the current fiber traces and selected points.
//   The overlay is drawn from information from the txt data file (complete Fiber
//   traces) and the ROI manager (individual points that have not yet been merged
//   into Fiber traces).
function redrawOverlay() {
    Overlay.remove();

    // First, draw overlays corresponding to each point in the ROI manager.
    if (roiManager("Count") > 0) {
	    outerOvalSize = 19; // This should be an odd number.
	    middleOvalSize = outerOvalSize - 2;
	    innerOvalSize = outerOvalSize - 4;
	    for (i = 0; i < roiManager("Count"); i++) {
	    	roiManager("Select", i);
	    	name = Roi.getName();
	    	if (indexOf(name, "NEW FIBER ") != -1 && indexOf(name, " POINT ") != -1) {
	    		color = substring(name,
	    						  lengthOf("NEW FIBER 001 POINT 001 "), // Dummy string; just need length.
	    						  lengthOf(name));
	    		if (color == "BLACK") color = "#ff555555"; else color = toLowerCase(color);
	    		getSelectionBounds(x, y, width, height);
	    		makeOval(x - (outerOvalSize - 1)/2, y - (outerOvalSize - 1)/2, outerOvalSize, outerOvalSize);
	    		Overlay.addSelection("", 0, "black");
	    		makeOval(x - (middleOvalSize - 1)/2, y - (middleOvalSize - 1)/2, middleOvalSize, middleOvalSize);
	    		Overlay.addSelection("", 0, "white");
	    		makeOval(x - (innerOvalSize - 1)/2, y - (innerOvalSize - 1)/2, innerOvalSize, innerOvalSize);
	    		Overlay.addSelection("", 0, color);
	    		run("Select None");
	    	}
	    }
    }

    // Now draw overlays corresponding to each segment in the txt data file.
    image_list = get_file_list_from_directory(working_path, image_type);
    image_list_no_ext = newArray();
    for (i = 0; i < image_list.length; i++) {
        append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
        image_list_no_ext = Array.concat(image_list_no_ext, append);
    }
    image = image_list_no_ext[current_image_index];
    if (File.exists(directory_txt_data + image + ".txt")) {
	    data = File.openAsString(directory_txt_data + image + ".txt");
	    data = split(data, "\n");
	    data = Array.slice(data, 1, data.length);
	    if (data.length > 0) {
	    	// Draw each segment.
	    	for (i = 0; i < data.length; i++) {
	    		x1 = getFieldFromTdf(data[i], 4, true);
	    		y1 = getFieldFromTdf(data[i], 5, true);
	    		x2 = getFieldFromTdf(data[i], 6, true);
	    		y2 = getFieldFromTdf(data[i], 7, true);
	    		color = getFieldFromTdf(data[i], 8, false);
	    		if (toLowerCase(color) == "black") color = "ff555555"; else color = toLowerCase(color);
	    		makeLine(x1, y1, x2, y2);
	    		Overlay.addSelection(color, 5);
	    		makeRectangle(x1 - 2, y1 - 2, 4, 4);
	    		Overlay.addSelection("", 0, "black");
	    		run("Select None");
	    	}
	    }
    }
    Overlay.show();
}

// Utility function to save any changes made to the ROI zip file.
function updateROIFile() {
	   if (!isOpen("ROI Manager")) {
        showStatus("ROI Manager is not open.");
    } else if (roiManager("Count") < 1) {
        showStatus("No ROIs to save.");
    } else {
        image_list = get_file_list_from_directory(working_path, image_type);
        image_list_no_ext = newArray();
        for (i = 0; i < image_list.length; i++) {
            append = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            image_list_no_ext = Array.concat(image_list_no_ext, append);
        }
        image = image_list_no_ext[current_image_index];
        if (!File.exists(obs_unit_ROI_path)) File.makeDirectory(obs_unit_ROI_path);
        roiManager("Save", obs_unit_ROI_path + image + ".zip");
        showStatus(image + ".zip" + " updated.");
    }
}