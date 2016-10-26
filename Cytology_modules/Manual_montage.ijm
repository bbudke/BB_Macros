var workingPath = getWorkingPaths("workingPath");
var analysisPath = getWorkingPaths("analysisPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

var inUse = false;
var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Manual Montage Startup" {
	run("Install...", "install=[" + getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Manual_montage.ijm]");
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
		"BB_macros" + File.separator() + "Cytology.ijm");
}

macro "Manual Montage Configuration Action Tool - C037T0b10CT8b09fTdb09g" {

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
	Dialog.addCheckbox("Show ROI Manager\n(must select all boxes above for this to work)", showRoiManagerDefault);
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
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Cytology_configurator.ijm", "change|2|" + toString(0 + 5 * nChannels) + "|" + displayChoice);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Cytology_configurator.ijm", "change|2|" + toString(1 + 5 * nChannels) + "|" + obsUnitBoxChoice);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Cytology_configurator.ijm", "change|2|" + toString(2 + 5 * nChannels) + "|" + globalMaskChoice);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Cytology_configurator.ijm", "change|2|" + toString(3 + 5 * nChannels) + "|" + submaskChoice);
	runMacro(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configurator.ijm", "change|1|6|" + showRoiManagerChoice);
	for (i=0; i<nChannels; i++) {
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

macro "Montage Builder Menu Tool - C037F0055C307F6055C370Fc055C031F0855C604F6b55C440Fce55" {
	
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