var workingPath = getWorkingPaths("workingPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");
var currentImageIndex = -1;
var inUse = false;
var alerts = newArray("No corresponding ROI zip file found for this image.", "No submasks found in the ROI zip file corresponding to this image.", "At least one channel must have a color that is not 'unused'. (Hit 'Cfg')");
var colorChoices = newArray("Unused", "Red", "Green", "Blue", "Gray", "Cyan", "Magenta", "Yellow");

var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Image Viewer Startup" {
	run("Install...", "install=[" + getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Image Viewer.ijm]");
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

macro "Image Viewer Configuration Action Tool - C037T0b10CT8b09fTdb09g" {

	// Get the old settings to see if the settings get changed
	// This code is almost-exactly repeated below for new settings
	allOldSettings = newArray(4 + 5 * nChannels);
	for (i=0; i<nChannels; i++) {
		for (j=0; j<5; j++) {
			value = retrieveConfiguration(2, j + 5 * i);
			allOldSettings[j + 5 * i] = value;
		}
	}
	for (i=0; i<4; i++) {
		value = retrieveConfiguration(2, i + 5 * nChannels);
		allOldSettings[i + 5 * nChannels] = value;
	}
	value = retrieveGlobalConfiguration(1, 6); // option to show ROI manager
	allOldSettings = Array.concat(allOldSettings, value);

	displayChoices = newArray("RGB Composite", "Single Monochrome Images", "Single Heatmap Images");
	displayDefault = retrieveConfiguration(2, 0 + 5 * nChannels);
	obsUnitBoxDefault = retrieveConfiguration(2, 1 + 5 * nChannels);
	globalMaskDefault = retrieveConfiguration(2, 2 + 5 * nChannels);
	submaskDefault = retrieveConfiguration(2, 3 + 5 * nChannels);
	showRoiManagerDefault = retrieveGlobalConfiguration(1, 6);
	colorDefaults = newArray(nChannels);
	monoMinDefaults = newArray(nChannels);
	monoMaxDefaults = newArray(nChannels);
	heatMinDefaults = newArray(nChannels);
	heatMaxDefaults = newArray(nChannels);
	for (i=0; i<nChannels; i++) {
		value = retrieveConfiguration(2, 0 + 5 * i);
		colorDefaults[i] = value;
		value = retrieveConfiguration(2, 1 + 5 * i);
		monoMinDefaults[i] = value;
		value = retrieveConfiguration(2, 2 + 5 * i);
		monoMaxDefaults[i] = value;
		value = retrieveConfiguration(2, 3 + 5 * i);
		heatMinDefaults[i] = value;
		value = retrieveConfiguration(2, 4 + 5 * i);
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
	for (i=0; i<nChannels; i++) {
		Dialog.setInsets(0, 20, 0);
		Dialog.addChoice("Display color:", colorChoices, colorDefaults[i]);
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
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(0 + 5 * nChannels) + "|" + displayChoice);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(1 + 5 * nChannels) + "|" + obsUnitBoxChoice);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(2 + 5 * nChannels) + "|" + globalMaskChoice);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(3 + 5 * nChannels) + "|" + submaskChoice);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Global Configurator.ijm", "change|1|6|" + showRoiManagerChoice);
	for (i=0; i<nChannels; i++) {
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(0 + 5 * i) + "|" + Dialog.getChoice());
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(1 + 5 * i) + "|" + Dialog.getNumber());
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(2 + 5 * i) + "|" + Dialog.getNumber());
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(3 + 5 * i) + "|" + Dialog.getNumber());
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Cytology Configurator.ijm", "change|2|" + toString(4 + 5 * i) + "|" + Dialog.getNumber());
	}

	// Get the new settings to see if the settings got changed
	// This code is almost-exactly repeated above for old settings
	allNewSettings = newArray(4 + 5 * nChannels);
	for (i=0; i<nChannels; i++) {
		for (j=0; j<5; j++) {
			value = retrieveConfiguration(2, j + 5 * i);
			allNewSettings[j + 5 * i] = value;
		}
	}
	for (i=0; i<4; i++) {
		value = retrieveConfiguration(2, i + 5 * nChannels);
		allNewSettings[i + 5 * nChannels] = value;
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
		inUse = true;
		cleanup();
		imageList = getFileListFromDirectory(workingPath, imageType);
		imageListNoExt = newArray();
		for (i=0; i<imageList.length; i++) {
			append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
			imageListNoExt = Array.concat(imageListNoExt, append);
		}

		if (currentImageIndex > imageList.length - 1 || currentImageIndex < 0) {
			currentImageIndex = 0;
		}
		image = imageListNoExt[currentImageIndex];
		displayImage(image);
		inUse = false;
	}
}

macro "Load Previous Image (Shortcut Key is F1) Action Tool - C22dF36c6H096f6300" {
	if (inUse == false) {
		inUse = true;
		cleanup();
		imageList = getFileListFromDirectory(workingPath, imageType);
		imageListNoExt = newArray();
		for (i=0; i<imageList.length; i++) {
			append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
			imageListNoExt = Array.concat(imageListNoExt, append);
		}
		currentImageIndex--;
		if (currentImageIndex < 0) {
			currentImageIndex = imageList.length - 1;
		}
		image = imageListNoExt[currentImageIndex];
		displayImage(image);
		inUse = false;
	}
}

macro "Load Image Action Tool - C037T0707LT4707OT9707ATe707DT2f08IT5f08MTcf08G" {
	inUse = false;
	cleanup();
	imageList = getFileListFromDirectory(workingPath, imageType);
	imageListNoExt = newArray();
	for (i=0; i<imageList.length; i++) {
		append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
		imageListNoExt = Array.concat(imageListNoExt, append);
	}
	Dialog.create("Select Image");
	Dialog.addChoice("Image: ", imageListNoExt, imageListNoExt[0]);
	Dialog.show();
	image = Dialog.getChoice();

	for (i=0; i<imageListNoExt.length; i++) {
		if (image == imageListNoExt[i]) {
			currentImageIndex = i;
			i = imageListNoExt.length;
		}
	}

	displayImage(image);
}

macro "Load Next Image (Shortcut Key is F2) Action Tool - C22dF06c6Hf9939f00" {
	if (inUse == false) {
		inUse = true;
		cleanup();
		imageList = getFileListFromDirectory(workingPath, imageType);
		imageListNoExt = newArray();
		for (i=0; i<imageList.length; i++) {
			append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
			imageListNoExt = Array.concat(imageListNoExt, append);
		}
		currentImageIndex++;
		if (currentImageIndex > imageList.length - 1) {
			currentImageIndex = 0;
		}
		image = imageListNoExt[currentImageIndex];
		displayImage(image);
		inUse = false;
	}
}

macro "Get Panel Action Tool - C037F0055C307F6055C370Fc055C031F0855C604F6b55C440Fce55" {
	analysisPath = getWorkingPaths("analysisPath");
	imageList = getFileListFromDirectory(workingPath, imageType);
	imageListNoExt = newArray();
	for (i=0; i<imageList.length; i++) {
		append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
		imageListNoExt = Array.concat(imageListNoExt, append);
	}
	if (currentImageIndex == -1) {
		showMessage("An image must be open first.");
	} else {
		selection = roiManager("index");
		if (selection == -1) {
			showMessage("No selection has been made.");
		} else {
			RoiName = Roi.getName();
			imageName = imageListNoExt[currentImageIndex];
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
	analysisPath = getWorkingPaths("analysisPath");
	/*
	    Panels.txt is a tdf with no header in which each line contains the image and the OBS UNIT
	    For example, "2016-01-06-15-358\tOBS UNIT 11\n"
	*/
	if (!File.exists(analysisPath + "Panels.txt")) {
		showMessage("No Panels.txt file found.\nGoing through all images files instead.");
		imageList = getFileListFromDirectory(workingPath, imageType);
		imageListNoExt = newArray();
		for (i=0; i<imageList.length; i++) {
			append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
			imageListNoExt = Array.concat(imageListNoExt, append);
		}
		for (i = 0; i < imageListNoExt.length; i++) {
			displayImage(imageListNoExt[i]);
			selectImage(1);
			if (File.exists(analysisPath + "Panels" + File.separator()) != true) {
				File.makeDirectory(analysisPath + "Panels" + File.separator());
			}
			saveAs("Tiff", analysisPath + "Panels" + File.separator() + imageList[i]);
//			wait(10);
			cleanup();
		}
	} else {
		panelList = File.openAsString(analysisPath + "Panels.txt");
		panelList = split(panelList, "\n");
		for (i = 0; i < panelList.length; i++) {
			image = getFieldFromTdf(panelList[i], 1, false);
			displayImage(image);
			run("Hide Overlay");
//			run("Flatten");

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
	if (inUse == false) {
		inUse = true;
		cleanup();
		imageList = getFileListFromDirectory(workingPath, imageType);
		imageListNoExt = newArray();
		for (i=0; i<imageList.length; i++) {
			append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
			imageListNoExt = Array.concat(imageListNoExt, append);
		}
		currentImageIndex--;
		if (currentImageIndex < 0) {
			currentImageIndex = imageList.length - 1;
		}
		image = imageListNoExt[currentImageIndex];
		displayImage(image);
		inUse = false;
	}
}

macro "Load Next Image [f2]" {
	if (inUse == false) {
		inUse = true;
		cleanup();
		imageList = getFileListFromDirectory(workingPath, imageType);
		imageListNoExt = newArray();
		for (i=0; i<imageList.length; i++) {
			append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
			imageListNoExt = Array.concat(imageListNoExt, append);
		}
		currentImageIndex++;
		if (currentImageIndex > imageList.length - 1) {
			currentImageIndex = 0;
		}
		image = imageListNoExt[currentImageIndex];
		displayImage(image);
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
}

function displayImage(image) {
	setBatchMode(true);
	displayChoice = retrieveConfiguration(2, 0 + 5 * nChannels);
	obsUnitBoxChoice = retrieveConfiguration(2, 1 + 5 * nChannels);
	globalMaskChoice = retrieveConfiguration(2, 2 + 5 * nChannels);
	submaskChoice = retrieveConfiguration(2, 3 + 5 * nChannels);
	showRoiManager = retrieveGlobalConfiguration(1, 6);
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + image + imageType + "|" + imageType + "|" + zSeriesOption);
	open(getDirectory("temp") + "Converted To Tiff.tif");
	deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
	alert = "";
	if (obsUnitBoxChoice == 1 || globalMaskChoice == 1 || submaskChoice == 1 || showRoiManager == 1) {
		if (File.exists(obsUnitRoiPath + image + ".zip") == true) {
			roiManager("Open", obsUnitRoiPath + image + ".zip");

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
	for (i=0; i<nChannels; i++) {
		label = retrieveConfiguration(1, i);
		color = retrieveConfiguration(2, 0 + 5 * i);
		if (color != "Unused") {
			if (displayChoice == "Single Monochrome Images" || displayChoice == "RGB Composite") {
				min = retrieveConfiguration(2, 1 + 5 * i);
				max = retrieveConfiguration(2, 2 + 5 * i);
			} else if (displayChoice == "Single Heatmap Images") {
				min = retrieveConfiguration(2, 3 + 5 * i);
				max = retrieveConfiguration(2, 4 + 5 * i);
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
//				eval("script", frameScript(image + " " + channel + " " + labels[i] + ".tif", width, height, x, y));
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
			for (i=1; i<colorChoices.length; i++) {
				for (j=0; j<colors.length; j++) {
					if (colorChoices[i] == colors[j]) {
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
	if (showRoiManager == 1 && File.exists(obsUnitRoiPath + image + ".zip") == true) {
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

function retrieveGlobalConfiguration(blockIndex, lineIndex) {
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Cytology Modules" + File.separator() + "Global Configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
	retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
	deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
	retrieved = split(retrieved, "\n");
	return retrieved[0];
}