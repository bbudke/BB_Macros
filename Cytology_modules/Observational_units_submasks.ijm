var workingPath = getWorkingPaths("workingPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");
var mode = "Crop";
var inUse = false;

var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);
var delineationChannel = parseInt(retrieveConfiguration(1, 0 + 1 * nChannels));

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
			"Cytology_modules" + File.separator() +
			"Observational_units_submasks.ijm]");
		cleanup();
	}
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

macro "Observational Units Submasks Configuration Action Tool - C037T0b10CT8b09fTdb09g" {
	thresholdOption = retrieveGlobalConfiguration(1, 2);
	minimumSubmaskSize = retrieveGlobalConfiguration(1,3);
	excludeOnEdgeOption = retrieveGlobalConfiguration(1,4);
	allowCompositesOption = retrieveGlobalConfiguration(1,5);
	Dialog.create("Observational Units Submasks");
	Dialog.addChoice("Thresholding: ", newArray("Local threshold", "Global threshold"), thresholdOption);
	Dialog.addNumber("Minimum submask size: ", minimumSubmaskSize);
	Dialog.addCheckbox("Exclude on-edge submasks ", excludeOnEdgeOption);
	Dialog.addCheckbox("Allow composite submasks ", allowCompositesOption);
	Dialog.show();
	thresholdOption = Dialog.getChoice();
	minimumSubmaskSize = Dialog.getNumber();
	excludeOnEdgeOption = Dialog.getCheckbox();
	allowCompositesOption = Dialog.getCheckbox();
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|2|" + thresholdOption);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|3|" + minimumSubmaskSize);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|4|" + excludeOnEdgeOption);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|5|" + allowCompositesOption);
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

macro "Enlarge Selection [f2]" {
	roiManager("Select", roiManager("Count") - 1);
	run("Enlarge...", "enlarge=1");
	roiManager("Update");
}

macro "Shrink Selection [f3]" {
	roiManager("Select", roiManager("Count") - 1);
	run("Enlarge...", "enlarge=-1");
	roiManager("Update");
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

function loadNextObsUnit() {
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
		GET NEXT OBSERVATIONAL UNIT AND OPEN THE IMAGE
	----------------------------------------------------------------------------
	*/

	totalObsUnits = 0;
	areWeThereYet = 0;
	setBatchMode(true);
	newImage("Dummy", "8-bit black", 100, 100, 1); //blank image because ROI Manager will complain otherwise

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

		// find the next Obs Unit that needs to be masked
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
		return 0;	// All done making submasks!
	} else {
		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Cytology_modules" + File.separator() +
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

					// BUG: For some images, the translation above does not stick. See below.

					roiManager("Update");
				}
			}
			
			submaskTranslatedArray = newArray();

			// HERE BE DRAGONS: In the loop below, translated ROIs get moved to the center of the image (they were moved off-screen above). This bug causes a part of the next ROI to be "chomped" off and seems to occur in images where OBS Units are selected from the top left of an image to the lower right.

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
		thresholdOption = retrieveGlobalConfiguration(1,2);

		if (thresholdOption == "Global threshold") {

			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (name == "Global Foreground mask") {
					initialSubmaskSelections = Array.concat(initialSubmaskSelections, i);
					i = roiManager("Count");
				}
			}

		} else if (thresholdOption != "Local threshold") {

			exit("Invalid threshold option in Global Configuration: " thresholdOption);

		}

		for (i=0; i<roiManager("Count"); i++) {
			roiManager("Select", i);
			name = Roi.getName();
			if (name == "OBS UNIT " + obsUnits[obsUnitIndex]) {
				roiManager("Select", i);
				getSelectionBounds(x, y, width, height);

				if (thresholdOption == "Global threshold") {

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

				} else if (thresholdOption == "Local threshold") {

					run("Copy");
					newImage("Submasks temp image.tif", "16-bit black", width, height, 1);
					run("Paste");
					setAutoThreshold("Li dark");
					run("Convert to Mask");
					run("Gaussian Blur...", "sigma=5");
					setAutoThreshold("Li dark");
					run("Convert to Mask");
					run("Invert");
					run("Create Selection");
					roiManager("Add");
					roiManager("Select", roiManager("Count") -1 );
					roiManager("Rename", "Initial submask");
					close();
					newImage("Submasks temp image.tif", "16-bit black", width, height, 1);
					run("Paste");

				}

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

	// This block will create an error message from the ROI manager saying the
	// active image does not have a selection if the code above does not
	// result in an ROI.

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
		roiManager("Reset");

	/*
	----------------------------------------------------------------------------
		RE-OPEN EVERYTHING AND WEED OUT SMALL AND ON-EDGE SUBMASKS
	----------------------------------------------------------------------------
	*/

		minimumSubmaskSize = retrieveGlobalConfiguration(1,3);
		excludeOnEdgeOption = retrieveGlobalConfiguration(1,4);
		if (minimumSubmaskSize > 0 || excludeOnEdgeOption == 1) {
			setBatchMode(false); // necessary or else ROI manager complains about no active selections
			newImage("Dummy", "8-bit white", width, height, 1);
			roiManager("Open", getDirectory("temp") + "temp roi file.zip");
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (name == "Initial submask") {
					roiManager("Select", i);
					i = roiManager("Count");
				}
				if (i == (roiManager("Count") - 1)) {
					exit("Initial submask not found");
				}
			}
			run("Set...", "value=0");
			run("Select None");
			roiManager("Reset");

			run("Analyze Particles...", "size=" + minimumSubmaskSize + "-Infinity exclude summarize");
			selectWindow("Summary");
			notOnEdgeParticles = split(getInfo(), "\n");
			notOnEdgeParticles = split(notOnEdgeParticles[1], "\t");
			notOnEdgeParticles = notOnEdgeParticles[1];
			run("Analyze Particles...", "size=" + minimumSubmaskSize + "-Infinity summarize");
			allParticles = split(getInfo(), "\n");
			allParticles = split(allParticles[2], "\t");
			allParticles = allParticles[1];
			selectWindow("Summary");
			run("Close");
			selectWindow("Dummy");

			if (notOnEdgeParticles > 0 && excludeOnEdgeOption == 1) {
				run("Analyze Particles...", "size=" + minimumSubmaskSize + "-Infinity exclude add");
			} else {
				run("Analyze Particles...", "size=" + minimumSubmaskSize + "-Infinity add");
			}
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				roiManager("Rename", "Initial submask particle " + (i + 1));
			}
			run("Select None");
			arr = newArray();
			for (i=0; i<roiManager("Count"); i++) {
				arr = Array.concat(arr, i);
			}
			selectWindow("Dummy");
			roiManager("Select", arr);
			if (arr.length > 1) {
				roiManager("OR");
			}
			if (roiManager("Count") > 0 && false) {
				roiManager("Add"); // for some reason, this doesn't work in batch mode
				roiManager("Select", roiManager("Count") - 1);
				roiManager("Rename", "Initial submask minus junk");
			} else {
				run("Select All");
				roiManager("Add");
				roiManager("Select", roiManager("Count") - 1);
				roiManager("Rename", "Initial submask minus junk");
			}
			roiManager("Open", getDirectory("temp") + "temp roi file.zip");
			do {
				found = false;
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i);
					name = Roi.getName();
					if (name == "Initial submask" || startsWith(name, "Initial submask particle") == true) {
						roiManager("Select", i);
						roiManager("Delete");
						found = true;
					}
				}
			} while (found == true);
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (name == "Initial submask minus junk") {
					roiManager("Select", i);
					roiManager("Rename", "Initial submask");
					i = roiManager("Count");
				}
				if (i == (roiManager("Count") - 1)) {
					exit("Initial submask minus junk not found");
				}
			}
		roiManager("Save", getDirectory("temp") + "temp roi file.zip");
		run("Close All");
		roiManager("Reset");
		}

	/*
	----------------------------------------------------------------------------
		RE-OPEN EVERYTHING AND PREPARE FOR MANUAL SUBMASK EDITING
	----------------------------------------------------------------------------
	*/		

		setBatchMode(false);
		open(getDirectory("temp") + "Submasks temp image.tif");
		selectImage(1);
		run("Fire");
		run("Enhance Contrast", "saturated=0.35");
		roiManager("Open", getDirectory("temp") + "temp roi file.zip");
		setTool("freehand");
		statusMsg = "Current Obs Unit is " + toString(areWeThereYet) + " of " + toString(totalObsUnits) + "\nfrom image\n" + zipListNoExt[zipIndex] + "\n" + floor((areWeThereYet / totalObsUnits) * 100) + "% done\n ";

	/*
	----------------------------------------------------------------------------
		ALLOW THE USER TO REFINE THE SUBMASK AND THEN SAVE
	----------------------------------------------------------------------------
	*/

		manualSelection = true;
		msg = statusMsg;
		do {
			run("Remove Overlay");
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (startsWith(name, "Initial submask") == true) {
					i = roiManager("Count");
				}
				if (i == (roiManager("Count") - 1)) {
					exit ("Initial submask not found");
				}
			}
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Add Selection...");
			run("Select None");
			roiManager("Show None");
			waitForUser(msg + "\nRefine submask ROI.");

			msg = statusMsg;
			if (selectionType != -1) {
				roiManager("Add");
				roiManager("Select", roiManager("Count") - 1);
				roiManager("Rename", "New freehand selection");
				roi1 = -1;
				roi2 = -1;
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i);
					name = Roi.getName();
					if (startsWith(name, "Initial submask") == true) {
						roi1 = i;
					} else if (name == "New freehand selection") {
						roi2 = i;
					}
					if (roi1 > 0 && roi2 > 0) {
						i = roiManager("Count");
					}
				}
				if (roi1 == -1) { exit("Initial submask not found"); }
				if (roi2 == -1) { exit("New freehand selection not found"); }
				roiManager("Select", newArray(roi1, roi2));
				if (mode == "Crop") {
					roiManager("AND");
				} else if (mode == "Expand") {
					roiManager("OR");
				} else {
					exit(mode + " not recognized as a submask refinement mode.");
				}
				roiManager("Add"); // Intersection of previous and new freehand selections
				roiManager("Deselect");
				roiManager("Select", roiManager("Count") - 1);
				roiManager("Rename", "Initial submask modified");
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i);
					name = Roi.getName();
					if (startsWith(name, "Initial submask") == true) {
						roiManager("Delete");
						i = roiManager("Count");
					}
				}
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i);
					name = Roi.getName();
					if (name == "New freehand selection") {
						roiManager("Delete");
						i = roiManager("Count");
					}
				}
			} else {
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i);
					name = Roi.getName();
					if (startsWith(name, "Initial submask") == true) {
						i = roiManager("Count");
					}
				}
				setBatchMode(true);
				run("Create Mask");
				run("Analyze Particles...", "size=1-Infinity summarize");
				selectWindow("Summary");
				particles = split(getInfo(), "\n");
				particles = split(particles[1], "\t");
				particles = particles[1];
				run("Close");
				selectWindow("Mask");
				run("Close");
				setBatchMode(false);
				allowCompositesOption = retrieveGlobalConfiguration(1,5);
				if (particles > 1 && allowCompositesOption == 0) {
					msg = statusMsg + "\nMultiple selections in this ROI!\nPlease trim the ROI to a\nsingle contiguous selection\nor check 'Allow composite submasks'\nin the cfg settings.";
				} else {
					roiManager("Rename", "Submask " + obsUnits[obsUnitIndex]);
					setTool("rectangle");
					manualSelection = false;
				}
			}
		} while (manualSelection == true);
//		roiManager("Sort");
		roiManager("Save", obsUnitRoiPath + zipList[zipIndex]);
		deleted = File.delete(getDirectory("temp") + "Submasks temp image.tif");
		return 1;
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

function retrieveGlobalConfiguration(blockIndex, lineIndex) {
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
	retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
	deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
	retrieved = split(retrieved, "\n");
	return retrieved[0];
}