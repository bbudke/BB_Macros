var workingPath = getWorkingPaths("workingPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);
var delineationChannel = parseInt(retrieveConfiguration(1, 0 + 1 * nChannels));

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Obervational Units Global Masks" {
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
	zipListNoMask = newArray();
	for (i=0; i<zipList.length; i++) {
		alreadyProcessed = false;
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipList[i]);
		for (j=0; j<roiManager("Count"); j++) {
			roiManager("Select", j);
			name = Roi.getName();
			if (name == "Global Foreground Mask" || name == "Global Background Mask") {
				alreadyProcessed = true;
				j = roiManager("Count");
			}
		}
		if (alreadyProcessed == false) {
			zipListNoMask = Array.concat(zipListNoMask, zipList[i]);
		}
	}
	run("Close All");
	zipListNoMaskNoExt = newArray();
	for (i=0; i<zipListNoMask.length; i++) {
		zipListNoMaskNoExt = Array.concat(zipListNoMaskNoExt, substring(zipListNoMask[i], 0, indexOf(zipListNoMask[i], ".zip")));
	}

	if (zipListNoMaskNoExt.length == 0) {
		showStatus("All ROI files have been processed already.");
	}

	for (i=0; i<zipListNoMaskNoExt.length; i++) {
		showProgress(i / zipListNoMaskNoExt.length);

		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Cytology_modules" + File.separator() +
			"Convert_to_tiff.ijm", workingPath + zipListNoMaskNoExt[i] + imageType + "|" + imageType + "|" + zSeriesOption);
		open(getDirectory("temp") + "Converted To Tiff.tif");
		deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
		getDimensions(width, height, channels, slices, frames);
		Stack.setPosition(delineationChannel, 1, 1);
		run("Select All");
		run("Copy");
		newImage("temp", "16-bit black", width, height, 1, 1, 1);
		run("Paste");
		run("Fire");
		run("Enhance Contrast", "saturated=0.35");
		saveAs("Tiff", getDirectory("temp") + "temp.tif");
		run("Close All");

		open(getDirectory("temp") + "temp.tif");
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipListNoMaskNoExt[i] + ".zip");
		setAutoThreshold("Li dark");
		run("Convert to Mask");
		run("Gaussian Blur...", "sigma=5");
		setAutoThreshold("Li dark");
		run("Convert to Mask");
		run("Invert");
		run("Create Selection");
		roiManager("Add");
		roiManager("Select", roiManager("Count") -1 );
		roiManager("Rename", "Global Foreground mask");
		run("Make Inverse");
		if (selectionType != -1) {
			roiManager("Add");
			roiManager("Select", roiManager("Count") -1 );
			roiManager("Rename", "Global Background mask");
		} else {
			roiManager("Select", findRoiWithName("Global Foreground mask"));
			roiManager("Add");
			roiManager("Select", roiManager("Count") -1 );
			roiManager("Rename", "Global Background mask");
		}
		roiManager("Save", obsUnitRoiPath + zipListNoMaskNoExt[i] + ".zip");
		deleted = File.delete(getDirectory("temp") + "temp.tif");
		run("Close All");
	}
	if (i > 0) {
		showStatus("Globals masks added to " + i + " ROI files.");
	}

}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

function findRoiWithName(roiName) { 
	nR = roiManager("Count"); 
 
	for (i=0; i<nR; i++) { 
		roiManager("Select", i); 
		rName = Roi.getName(); 
		if (matches(rName, roiName)) { 
			return i; 
		} 
	} 
	return -1; 
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