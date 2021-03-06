var globalSetupFileHeaders = newArray("*** Auto generated by BB Macros.\nDo not modify unless you know exactly what you are doing.\n\n--------------------------------------------------------------------------------\n\tPATHS\n--------------------------------------------------------------------------------\n\n", "\n--------------------------------------------------------------------------------\n\tSETTINGS\n--------------------------------------------------------------------------------\n\n");
var globalSetupBlock01Labels = newArray("Working Path: ", "Analysis Path: ", "Obs Unit Roi Path: ", "Analysis Setup File: ", "Image Index File: ", "Group Labels File: ");
var globalSetupBlock01Defaults = newArray("", "", "", "", "", "");
var globalSetupBlock01Types = newArray("String", "String", "String", "String", "String", "String");

var globalSetupBlock02Labels = newArray("Maximum panels for box montage: ", "Randomize panels for box montage: ");
var globalSetupBlock02Defaults = newArray(9, 1);
var globalSetupBlock02Types = newArray("Int", "Boolean");

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Global Configurator" {
	args = getArgument();
	args = split(args, "|");

	globalConfigurationFile = getDirectory("plugins") +
	"BB_macros" + File.separator() +
	"Clonogenics_modules" + File.separator() +
	"Global_configuration.txt";

	pathArgs = newArray("workingPath", "analysisPath", "obsUnitRoiPath", "analysisSetupFile", "imageIndexFile", "groupLabelsFile");

	if (args[0] == "create") {
		if (File.exists(globalConfigurationFile) == true) {
			firstTimeSetupBoolean = false;
			lastBlock02Settings = getGlobalConfiguration(1, -1);
		} else {
			firstTimeSetupBoolean = true;
		}

		workingPath = getDirectory("Choose the directory in which image files are located:");
		analysisPath = workingPath + "Analysis" + File.separator();
		obsUnitRoiPath = analysisPath + "OBS UNIT ROIs" + File.separator();
		analysisSetupFile = analysisPath + "Setup.txt";
		imageIndexFile = analysisPath + "Image index.txt";
		groupLabelsFile = analysisPath + "Group labels.txt";
		globalSetupBlock01Choices = newArray(workingPath, analysisPath, obsUnitRoiPath, analysisSetupFile, imageIndexFile, groupLabelsFile);

		globalConfiguration = File.open(globalConfigurationFile);
		print(globalConfiguration, globalSetupFileHeaders[0]);
		for (i=0; i<globalSetupBlock01Labels.length; i++) {
			print(globalConfiguration, globalSetupBlock01Labels[i] + "\t" + globalSetupBlock01Choices[i]);
		}
		print(globalConfiguration, globalSetupFileHeaders[1]);
		if (firstTimeSetupBoolean == true) {
			for (i=0; i<globalSetupBlock02Labels.length; i++) {
				print(globalConfiguration, globalSetupBlock02Labels[i] + "\t" + globalSetupBlock02Defaults[i]);
			}
		} else {
			for (i=0; i<globalSetupBlock02Labels.length; i++) {
				print(globalConfiguration, globalSetupBlock02Labels[i] + "\t" + lastBlock02Settings[i]);
			}
		}
		File.close(globalConfiguration);
	} else if (args[0] == "change") {
		modifyGlobalSetupFile(args[1], args[2], args[3]);
	} else if (args[0] == "retrieve") {
		writeRetrievedToTemp(args[1], args[2]);
	} else if (args.length == 1) {
		pathIndex = -1;
		for (i=0; i<pathArgs.length; i++) {
			if (args[0] == pathArgs[i]) {
				pathIndex = i;
				break;
			}
		}
		retrieved = getGlobalConfiguration(0, pathIndex);
		retrievedTemp = File.open(getDirectory("temp") + "temp retrieved value.txt");
		print(retrievedTemp, retrieved);
		File.close(retrievedTemp);
	} else {
		exit("Invalid arguments passed to Global Configurator");
	}
}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

function getGlobalConfiguration(blockIndex, lineIndex) {
	rawText = File.openAsString(globalConfigurationFile);
	result = substring(rawText, indexOf(rawText, globalSetupFileHeaders[blockIndex]) + lengthOf(globalSetupFileHeaders[blockIndex]), lengthOf(rawText));
	if (blockIndex < globalSetupFileHeaders.length - 1) {
		result = substring(result, 0, indexOf(result, globalSetupFileHeaders[blockIndex + 1]));
	}
	result = split(result, "\n");
	trimmedResult = newArray();
	for (i=0; i<result.length; i++) {
		if (lengthOf(result[i]) == 0) { continue; }
		append = result[i];
		append = substring(append, indexOf(append, ": \t") + lengthOf(": \t"), lengthOf(append));
		trimmedResult = Array.concat(trimmedResult, append);
	}
	if (lineIndex < 0) {
		return trimmedResult;
	} else {
		return trimmedResult[lineIndex];
	}
}

function modifyGlobalSetupFile(blockIndex, lineIndex, newValue) {
	lastBlock01Settings = getGlobalConfiguration(0, -1);
	lastBlock02Settings = getGlobalConfiguration(1, -1);

	globalConfiguration = File.open(globalConfigurationFile);
	print(globalConfiguration, globalSetupFileHeaders[0]);
	for (i=0; i<globalSetupBlock01Labels.length; i++) {
		if (blockIndex == 0 && lineIndex == i) {
			print(globalConfiguration, globalSetupBlock01Labels[i] + "\t" + newValue);
		} else {
			print(globalConfiguration, globalSetupBlock01Labels[i] + "\t" + lastBlock01Settings[i]);
		}
	}
	print(globalConfiguration, globalSetupFileHeaders[1]);
	for (i=0; i<globalSetupBlock02Labels.length; i++) {
		if (blockIndex == 1 && lineIndex == i) {
			print(globalConfiguration, globalSetupBlock02Labels[i] + "\t" + newValue);
		} else {
			print(globalConfiguration, globalSetupBlock02Labels[i] + "\t" + lastBlock02Settings[i]);
		}
	}
	File.close(globalConfiguration);
}

function writeRetrievedToTemp(blockIndex, lineIndex) {
	retrieved = getGlobalConfiguration(blockIndex, lineIndex);
	retrievedTemp = File.open(getDirectory("temp") + "temp retrieved value.txt");
	print(retrievedTemp, retrieved);
	File.close(retrievedTemp);
}