var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Observational Units Utilities" {
	arg = getArgument();

	if (File.exists(obsUnitRoiPath) != true) {
		exit("No ROI zip file directory detected.\nPlease run 'Select observational units' first.");
	}
	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	if (zipList.length == 0) {
		exit("No ROI zip files detected.\nPlease run 'Select observational units' first.");
	}

	setBatchMode(true);
	newImage("Untitled", "8-bit black", 100, 100, 1);
	selectImage(1);

	modifiedFiles = 0;
	if (arg == "Remove submasks") {
		choice = getBoolean("This command removes the submasks from all the files in the\nAnalysis/OBS UNIT ROIs/ path. This can destroy hours of your\nwork if used accidentally. It is recommended that you make a\nbackup of the OBS UNIT ROIs directory. Continue?");
		if (choice == 0) {
			exit();
		} else {
			for (i=0; i<zipList.length; i++) {
				modified = false;
				roiManager("Reset");
				roiManager("Open", obsUnitRoiPath + zipList[i]);
				do {
					deleted = false;
					for (j=0; j<roiManager("Count"); j++) {
						roiManager("Select", j);
						name = Roi.getName();
						if (indexOf(name, "Submask ") != -1 || indexOf(name, "Global") != -1) {
							roiManager("Delete");
							deleted = true;
							modified = true;
							j = roiManager("Count");
						}
					}
				} while (deleted == true);
				if (modified == true) {
					modifiedFiles++;
				}
				roiManager("Save", obsUnitRoiPath + zipList[i]);
			}
		}
	} else if (arg == "Update ROI zip files") {
		for (i=0; i<zipList.length; i++) {
			modified = false;
			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + zipList[i]);
			for (j=0; j<roiManager("Count"); j++) {
				roiManager("Select", j);
				name = Roi.getName();
				if (name == "DAPI mask") {
					roiManager("Rename", "Global Foreground mask");
					modified = true;
				} else if (name == "Background mask") {
					roiManager("Rename", "Global Background mask");
					modified = true;
				} else if (indexOf(name, "DAPI ") != -1) {
					roiManager("Rename", "Submask " + substring(name, lengthOf("DAPI "), lengthOf(name)));
					modified = true;
				}
			}
			if (modified == true) {
				modifiedFiles++;
			}
			roiManager("Save", obsUnitRoiPath + zipList[i]);
		}
	}

	run("Close All");
	showStatus(modifiedFiles + " files modified.");
}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

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
	pathArgs = newArray("workingPath", "analysisPath", "obsUnitRoiPath", "analysisSetupFile", "imageIndexFile", "groupLabelsFile");
	if (File.exists(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Global configuration.txt") == true) {
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Global Configurator.ijm", pathArg);
		retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
		deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
		retrieved = split(retrieved, "\n");
		return retrieved[0];
	} else {
		exit("Global configuration not found.");
	}
}

function retrieveConfiguration(blockIndex, lineIndex) {
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
	retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
	deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
	retrieved = split(retrieved, "\n");
	return retrieved[0];
}