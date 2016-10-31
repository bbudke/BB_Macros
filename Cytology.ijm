var wdCmds = newMenu(
    "Working Directory Menu Tool",
    newArray("Set working directory",
             "Show working directory"));
var ouCmds = newMenu(
    "Observational Units Menu Tool",
    newArray("Select observational units",
             "Add global background masks",
             "Add submasks",
             "-",
             "Remove submasks",
             "Update ROI zip files"));
var fcCmds = newMenu(
    "Focus Counter Menu Tool",
    newArray("Change channel to be measured",
             "Show channel to be measured",
             "-",
             "Select calibration images",
             "-",
             "Calibrate focus counter",
             "-",
             "Count foci and organize data",
             "Measure submasks only",
             "Organize foci data only",
             "-",
             "Colocalization"));
var ivCmds = newMenu(
    "Image Viewer Menu Tool",
    newArray("Change image viewer settings",
             "View image"));
var amCmds = newMenu(
    "Auto Montage Menu Tool",
    newArray("Change auto montage settings",
             "Create montages"));

/*
--------------------------------------------------------------------------------
    MACRO BUTTONS
--------------------------------------------------------------------------------
*/

macro "Cytology Frontend Startup" {
    requires("1.49t");
    run("Install...", "install=[" + getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology.ijm]");
}

macro "Working Directory Menu Tool - C037L02f2L5270L70c0Lc0f2L020cLf2fcL0cfc" {
    cmd = getArgument();
    noTempFile = false;
    if (cmd == "Set working directory") {
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Global_configurator.ijm", "create");
    }
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") != true) {
        noTempFile = true;
        showStatus("Working directory has not been set.");
    }
    if (noTempFile == false) {
        workingPath = getWorkingPaths("workingPath");
        workingPath = substring(workingPath, 0, lengthOf(workingPath) - 1);
        workingPath = split(workingPath, File.separator());
        showStatus(".." + File.separator() +
            workingPath[workingPath.length - 2] + File.separator() +
            workingPath[workingPath.length - 1] + File.separator() +
            " loaded.");
    }
}

macro "Cytology Configuration Action Tool - C037T0b10CT8b09fTdb09g" {
    if (File.exists(getDirectory("plugins") 
     "BB_macros" + File.separator() +
     "Cytology_modules" + File.separator() +
     "Global_configuration.txt") == true) {
        if (File.exists(getWorkingPaths("workingPath")) == true) {
            runMacro(getDirectory("plugins") +
                "BB_macros" + File.separator() +
                "Cytology_modules" + File.separator() +
                "Cytology_configurator.ijm", "create");
            imageIndexFile = getWorkingPaths("imageIndexFile");
            groupLabelsFile = getWorkingPaths("groupLabelsFile");
            checkForAndCreateIndexFiles();
        } else {
            showStatus("Working directory not found. " +
                       "Please set the working directory.");
        }
    } else {
        showStatus("Working directory has not been set.");
    }
}

macro "Image Viewer Action Tool - C037R00eeL707eL07e7C22fV2244C2c2V9244C0f0V2944Cc22V9944" {
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") == true) {
        if (File.exists(getWorkingPaths("workingPath")) == true) {
            if (File.exists(getWorkingPaths("analysisSetupFile")) == true) {
                runMacro(getDirectory("plugins") +
                    "BB_macros" + File.separator() +
                    "Cytology_modules" + File.separator() +
                    "Image_viewer.ijm");
            } else {
                showStatus("Setup file not found. " +
                           "Please run Cytology Configuration");
            }
        } else {
            showStatus("Working directory not found. " +
                       "Please set the working directory.");
        }
    } else {
        showStatus("Working directory has not been set.");
    }
}

macro "Observational Units Menu Tool - CaaaR00aaC00cV2266CaaaR83aaC00cVb666CaaaR08aaC00cV2b66" {
    cmd = getArgument();
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") == true) {
        if (File.exists(getWorkingPaths("workingPath")) == true) {
            if (File.exists(getWorkingPaths("analysisSetupFile")) == true) {
                if (cmd == "Select observational units") {
                    runMacro(getDirectory("plugins") +
                        "BB_macros" + File.separator() +
                        "Cytology_modules" + File.separator() +
                        "Observational_units_selector.ijm");
                } else if (cmd == "Add global background masks") {
                    runMacro(getDirectory("plugins") +
                        "BB_macros" + File.separator() +
                        "Cytology_modules" + File.separator() +
                        "Observational_units_global_masks.ijm");
                } else if (cmd == "Add submasks") {
                    runMacro(getDirectory("plugins") +
                        "BB_macros" + File.separator() +
                        "Cytology_modules" + File.separator() +
                        "Observational_units_submasks.ijm");
                } else if (cmd == "Remove submasks") {
                    runMacro(getDirectory("plugins") +
                        "BB_macros" + File.separator() +
                        "Cytology_modules" + File.separator() +
                        "Observational_units_utilities.ijm", cmd);
                } else if (cmd == "Update ROI zip files") {
                    runMacro(getDirectory("plugins") +
                        "BB_macros" + File.separator() +
                        "Cytology_modules" + File.separator() +
                        "Observational_units_utilities.ijm", cmd);
                }
            } else {
                showStatus("Setup file not found. " +
                           "Please run Cytology Configuration");
            }
        } else {
            showStatus("Working directory not found. " +
                       "Please set the working directory.");
        }
    } else {
        showStatus("Working directory has not been set.");
    }
}

macro "Focus Counter Menu Tool - C037O00ffC703V3344V8444V5944" {
    cmd = getArgument();
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") == true) {
        if (File.exists(getWorkingPaths("workingPath")) == true) {
            if (File.exists(getWorkingPaths("analysisSetupFile")) == true) {
                nChannels = retrieveConfiguration(0, 1);
                activeChannel = retrieveConfiguration(4, 0 + 8 * nChannels);
                if (cmd == "Change channel to be measured") {
                    labeledChoices = newArray();
                    for (i=0; i<nChannels; i++) {
                        labeledChoices = Array.concat(
                            labeledChoices,
                            "Channel " + toString(i + 1) + ": " +
                            retrieveConfiguration(1, 0 + 1 * i)
                        );
                    }
                    Dialog.create("Select a channel for focus counting");
                    if (activeChannel > 0) {
                        Dialog.addChoice("Count foci in:",
                                         labeledChoices,
                                         labeledChoices[activeChannel - 1]);
                    } else {
                        Dialog.addChoice("Count foci in:",
                                         labeledChoices,
                                         labeledChoices[0]);
                    }
                    Dialog.show();
                    choice = Dialog.getChoice();
                    choice = substring(choice, lengthOf("Channel "), lengthOf(choice));
                    choice = substring(choice, 0, indexOf(choice, ":"));
                    runMacro(getDirectory("plugins") +
                        "BB_macros" + File.separator() +
                        "Cytology_modules" + File.separator() +
                        "Cytology_configurator.ijm",
                        "change|4|" + toString(0 + 8 * nChannels) + "|" + choice);
                    showStatus("Active channel for focus counting changed to Channel " +
                        choice + ": " +
                        retrieveConfiguration(1, 0 + 1 * (-1 + choice)));
                } else if (activeChannel != -1) {
                    if (cmd == "Show channel to be measured") {
                        showStatus("Active channel for focus counting is Channel " +
                            activeChannel + ": " +
                            retrieveConfiguration(1, 0 + 1 * (-1 + activeChannel)));
                    } else if (cmd == "Select calibration images") {
                        runMacro(getDirectory("plugins") +
                            "BB_macros" + File.separator() +
                            "Cytology_modules" + File.separator() +
                            "Focus_counter.ijm", "Select calibration images");
                    } else if (cmd == "Calibrate focus counter") {
                        runMacro(getDirectory("plugins") +
                            "BB_macros" + File.separator() +
                            "Cytology_modules" + File.separator() +
                            "Focus_counter.ijm", "Calibrate focus counter");
                    } else if (cmd == "Count foci and organize data" ||
                               cmd == "Measure submasks only" ||
                               cmd == "Organize foci data only") {
                        runMacro(getDirectory("plugins") +
                            "BB_macros" + File.separator() +
                            "Cytology_modules" + File.separator() +
                            "Focus_counter.ijm", cmd);
                    } else if (cmd == "Colocalization") {
                        runMacro(getDirectory("plugins") +
                            "BB_macros" + File.separator() +
                            "Cytology_modules" + File.separator() +
                            "Colocalization.ijm");
                    }
                } else {
                    showStatus("Active channel for focus counting has not been set.");
                }
            } else {
                showStatus("Setup file not found. " +
                           "Please run Cytology Configuration");
            }
        } else {
            showStatus("Working directory not found. " +
                       "Please set the working directory.");
        }
    } else {
        showStatus("Working directory has not been set.");
    }
}

macro "Manual Montage Action Tool - C037F0055C307F6055C370Fc055C031F0855C604F6b55C440Fce55" {
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") == true) {
        if (File.exists(getWorkingPaths("workingPath")) == true) {
            if (File.exists(getWorkingPaths("analysisSetupFile")) == true) {
                if (File.exists(getWorkingPaths("obsUnitRoiPath")) == true) {
                    zipList = getFileListFromDirectory(
                        getWorkingPaths("obsUnitRoiPath"), ".zip"
                        );
                    if (zipList.length > 0) {
                        runMacro(getDirectory("plugins") +
                            "BB_macros" + File.separator() +
                            "Cytology_modules" + File.separator() +
                            "Manual_montage.ijm");
                    } else {
                        showStatus("No ROI zip files found in the OBS UNIT ROIs folder. " +
                                   "Please select observational units.");
                    }
                } else {
                    showStatus("OBS UNIT ROIs folder not found. " +
                               "Please select observational units.");
                }
            } else {
                showStatus("Setup file not found. " +
                           "Please run Cytology Configuration");
            }
        } else {
            showStatus("Working directory not found. " +
                       "Please set the working directory.");
        }
    } else {
        showStatus("Working directory has not been set.");
    }
}

macro "Auto Montage Action Tool - C037F0055C307F6055C370Fc055C031F0655C604F6655C440Fc655" {
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") == true) {
        if (File.exists(getWorkingPaths("workingPath")) == true) {
            if (File.exists(getWorkingPaths("analysisSetupFile")) == true) {
                if (File.exists(getWorkingPaths("obsUnitRoiPath")) == true) {
                    zipList = getFileListFromDirectory(
                        getWorkingPaths("obsUnitRoiPath"), ".zip"
                        );
                    if (zipList.length > 0) {
                        runMacro(getDirectory("plugins") +
                            "BB_macros" + File.separator() +
                            "Cytology_modules" + File.separator() +
                            "Auto_montage.ijm");
                    } else {
                        showStatus("No ROI zip files found in the OBS UNIT ROIs folder. " +
                                   "Please select observational units.");
                    }
                } else {
                    showStatus("OBS UNIT ROIs folder not found. " +
                               "Please select observational units.");
                }
            } else {
                showStatus("Setup file not found. " +
                           "Please run Cytology Configuration");
            }
        } else {
            showStatus("Working directory not found. " +
                       "Please set the working directory.");
        }
    } else {
        showStatus("Working directory has not been set.");
    }
}

/*
--------------------------------------------------------------------------------
    FUNCTIONS
--------------------------------------------------------------------------------
*/

function checkForAndCreateIndexFiles() {
    workingPath = getWorkingPaths("workingPath");
    imageType = retrieveConfiguration(0, 0);
    autoAssignGroupNumbers = true;

    noImageIndex = false;
    if (File.exists(imageIndexFile) != true) {
        noImageIndex = true;
        imageIndex = File.open(imageIndexFile);
        print(imageIndex, "Image\tGroup number");
        fileList = getFileListFromDirectory(workingPath, imageType);
        for (i=0; i<fileList.length; i++) {
            rawString = fileList[i];
            filename = substring(rawString, 0, indexOf(rawString, imageType));
            if (autoAssignGroupNumbers == true) {
                group = substring(rawString, 11, 13);
                print(imageIndex, filename + "\t" + group);
            } else {
                print(imageIndex, filename + "\t");
            }
        }
        File.close(imageIndex);
        message1 = "An image index file has been created under the\n" +
                   "'Analysis' folder in the experiment directory.\n" +
                   "Please modify this file so that each image is in\n" +
                   "its appropriate group in the experiment.";
    }

    noGroupLabels = false;
    if (File.exists(groupLabelsFile) != true) {
        noGroupLabels = true;
        groupLabels = File.open(groupLabelsFile);
        print(groupLabels, "Group number\tGroup label");
        File.close(groupLabels);
        message2 = "A group index file has been created under the\n" +
                   "'Analysis' folder in the experiment directory.\n" +
                   "Please modify this file so that all the groups in\n" +
                   "the experiment are listed with corresponding\n" +
                   "identifying group names.";
    }

    if (noImageIndex == true || noGroupLabels == true) {
        if (noImageIndex == true && noGroupLabels == false) {
            showMessage(message1);
        } else if (noImageIndex == false && noGroupLabels == true) {
            showMessage(message2);
        } else {
            showMessage(message1 + "\nAlso,\n" + message2);
        }
    }
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

function getWorkingPaths(pathArg) {
    pathArgs = newArray("workingPath",
                        "analysisPath",
                        "obsUnitRoiPath",
                        "analysisSetupFile",
                        "imageIndexFile",
                        "groupLabelsFile");
    if (File.exists(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Global_configuration.txt") == true) {
        runMacro(getDirectory("plugins") +
            "BB_macros" + File.separator() +
            "Cytology_modules" + File.separator() +
            "Global_configurator.ijm", pathArg);
        retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
        deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
        retrieved = split(retrieved, "\n");
        return retrieved[0];
    } else {
        exit("Global configuration not found.");
    }
}

function retrieveConfiguration(blockIndex, lineIndex) {
    runMacro(getDirectory("plugins") +
        "BB_macros" + File.separator() +
        "Cytology_modules" + File.separator() +
        "Cytology_configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
    retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
    deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
    retrieved = split(retrieved, "\n");
    return retrieved[0];
}