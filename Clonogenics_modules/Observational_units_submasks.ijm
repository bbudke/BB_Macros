var workingPath = getWorkingPaths("workingPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");
var mode = "Crop";
var inUse = false;

var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);
var delineationChannel = parseInt(retrieveConfiguration(1, 0 + 1 * nChannels));

// radius was originally hard-coded as 734

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Observational Units Submasks Startup" {
	if (File.exists(obsUnitRoiPath) != true) {
		exit("No ROI zip file directory detected.\nPlease run 'Select observational units' first.");
	}

	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	zipListNoExt = newArray();
	for (i=0; i<zipList.length; i++) {
		zipListNoExt = Array.concat(zipListNoExt, substring(zipList[i], 0 , indexOf(zipList[i], ".zip")));
	}

	if (zipList.length == 0) {
		exit("No ROI zip files detected.\nPlease run 'Select observational units' first.");
	}

	imageList = getFileListFromDirectory(workingPath, imageType);
	imageListNoExt = newArray();
	for (i=0; i<imageList.length; i++) {
		imageListNoExt = Array.concat(imageListNoExt, substring(imageList[i], 0 , indexOf(imageList[i], imageType)));
	}

	nMatches = 0;
	for (i=0; i<imageListNoExt.length; i++) {
		for (j=0; j<zipListNoExt.length; j++) {
			if (zipListNoExt[j] == imageListNoExt[i]) {
				nMatches++;
				j = zipListNoExt.length;
			}
		}
	}
	if (nMatches < imageList.length) {
		choice = getBoolean("Not all images have corresponding ROI zip files\nthat indicate the position of each observational unit.\nHit 'Yes' to continue (some images will not be processed)\nor 'No' or 'Cancel' to exit.");
	} else {
		choice = 1;
	}

	if (choice == 1) {
		run("Install...", "install=[" + getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Clonogenics_modules" + File.separator() +
			"Observational_units_submasks.ijm]");
		cleanup();
	}
}

/*
--------------------------------------------------------------------------------
	MACRO BUTTONS
--------------------------------------------------------------------------------
*/

macro "Return to Clonogenics Frontend Action Tool - Ca44F36d6H096f6300" {
	cleanup();
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics.ijm");
}

macro "Observational Units Submasks Configuration Action Tool - C037T0b10CT8b09fTdb09g" {
	radiusOption = parseInt(retrieveConfiguration(3, 1));
	Dialog.create("Observational Units Submasks");
	Dialog.addNumber("Circle radius for well submasks: ", radiusOption);
	Dialog.show();
	radius = Dialog.getNumber();
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Clonogenics_configurator.ijm", "change|3|1|" + radius);
}

macro "Load First Or Next Observational Unit (Shortcut key is F1) Action Tool - C037T0507LT4507OT9507ATe507DT0f07NT5f07ETaf07XTef07T" {
	if (inUse == false) {
		inUse = true;
		cleanup();
		status = loadNextObsUnit();
		if (status == 0) {
			showStatus("No more observational units to process.");
		}
		inUse = false;
	}
}

macro "Switch Submask Refinement Mode Action Tool - C037T0907MT4907OT9907DTe907E" {
	if (mode == "Crop") {
		mode = "Expand";
	} else if (mode == "Expand") {
		mode = "Crop";
	}
	showStatus("Submask refinement mode is set to '" + mode + "'");
}

macro "Reset Action Tool - C037T0a07RT4a07ET8a07STba07ETfa07T" {
	cleanup();
	inUse = false;
}
/*
macro "Delete Last Submask Action Tool - C037T0707UT5707NTa707DTf707OT0f07PT4f07RT9f07ETef07V" {
	TODO
}
*/
/*
--------------------------------------------------------------------------------
	MACRO SHORTCUT KEYS
--------------------------------------------------------------------------------
*/

macro "Load First Or Next Observational Unit [f1]" {
	if (inUse == false) {
		inUse = true;
		cleanup();
		status = loadNextObsUnit();
		if (status == 0) {
			showStatus("No more observational units to process.");
		}
		inUse = false;
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
	if (File.exists(getDirectory("temp") + "Submasks temp image.tif")) {
		deleted = File.delete(getDirectory("temp") + "Submasks temp image.tif");
	}
	if (File.exists(getDirectory("temp") + "temp roi file.zip")) {
		deleted = File.delete(getDirectory("temp") + "temp roi file.zip");
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
	pathArgs = newArray("workingPath", "analysisPath", "obsUnitRoiPath", "analysisSetupFile", "imageIndexFile", "groupLabelsFile");
	if (File.exists(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Global_configuration.txt") == true) {
		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Clonogenics_modules" + File.separator() +
			"Global_configurator.ijm", pathArg);
		retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
		deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
		retrieved = split(retrieved, "\n");
		return retrieved[0];
	} else {
		exit("Global configuration not found.");
	}
}

function loadNextObsUnit() {
	radius = parseInt(retrieveConfiguration(3, 1));

	imageList = getFileListFromDirectory(workingPath, imageType);
	imageListNoExt = newArray();
	for (i=0; i<imageList.length; i++) {
		imageListNoExt = Array.concat(imageListNoExt, substring(imageList[i], 0 , indexOf(imageList[i], imageType)));
	}
	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	zipListNoExt = newArray();
	for (i=0; i<zipList.length; i++) {
		zipListNoExt = Array.concat(zipListNoExt, substring(zipList[i], 0 , indexOf(zipList[i], ".zip")));
	}

	/*
	----------------------------------------------------------------------------
		GET NEXT OBSERVATIONAL UNIT
	----------------------------------------------------------------------------
	*/

	totalObsUnits = 0;
	areWeThereYet = 0;
	setBatchMode(true);
	newImage("Untitled", "8-bit black", 100, 100, 1);

	for (i=0; i<zipList.length; i++) {
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipList[i]);
		for (j=0; j<roiManager("Count"); j++) {
			roiManager("Select", j);
			name = Roi.getName();
			if (indexOf(name, "OBS UNIT ") != -1) {
				totalObsUnits++;
			}
		}
	}

	zipIndex = -1;
	for (i=0; i<zipList.length; i++) {
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipList[i]);
		obsUnits = newArray();
		submasks = newArray();
		for (j=0; j<roiManager("Count"); j++) {
			roiManager("Select", j);
			name = Roi.getName();
			if (indexOf(name, "OBS UNIT ") != -1) {
				obsUnits = Array.concat(obsUnits, substring(name, lengthOf("OBS UNIT "), lengthOf(name)));
			} else if (indexOf(name, "Submask ") != -1) {
				submasks = Array.concat(submasks, substring(name, lengthOf("Submask "), lengthOf(name)));
				areWeThereYet++;
			}
		}

		obsUnitIndex = -1;
		for (j=0; j<obsUnits.length; j++) {
			foundMask = false;
			for (k=0; k<submasks.length; k++) {
				if (submasks[k] == obsUnits[j]) {
					foundMask = true;
					k = submasks.length;
				}
			}
			if (foundMask == false) {
				obsUnitIndex = j;
				j = obsUnits.length;
			}
		}
		if (obsUnitIndex != -1) {
			zipIndex = i;
			i = zipList.length;
		}
	}
	run("Close All");

	if (zipIndex == -1) {
		if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
		return 0;		
	} else {
		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Clonogenics_modules" + File.separator() +
			"Convert_to_tiff.ijm", workingPath + zipListNoExt[zipIndex] + imageType + "|" + imageType + "|" + zSeriesOption);
		open(getDirectory("temp") + "Converted To Tiff.tif");
		deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
		getDimensions(width, height, channels, slices, frames);
		Stack.setPosition(delineationChannel, 1, 1);
		run("Select All");
		run("Copy");
		newImage("Opened image", "16-bit black", width, height, 1, 1, 1);
		run("Paste");
		saveAs("Tiff", getDirectory("temp") + "Opened image.tif");
		run("Close All");
		open(getDirectory("temp") + "Opened image.tif");
		deleted = File.delete(getDirectory("temp") + "Opened image.tif");
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipList[zipIndex]);

	/*
	----------------------------------------------------------------------------
		PREPARE TO REMOVE PREVIOUS SUBMASKS FROM THE NEW SUBMASK BELOW
	----------------------------------------------------------------------------
	*/

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
				obsUnitIndex2 = -1;
				submaskIndex = -1;
				for (j=0; j<roiManager("Count"); j++) {
					roiManager("Select", j)
					name = Roi.getName();
					if (name == "OBS UNIT " + obsUnits[i]) {
						obsUnitIndex2 = j;
						j = roiManager("Count");
					}
				}
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
					roiManager("Add");
					roiManager("Select", roiManager("Count") - 1);
					roiManager("Rename", "Submask " + obsUnits[i] + " translated");
					roiManager("translate", xArray[i] - xArray[obsUnitIndex], yArray[i] - yArray[obsUnitIndex]);
					roiManager("Update");
				}
			}
			
			submaskTranslatedArray = newArray();
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i)
				name = Roi.getName();
				if (indexOf(name, "translated") != -1) {
					submaskTranslatedArray = Array.concat(submaskTranslatedArray, i);
				}
			}
			roiManager("Deselect");
			roiManager("Select", submaskTranslatedArray);
			if (submaskTranslatedArray.length > 1) {
				roiManager("OR");
			}
			run("Make Inverse");
			roiManager("Add");
			roiManager("Select", roiManager("Count") - 1);
			roiManager("Rename", "All inverse submasks");

			do {
				deleted = false;
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i)
					name = Roi.getName();
					if (indexOf(name, "translated") != -1) {
						roiManager("Delete");
						deleted = true;
					}
				}
			} while (deleted == true);	
		}

	/*
	----------------------------------------------------------------------------
		CREATE AN INITIAL SUBMASK BASED ON STAINING INTENSITY
	----------------------------------------------------------------------------
	*/

		initialSubmaskSelections = newArray();
		for (i=0; i<roiManager("Count"); i++) {
			roiManager("Select", i);
			name = Roi.getName();
			if (name == "Global Foreground mask") {
				initialSubmaskSelections = Array.concat(initialSubmaskSelections, i);
				i = roiManager("Count");
			}
		}
		for (i=0; i<roiManager("Count"); i++) {
			roiManager("Select", i);
			name = Roi.getName();
			if (name == "OBS UNIT " + obsUnits[obsUnitIndex]) {
				roiManager("Select", i);
				getSelectionBounds(x, y, width, height);
				initialSubmaskSelections = Array.concat(initialSubmaskSelections, i);
				roiManager("Select", initialSubmaskSelections);
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", roiManager("Count") - 1);
				getSelectionBounds(x2, y2, width2, height2);
				setSelectionLocation(x2 - x, y2 - y);
				roiManager("Update");
				roiManager("Rename", "Initial submask");

				roiManager("Select", i);
				run("Copy");
				newImage("Submasks temp image.tif", "16-bit black", width, height, 1);
				run("Paste");
				run("Fire");
				run("Enhance Contrast", "saturated=0.35");
				run("Select None");
				saveAs("Tiff", getDirectory("temp") + "Submasks temp image.tif");
				run("Close All");
				i = roiManager("Count");
			}
		}
		open(getDirectory("temp") + "Submasks temp image.tif");
		selectImage(1);

	/*
	----------------------------------------------------------------------------
		SUBTRACT OUT THE PREVIOUS SUBMASKS, IF THERE ARE ANY
	----------------------------------------------------------------------------
	*/

		if (submasks.length > 0) {
			arr = newArray();
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i)
				name = Roi.getName();
				if (name == "Initial submask") {
					arr = Array.concat(arr, i);
				} else if (name == "All inverse submasks") {
					arr = Array.concat(arr, i);
				}
			}
			roiManager("Select", arr);
			if (arr.length > 1) {
				roiManager("AND");
			}
			roiManager("Add");
			roiManager("Select", roiManager("Count") - 1);
			roiManager("Rename", "Initial submask subtracted");

			do {
				deleted = false;
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i)
					name = Roi.getName();
					if (name == "Initial submask") {
						roiManager("Delete");
						deleted = true;
					} else if (name == "All inverse submasks") {
						roiManager("Delete");
						deleted = true;
					}
				}
			} while (deleted == true);
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (name == "Initial submask subtracted") {
					roiManager("Rename", "Initial submask");
					i = roiManager("Count");
				}
			}
		}

		roiManager("Save", getDirectory("temp") + "temp roi file.zip");
		run("Close All");

		setBatchMode(false);
		open(getDirectory("temp") + "Submasks temp image.tif");
		selectImage(1);
		run("Fire");
		run("Enhance Contrast", "saturated=0.35");
		roiManager("Reset");
		roiManager("Open", getDirectory("temp") + "temp roi file.zip");
		setTool("freehand");
		statusMsg = "Current Obs Unit is " + toString(areWeThereYet) + " of " + toString(totalObsUnits) + "\nfrom image\n" + zipListNoExt[zipIndex] + "\n" + floor((areWeThereYet / totalObsUnits) * 100) + "% done\n ";

	/*
	----------------------------------------------------------------------------
		ALLOW THE USER TO REFINE THE SUBMASK AND THEN SAVE
	----------------------------------------------------------------------------
	*/

		manualSelection = true;
		do {
			run("Remove Overlay");
			makeOval(74, 74, radius, radius);
			setTool("oval");
			waitForUser(statusMsg + "\nPlace circular\nsubmask ROI.");

			roiManager("Add");
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Add Selection...");
			roiManager("Select", roiManager("Count") - 1);
			roiManager("Rename", "Submask " + obsUnits[obsUnitIndex]);

			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (name == "Initial submask") {
					roiManager("Delete");
					i = roiManager("Count");
				}
			}
			manualSelection = false;

		} while (manualSelection == true);
		roiManager("Save", obsUnitRoiPath + zipList[zipIndex]);
		deleted = File.delete(getDirectory("temp") + "Submasks temp image.tif");
		return 1;
	}
}

function retrieveConfiguration(blockIndex, lineIndex) {
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Clonogenics_configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
	retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
	deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
	retrieved = split(retrieved, "\n");
	return retrieved[0];
}

function retrieveGlobalConfiguration(blockIndex, lineIndex) {
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Global_configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
	retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
	deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
	retrieved = split(retrieved, "\n");
	return retrieved[0];
}