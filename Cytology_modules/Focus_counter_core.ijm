/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Focus Counter Core" {
	args = getArgument(); // args: "mode|channel|median|average|submaskFileIndex|submaskRoiIndex|percentComplete"

	originalImage = getDirectory("temp") + "Original image.tif";
	segmentationMap = getDirectory("temp") + "Segmentation map.tif";
	backgroundSubtracted = getDirectory("temp") + "Background subtracted.tif";
	thresholded = getDirectory("temp") + "Thresholded.tif";
	fociMask = getDirectory("temp") + "Foci mask.tif";
	originalImageOverlay = getDirectory("temp") + "Original image overlay.tif";
	fociROIs = getDirectory("temp") + "fociROIs.zip";

	if (nImages != 1) {
		exit("Focus Counter Core.ijm requires one and only one image to be open.");
	} else {
		getDimensions(width, height, channels, slices, frames);
		if (slices != 1 || channels != 1) {
			exit("Only single-plane, single-channel images are supported.")
		} else{
			selectImage(1);
			saveAs("Tiff", originalImage);
		}
	}
	cleanup();

	/*
	----------------------------------------------------------------------------
		GET MEASUREMENT AND DISPLAY PARAMETERS
	----------------------------------------------------------------------------
	*/

	if (lengthOf(args) != 0) { // Run this if this macro was executed by another macro

		argsArray = split(args, "|");
		mode = argsArray[0];
		channel = parseInt(argsArray[1]);

		heatMapDisplayMin = parseInt(retrieveConfiguration(2, 3 + 5 * (channel - 1)));
		heatMapDisplayMax = parseInt(retrieveConfiguration(2, 4 + 5 * (channel - 1)));
		maximaTolerance = parseInt(retrieveConfiguration(4, 2 + 8 * (channel - 1)));
		lowerThreshold = parseInt(retrieveConfiguration(4, 3 + 8 * (channel - 1)));
		minimumSize = parseInt(retrieveConfiguration(4, 4 + 8 * (channel - 1)));
		minimumAvgIntensity = parseInt(retrieveConfiguration(4, 5 + 8 * (channel - 1)));
		minimumIntensity = parseInt(retrieveConfiguration(4, 6 + 8 * (channel - 1)));
		minimumUpperDecile = parseInt(retrieveConfiguration(4, 7 + 8 * (channel - 1)));

		backendBSub = parseInt(retrieveConfiguration(4, 1 + 8 * (channel - 1)));
		medianBackground = argsArray[2];
		averageBackground = argsArray[3];

		submaskFileIndex = argsArray[4];
		maskFile = getWorkingPaths("obsUnitRoiPath");
		maskFile = getFileListFromDirectory(maskFile, ".zip");
		maskFile = toString(getWorkingPaths("obsUnitRoiPath")) + maskFile[submaskFileIndex];
		submaskRoiIndex = argsArray[5];
		percentComplete = argsArray[6];

	} else { // Run this if this macro was executed as a stand-alone

		roiManager("Reset");

		mode = "Single";

		heatMapDisplayMin = 0;
		heatMapDisplayMax = 4095;
		maximaTolerance = 70;
		lowerThreshold = 250;
		minimumSize = 10;
		minimumAvgIntensity = 50;
		minimumIntensity = 3000;
		minimumUpperDecile = 500;

		Dialog.create("BSub options");
		Dialog.addChoice("Background subtraction", newArray("No background subtraction", "Rolling ball", "Enter a value"), "No background subtraction");
		Dialog.show();
		choice = Dialog.getChoice();
		if (choice == "No background subtraction") {
			backendBSub = 0;
		} else if (choice == "Rolling ball") {
			backendBSub = -50;
		} else if (choice == "Enter a value") {
			do {
				Dialog.create("Enter a value > 0");
				Dialog.addNumber("Background value to subtract: ", 0);
				Dialog.show();
				backendBSub = Dialog.getNumber();
			} while (backendBSub > 0);
		}

		Dialog.create("Mask options");
		Dialog.addChoice("Option", newArray("No mask", "Draw mask", "Select from saved ROI file"), "No mask");
		Dialog.show();
		choice = Dialog.getChoice();
		if (choice == "No mask") {
			maskFile = "null";
			submaskRoiIndex = -1;
		} else if (choice == "Draw mask") {
			open(originalImage);
			selectImage(1);
			run("Select None");
			setTool("freehand");
			do {
				waitForUser("Draw a mask");
			} while (selectionType == -1);
			roiManager("Add");
			maskFile = getDirectory("temp") + "temp mask.zip";
			submaskRoiIndex = 0;
			roiManager("Save", maskFile);
		} else if (choice == "Select from saved ROI file") {
			maskFile = File.openDialog("Zip file containing mask");
			setBatchMode(true);
			roiManager("Open", maskFile);
			roiNames = newArray();
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				roiNames = Array.concat(roiNames, Roi.getName());
			}
			cleanup();
			Dialog.create("Selection containing mask");
			Dialog.addChoice("ROI", roiNames, roiNames[0]);
			Dialog.show();
			maskRoi = Dialog.getChoice();
			submaskRoiIndex = -1;
			for (i=0; i<roiNames.length; i++) {
				if (maskRoi == roiNames[i]) {
					submaskRoiIndex = i;
					break;
				}
			}
		}
	}

	finished = false;
	showProgress(percentComplete);
	do {

	/*
	----------------------------------------------------------------------------
		GENERATE PROCESSING IMAGES
	----------------------------------------------------------------------------
	*/

		cleanup();
		setBatchMode(true);

		// Original source image (1)
		open(originalImage);
		rename("Original image.tif");
		getDimensions(width, height, channels, slices, frames);
//		eval("script", frameScript("Original image.tif", 400, 400, 0, 200));
		run("Scale to Fit");
		run("Fire");
		setMinAndMax(heatMapDisplayMin, heatMapDisplayMax);
		saveAs("Tiff", originalImage);

		// 'Spider web' image of segmented particles (2)
		run("Find Maxima...", "noise=" + maximaTolerance + " output=[Segmented Particles]");
		showProgress(percentComplete);
		rename("Segmentation map.tif");
//		eval("script", frameScript("Segmentation map.tif", 400, 400, 400, 200));
		run("Scale to Fit");
		run("Max...", "value=1");
		setMinAndMax(0, 1);
		saveAs("Tiff", segmentationMap);

		// Background-subtracted image (3)
		if (backendBSub != 0) {
			selectWindow("Original image.tif");
			run("Select All");
			run("Copy");
			newImage("Background subtracted.tif", "16-bit black", width, height, 1);
			selectWindow("Background subtracted.tif");
			run("Paste");
//			eval("script", frameScript("Background subtracted.tif", 400, 400, 0, 600));
			run("Scale to Fit");
			if (backendBSub > 0) {
				run("Subtract...", "value=" + backendBSub);
			} else {
				run("Subtract Background...", "rolling=" + ( backendBSub * -1 ));
			}

			// Manual switch for Gaussian blur
			run("Gaussian Blur...", "sigma=1");

			run("Fire");
			setMinAndMax(heatMapDisplayMin, heatMapDisplayMax);
			saveAs("Tiff", backgroundSubtracted);
		}

		// Thresholded image (4)
		if (backendBSub != 0) {
			selectWindow("Background subtracted.tif");
		} else {
			selectWindow("Original image.tif");
		}
		run("Copy");
		newImage("Thresholded.tif", "16-bit black", width, height, 1);
		selectWindow("Thresholded.tif");
		run("Paste");
//		eval("script", frameScript("Thresholded.tif", 400, 400, 400, 600));
		run("Scale to Fit");
		setThreshold(lowerThreshold, 4095);
		run("Make Binary");
		run("Gaussian Blur...", "sigma=1");
		setThreshold(64, 255);
		run("Make Binary");
		run("Invert LUT");
		saveAs("Tiff", thresholded);

		// Mask of foci (5)
		imageCalculator("Multiply create", "Thresholded.tif", "Segmentation map.tif");
		rename("Foci mask.tif");
//		eval("script", frameScript("Foci mask.tif", 400, 400, 800, 200));
		run("Scale to Fit");
		run("Invert");
		if (maskFile != "null" && submaskRoiIndex != -1) {
			roiManager("Open", maskFile);
			submaskEnlarge = 0; // temporary until I write an option to resize submasks later.
			
			selectWindow("Original image.tif");
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Labels...", "color=green font=18");
			roiManager("Select", submaskRoiIndex);

			run("Enlarge...", "enlarge=" + submaskEnlarge);

			run("Add Selection...");
			run("Select None");
			saveAs("Tiff", originalImageOverlay);
			
			selectWindow("Segmentation map.tif");
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Labels...", "color=green font=18");
			roiManager("Select", submaskRoiIndex);

			run("Enlarge...", "enlarge=" + submaskEnlarge);

			run("Add Selection...");
			run("Select None");
			saveAs("Tiff", segmentationMap);

			if (backendBSub != 0) {
				selectWindow("Background subtracted.tif");
				run("Overlay Options...", "stroke=green width=0 fill=none");
				run("Labels...", "color=green font=18");
				roiManager("Select", submaskRoiIndex);

				run("Enlarge...", "enlarge=" + submaskEnlarge);

				run("Add Selection...");
				run("Select None");
				saveAs("Tiff", backgroundSubtracted);
			}

			selectWindow("Thresholded.tif");
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Labels...", "color=green font=18");
			roiManager("Select", submaskRoiIndex);

			run("Enlarge...", "enlarge=" + submaskEnlarge);

			run("Add Selection...");
			run("Select None");
			saveAs("Tiff", thresholded);

			selectWindow("Foci mask.tif");
			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Labels...", "color=green font=18");
			roiManager("Select", submaskRoiIndex);

			run("Enlarge...", "enlarge=" + submaskEnlarge);

			run("Add Selection...");
			run("Make Inverse");
			run("Set...", "value=255");

			roiManager("Reset");
		} else {
			selectWindow("Original image.tif");
			saveAs("Tiff", originalImageOverlay);
			selectWindow("Foci mask.tif");
		}
		run("Select None");
		run("Analyze Particles...", "  add");
		nFoci = roiManager("Count");
		roiManager("Show None");
		run("Invert");
		saveAs("Tiff", fociMask);
		run("Close All");

	/*
	----------------------------------------------------------------------------
		MEASURE FOCI
	----------------------------------------------------------------------------
	*/

		nBackendFoci = 0;
		if (nFoci > 0) {
			open(originalImageOverlay);
			if (backendBSub != 0) {
				open(backgroundSubtracted);
			}
			open(fociMask);
			focusMeasurements = File.open(getDirectory("temp") + "FCC foci temp.txt");
			run("Set Measurements...", "area mean integrated redirect=None decimal=3");
			for (i=0; i<roiManager("Count"); i++) {
				if (backendBSub == 0) {
					selectWindow("Original image overlay.tif");
				} else {
					selectWindow("Background subtracted.tif");
				}

				roiManager("Select", i);
				roiManager("Rename", i);
				run("Measure");
				getHistogram(values, counts, 10);
				focusArea = getResult("Area");
				focusAvgIntensity = parseInt(getResult("Mean"));
				focusIntensity = getResult("IntDen");
				focusUpperDecile = parseInt(values[9]);

				run("Clear Results");
				selectWindow("Original image overlay.tif");

				roiManager("Select", i);
				roiManager("Rename", i);
				run("Measure");
				getHistogram(values, counts, 10);
				focusAreaRaw = getResult("Area");
				focusAvgIntensityRaw = parseInt(getResult("Mean"));
				focusIntensityRaw = getResult("IntDen");
				focusUpperDecileRaw = parseInt(values[9]);
				
				focusAreaTest = focusArea - minimumSize;
				focusAvgIntensityTest = focusAvgIntensity - minimumAvgIntensity;
				focusIntensityTest = focusIntensity - minimumIntensity;
				focusUpperDecileTest = focusUpperDecile - minimumUpperDecile;
				if (focusAreaTest >= 0 && focusAvgIntensityTest >=0 && focusIntensityTest >= 0 && focusUpperDecileTest >= 0) {
					pass = 1;
				} else {
					pass = 0;
				}

				print(focusMeasurements,
					i + "\t" + 
					pass + "\t" + 
					focusArea + "\t" + 
					focusAvgIntensity + "\t" + 
					focusIntensity + "\t" + 
					focusUpperDecile + "\t" + 
					focusAreaTest + "\t" + 
					focusAvgIntensityTest + "\t" + 
					focusIntensityTest + "\t" + 
					focusUpperDecileTest + "\t" + 
					focusAreaRaw + "\t" + 
					focusAvgIntensityRaw + "\t" + 
					focusIntensityRaw + "\t" + 
					focusUpperDecileRaw
					);

				if (pass == 1) {
					selectWindow("Original image overlay.tif");
					run("Overlay Options...", "stroke=green width=0 fill=none");
					run("Labels...", "color=green font=18");
					roiManager("Select", i);
					roiManager("Rename", "Focus PASS " + IJ.pad(i, 5));
					run("Add Selection...");
					run("Select None");
					nBackendFoci++;
				} else {
					selectWindow("Foci mask.tif");
					roiManager("Select", i);
					roiManager("Rename", "Focus FAIL " + IJ.pad(i, 5));
					run("Set...", "value=96");
					run("Select None");
				}
			}
			roiManager("save", fociROIs);
			roiManager("Reset");
			File.close(focusMeasurements);
			selectWindow("Original image overlay.tif");
			saveAs("Tiff", originalImageOverlay);
			selectWindow("Foci mask.tif");
			saveAs("Tiff", fociMask);
			run("Close All");
		}

	/*
	----------------------------------------------------------------------------
		DISPLAY RESULTS AND ALLOW USER TO CHANGE SETTINGS IF MODE = 'Single'
	----------------------------------------------------------------------------
	*/

		if (mode == "Single") { // run this if this macro was executed in 'Single' mode

			setBatchMode(false);

			open(segmentationMap);
//			eval("script", frameScript("Segmentation map.tif", 400, 400, 400, 200));
			run("Scale to Fit");
			open(fociMask);
//			eval("script", frameScript("Foci mask.tif", 400, 400, 1200, 200));
			run("Scale to Fit");
			open(thresholded);
//			eval("script", frameScript("Thresholded.tif", 400, 400, 400, 600));
			run("Scale to Fit");
			if (backendBSub != 0) {
				open(backgroundSubtracted);
//				eval("script", frameScript("Background subtracted.tif", 400, 400, 0, 600));
				run("Scale to Fit");
			}
			open(originalImageOverlay);
//			eval("script", frameScript("Original image overlay.tif", 400, 400, 0, 200));
			run("Scale to Fit");

			if (isOpen("Results")) { selectWindow("Results"); run("Close"); }

			if (nFoci > 0) {
				focusMeasurements = File.openAsString(getDirectory("temp") + "FCC foci temp.txt");
				resultsTable = File.open(getDirectory("temp") + "FCC results temp.txt");
				print(resultsTable,
					"Focus\t" +
					"Pass\t" +
					"Area\t" +
					"Avg Int\t" +
					"Int\t" +
					"Upper Dec\t" +
					"Area Diff\t" +
					"Avg Int Diff\t" +
					"Int Diff\t" +
					"Upper Dec Diff\t" +
					"Area Raw\t" +
					"Avg Int Raw\t" +
					"Int Raw\t" +
					"Upper Dec Raw"
					);
				print(resultsTable, focusMeasurements);
				File.close(resultsTable);
				run("Table... ", "open=[" + getDirectory("temp") + "FCC results temp.txt]");
//				eval("script", frameScript("FCC results temp.txt", 800, 400, 800, 600));
			}

			oldSettings = newArray(backendBSub, maximaTolerance, lowerThreshold, minimumSize, minimumAvgIntensity, minimumIntensity, minimumUpperDecile);

			do {

				redisplay = false;
				Dialog.create("Focus Enumeration Setup Dialog");
				imageTitle = getWorkingPaths("obsUnitRoiPath");
				imageTitle = getFileListFromDirectory(imageTitle, ".zip");
				Dialog.addMessage("Current image: " + imageTitle[submaskFileIndex] + ", submask " + toString(submaskRoiIndex));
				if (nBackendFoci == 1) {
					Dialog.addMessage(nBackendFoci + " focus counted with these settings:\n");
				} else {
					Dialog.addMessage(nBackendFoci + " foci counted with these settings:\n");
				}
				Dialog.setInsets(0, 20, 0);

				if (lengthOf(args) != 0) { // Run this if this macro was executed by another macro
					if (backendBSub == 0) {
						bsubChoiceDefault = "None";
						bsubRadiusDefault = 50;
					} else if (backendBSub == averageBackground) {
						default = "Average";
						bsubRadiusDefault = 50;
					} else if (backendBSub == medianBackground || backendBSub > 0) {
						bsubChoiceDefault = "Median";
						bsubRadiusDefault = 50;
					} else if (backendBSub < 0) {
						bsubChoiceDefault = "Rolling ball";
						bsubRadiusDefault = backendBSub * -1;
					}
					Dialog.addChoice("Background subtraction mode", newArray("None", "Rolling ball", "Median", "Average"), bsubChoiceDefault);
					Dialog.setInsets(0, 20, 0);
					Dialog.addMessage("Rolling ball radius only used if 'Rolling ball' is selected above");
					Dialog.setInsets(0, 20, 0);
					Dialog.addNumber("Rolling ball radius", bsubRadiusDefault);
					Dialog.setInsets(0, 20, 8);

				} else { // Run this if this macro was executed as a stand-alone

					if (backendBSub == 0) {
						bsubChoiceDefault = "None";
						bsubRadiusDefault = 50;
					} else if (backendBSub > 0) {
						default = "Enter a value";
						bsubRadiusDefault = 50;
					} else if (backendBSub < 0) {
						bsubChoiceDefault = "Rolling ball";
						bsubRadiusDefault = backendBSub * -1;
					}
					Dialog.addChoice("Background subtraction mode", newArray("None", "Enter a value", "Rolling ball"), bsubChoiceDefault);
					Dialog.setInsets(0, 20, 0);
					Dialog.addMessage("Rolling ball radius only used if 'Rolling ball' is selected above");
					Dialog.setInsets(0, 20, 0);
					Dialog.addNumber("Rolling ball radius", bsubRadiusDefault);
					Dialog.setInsets(0, 20, 0);
					Dialog.addMessage("Background value to subtract is used only if 'Enter a value' is selected above");
					Dialog.setInsets(0, 20, 0);
					Dialog.addNumber("Background value to subtract", backendBSub);
					Dialog.setInsets(0, 20, 8);	
				}

				Dialog.addNumber("Maxima tolerance for segmentation", maximaTolerance);
				Dialog.setInsets(0, 20, 0);
				Dialog.addNumber("Lower threshold value", lowerThreshold);
				Dialog.setInsets(0, 20, 0);
				Dialog.addNumber("Minimum focus size", minimumSize);
				Dialog.setInsets(0, 20, 0);
				Dialog.addNumber("Minimum focus average intensity", minimumAvgIntensity);
				Dialog.setInsets(0, 20, 0);
				Dialog.addNumber("Minimum focus intensity", minimumIntensity);
				Dialog.setInsets(0, 20, 0);
				Dialog.addNumber("Minimum focus upper decile", minimumUpperDecile);
				Dialog.setInsets(0, 20, 8);
				Dialog.addChoice("Continuation options", newArray("Exit here", "Exit here and clean up", "Inspect images", "Do not exit"), "Do not exit");
				Dialog.show();

				if (lengthOf(args) != 0) { // Run this if this macro was executed by another macro
					bsubChoice = Dialog.getChoice();
					rollingBall = Dialog.getNumber();
					if (bsubChoice == "None") {
						backendBSub = 0;
					} else if (bsubChoice == "Average") {
						backendBSub = averageBackground;
					} else if (bsubChoice == "Median") {
						backendBSub = medianBackground;
					} else if (bsubChoice == "Rolling ball") {
						backendBSub = rollingBall * -1;
					}
				} else { // Run this if this macro was executed as a stand-alone
					bsubChoice = Dialog.getChoice();
					rollingBall = Dialog.getNumber();
					bsubValue = Dialog.getNumber();
					if (bsubChoice == "None") {
						backendBSub = 0;
					} else if (bsubChoice == "Enter a value") {
						backendBSub = bsubValue;
					} else if (bsubChoice == "Rolling ball") {
						backendBSub = rollingBall * -1;
					}
				}
				maximaTolerance = Dialog.getNumber();
				lowerThreshold = Dialog.getNumber();
				minimumSize = Dialog.getNumber();
				minimumAvgIntensity = Dialog.getNumber();
				minimumIntensity = Dialog.getNumber();
				minimumUpperDecile = Dialog.getNumber();
				continuation = Dialog.getChoice();

				exitCommand = File.open(getDirectory("temp") + "FCC exit command.txt");
				print(exitCommand, continuation);
				File.close(exitCommand);
				if (continuation == "Exit here") {
					exit();
				} else if (continuation == "Exit here and clean up") {
					cleanup();
					exit();
				} else if (continuation == "Inspect images") {
					roiManager("Open", fociROIs);
					waitForUser("Inspect images");
					roiManager("Reset");
					redisplay = true;
					continue;
				}

			} while (redisplay == true);

			newSettings = newArray(backendBSub, maximaTolerance, lowerThreshold, minimumSize, minimumAvgIntensity, minimumIntensity, minimumUpperDecile);
			settingsMatches = 0;
			for (i=0; i<oldSettings.length; i++) {
				if (oldSettings[i] == newSettings[i]) {
					settingsMatches++;
				}
			}
			if (settingsMatches == oldSettings.length) {
				finished = true;
			}

		} else { // Run this if the macro was executed in 'Batch' mode (no dialogs)

			finished = true;

		}

	} while (finished == false);
	cleanup();

	/*
	----------------------------------------------------------------------------
		SAVE SETTINGS AND DATA OUTPUT, CLEAN UP
	----------------------------------------------------------------------------
	*/

	if (lengthOf(args) != 0) {
		savedSettings = newArray(backendBSub, maximaTolerance, lowerThreshold, minimumSize, minimumAvgIntensity, minimumIntensity, minimumUpperDecile);
		for (i=0; i<savedSettings.length; i++) {
			runMacro(getDirectory("plugins") +
				"BB_macros" + File.separator() +
				"Cytology_modules" + File.separator() +
				"Cytology_configurator.ijm", "change|4|" + toString((1 + i) + 8 * (channel - 1)) + "|" + toString(savedSettings[i]));
		}

		output = File.open(getDirectory("temp") + "FCC output.txt");
		print(output,
			"Focus Area\t" +
			"Focus Avg Int\t" +
			"Focus Int\t" +
			"Focus Upper Dec\t" +
			"Focus Area Raw\t" +
			"Focus Avg Int Raw\t" +
			"Focus Int Raw\t" +
			"Focus Upper Dec Raw"
			);
		if (nBackendFoci > 0) {
			focusMeasurements = File.openAsString(getDirectory("temp") + "FCC foci temp.txt");
			focusMeasurements = split(focusMeasurements, "\n");
			for (i=0; i<focusMeasurements.length; i++) {
				pass = getFieldFromTdf(focusMeasurements[i], 2, true);
				if (pass == 1) {
					string = getFieldFromTdf(focusMeasurements[i], 3, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 4, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 5, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 6, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 11, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 12, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 13, false);
					string = string + "\t" + getFieldFromTdf(focusMeasurements[i], 14, false);
					print(output, string);
				}
			}
		}
		File.close(output);
	}

	if (File.exists(getDirectory("temp") + "Original image.tif")) { deleted = File.delete(getDirectory("temp") + "Original image.tif"); }
	if (File.exists(getDirectory("temp") + "Original image overlay.tif")) { deleted = File.delete(getDirectory("temp") + "Original image overlay.tif"); }
	if (File.exists(getDirectory("temp") + "Segmentation map.tif")) { deleted = File.delete(getDirectory("temp") + "Segmentation map.tif"); }
	if (File.exists(getDirectory("temp") + "Background subtracted.tif")) { deleted = File.delete(getDirectory("temp") + "Background subtracted.tif"); }
	if (File.exists(getDirectory("temp") + "Thresholded.tif")) { deleted = File.delete(getDirectory("temp") + "Thresholded.tif"); }
	if (File.exists(getDirectory("temp") + "Foci mask.tif")) { deleted = File.delete(getDirectory("temp") + "Foci mask.tif"); }
	if (File.exists(getDirectory("temp") + "FCC foci temp.txt")) { deleted = File.delete(getDirectory("temp") + "FCC foci temp.txt"); }
	if (File.exists(getDirectory("temp") + "FCC results temp.txt")) { deleted = File.delete(getDirectory("temp") + "FCC results temp.txt"); }

}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

function cleanup() {
	roiManager("Reset");
	if (isOpen("Log")) { selectWindow("Log"); run("Close"); }
	if (isOpen("Results")) { selectWindow("Results"); run("Close"); }
	if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }
	if (isOpen("FCC results temp.txt")) { selectWindow("FCC results temp.txt"); run("Close"); }
	run("Close All");
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