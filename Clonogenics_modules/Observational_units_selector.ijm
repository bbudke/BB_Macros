var workingPath = getWorkingPaths("workingPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

var imageName;
var roiCounter = 0;
var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);
var delineationChannel = parseInt(retrieveConfiguration(1, 0 + 1 * nChannels));

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Obervational Units Selector Startup" {
	run("Install...", "install=[" + getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Observational_units_selector.ijm]");
	cleanup();
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

macro "Observational Units Selector Configuration Action Tool - C037T0b10CT8b09fTdb09g" {
	boxMontagePanels = retrieveGlobalConfiguration(1, 0);
	randomizeBoolean = retrieveGlobalConfiguration(1, 1);
	Dialog.create("Observational Units Selector");
	Dialog.addNumber("Maximum panels for box size montage: ", boxMontagePanels);
	Dialog.addCheckbox("Randomize panels for box size montage? ", randomizeBoolean);
	Dialog.show();
	boxMontagePanels = Dialog.getNumber();
	randomizeBoolean = Dialog.getCheckbox();
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|0|" + boxMontagePanels);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|1|" + randomizeBoolean);
}

macro "Set Observational Unit Enclosing Box Size Action Tool - C66eV3355C037R00aaLd0daLc0e0LcaeaL0dadL0c0eLacae" {
	delineationDisplayMin = retrieveConfiguration(2, 3 + 5 * (delineationChannel - 1));
	delineationDisplayMax = retrieveConfiguration(2, 4 + 5 * (delineationChannel - 1));
	boxSize = retrieveConfiguration(3, 0);
	boxMontagePanels = retrieveGlobalConfiguration(1, 0);
	randomizeBoolean = retrieveGlobalConfiguration(1, 1);
	if (boxSize == -1) {
		boxSize = 920;
	}

	run("Close All");
	setBatchMode(true);

	imageList = getFileListFromDirectory(workingPath, imageType);
	if (randomizeBoolean == 1) {
		shuffledImageList = newArray();
		do {
			i = random() * imageList.length;
			i = floor(i);
			shuffledImageList = Array.concat(shuffledImageList, imageList[i]);
			if (i == 0) {
				imageList = Array.slice(imageList, 1);
			} else if (i == imageList.length - 1) {
				imageList = Array.trim(imageList, imageList.length - 1);
			} else {
				a1 = Array.trim(imageList, i);
				a2 = Array.slice(imageList, i + 1);
				imageList = Array.concat(a1, a2);
			}
		} while (imageList.length > 0);

		imageList = newArray();
		for (i=0; i<shuffledImageList.length; i++) {
			imageList = Array.concat(imageList, shuffledImageList[i]);
		}
	}

	montagePanels = 0;
	for (i=0; i<imageList.length; i++) {
		if (i < boxMontagePanels) {
			runMacro(getDirectory("plugins") +
				"BB_macros" + File.separator() +
				"Clonogenics_modules" + File.separator() +
				"Convert_to_tiff.ijm", workingPath + imageList[i] + "|" + imageType + "|" + zSeriesOption);
			open(getDirectory("temp") + "Converted To Tiff.tif");
			deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
			getDimensions(width, height, channels, slices, frames);
			selectImage(1);
			Stack.setPosition(delineationChannel, 1, 1);
			run("Select All");
			run("Copy");
			newImage("Box size temp montage panel " + IJ.pad(i + 1, 2), "16-bit black", width, height, 1, 1, 1);
			run("Paste");
			run("Fire");
			run("Enhance Contrast", "saturated=0.35");
			setMinAndMax(delineationDisplayMin, delineationDisplayMax);
			saveAs("Tiff", getDirectory("temp") + "Box size temp montage panel " + IJ.pad(i + 1, 2) + ".tif");
			run("Close All");
			montagePanels++;
		} else {
			i = imageList.length;
		}
		showProgress(montagePanels / boxMontagePanels);
	}

	for (i=0; i<montagePanels; i++) {
		open(getDirectory("temp") + "Box size temp montage panel " + IJ.pad(i + 1, 2) + ".tif");
	}

	rows = round(sqrt(montagePanels));
	columns = -1 * floor( -1 * sqrt(montagePanels));
	run("Images to Stack", "name=Stack title=[] use");
	run("Make Montage...", "columns=" + columns + " rows=" + rows + " scale=1 first=1 last=" + montagePanels + " increment=1 border=0 font=12");
	saveAs("Tiff", getDirectory("temp") + "Box size temp montage.tif");
	run("Close All");

	for (i=0; i<montagePanels; i++) {
		deleted = File.delete(getDirectory("temp") + "Box size temp montage panel " + IJ.pad(i + 1, 2) + ".tif");
	}

	setBatchMode(false);
	open(getDirectory("temp") + "Box size temp montage.tif");

	setTool("rectangle");
	selectImage(1);
	makeRectangle(0, 0, boxSize, boxSize);
	waitForUser("Resize box as needed");
	getSelectionBounds(x, y, width, height);
	if (width > height) {
		newBoxSize = width;
	} else {
		newBoxSize = height;
	}
	close();
	deleted = File.delete(getDirectory("temp") + "Box size temp montage.tif");

	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Clonogenics_modules" + File.separator() +
		"Clonogenics_configurator.ijm", "change|3|0|" + newBoxSize);
	if (boxSize == newBoxSize) {
		showStatus("Previous box size of " + newBoxSize + " left unchanged.");
	} else {
		showStatus(newBoxSize + " entered as new box size.");
	}
}

macro "Load First Or Next Image (Shortcut key is F2) Action Tool - C037T0507LT4507OT9507ATe507DT0f07NT5f07ETaf07XTef07T" {
	boxSize = retrieveConfiguration(3, 0);
	if (boxSize != -1) {
		cleanup();
		roiCounter = 0;
		status = loadNextImage();
		if (status == 1) {
			roiManager("Reset");
			roiManager("Show None");
		} else {
			showStatus("End of image list.");
		}
	} else {
		showStatus("Observational unit enclosing box size must be set first.");
	}
}

macro "Add ROI (Shortcut key is F1) Action Tool - C037T0708AT6708DTc708DT2f08RT7f08OTef08I" {
	boxSize = retrieveConfiguration(3, 0);
	if (boxSize != -1) {
		if (nImages() == 1) {
			imageName = getTitle();
			roiCounter += 1;
			roiManager("Add");
			roiManager("Select", roiManager("Count") - 1);
			roiManager("Rename", "OBS UNIT " + IJ.pad(roiCounter, 2));
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Add Selection...");
			roiManager("Save", obsUnitRoiPath + imageName + ".zip");
		} else {
			showStatus("One image must be loaded.");
		}
	} else {
		showStatus("Observational unit enclosing box size must be set first.");
	}
}

macro "Delete ROI Action Tool - C037T1708DT8708ETd708LT2f08RT7f08OTef08I" {
	boxSize = retrieveConfiguration(3, 0);
	if (boxSize != -1) {
		if (nImages() == 1) {
			if (roiCounter > 0) {
				roiManager("Select", roiManager("Count") - 1);
				roiManager("Delete");
				selectImage(1);
				run("Remove Overlay");
				roiCounter -= 1;
			}
			if (roiCounter > 0) {
				run("Overlay Options...", "stroke=green width=0 fill=none");
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i);
					run("Add Selection...");
				}
				roiManager("Select", roiManager("Count") - 1);
			} else {
				deleted = File.delete(obsUnitRoiPath + imageName + ".zip");
			}
		} else {
			showStatus("One image must be loaded.");
		}
	} else {
		showStatus("Observational unit enclosing box size must be set first.");
	}
}

macro "Reset Image Action Tool - C037T0a07RT4a07ET8a07STba07ETfa07T" {
	boxSize = retrieveConfiguration(3, 0);
	if (boxSize != -1) {
		if (nImages() == 1) {
			cleanup();
			if (File.exists(obsUnitRoiPath + toString(imageName) + ".zip")) {
				deleted = File.delete(obsUnitRoiPath + toString(imageName) + ".zip");
			}
			roiCounter = 0;
			status = loadNextImage();
			selectImage(1);
			makeRectangle(0, 0, boxSize, boxSize);
			roiManager("Reset");
			roiManager("Show None");
		} else {
			showStatus("One image must be loaded.");
		}
	} else {
		showStatus("Observational unit enclosing box size must be set first.");
	}
}

/*
--------------------------------------------------------------------------------
	MACRO SHORTCUT KEYS
--------------------------------------------------------------------------------
*/

macro "Add ROI [f1]" {
	boxSize = retrieveConfiguration(3, 0);
	if (boxSize != -1) {
		if (nImages() == 1) {
			imageName = getTitle();
			roiCounter += 1;
			roiManager("Add");
			roiManager("Select", roiManager("Count") - 1);
			roiManager("Rename", "OBS UNIT " + IJ.pad(roiCounter, 2));
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Add Selection...");
			roiManager("Save", obsUnitRoiPath + imageName + ".zip");
		} else {
			showStatus("One image must be loaded.");
		}
	} else {
		showStatus("Observational unit enclosing box size must be set first.");
	}
}

macro "Add ROI Or Advance To Next Image [f2]" {
	boxSize = retrieveConfiguration(3, 0);
	if (boxSize != -1) {
		cleanup();
		roiCounter = 0;
		status = loadNextImage();
		if (status == 1) {
			roiManager("Reset");
			roiManager("Show None");
		} else {
			showStatus("End of image list.");
		}
	} else {
		showStatus("Observational unit enclosing box size must be set first.");
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
	if (File.exists(getDirectory("temp") + "Obs Unit Delineator Temp.tif")) {
		deleted = File.delete(getDirectory("temp") + "Obs Unit Delineator Temp.tif");
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

function loadNextImage() {
	boxSize = retrieveConfiguration(3, 0);
	imageList = getFileListFromDirectory(workingPath, imageType);
	imageListNoExt = newArray();
	for (i=0; i<imageList.length; i++) {
		imageListNoExt = Array.concat(imageListNoExt, substring(imageList[i], 0 , indexOf(imageList[i], imageType)));
	}
	if (File.exists(obsUnitRoiPath) != true) { File.makeDirectory(obsUnitRoiPath); }
	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	zipListNoExt = newArray();
	for (i=0; i<zipList.length; i++) {
		zipListNoExt = Array.concat(zipListNoExt, substring(zipList[i], 0 , indexOf(zipList[i], ".zip")));
	}
	
	imageListIndex = -1;
	for (i=0; i<imageListNoExt.length; i++) {
		found = false;
		for (j=0; j<zipListNoExt.length; j++) {
			if (zipListNoExt[j] == imageListNoExt[i]) {
				found = true;
				j = zipListNoExt.length;
			}
		}
		if (found == false) {
			imageListIndex = i;
			i = imageListNoExt.length;
		}
	}

	if (imageListIndex == -1) {
		if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
		return 0;
	} else {
		setBatchMode(true);

		imageName = substring(imageList[imageListIndex], 0, indexOf(imageList[imageListIndex], imageType));
		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Clonogenics_modules" + File.separator() +
			"Convert_to_tiff.ijm", workingPath + imageList[imageListIndex] + "|" + imageType + "|" + zSeriesOption);
		open(getDirectory("temp") + "Converted To Tiff.tif");
		deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
		getDimensions(width, height, channels, slices, frames);
		Stack.setPosition(delineationChannel, 1, 1);
		run("Select All");
		run("Copy");
		newImage("Obs Unit Delineator Temp", "16-bit black", width, height, 1, 1, 1);
		run("Paste");
		run("Fire");
		run("Enhance Contrast", "saturated=0.35");
		saveAs("Tiff", getDirectory("temp") + "Obs Unit Delineator Temp.tif");
		run("Close All");

		setBatchMode(false);
		open(getDirectory("temp") + "Obs Unit Delineator Temp.tif");
		rename(imageName);
		makeRectangle(0, 0, boxSize, boxSize);
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