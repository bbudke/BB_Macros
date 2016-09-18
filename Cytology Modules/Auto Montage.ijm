var workingPath = getWorkingPaths("workingPath");
var analysisPath = getWorkingPaths("analysisPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Auto Montage Startup" {
	run("Install...", "install=[" + getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Auto Montage.ijm]");
	cleanup();
}

/*
--------------------------------------------------------------------------------
	MACRO BUTTONS
--------------------------------------------------------------------------------
*/

macro "Return to Cytology Frontend Action Tool - Ca44F36d6H096f6300" {
	cleanup();
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology.ijm");
}

macro "Auto Montage Configuration Action Tool - C037T0b10CT8b09fTdb09g" {
	panelsWideError = false;
	panelsHighError = false;
	maxOverlapError = false;
	do {
		Dialog.create("Auto Montage Options");
		if (panelsWideError == true) {
			Dialog.addMessage("'Panels wide' must be greater than zero.");
		}
		if (panelsHighError == true) {
			Dialog.addMessage("'Panels high' must be greater than zero.");
		}
		if (maxOverlapError == true) {
			Dialog.addMessage("'Max overlap between Obs Units' must be between 0.0 and 1.0.");
		}
		default = parseInt(retrieveConfiguration(5, 0));
		default = "Channel " + toString(default) + ": " + retrieveConfiguration(1, 0 + 1 * (-1 + default));
		labeledChoices = newArray();
		for (i=0; i<nChannels; i++) {
			labeledChoices = Array.concat(labeledChoices, "Channel " + toString(i + 1) + ": " + retrieveConfiguration(1, 0 + 1 * i));
		}
		Dialog.addChoice("Channel for single-channel montages:", labeledChoices, default);
		Dialog.addNumber("Panels wide:", parseInt(retrieveConfiguration(5, 1)));
		Dialog.addNumber("Panels high:", parseInt(retrieveConfiguration(5, 2)));
		Dialog.addCheckbox("Randomize panels:", parseInt(retrieveConfiguration(5, 3)));
		Dialog.addNumber("Max overlap between Obs Units (0.0 - 1.0):", parseFloat(retrieveConfiguration(5, 4)));
		Dialog.show();
		channel = Dialog.getChoice();
		channel = substring(channel, lengthOf("Channel "), lengthOf(channel));
		channel = parseInt(substring(channel, 0, indexOf(channel, ": ")));
		panelsWide = Dialog.getNumber();
		panelsHigh = Dialog.getNumber();
		randomize = Dialog.getCheckbox();
		maxOverlap = Dialog.getNumber();
		if (panelsWide < 1) { panelsWideError = true; } else { panelsWideError = false; }
		if (panelsHigh < 1) { panelsHighError = true; } else { panelsHighError = false; }
		if (maxOverlap < 0 || maxOverlap > 1) { maxOverlapError = true; } else { maxOverlapError = false; }
	} while (panelsWideError == true || panelsHighError == true || maxOverlapError == true);

	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|5|" + toString(0) + "|" + channel);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|5|" + toString(1) + "|" + panelsWide);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|5|" + toString(2) + "|" + panelsHigh);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|5|" + toString(3) + "|" + randomize);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|5|" + toString(4) + "|" + maxOverlap);
}

macro "Monochrome Montages From Single Channel Action Tool - C3a0F0055C140F6055C270Fc0553C030F0655C0a0F6655C080Fc655" {
	createMontages("mono");
}

macro "Heat Map Montages From Single Channel Action Tool - Cfb0F0055Cf40F6055Cf20Fc055Cfc0F0655Cff0F6655Cf60Fc655" {
	createMontages("heat");
}

macro "RGB Composite Montages Action Tool - Cc00F0055C0c0F6055C00cFc055C00cF0655Cc00F6655C0c0Fc655" {
	createMontages("composite");
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

function createMontages(montageType) {
	print("\\Clear");
	panelsWide = parseInt(retrieveConfiguration(5, 1));
	panelsHigh = parseInt(retrieveConfiguration(5, 2));

	imageIndex = File.openAsString(getWorkingPaths("imageIndexFile"));
	imageIndex = split(imageIndex, "\n");
	imageIndex = Array.slice(imageIndex, 1);
	if (lengthOf(imageIndex[imageIndex.length - 1]) == 0) {
		imageIndex = Array.slice(imageIndex, 0, imageIndex.length - 1);
	}

	labelIndex = File.openAsString(getWorkingPaths("groupLabelsFile"));
	labelIndex = split(labelIndex, "\n");
	labelIndex = Array.slice(labelIndex, 1);
	if (lengthOf(labelIndex[labelIndex.length - 1]) == 0) {
		labelIndex = Array.slice(labelIndex, 0, labelIndex.length - 1);
	}

	groups = newArray();
	labels = newArray();
	for (i=0; i<imageIndex.length; i++) {
		group = getFieldFromTdf(imageIndex[i], 2, true);
		if (toString(group) == "NaN") { group = "null"; }
		alreadyAdded = false;
		for (j=0; j<groups.length; j++) {
			if (group == groups[j]) {
				alreadyAdded = true;
			}
		}
		if (alreadyAdded == false) {
			groups = Array.concat(groups, group);
			if (toString(group) == "null") {
				labels = Array.concat("No label");
			} else {
				for (j=0; j<labelIndex.length; j++) {
					if (group == getFieldFromTdf(labelIndex[j], 1, true)) {
						append = getFieldFromTdf(labelIndex[j], 2, false);
						labels = Array.concat(labels, append);
					}
				}
			}
		}
	}

	for (i=0; i<groups.length; i++) {
		createObsUnitArrays(groups[i]);

		imageArray = File.openAsString(getDirectory("temp") + "savedImageArray.txt");
		deleted = File.delete(getDirectory("temp") + "savedImageArray.txt");
		imageArray = split(imageArray, "\n");
		if (lengthOf(imageArray[imageArray.length - 1]) == 0) {
			imageArray = Array.trim(imageArray, 0, imageArray - 1);
		}
		obsUnitArray = File.openAsString(getDirectory("temp") + "savedObsUnitArray.txt");
		deleted = File.delete(getDirectory("temp") + "savedObsUnitArray.txt");
		obsUnitArray = split(obsUnitArray, "\n");
		if (lengthOf(obsUnitArray[obsUnitArray.length - 1]) == 0) {
			obsUnitArray = Array.trim(obsUnitArray, 0, obsUnitArray - 1);
		}
		Array.print(imageArray);
		Array.print(obsUnitArray);

		setBatchMode(true);
		zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
		zipListNoExt = newArray();
		for (j=0; j<zipList.length; j++) {
			zipListNoExt = Array.concat(zipListNoExt, substring(zipList[j], 0, indexOf(zipList[j], ".zip")));
		}

		for (j=0; j<imageArray.length; j++) {
			runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + imageArray[j] + imageType + "|" + imageType + "|" + zSeriesOption);
			open(getDirectory("temp") + "Converted To Tiff.tif");
			deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
			run("Select None");

			if (montageType == "composite") {
				k1 = 1;
				k2 = 1;
				do {
					Stack.setPosition(k1, 1, 1);
					label = retrieveConfiguration(2, 0 + 5 * (-1 + k2));
					if (label == "Unused") {
						run("Delete Slice", "delete=channel");
					} else {
						min = retrieveConfiguration(2, 1 + 5 * (-1 + k2));
						max = retrieveConfiguration(2, 2 + 5 * (-1 + k2));
						color = retrieveConfiguration(2, 0 + 5 * (-1 + k2));
						if (color == "Gray") { color = "Grays"; }
						run(color);
						setMinAndMax(min, max);
						k1++;
					}
					k2++;
				} while (k1 <= nSlices());
				run("Make Composite");
				run("RGB Color");
			} else {
				singleChannel = parseInt(retrieveConfiguration(5, 0));
				k = 1;
				stackPosition = 1;
				do {
					Stack.setPosition(k, 1, 1);
					if (stackPosition != singleChannel) {
						run("Delete Slice", "delete=channel");
					} else {
						if (montageType == "mono") {
							min = retrieveConfiguration(2, 1 + 5 * (-1 + singleChannel));
							max = retrieveConfiguration(2, 2 + 5 * (-1 + singleChannel));
							color = retrieveConfiguration(2, 0 + 5 * (-1 + singleChannel));
							if (color == "Gray") { color = "Grays"; }
							run(color);
							setMinAndMax(min, max);
						} else if (montageType == "heat") {
							min = retrieveConfiguration(2, 3 + 5 * (-1 + singleChannel));
							max = retrieveConfiguration(2, 4 + 5 * (-1 + singleChannel));
							run("Fire");
							selectWindow("Converted To Tiff.tif");
							setMinAndMax(min, max);
						}
						k++;
					}
					stackPosition++;
				} while (k <= nSlices());

				run("Make Composite");
				run("RGB Color");
			}
			saveAs("Tiff", getDirectory("temp") + "RGB temp image for montage.tif");
			run("Close All");
			open(getDirectory("temp") + "RGB temp image for montage.tif");
			deleted = File.delete(getDirectory("temp") + "RGB temp image for montage.tif");

			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + imageArray[j] + ".zip");
			roiManager("Select", obsUnitArray[j]);
			getSelectionBounds(x, y, width, height);
			run("Copy");
			newImage("temp montage panel " + IJ.pad(1 + j, 2), "RGB black", width, height, 1, 1, 1);
			run("Paste");
			run("Size...", "width=" + toString(1600 / panelsWide) + " constrain average interpolation=Bilinear");
			saveAs("Tiff", getDirectory("temp") + "temp montage panel " + IJ.pad(1 + j, 2) + ".tif");
			run("Close All");
		}

		for (j=0; j<imageArray.length; j++) {
			open(getDirectory("temp") + "temp montage panel " + IJ.pad(1 + j, 2) + ".tif");
			deleted = File.delete(getDirectory("temp") + "temp montage panel " + IJ.pad(1 + j, 2) + ".tif");
		}
		if (nImages() == 1) {
			getDimensions(width, height, channels, frames, slices);
			newImage("dummy", "16-bit black", width, height, 1, 1, 1);
			run(color);
			run("RGB Color");
		}
		run("Images to Stack", "name=Stack title=[] use");
		run("Make Montage...", "columns=" + panelsWide + " rows=" + panelsHigh + " scale=1 first=1 last=" + toString(imageArray.length) + " increment=1 border=0 font=12");
		if (File.exists(analysisPath + "Montages" + File.separator()) != true) {
			File.makeDirectory(analysisPath + "Montages");
		}

		if (montageType == "composite") {
			saveAs("Tiff", analysisPath + "Montages" + File.separator() + "Montage " + "Composite" + " " + IJ.pad(groups[i], 2) + " " + labels[i] + ".tif");
		} else {
			target = retrieveConfiguration(1, 0 + 1 * (-1 + singleChannel));
			if (toString(groups[i]) == "null") {
				saveAs("Tiff", analysisPath + "Montages" + File.separator() + "Montage " + target + " " + labels[i] + ".tif");
			} else {
				saveAs("Tiff", analysisPath + "Montages" + File.separator() + "Montage " + target + " " + IJ.pad(groups[i], 2) + " " + labels[i] + ".tif");
			}
		}
		run("Close All");
	}
}

function createObsUnitArrays(groupNumber) {
	imageList = getFileListFromDirectory(workingPath, imageType);
	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	zipListNoExt = newArray();
	for (i=0; i<zipList.length; i++) {
		zipListNoExt = Array.concat(zipListNoExt, substring(zipList[i], 0, indexOf(zipList[i], ".zip")));
	}
	imageIndex = File.openAsString(getWorkingPaths("imageIndexFile"));
	imageIndex = split(imageIndex, "\n");
	imageIndex = Array.slice(imageIndex, 1);
	if (lengthOf(imageIndex[imageIndex.length - 1]) == 0) {
		imageIndex = Array.slice(imageIndex, 0, imageIndex.length - 1);
	}

	panelsWide = parseInt(retrieveConfiguration(5, 1));
	panelsHigh = parseInt(retrieveConfiguration(5, 2));
	randomize = parseInt(retrieveConfiguration(5, 3));
	maxOverlap = parseFloat(retrieveConfiguration(5, 4));

	indexCounter = 0;
	indexArray = newArray();
	imageArray = newArray();
	obsUnitArray = newArray();
	groupArray = newArray();

	setBatchMode(true);

	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + imageList[0] + "|" + imageType + "|" + zSeriesOption);
	open(getDirectory("temp") + "Converted To Tiff.tif");
	deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
	getDimensions(width, height, channels, slices, frames);
	run("Close All");
	newImage("temp", "8-bit black", width, height, 1, 1, 1);
	saveAs("Tiff", getDirectory("temp") + "temp.tif");
	for (i=0; i<zipList.length; i++) {
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipList[i]);
		for (j=0; j<roiManager("Count"); j++) {
			roiManager("Select", j);
			name = Roi.getName();
			if (indexOf(name, "OBS UNIT ") != -1) {
				indexCounter++;
				imageArray = Array.concat(imageArray, zipListNoExt[i]);
				obsUnitArray = Array.concat(obsUnitArray, j);
				for (k=0; k<imageIndex.length; k++) {
					if (zipListNoExt[i] == getFieldFromTdf(imageIndex[k], 1, false)) {
						if (toString(getFieldFromTdf(imageIndex[k], 2, true)) == "") {
							groupArray = Array.concat(groupArray, "null");
						} else {
							groupArray = Array.concat(groupArray, getFieldFromTdf(imageIndex[k], 2, true));

						}
					}
				}
			}
		}
	}

	for (i=0; i<indexCounter; i++) {
		indexArray = Array.concat(indexArray, i);
	}
	if (randomize == 1) {
		shuffledArray = newArray();
		do {
			i = random() * indexArray.length;
			i = floor(i);
			shuffledArray = Array.concat(shuffledArray, indexArray[i]);
			if (i ==0) {
				indexArray = Array.slice(indexArray, 1);
			} else if (i == indexArray.length - 1) {
				indexArray = Array.trim(indexArray, indexArray.length - 1);
			} else {
				a1 = Array.trim(indexArray, i);
				a2 = Array.slice(indexArray, i + 1);
				indexArray = Array.concat(a1, a2);
			}
		} while (indexArray.length > 0);

		indexArray = newArray();
		for (i=0; i<shuffledArray.length; i++) {
			indexArray = Array.concat(indexArray, shuffledArray[i]);
		}
	}

	imageArrayCopy = Array.copy(imageArray);
	obsUnitArrayCopy = Array.copy(obsUnitArray);
	groupArrayCopy = Array.copy(groupArray);
	imageArray = newArray();
	obsUnitArray = newArray();
	groupArray = newArray();
	for (i=0; i<indexArray.length; i++) {
		imageArray = Array.concat(imageArray, imageArrayCopy[indexArray[i]]);
		obsUnitArray = Array.concat(obsUnitArray, obsUnitArrayCopy[indexArray[i]]);
		groupArray = Array.concat(groupArray, groupArrayCopy[indexArray[i]]);
	}

	run("Set Measurements...", "area redirect=None decimal=3");
	selectedImageArray = newArray();
	selectedObsUnitArray = newArray();

	i=0;
	do {
		keep = "";
		if (groupArray[i] == groupNumber || isNaN(groupArray[i]) == true) {
			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + imageArray[i] + ".zip");
			previousObsUnits = newArray();
			if (selectedObsUnitArray.length > 0) {
				for (j=0; j<selectedObsUnitArray.length; j++) {
					if (selectedImageArray[j] == imageArray[i]) {
						previousObsUnits = Array.concat(previousObsUnits, selectedObsUnitArray[j]);
					}
				}
			}
			if (previousObsUnits.length > 0) {
				if (previousObsUnits.length > 1) {
					roiManager("Select", previousObsUnits);
					roiManager("OR");
				} else {
					roiManager("Select", previousObsUnits[0]);
				}
				roiManager("Add");
				roiManager("Select", roiManager("Count") - 1);
				roiManager("Rename", "Previous Obs Units");
				roiManager("Deselect");
			}
			roiManager("Select", obsUnitArray[i]);
			roiManager("Rename", "Current Obs Unit");
			run("Measure");
			area1 = getResult("Area");
			roiManager("Deselect");
			if (previousObsUnits.length > 0) {
				combinedArray = newArray();
				for (j=0; j<roiManager("Count"); j++) {
					roiManager("Select", j);
					name = Roi.getName();
					if (name == "Previous Obs Units" || name == "Current Obs Unit") {
						combinedArray = Array.concat(combinedArray, j);
					}
				}
				roiManager("Select", combinedArray);
				roiManager("AND");
				if (selectionType() != -1) {
					roiManager("Add");
					roiManager("Select", roiManager("Count") - 1);
					roiManager("Rename", "Combined Array");
					getSelectionBounds(x, y, width, height);
					run("Measure");
					area2 = getResult("Area");
					area3 = area2 / area1;
					if (area3 <= maxOverlap) {
						selectedImageArray = Array.concat(selectedImageArray, imageArray[i]);
						selectedObsUnitArray = Array.concat(selectedObsUnitArray, obsUnitArray[i]);
						keep = "keep";
					}
				} else {
					x = "null"; y = "null"; area2 = "null"; area3 = "no overlap";
					selectedImageArray = Array.concat(selectedImageArray, imageArray[i]);
					selectedObsUnitArray = Array.concat(selectedObsUnitArray, obsUnitArray[i]);
					keep = "keep";
				}
			} else {
				x = "first"; y = "first"; area2 = "first"; area3 = "first";
				selectedImageArray = Array.concat(selectedImageArray, imageArray[i]);
				selectedObsUnitArray = Array.concat(selectedObsUnitArray, obsUnitArray[i]);
				keep = "keep";
			}
			print(imageArray[i] + "   " + obsUnitArray[i] + "   " + groupArray[i] + "    x: " + x + " y: " + y + " int a: " + area3 + "   " + keep);
		} else {
			// do nothing and continue
		}
		i++;
	} while (i < imageArray.length && selectedImageArray.length < panelsWide * panelsHigh);

	savedImageArray = File.open(getDirectory("temp") + "savedImageArray.txt");
	for (i=0; i<selectedImageArray.length; i++) {
		print(savedImageArray, selectedImageArray[i]);
	}
	File.close(savedImageArray);
	savedObsUnitArray = File.open(getDirectory("temp") + "savedObsUnitArray.txt");
	for (i=0; i<selectedObsUnitArray.length; i++) {
		print(savedObsUnitArray, selectedObsUnitArray[i]);
	}
	File.close(savedObsUnitArray);
	if (isOpen("Results")) { selectWindow("Results"); run("Close"); }
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