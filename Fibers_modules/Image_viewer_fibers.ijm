var working_path        = get_working_paths("working_path");
var obs_unit_ROI_path   = get_working_paths("obs_unit_ROI_path");

var current_image_index = -1;
var in_use = false;
var alerts = newArray("No corresponding ROI zip file found for this image.",
                      "No submasks found in the ROI zip file corresponding to this image.",
                      "At least one channel must have a color that is not 'unused'. (Hit 'Cfg')");
var color_choices = newArray("Unused",
                             "Red",
                             "Green",
                             "Blue",
                             "Gray",
                             "Cyan",
                             "Magenta",
                             "Yellow");

var temp_directory = getDirectory("temp") +
                     "BB_macros" + File.separator() +
                     "Fibers" + File.separator();

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
        "Cytology_modules" + File.separator() +
        "Image_viewer.ijm]");
    cleanup();
}

/*
--------------------------------------------------------------------------------
    MACRO BUTTONS
--------------------------------------------------------------------------------
*/

macro "Return to Cytology Frontend Action Tool - Ca44F36d6H096f6300" {
    cleanup();
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology.ijm");
}

macro "Image Viewer Configuration Action Tool - C037T0b10CT8b09fTdb09g" {

    // Get the old settings to see if the settings get changed
    // This code is almost-exactly repeated below for new settings
    allOldSettings = newArray(4 + 5 * n_channels);
    for (i=0; i<n_channels; i++) {
        for (j=0; j<5; j++) {
            value = retrieve_configuration(2, j + 5 * i);
            allOldSettings[j + 5 * i] = value;
        }
    }
    for (i=0; i<4; i++) {
        value = retrieve_configuration(2, i + 5 * n_channels);
        allOldSettings[i + 5 * n_channels] = value;
    }
    value = retrieveGlobalConfiguration(1, 6); // option to show ROI manager
    allOldSettings = Array.concat(allOldSettings, value);

    displayChoices = newArray("RGB Composite", "Single Monochrome Images", "Single Heatmap Images");
    displayDefault = retrieve_configuration(2, 0 + 5 * n_channels);
    obsUnitBoxDefault = retrieve_configuration(2, 1 + 5 * n_channels);
    globalMaskDefault = retrieve_configuration(2, 2 + 5 * n_channels);
    submaskDefault = retrieve_configuration(2, 3 + 5 * n_channels);
    showRoiManagerDefault = retrieveGlobalConfiguration(1, 6);
    colorDefaults = newArray(n_channels);
    monoMinDefaults = newArray(n_channels);
    monoMaxDefaults = newArray(n_channels);
    heatMinDefaults = newArray(n_channels);
    heatMaxDefaults = newArray(n_channels);
    for (i=0; i<n_channels; i++) {
        value = retrieve_configuration(2, 0 + 5 * i);
        colorDefaults[i] = value;
        value = retrieve_configuration(2, 1 + 5 * i);
        monoMinDefaults[i] = value;
        value = retrieve_configuration(2, 2 + 5 * i);
        monoMaxDefaults[i] = value;
        value = retrieve_configuration(2, 3 + 5 * i);
        heatMinDefaults[i] = value;
        value = retrieve_configuration(2, 4 + 5 * i);
        heatMaxDefaults[i] = value;
    }
    Dialog.create("Image Viewer Settings");
    Dialog.addChoice("Display images as: ", displayChoices, displayDefault);
    Dialog.setInsets(0, 20, 0);
    Dialog.addMessage("Overlay options");
    Dialog.setInsets(0, 20, 0);
    Dialog.addCheckbox("Show Obs Unit boxes", obsUnitBoxDefault);
    Dialog.addCheckbox("Show global foreground mask", globalMaskDefault);
    Dialog.addCheckbox("Show submasks", submaskDefault);
    Dialog.addCheckbox("Show ROI Manager\n(must select at least one box above for this to work)", showRoiManagerDefault);
    Dialog.addMessage("Channel options");

    for (i=0; i<n_channels; i++) {
        Dialog.setInsets(0, 20, 0);
        Dialog.addChoice("Display color:", color_choices, colorDefaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Monotone display min value:", monoMinDefaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Monotone display max value:", monoMaxDefaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Heat map display min value:", heatMinDefaults[i]);
        Dialog.setInsets(0, 20, 0);
        Dialog.addNumber("Heat map display max value:", heatMaxDefaults[i]);
    }
    Dialog.show();
    displayChoice = Dialog.getChoice();
    obsUnitBoxChoice = Dialog.getCheckbox();
    globalMaskChoice = Dialog.getCheckbox();
    submaskChoice = Dialog.getCheckbox();
    showRoiManagerChoice = Dialog.getCheckbox();
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Cytology_configurator.ijm", "change|2|" + toString(0 + 5 * n_channels) + "|" + displayChoice);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Cytology_configurator.ijm", "change|2|" + toString(1 + 5 * n_channels) + "|" + obsUnitBoxChoice);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Cytology_configurator.ijm", "change|2|" + toString(2 + 5 * n_channels) + "|" + globalMaskChoice);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Cytology_configurator.ijm", "change|2|" + toString(3 + 5 * n_channels) + "|" + submaskChoice);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configurator.ijm", "change|1|6|" + showRoiManagerChoice);

    for (i=0; i<n_channels; i++) {
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Cytology_configurator.ijm", "change|2|" + toString(0 + 5 * i) + "|" + Dialog.getChoice());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Cytology_configurator.ijm", "change|2|" + toString(1 + 5 * i) + "|" + Dialog.getNumber());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Cytology_configurator.ijm", "change|2|" + toString(2 + 5 * i) + "|" + Dialog.getNumber());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Cytology_configurator.ijm", "change|2|" + toString(3 + 5 * i) + "|" + Dialog.getNumber());
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Cytology_configurator.ijm", "change|2|" + toString(4 + 5 * i) + "|" + Dialog.getNumber());
    }

    // Get the new settings to see if the settings got changed
    // This code is almost-exactly repeated above for old settings
    allNewSettings = newArray(4 + 5 * n_channels);
    for (i=0; i<n_channels; i++) {
        for (j=0; j<5; j++) {
            value = retrieve_configuration(2, j + 5 * i);
            allNewSettings[j + 5 * i] = value;
        }
    }
    for (i=0; i<4; i++) {
        value = retrieve_configuration(2, i + 5 * n_channels);
        allNewSettings[i + 5 * n_channels] = value;
    }
    value = retrieveGlobalConfiguration(1, 6);
    allNewSettings = Array.concat(allNewSettings, value);
    changed = false;

    for (i=0; i<allOldSettings.length; i++) {
        if (allOldSettings[i] != allNewSettings[i]) {
            changed = true;
        }
    }
    if (changed == true) {
        in_use = true;
        cleanup();
        imageList = getFileListFromDirectory(working_path, image_type);
        imageListNoExt = newArray();
        for (i=0; i<imageList.length; i++) {
            append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
            imageListNoExt = Array.concat(imageListNoExt, append);
        }

        if (current_image_index > imageList.length - 1 || current_image_index < 0) {
            current_image_index = 0;
        }
        image = imageListNoExt[current_image_index];
        displayImage(image);
        in_use = false;
    }
}

macro "Load Previous Image (Shortcut Key is F1) Action Tool - C22dF36c6H096f6300" {
    if (in_use == false) {
        in_use = true;
        cleanup();
        imageList = getFileListFromDirectory(working_path, image_type);
        imageListNoExt = newArray();
        for (i=0; i<imageList.length; i++) {
            append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
            imageListNoExt = Array.concat(imageListNoExt, append);
        }
        current_image_index--;
        if (current_image_index < 0) {
            current_image_index = imageList.length - 1;
        }
        image = imageListNoExt[current_image_index];
        displayImage(image);
        in_use = false;
    }
}

macro "Load Image Action Tool - C037T0707LT4707OT9707ATe707DT2f08IT5f08MTcf08G" {
    in_use = false;
    cleanup();
    imageList = getFileListFromDirectory(working_path, image_type);
    imageListNoExt = newArray();
    for (i=0; i<imageList.length; i++) {
        append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
        imageListNoExt = Array.concat(imageListNoExt, append);
    }
    Dialog.create("Select Image");
    Dialog.addChoice("Image: ", imageListNoExt, imageListNoExt[0]);
    Dialog.show();
    image = Dialog.getChoice();

    for (i=0; i<imageListNoExt.length; i++) {
        if (image == imageListNoExt[i]) {
            current_image_index = i;
            i = imageListNoExt.length;
        }
    }

    displayImage(image);
}

macro "Load Next Image (Shortcut Key is F2) Action Tool - C22dF06c6Hf9939f00" {
    if (in_use == false) {
        in_use = true;
        cleanup();
        imageList = getFileListFromDirectory(working_path, image_type);
        imageListNoExt = newArray();
        for (i=0; i<imageList.length; i++) {
            append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
            imageListNoExt = Array.concat(imageListNoExt, append);
        }
        current_image_index++;
        if (current_image_index > imageList.length - 1) {
            current_image_index = 0;
        }
        image = imageListNoExt[current_image_index];
        displayImage(image);
        in_use = false;
    }
}

macro "Get Panel Action Tool - C037F0055C307F6055C370Fc055C031F0855C604F6b55C440Fce55" {
    analysisPath = get_working_paths("analysisPath");
    imageList = getFileListFromDirectory(working_path, image_type);
    imageListNoExt = newArray();
    for (i=0; i<imageList.length; i++) {
        append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
        imageListNoExt = Array.concat(imageListNoExt, append);
    }
    if (current_image_index == -1) {
        showMessage("An image must be open first.");
    } else {
        selection = roiManager("index");
        if (selection == -1) {
            showMessage("No selection has been made.");
        } else {
            RoiName = Roi.getName();
            imageName = imageListNoExt[current_image_index];
            run("Crop");
            if (File.exists(analysisPath + "Panels" + File.separator()) != true) {
                File.makeDirectory(analysisPath + "Panels" + File.separator());
            }
            saveAs("Tiff", analysisPath + "Panels" + File.separator() + imageName + " " + RoiName);
        }
    }
}

macro "Batch Get Panel Action Tool - C037F0055C307F6055C370Fc055C031F0655C604F6655C440Fc655" {
    cleanup();
    analysisPath = get_working_paths("analysisPath");
    /*
        Panels.txt is a tdf with no header in which each line contains the image and the OBS UNIT
        For example, "2016-01-06-15-358\tOBS UNIT 11\n"
    */
    if (!File.exists(analysisPath + "Panels.txt")) {
        showMessage("No Panels.txt file found.\nGoing through all images files instead.");
        imageList = getFileListFromDirectory(working_path, image_type);
        imageListNoExt = newArray();
        for (i=0; i<imageList.length; i++) {
            append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
            imageListNoExt = Array.concat(imageListNoExt, append);
        }
        for (i = 0; i < imageListNoExt.length; i++) {
            displayImage(imageListNoExt[i]);
            selectImage(1);
            if (File.exists(analysisPath + "Panels" + File.separator()) != true) {
                File.makeDirectory(analysisPath + "Panels" + File.separator());
            }
            saveAs("Tiff", analysisPath + "Panels" + File.separator() + imageList[i]);
//          wait(10);
            cleanup();
        }
    } else {
        panelList = File.openAsString(analysisPath + "Panels.txt");
        panelList = split(panelList, "\n");
        for (i = 0; i < panelList.length; i++) {
            image = getFieldFromTdf(panelList[i], 1, false);
            displayImage(image);
            run("Hide Overlay");
//          run("Flatten");

            roi = getFieldFromTdf(panelList[i], 2, false);
            for (j = 0; j < roiManager("Count"); j++) {
                roiManager("Select", j);
                name = Roi.getName();
                if (name == roi) {
                    j = roiManager("Count");
                }
            }
            run("Crop");
            if (File.exists(analysisPath + "Panels" + File.separator()) != true) {
                File.makeDirectory(analysisPath + "Panels" + File.separator());
            }
            saveAs("Tiff", analysisPath + "Panels" + File.separator() + image + " " + roi);
            cleanup();
        }
    }
}

/*
--------------------------------------------------------------------------------
    MACRO SHORTCUT KEYS
--------------------------------------------------------------------------------
*/

macro "Load Previous Image [f1]" {
    if (in_use == false) {
        in_use = true;
        cleanup();
        imageList = getFileListFromDirectory(working_path, image_type);
        imageListNoExt = newArray();
        for (i=0; i<imageList.length; i++) {
            append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
            imageListNoExt = Array.concat(imageListNoExt, append);
        }
        current_image_index--;
        if (current_image_index < 0) {
            current_image_index = imageList.length - 1;
        }
        image = imageListNoExt[current_image_index];
        displayImage(image);
        in_use = false;
    }
}

macro "Load Next Image [f2]" {
    if (in_use == false) {
        in_use = true;
        cleanup();
        imageList = getFileListFromDirectory(working_path, image_type);
        imageListNoExt = newArray();
        for (i=0; i<imageList.length; i++) {
            append = substring(imageList[i], 0, indexOf(imageList[i], image_type));
            imageListNoExt = Array.concat(imageListNoExt, append);
        }
        current_image_index++;
        if (current_image_index > imageList.length - 1) {
            current_image_index = 0;
        }
        image = imageListNoExt[current_image_index];
        displayImage(image);
        in_use = false;
    }
}

/*
--------------------------------------------------------------------------------
    FUNCTIONS
--------------------------------------------------------------------------------
*/

function cleanup() {
    run("Close All");
    if (isOpen("Log")) { selectWindow("Log"); run("Close"); }
    if (isOpen("Results")) { selectWindow("Results"); run("Close"); }
    if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
}

function displayImage(image) {
    setBatchMode(true);
    displayChoice = retrieve_configuration(2, 0 + 5 * n_channels);
    obsUnitBoxChoice = retrieve_configuration(2, 1 + 5 * n_channels);
    globalMaskChoice = retrieve_configuration(2, 2 + 5 * n_channels);
    submaskChoice = retrieve_configuration(2, 3 + 5 * n_channels);
    showRoiManager = retrieveGlobalConfiguration(1, 6);
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Convert_to_tiff.ijm", working_path + image + image_type + "|" + image_type + "|" + zSeriesOption);
    open(getDirectory("temp") + "Converted To Tiff.tif");
    deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
    alert = "";
    if (obsUnitBoxChoice == 1 || globalMaskChoice == 1 || submaskChoice == 1 || showRoiManager == 1) {
        if (File.exists(obs_unit_ROI_path + image + ".zip") == true) {
            roiManager("Open", obs_unit_ROI_path + image + ".zip");

            obsUnits = newArray();
            submasks = newArray();
            for (i=0; i<roiManager("Count"); i++) {
                roiManager("Select", i);
                name = Roi.getName();
                if (indexOf(name, "OBS UNIT ") != -1) {
                    obsUnits = Array.concat(obsUnits, substring(name, lengthOf("OBS UNIT "), lengthOf(name)));
                } else if (indexOf(name, "Submask ") != -1) {
                    submasks = Array.concat(submasks, substring(name, lengthOf("Submask "), lengthOf(name)));
                }
            }
            if (submaskChoice == 1) {
                if (submasks.length > 0) {
                    xArray = newArray();
                    yArray = newArray();
                    for (i=0; i<obsUnits.length; i++) {
                        for (j=0; j<roiManager("Count"); j++) {
                            roiManager("Select", j)
                            name = Roi.getName();
                            if (name == "OBS UNIT " + obsUnits[i]) {
                                getSelectionBounds(x, y, width, height);
                                xArray = Array.concat(xArray, x);
                                yArray = Array.concat(yArray, y);
                                j = roiManager("Count");
                            }
                        }
                    }

                    for (i=0; i<obsUnits.length; i++) {
                        submaskIndex = -1;
                        for (j=0; j<roiManager("Count"); j++) {
                            roiManager("Select", j)
                            name = Roi.getName();
                            if (name == "Submask " + obsUnits[i]) {
                                submaskIndex = j;
                                j = roiManager("Count");
                            }
                        }
                        if (submaskIndex != -1) {
                            roiManager("Select", submaskIndex);
                            roiManager("translate", xArray[i], yArray[i]);
                            roiManager("Update");
                        }
                    }
                } else {
                    alert = alerts[1];
                }
            }

            do {
                deleted = false;
                for (i=0; i<roiManager("Count"); i++) {
                    roiManager("Select", i);
                    name = Roi.getName();
                    if (obsUnitBoxChoice == 0 && indexOf(name, "OBS UNIT ") != -1) {
                        roiManager("Delete");
                        deleted = true;
                    } else if (globalMaskChoice == 0 && indexOf(name, "Global ") != -1) {
                        roiManager("Delete");
                        deleted = true;
                    } else if (submaskChoice == 0 && indexOf(name, "Submask ") != -1) {
                        roiManager("Delete");
                        deleted = true;
                    }
                }
            } while (deleted == true);

            if (roiManager("Count") > 0) {
                roiManager("Save", getDirectory("temp") + "overlay rois.zip");
            }
        } else {
            alert = alerts[0];
        }
    }

    labels = newArray();
    colors = newArray();
    mins = newArray();
    maxes = newArray();
    getDimensions(width, height, channels, slices, frames);
    for (i=0; i<n_channels; i++) {
        label = retrieve_configuration(1, i);
        color = retrieve_configuration(2, 0 + 5 * i);
        if (color != "Unused") {
            if (displayChoice == "Single Monochrome Images" || displayChoice == "RGB Composite") {
                min = retrieve_configuration(2, 1 + 5 * i);
                max = retrieve_configuration(2, 2 + 5 * i);
            } else if (displayChoice == "Single Heatmap Images") {
                min = retrieve_configuration(2, 3 + 5 * i);
                max = retrieve_configuration(2, 4 + 5 * i);
            }
            labels = Array.concat(labels, label);
            colors = Array.concat(colors, color);
            mins = Array.concat(mins, min);
            maxes = Array.concat(maxes, max);
            selectImage(1);
            Stack.setPosition(1 + i, 1, 1);
            run("Select All");
            run("Copy");
            newImage("Ch " + toString(i + 1) + " temp image", "16-bit black", width, height, 1, 1, 1);
            selectImage(nImages());
            run("Paste");
            if (displayChoice == "Single Monochrome Images" || displayChoice == "RGB Composite") {
                if (color == "Gray") {
                    color = "Grays";
                }
                run(color);
            } else if (displayChoice == "Single Heatmap Images") {
                run("Fire");
            }
            saveAs("Tiff", getDirectory("temp") + "Ch " + toString(i + 1) + " temp image.tif");
            close();
        }
    }
    run("Close All");

    tempFiles = getFileListFromDirectory(getDirectory("temp"), " temp image.tif");
    if (tempFiles.length == 0) {
        alert = alerts[2];
    }

    if (alert != alerts[2]) {
        if (displayChoice == "Single Monochrome Images" || displayChoice == "Single Heatmap Images") {
            for (i=0; i<tempFiles.length; i++) {
                open(getDirectory("temp") + tempFiles[i]);
                deleted = File.delete(getDirectory("temp") + tempFiles[i]);
                if (obsUnitBoxChoice == 1 || globalMaskChoice == 1 ||  submaskChoice == 1) {
                    if (File.exists(getDirectory("temp") + "overlay rois.zip") == true) {
                        roiManager("Reset");
                        roiManager("Open", getDirectory("temp") + "overlay rois.zip");
                        run("Overlay Options...", "stroke=white width=0 fill=none");
                        for (j=0; j<roiManager("Count"); j++) {
                            roiManager("Select", j);
                            run("Add Selection...");
                        }
                    }
                }
                setMinAndMax(mins[i], maxes[i]);
                saveAs("Tiff", getDirectory("temp") + tempFiles[i]);
                run("Close All");
            }
            setBatchMode(false);
            for (i=0; i<tempFiles.length; i++) {
                open(getDirectory("temp") + tempFiles[i]);
                deleted = File.delete(getDirectory("temp") + tempFiles[i]);
                channel = substring(tempFiles[i], 0, indexOf(tempFiles[i], " temp image.tif"));
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

        } else if (displayChoice == "RGB Composite") {

            tempFiles = getFileListFromDirectory(getDirectory("temp"), " temp image.tif");
            for (i=0; i<tempFiles.length; i++) {
                open(getDirectory("temp") + tempFiles[i]);
                deleted = File.delete(getDirectory("temp") + tempFiles[i]);
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
            if (obsUnitBoxChoice == 1 || globalMaskChoice == 1 ||  submaskChoice == 1) {
                if (File.exists(getDirectory("temp") + "overlay rois.zip") == true) {
                    roiManager("Reset");
                    roiManager("Open", getDirectory("temp") + "overlay rois.zip");
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
        if (File.exists(getDirectory("temp") + "overlay rois.zip") == true) {
            roiManager("Open", getDirectory("temp") + "overlay rois.zip");
        }
    }
    if (File.exists(getDirectory("temp") + "overlay rois.zip")) { deleted = File.delete(getDirectory("temp") + "overlay rois.zip"); }
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

function getFileListFromDirectory(directory, extension) {
    allFileList = getFileList(directory);
    fileList = newArray();
    for (i=0; i<allFileList.length; i++) {
        if (endsWith(allFileList[i], extension) == true) {
            fileList = Array.concat(fileList, allFileList[i]);
        }
    }
    return fileList;
}

// Runs the global configurator macro, which writes the resulting path
//     to a text file in the temp directory. This result is read back and
//     returned by the function and the temp file is deleted.
function get_working_paths(path_arg) {
    temp_directory = getDirectory("temp") +
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
        retrieved = File.openAsString(temp_directory + "g_config_temp.txt");
        deleted = File.delete(temp_directory + "g_config_temp.txt");
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
    retrieved = File.openAsString(temp_directory + "config_temp.txt");
    deleted = File.delete(temp_directory + "config_temp.txt");
    retrieved = split(retrieved, "\n");
    return retrieved[0];
}

function retrieve_g_configuration(block_index, line_index) {
    runMacro(getDirectory("plugins") +
             "BB_macros" + File.separator() +
             "Fibers_modules" + File.separator() +
             "Global_configurator_fibers.ijm",
             "retrieve|" + block_index + "|" + line_index);
    retrieved = File.openAsString(temp_directory + "g_config_temp.txt");
    deleted = File.delete(temp_directory + "g_config_temp.txt");
    retrieved = split(retrieved, "\n");
    return retrieved[0];
}