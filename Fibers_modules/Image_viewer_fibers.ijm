var working_path        = get_working_paths("working_path");
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

var image_type = retrieve_configuration(1, 1);
var n_channels = retrieve_configuration(1, 2);

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
    setTool("polyline");
    run("Colors...", "foreground=white background=black selection=cyan");
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
            roiManager("Show all with labels");
        }

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
        roiManager("Show all");
        run("Labels...", "color=cyan font=10 show use");
    }

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
            roiManager("Show all");
            run("Labels...", "color=cyan font=10 show use");
        }

        is_in_use = false;
    }
}

macro "Manually Add Fiber Action Tool (Shortcut Key is F5) - Cf00Lf096C0f0L963cC037LdadeLbcfc" {
    if (!(selectionType() == 5 || selectionType() == 6)) {
        showStatus("Straight or segmented line selection required.");
    } else {
        obs_unit_ROI_path = get_working_paths("obs_unit_ROI_path");
        if (!File.exists(obs_unit_ROI_path)) File.makeDirectory(obs_unit_ROI_path);
        image_name = getTitle();

        image_list = get_file_list_from_directory(working_path, image_type);
        for (i = 0; i < image_list.length; i++) {
            this_name = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            if (indexOf(image_name, this_name) != -1) {
                zip_name = this_name;
                break;
            }
            if (i == image_list.length - 1)
                exit("The name of this image doesn't match any of the ZVI file names.");
        }

        // See if the zip file containing ROIs exists. If so, open it and count the number
        //   of FIBER ROIs. If not, start the counting from one.
        fiber_ROIs = 1;
        if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
        if (File.exists(obs_unit_ROI_path + zip_name + ".zip")) {
            if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
            roiManager("Open", obs_unit_ROI_path + zip_name + ".zip");
            roiManager("Add");
            roiManager("Select", roiManager("Count") - 1);
            roiManager("Rename", "New selection");
            for (i = 0; i < roiManager("Count"); i++) {
                roiManager("Select", i);
                name = Roi.getName();
                if (indexOf(name, "FIBER") != -1) fiber_ROIs++;
            }
            for (i = 0; i < roiManager("Count"); i++) {
                roiManager("Select", i);
                name = Roi.getName();
                if (matches(name, "New selection")) 
                    roiManager("Rename", "FIBER " + IJ.pad(fiber_ROIs, 2));
            }
        } else {
            roiManager("Add");
            roiManager("Select", roiManager("Count") - 1);
            roiManager("Rename", "FIBER " + IJ.pad(fiber_ROIs, 2));
        }
        roiManager("Save", obs_unit_ROI_path + zip_name + ".zip");
        roiManager("Show all");
        run("Labels...", "color=cyan font=10 show use");
        run("Select None");

        showStatus("Added FIBER " + IJ.pad(fiber_ROIs, 2) + " to " + obs_unit_ROI_path + zip_name + ".zip");
    }
}

macro "Update ROI File Action Tool - C037T0707ST5707AT9707VTe707ET0f08RT6f08OTdf08I" {
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
        roiManager("Save", obs_unit_ROI_path + image + ".zip");
        showStatus(image + ".zip" + " updated.");
    }
}

macro "Check Fibers Action Tool (Shortcut Key is F6) - Cf00Lf096C0f0L963cC037Lf9cfLcfad" {
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
    run("Select None");
    if (ROI_list.length < 1) exit("The ROI list must contain ROIs " +
        "whose names include 'FIBER'.");

    if (Overlay.size == 0) {
        runMacro(getDirectory("plugins") +
                 "BB_macros" + File.separator() +
                 "Fibers_modules" + File.separator() +
                 "Measure_fibers_image.ijm");
        if (!File.exists(temp_directory_fibers + "Measure_fibers_result.txt"))
            exit("Something went wrong here!\n" +
                 "Ran 'Measure_fibers_image.ijm' but couldn't find" +
                 "'Measure_fibers_result.txt' in the temp directory.");

        this_ROI_result = File.openAsString(temp_directory_fibers +
                                            "Measure_fibers_result.txt");
        this_ROI_result = split(this_ROI_result, "\n");
        this_ROI_result_header = Array.slice(this_ROI_result, 0, 1);
        this_ROI_result_data = Array.slice(this_ROI_result, 1, this_ROI_result.length);
        for (this_row = 0; this_row < this_ROI_result_data.length; this_row++) {
            // Paint the line segments on the Overlay.
            redColorAlias = "magenta";
            greenColorAlias = "cyan";
            segment = split(this_ROI_result_data[this_row], "\t");
            x1 = segment[3];
            y1 = segment[4];
            x2 = segment[5];
            y2 = segment[6];
            color = segment[9];
            if (toLowerCase(color) == "red")
                overlayColor = redColorAlias;
            else if (toLowerCase(color) == "green")
                overlayColor = greenColorAlias;
            else
                overlayColor = "white";
            run("Overlay Options...", "stroke=" + overlayColor + " width=6 show");
            makeLine(x1, y1, x2, y2);
            run("Add Selection...");
            run("Select None");
        }
        Overlay.show;
        showStatus("Showing fiber overlay");
    } else {
        run("Remove Overlay");
        roiManager("Show all");
        run("Labels...", "color=cyan font=10 show use");
        showStatus("Removing fiber overlay");
    }
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
            roiManager("Show all");
            run("Labels...", "color=cyan font=10 show use");
        }

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
            roiManager("Show all");
            run("Labels...", "color=cyan font=10 show use");
        }

        is_in_use = false;
    }
}

macro "Manually Add Fiber [f5]" {
    if (!(selectionType() == 5 || selectionType() == 6)) {
        showStatus("Straight or segmented line selection required.");
    } else {
        obs_unit_ROI_path = get_working_paths("obs_unit_ROI_path");
        if (!File.exists(obs_unit_ROI_path)) File.makeDirectory(obs_unit_ROI_path);
        image_name = getTitle();

        image_list = get_file_list_from_directory(working_path, image_type);
        for (i = 0; i < image_list.length; i++) {
            this_name = substring(image_list[i], 0, indexOf(image_list[i], image_type));
            if (indexOf(image_name, this_name) != -1) {
                zip_name = this_name;
                break;
            }
            if (i == image_list.length - 1)
                exit("The name of this image doesn't match any of the ZVI file names.");
        }

        // See if the zip file containing ROIs exists. If so, open it and count the number
        //   of FIBER ROIs. If not, start the counting from one.
        fiber_ROIs = 1;
        if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
        if (File.exists(obs_unit_ROI_path + zip_name + ".zip")) {
            if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
            roiManager("Open", obs_unit_ROI_path + zip_name + ".zip");
            roiManager("Add");
            roiManager("Select", roiManager("Count") - 1);
            roiManager("Rename", "New selection");
            for (i = 0; i < roiManager("Count"); i++) {
                roiManager("Select", i);
                name = Roi.getName();
                if (indexOf(name, "FIBER") != -1) fiber_ROIs++;
            }
            for (i = 0; i < roiManager("Count"); i++) {
                roiManager("Select", i);
                name = Roi.getName();
                if (matches(name, "New selection")) 
                    roiManager("Rename", "FIBER " + IJ.pad(fiber_ROIs, 2));
            }
        } else {
            roiManager("Add");
            roiManager("Select", roiManager("Count") - 1);
            roiManager("Rename", "FIBER " + IJ.pad(fiber_ROIs, 2));
        }
        roiManager("Save", obs_unit_ROI_path + zip_name + ".zip");
        roiManager("Show all");
        run("Labels...", "color=cyan font=10 show use");
        run("Select None");

        showStatus("Added FIBER " + IJ.pad(fiber_ROIs, 2) + " to " + obs_unit_ROI_path + zip_name + ".zip");
    }
}

macro "Check Fibers [f6]" {
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
    run("Select None");
    if (ROI_list.length < 1) exit("The ROI list must contain ROIs " +
        "whose names include 'FIBER'.");

    if (Overlay.size == 0) {
        runMacro(getDirectory("plugins") +
                 "BB_macros" + File.separator() +
                 "Fibers_modules" + File.separator() +
                 "Measure_fibers_image.ijm");
        if (!File.exists(temp_directory_fibers + "Measure_fibers_result.txt"))
            exit("Something went wrong here!\n" +
                 "Ran 'Measure_fibers_image.ijm' but couldn't find" +
                 "'Measure_fibers_result.txt' in the temp directory.");

        this_ROI_result = File.openAsString(temp_directory_fibers +
                                            "Measure_fibers_result.txt");
        this_ROI_result = split(this_ROI_result, "\n");
        this_ROI_result_header = Array.slice(this_ROI_result, 0, 1);
        this_ROI_result_data = Array.slice(this_ROI_result, 1, this_ROI_result.length);
        for (this_row = 0; this_row < this_ROI_result_data.length; this_row++) {
            // Paint the line segments on the Overlay.
            redColorAlias = "magenta";
            greenColorAlias = "cyan";
            segment = split(this_ROI_result_data[this_row], "\t");
            x1 = segment[3];
            y1 = segment[4];
            x2 = segment[5];
            y2 = segment[6];
            color = segment[9];
            if (toLowerCase(color) == "red")
                overlayColor = redColorAlias;
            else if (toLowerCase(color) == "green")
                overlayColor = greenColorAlias;
            else
                overlayColor = "white";
            run("Overlay Options...", "stroke=" + overlayColor + " width=6 show");
            makeLine(x1, y1, x2, y2);
            run("Add Selection...");
            run("Select None");
        }
        Overlay.show;
        showStatus("Showing fiber overlay");
    } else {
        run("Remove Overlay");
        roiManager("Show all");
        run("Labels...", "color=cyan font=10 show use");
        showStatus("Removing fiber overlay");
    }
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
            if (display_choice == "Single Monochrome Images" || display_choice == "RGB Composite") {
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
            if (display_choice == "Single Monochrome Images" || display_choice == "RGB Composite") {
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
                    run("Set Measurements...", "mean standard modal min median redirect=None decimal=3");
                    run("Measure");
                    min1 = getResult("Min");
                    std = getResult("StdDev");
                    getHistogram(values, counts, 256, min1, 4094);
                    Array.getStatistics(counts, min2, max, mean, stdDev);
                    maxLocs = Array.findMaxima(counts, max * 0.5);
                    mode = values[maxLocs[0]];
                    range = std * 2;
                    offset = range * 0;
                    lower = mode + offset;
                    upper = mode + range + offset;
                    setMinAndMax(lower, upper);
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

        } else if (display_choice == "RGB Composite") {

            temp_files = get_file_list_from_directory(temp_directory_fibers, "_image_temp.tif");
            for (i = 0; i < temp_files.length; i++) {
                open(temp_directory_fibers + temp_files[i]);
                deleted = File.delete(temp_directory_fibers + temp_files[i]);
                title = image + " " + labels[i] + ".tif";
                selectImage(nImages());
                rename(title);
                if (auto_contrast_choice == 1) {
                    run("Set Measurements...", "mean standard modal min median redirect=None decimal=3");
                    run("Measure");
                    min1 = getResult("Min");
                    std = getResult("StdDev");
                    getHistogram(values, counts, 256, min1, 4094);
                    Array.getStatistics(counts, min2, max, mean, stdDev);
                    maxLocs = Array.findMaxima(counts, max * 0.5);
                    mode = values[maxLocs[0]];
                    range = std * 2;
                    offset = range * 0;
                    lower = mode + offset;
                    upper = mode + range + offset;
                    setMinAndMax(lower, upper);
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
            run("Merge Channels...", merge_channels_str);
            run("RGB Color");
            selectImage(nImages());
            saveAs(temp_directory_fibers + "RGB_composite_image_temp.tif");
            run("Close All");

            open(temp_directory_fibers + "RGB_composite_image_temp.tif");
            deleted = File.delete(temp_directory_fibers + "RGB_composite_image_temp.tif");

            if (auto_contrast_choice == 1) {

            }

            saveAs(temp_directory_fibers + "RGB_composite_image_temp.tif");
            run("Close All");

            setBatchMode(false);
            open(temp_directory_fibers + "RGB_composite_image_temp.tif");
            deleted = File.delete(temp_directory_fibers + "RGB_composite_image_temp.tif");
            title = image + " RGB Composite";
            rename(title);
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