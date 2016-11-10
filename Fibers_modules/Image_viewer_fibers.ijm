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
    show_traces_default = retrieve_configuration(3, 2 + (5 * n_channels));

    Dialog.create("Image Viewer Settings");
    Dialog.addChoice("Display images as: ", display_choices, display_default);
    Dialog.setInsets(0, 20, 0);
    Dialog.addMessage("Overlay options");
    Dialog.setInsets(0, 20, 0);
    Dialog.addCheckbox("Show fiber traces", show_traces_default);
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
    show_traces_choice = Dialog.getCheckbox();

    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Fibers_modules" + File.separator() +
        "Fibers_configurator.ijm",
        "change|3|" + toString(1 + (5 * n_channels)) + "|" + display_choice);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Fibers_modules" + File.separator() +
        "Fibers_configurator.ijm",
        "change|3|" + toString(2 + (5 * n_channels)) + "|" + show_traces_choice);

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

    display_image(image);
}

macro "Load Next Image (Shortcut Key is F2) Action Tool - C22dF06c6Hf9939f00" {
    if (is_in_use == false) {
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
        is_in_use = false;
    }
}

macro "Manually Add Fiber Action Tool (Shortcut Key is F5) - C037F0055C307F6055C370Fc055C031F0855C604F6b55C440Fce55" {
    analysis_path = get_working_paths("analysis_path");

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
        is_in_use = false;
    }
}

macro "Load Next Image [f2]" {
    if (is_in_use == false) {
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
        is_in_use = false;
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
    show_traces_choice = retrieve_configuration(3, 2 + (5 * n_channels));
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Utilities" + File.separator() +
        "Convert_to_tiff.ijm",
        working_path + image + image_type + "|" + image_type + "|" + z_series_option);
    open(temp_directory_utilities + "convert_to_tiff_temp.tif");
    deleted = File.delete(temp_directory_utilities + "convert_to_tiff_temp.tif");

    alert = "";
    if (show_traces_choice == 1) {
        if (File.exists(obs_unit_ROI_path + image + ".zip") == true) {
            roiManager("Open", obs_unit_ROI_path + image + ".zip");

            obs_units = newArray();
            for (i = 0; i < roiManager("Count"); i++) {
                roiManager("Select", i);
                ROI_name = Roi.getName();
                if (indexOf(ROI_name, "FIBER ") != -1) {
                    obs_units = Array.concat(obs_units,
                                             substring(ROI_name,
                                                       lengthOf("FIBER "),
                                                       lengthOf(ROI_name)));
                }
            }

            do {
                deleted = false;
                for (i = 0; i < roiManager("Count"); i++) {
                    roiManager("Select", i);
                    ROI_name = Roi.getName();
                    if (show_traces_choice == 0 && indexOf(ROI_name, "FIBER ") != -1) {
                        roiManager("Delete");
                        deleted = true;
                    }
                }
            } while (deleted == true);

            if (roiManager("Count") > 0) {
                roiManager("Save", temp_directory_fibers + "overlay_rois_temp.zip");
            }
        } else {
            alert = alerts[0];
        }
    }

    labels = newArray();
    colors = newArray();
    mins   = newArray();
    maxes  = newArray();
    getDimensions(width, height, channels, slices, frames);
    for (i = 0; i < n_channels; i++) {
        label = retrieve_configuration(2, i);
        color = retrieve_configuration(3, 1 + (5 * i));
        if (color != "Unused") {
            if (display_choice == "Single Monochrome Images" || display_choice == "RGB Composite") {
                min = retrieve_configuration(3, 2 + (5 * i));
                max = retrieve_configuration(3, 3 + (5 * i));
            } else if (display_choice == "Single Heatmap Images") {
                min = retrieve_configuration(3, 4 + (5 * i));
                max = retrieve_configuration(3, 5 + (5 * i));
            }
            labels = Array.concat(labels, label);
            colors = Array.concat(colors, color);
            mins   = Array.concat(mins, min);
            maxes  = Array.concat(maxes, max);
            selectImage(1);
            Stack.setPosition(1 + i, 1, 1);
            run("Select All");
            run("Copy");
            newImage("Ch " + toString(i + 1) + " temp image", "16-bit black", width, height, 1, 1, 1);
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
                if (show_traces_choice == 1) {
                    if (File.exists(temp_directory_fibers + "overlay_rois_temp.zip") == true) {
                        roiManager("Reset");
                        roiManager("Open", temp_directory_fibers + "overlay_rois_temp.zip");
                        run("Overlay Options...", "stroke=white width=0 fill=none");
                        for (j = 0; j < roiManager("Count"); j++) {
                            roiManager("Select", j);
                            run("Add Selection...");
                        }
                    }
                }
                setMinAndMax(mins[i], maxes[i]);
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
//              eval("script", frameScript(image + " " + channel + " " + labels[i] + ".tif", width, height, x, y));
                run("Scale to Fit");
                run("Select None");
            }

        } else if (display_choice == "RGB Composite") {

            temp_files = get_file_list_from_directory(getDirectory("temp"), " temp image.tif");
            for (i=0; i<temp_files.length; i++) {
                open(getDirectory("temp") + temp_files[i]);
                deleted = File.delete(getDirectory("temp") + temp_files[i]);
                title = image + " " + labels[i] + ".tif";
                selectImage(nImages());
                rename(title);
                setMinAndMax(mins[i], maxes[i]);
            }

            mergeChannelsString = "";
            for (i=1; i<color_choices.length; i++) {
                for (j=0; j<colors.length; j++) {
                    if (color_choices[i] == colors[j]) {
                        mergeChannelsString = mergeChannelsString + "c" + i + "=[" + image + " " + labels[j] + ".tif] ";
                        break;
                    }
                }
            }
            mergeChannelsString = mergeChannelsString + "create";
            run("Merge Channels...", mergeChannelsString);
            run("RGB Color");
            selectImage(nImages());
            saveAs(getDirectory("temp") + "RGB composite temp image.tif");
            run("Close All");

            open(getDirectory("temp") + "RGB composite temp image.tif");
            deleted = File.delete(getDirectory("temp") + "RGB composite temp image.tif");
            if (show_traces_choice == 1 || globalMaskChoice == 1 ||  submaskChoice == 1) {
                if (File.exists(getDirectory("temp") + "overlay_rois_temp.zip") == true) {
                    roiManager("Reset");
                    roiManager("Open", getDirectory("temp") + "overlay_rois_temp.zip");
                    run("Overlay Options...", "stroke=#FFFFFFFF width=0 fill=none");
                    for (j=0; j<roiManager("Count"); j++) {
                        roiManager("Select", j);
                        run("Add Selection...");
                    }
                    run("Select None");
                }
            }
            saveAs(getDirectory("temp") + "RGB composite temp image.tif");
            run("Close All");

            setBatchMode(false);
            open(getDirectory("temp") + "RGB composite temp image.tif");
            deleted = File.delete(getDirectory("temp") + "RGB composite temp image.tif");
            title = image + " RGB Composite";
            rename(title);
        }
        
    }
    if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
    if (showRoiManager == 1 && File.exists(obs_unit_ROI_path + image + ".zip") == true) {
        if (File.exists(getDirectory("temp") + "overlay_rois_temp.zip") == true) {
            roiManager("Open", getDirectory("temp") + "overlay_rois_temp.zip");
        }
    }
    if (File.exists(getDirectory("temp") + "overlay_rois_temp.zip")) { deleted = File.delete(getDirectory("temp") + "overlay_rois_temp.zip"); }
    if (lengthOf(alert) > 0) {
        showStatus(alert);
    }
}

function frameScript(title, width, height, x, y) {
    return "frame = WindowManager.getFrame(\"" + title + "\"); if (frame != null) {frame.setSize(" + width + ", " + height + "); frame.setLocation(" + x + ", " + y + ");}";
}

function getFieldFromTdf(inputString, field, isNumberBoolean) {
    field -= 1;
    result = replace(inputString, "^(.+?\t){" + field + "}", "");
    result = replace(result, "\t.*", "");
    if (isNumberBoolean == true) { result = parseInt(result); }
    return result;
}

function get_file_list_from_directory(directory, extension) {
    file_list_all = getFileList(directory);
    file_list_ext = newArray();
    for (i = 0; i < file_list_all.length; i++) {
        if (endsWith(file_list_all[i], extension) == true) {
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