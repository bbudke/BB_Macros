var workingPath = getWorkingPaths("workingPath");
var obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

var imageType = retrieveConfiguration(0, 0);
var nChannels = retrieveConfiguration(0, 1);
var zSeriesOption = retrieveConfiguration(0, 3);
var activeChannel = parseInt(retrieveConfiguration(4, 0 + 8 * nChannels));

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Focus Counter" {
	arg = getArgument();
	run("Close All");
	resultsPath = toString(getWorkingPaths("analysisPath")) + "Channel " + activeChannel + " Results" + File.separator();
	imageList = getFileListFromDirectory(workingPath, imageType);
	imageListNoExt = newArray();
	for (i=0; i<imageList.length; i++) {
		append = substring(imageList[i], 0, indexOf(imageList[i], imageType));
		imageListNoExt = Array.concat(imageListNoExt, append);
	}
	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	zipListNoExt = newArray();
	for (i=0; i<zipList.length; i++) {
		append = substring(zipList[i], 0, indexOf(zipList[i], ".zip"));
		zipListNoExt = Array.concat(zipListNoExt, append);
	}

	/*
	----------------------------------------------------------------------------
		SELECT CALIBRATION IMAGES
	----------------------------------------------------------------------------
	*/

	if (arg == "Select calibration images") {
		
		calibrationImages = "";
		do {
			Dialog.create("Choose an image");
			Dialog.addChoice("Image: ", zipListNoExt, zipListNoExt[0]);
			Dialog.show();
			image = Dialog.getChoice();
			setBatchMode(true);

			runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + image + imageType + "|" + imageType + "|" + zSeriesOption);
			open(getDirectory("temp") + "Converted To Tiff.tif");
			deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
			getDimensions(width, height, channels, slices, frames);
			Stack.setPosition(activeChannel, 1, 1);
			run("Select All");
			run("Copy");
			newImage("showOverlayTemp", "16-bit black", width, height, 1, 1, 1);
			run("Paste");
			run("Fire");
			setMinAndMax(parseInt(retrieveConfiguration(2, 3 + 5 * (activeChannel - 1))), parseInt(retrieveConfiguration(2, 4 + 5 * (activeChannel - 1))));
			saveAs("Tiff", getDirectory("temp") + "showOverlayTemp.tif");
			run("Close All");

		/*
		------------------------------------------------------------------------
			CREATE AN IMAGE WITH AN OVERLAY
		------------------------------------------------------------------------
		*/

			open(getDirectory("temp") + "showOverlayTemp.tif");
			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + image + ".zip");
			do {
				deleted = false;
				for (i=0; i<roiManager("Count"); i++) {
					roiManager("Select", i)
					name = Roi.getName();
					if (indexOf(name, "OBS UNIT ") == -1 && indexOf(name, "Submask ") == -1) {
						roiManager("Delete");
						deleted = true;
					}
				}
			} while (deleted == true);

			roiObsIndices = newArray();
			roiObsChoices = newArray();
			submaskIndices = newArray();
			obsUnits = newArray();
			submasks = newArray();
			for (i=0; i<roiManager("Count"); i++) {
				roiManager("Select", i);
				name = Roi.getName();
				if (indexOf(name, "OBS UNIT ") != -1) {
					obsUnits = Array.concat(obsUnits, substring(name, lengthOf("OBS UNIT "), lengthOf(name)));
					roiObsIndices = Array.concat(roiObsIndices, i);
					roiObsChoices = Array.concat(roiObsChoices, name);
				} else if (indexOf(name, "Submask ") != -1) {
					submasks = Array.concat(submasks, substring(name, lengthOf("Submask "), lengthOf(name)));
					submaskIndices = Array.concat(submaskIndices, i);
				}
			}

			if (submasks.length > 1) {
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
			}

			run("Overlay Options...", "stroke=green width=0 fill=none");
			run("Labels...", "color=green font=18");
			for (i=0; i<submaskIndices.length; i++) {
				roiManager("Select", submaskIndices[i]);
				run("Add Selection...");
			}
			run("RGB Color");
			run("Flatten");
			saveAs("tiff", getDirectory("temp") + "showOverlayTemp.tif");
			run("Close All");

			open(getDirectory("temp") + "showOverlayTemp.tif");
			run("Labels...", "color=green font=18 show use");
			for (i=0; i<roiObsIndices.length; i++) {
				roiManager("Select", roiObsIndices[i]);
				run("Add Selection...");
			}
			run("RGB Color");
			run("Flatten");
			roiManager("Reset");
			saveAs("Tiff", getDirectory("temp") + "showOverlayTemp.tif");
			run("Close All");

			setBatchMode(false);
			open(getDirectory("temp") + "showOverlayTemp.tif");
			run("Select None");

			do {
				Dialog.create("Choose an observational unit");
				Dialog.addChoice("Obs unit: ", roiObsChoices, roiObsChoices[0]);
				Dialog.addChoice("Action:", newArray("Add this Obs unit", "Go to another image", "Finish and close"), "Add this Obs unit");
				Dialog.show();
				obsUnit = Dialog.getChoice();
				action = Dialog.getChoice();
				if (action == "Add this Obs unit") {
					imageIndex = -1;
					for (i=0; i<imageListNoExt.length; i++) {
						if (image == imageListNoExt[i]) {
							imageIndex = i;
							i = imageListNoExt.length;
						}
					}
					roiObsIndex = -1;
					for (i=0; i<roiObsChoices.length; i++) {
						if (obsUnit == roiObsChoices[i]) {
							roiObsIndex = i;
							i = roiObsChoices.length;
						}
					}
					calibrationImages = calibrationImages + toString(imageIndex) + "," + toString(roiObsIndex);
					calibrationImages = calibrationImages + ";";
					showStatus("Obs unit index " + toString(roiObsIndex) + " from image index " + toString(imageIndex) + " added");
				}
			} while (action == "Add this Obs unit");
			run("Close All");
			deleted = File.delete(getDirectory("temp") + "showOverlayTemp.tif");

		} while (action != "Finish and close");

		if (lengthOf(calibrationImages) == 0) {
			calibrationImages = "null";
		} else {
			calibrationImages = substring(calibrationImages, 0, lengthOf(calibrationImages) - 1);
		}
		showStatus(calibrationImages);
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Clonogenics Configurator.ijm", "change|4|" + toString(0 + 8 * (activeChannel - 1)) + "|" + toString(calibrationImages));

	/*
	----------------------------------------------------------------------------
		CALIBRATE FOCUS COUNTER
	----------------------------------------------------------------------------
	*/

	} else if (arg == "Calibrate focus counter") {

		calibrationImages = retrieveConfiguration(4, 0 + 8 * (activeChannel - 1));
		calibrationImages = split(calibrationImages, ";");
		imagesCounted = 0;
		for (i=0; i<calibrationImages.length; i++) {
			calibrationImage = split(calibrationImages[i], ",");
			imageIndex = calibrationImage[0];
			obsUnitIndex = calibrationImage[1];
			image = imageList[imageIndex];
			imageNoExt = substring(image, 0, indexOf(image, imageType));
			submaskFileIndex = -1;
			for (j=0; j<zipListNoExt.length; j++) {
				if (imageNoExt == zipListNoExt[j]) {
					submaskFileIndex = j;
					j = zipListNoExt.length;
				}
			}
			setBatchMode(true);

			runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + imageList[imageIndex] + "|" + imageType + "|" + zSeriesOption);
			open(getDirectory("temp") + "Converted To Tiff.tif");
			deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
			getDimensions(width, height, channels, slices, frames);
			Stack.setPosition(activeChannel, 1, 1);
			run("Select All");
			run("Copy");
			newImage("BSub mask", "16-bit black", width, height, 1, 1, 1);
			run("Paste");
			saveAs("Tiff", getDirectory("temp") + "BSub mask.tif");
			run("Close All");

			open(getDirectory("temp") + "BSub mask.tif");
			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + imageListNoExt[imageIndex] + ".zip");
			globalMaskRoiIndex = -1;
			for (j=0; j<roiManager("Count"); j++) {
				roiManager("Select", j);
				name = Roi.getName();
				if (name == "Global Background mask") {
					globalMaskRoiIndex = j;
					j = roiManager("Count");
				}
			}
			run("Set Measurements...", "  mean median redirect=None decimal=3");
			selectWindow("BSub mask.tif");
			if (globalMaskRoiIndex != -1) {
				roiManager("Select", globalMaskRoiIndex);
				run("Measure");
				averageBackground = parseInt(getResult("Mean"));
				medianBackground = parseInt(getResult("Median"));
			} else {
				averageBackground = 0;
				medianBackground = 0;
			}
			roiManager("Reset");
			run("Close All");

			extractImage(imageIndex, obsUnitIndex);
			open(getDirectory("temp") + "extractedImage.tif");
			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + imageListNoExt[imageIndex] + ".zip");
			submaskRoiIndex = -1;
			for (j=0; j<roiManager("Count"); j++) {
				roiManager("Select", j);
				name = Roi.getName();
				if (indexOf(name, "Submask ") != -1) {
					name = substring(name, lengthOf("Submask "), lengthOf(name));
					name = parseInt(name);
					if (obsUnitIndex == name - 1) {
						submaskRoiIndex = j;
						j = roiManager("Count");
					}
				}
			}
			percentComplete = imagesCounted / calibrationImages.length;

			runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Focus Counter Core.ijm", "Single|" + activeChannel + "|" + medianBackground + "|" + averageBackground + "|" + submaskFileIndex + "|" + submaskRoiIndex + "|" + percentComplete);

			exitCommand = File.openAsString(getDirectory("temp") + "FCC exit command.txt");
			imagesCounted++;
			deleted = File.delete(getDirectory("temp") + "FCC exit command.txt");
			deleted = File.delete(getDirectory("temp") + "extractedImage.tif");
			deleted = File.delete(getDirectory("temp") + "FCC output.txt");
			if (indexOf(exitCommand, "Exit here") != -1) {
				deleted = File.delete(getDirectory("temp") + "BSub mask.tif");
				exit();
			}
		}
		deleted = File.delete(getDirectory("temp") + "BSub mask.tif");

	/*
	----------------------------------------------------------------------------
		COUNT FOCI
	----------------------------------------------------------------------------
	*/

	} else if (arg == "Count foci and organize data" || arg == "Organize data only") {

		if (arg == "Count foci and organize data") {
			if (File.exists(resultsPath) != true) {
				File.makeDirectory(resultsPath);
			}
			if (File.exists(resultsPath + "Raw Data" + File.separator()) != true) {
				File.makeDirectory(resultsPath + "Raw Data");
			}
			rawDataFileList = getFileListFromDirectory(resultsPath + "Raw Data" + File.separator(), ".txt");
			for (i=0; i<rawDataFileList.length; i++) {
				deleted = File.delete(resultsPath + "Raw Data" + File.separator() + rawDataFileList[i]);
			}

			setBatchMode(true);
			totalImages = 0;
			imagesCounted = 0;
			newImage("temp image", "16-bit black", 367, 367, 1);
			for (i=0; i<zipList.length; i++) {
				roiManager("Reset");
				roiManager("Open", obsUnitRoiPath + zipList[i]);
				count = roiManager("Count");
				for (j=0; j<count; j++) {
					roiManager("Select", j);
					name = Roi.getName();
					if (indexOf(name, "OBS UNIT") != -1) { totalImages++; }
				}
			}

			nuclearMeasurements = File.open(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt");
			print(nuclearMeasurements,
				"Obs Unit\t" + 
				"AreaBg\t" + 
				"IntDenBg\t" + 
				"AvgBg\t" + 
				"MedBg\t" + 
				"AreaROI\t" + 
				"IntDenROI\t" + 
				"AvgROI\t" + 
				"MedROI\t"
				);
			File.close(nuclearMeasurements);

			for (i=0; i<zipList.length; i++) {

				runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + zipListNoExt[i] + imageType + "|" + imageType + "|" + zSeriesOption);
				open(getDirectory("temp") + "Converted To Tiff.tif");
				deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
				getDimensions(width, height, channels, slices, frames);
				Stack.setPosition(activeChannel, 1, 1);
				run("Select All");
				run("Copy");
				newImage("BSub mask", "16-bit black", width, height, 1, 1, 1);
				run("Paste");
				saveAs("Tiff", getDirectory("temp") + "BSub mask.tif");
				run("Close All");

				open(getDirectory("temp") + "BSub mask.tif");
				roiManager("Reset");
				roiManager("Open", obsUnitRoiPath + zipList[i]);
				imageIndex = -1;
				for (j=0; j<imageListNoExt.length; j++) {
					if (zipListNoExt[i] == imageListNoExt[j]) {
						imageIndex = j;
					}
				}
				submaskFileIndex = i;
				globalMaskRoiIndex = -1;
				obsUnitIndices = newArray();
				for (j=0; j<roiManager("Count"); j++) {
					roiManager("Select", j);
					name = Roi.getName();
					print(zipList[i] + "   " + name);
					if (name == "Global Background mask") {
						globalMaskRoiIndex = j;
					} else if (indexOf(name, "OBS UNIT") != -1) {
						obsUnitIndices = Array.concat(obsUnitIndices, j);
					}
				}
				run("Set Measurements...", "  mean median redirect=None decimal=3");
				selectWindow("BSub mask.tif");
				roiManager("Select", globalMaskRoiIndex);
				run("Measure");
				averageBackground = parseInt(getResult("Mean"));
				medianBackground = parseInt(getResult("Median"));
				run("Close All");

				for (j=0; j<obsUnitIndices.length; j++) {
					extractImage(imageIndex, obsUnitIndices[j]);
					open(getDirectory("temp") + "extractedImage.tif");
					roiManager("Reset");
					roiManager("Open", obsUnitRoiPath + zipList[i]);
					submaskRoiName = "Submask " + IJ.pad(j + 1, 2);
					
					submaskRoiIndex = -1;
					for (k=0; k<roiManager("Count"); k++) {
						roiManager("Select", k);
						name = Roi.getName();
						if (indexOf(name, submaskRoiName) != -1) {
							submaskRoiIndex = k;
							k = roiManager("Count");
						}
					}

					run("Set Measurements...", "area integrated redirect=None decimal=3");
					selectWindow("extractedImage.tif");
					roiManager("Select", submaskRoiIndex);
					run("Measure");
					area = getResult("Area");
					intDen = getResult("RawIntDen");
					intDenBSubM = intDen - (area * medianBackground);
					intDenBSubA = intDen - (area * averageBackground);
					run("Select None");
					backendBSub = parseInt(retrieveConfiguration(4, 1 + 8 * (activeChannel - 1)));
					backendBSub = abs(backendBSub);
					run("Subtract Background...", "rolling=" + backendBSub);
					roiManager("Select", submaskRoiIndex);
					run("Measure");
					intDenBSubR = getResult("RawIntDen");

					intDenBSub = intDenBSubR;

					close();
					open(getDirectory("temp") + "extractedImage.tif");
					string = toString(zipListNoExt[i]) + "-" + IJ.pad(j + 1, 2) + "\t" + area + "\t" + intDenBSub;
					nuclearMeasurementsExisting = File.openAsString(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt");
					nuclearMeasurements = File.open(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt");
					print(nuclearMeasurements, nuclearMeasurementsExisting);
					print(nuclearMeasurements, string);
					File.close(nuclearMeasurements);

					percentComplete = imagesCounted / totalImages;

					runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Focus Counter Core.ijm", "Batch|" + activeChannel + "|" + medianBackground + "|" + averageBackground + "|" + submaskFileIndex + "|" + submaskRoiIndex + "|" + percentComplete);
					
					fccOutputTemp = File.openAsString(getDirectory("temp") + "FCC output.txt");
					fccOutput = File.open(resultsPath + "Raw Data" + File.separator() + zipListNoExt[i] + "-" + IJ.pad(j + 1, 2) + " foci.txt");
					print(fccOutput, fccOutputTemp);
					File.close(fccOutput);

					deleted = File.delete(getDirectory("temp") + "FCC output.txt");
					deleted = File.delete(getDirectory("temp") + "FCC exit command.txt");
					deleted = File.delete(getDirectory("temp") + "extractedImage.tif");
					imagesCounted++;
				}
				deleted = File.delete(getDirectory("temp") + "BSub mask.tif");
			}
		} else if (arg == "Organize data only") {
			if (File.exists(resultsPath + "Raw Data" + File.separator()) != true) {
				exit("Raw data not found. Please run 'Count foci and organize data'.");
			} else {
				fociDataFileList = getFileListFromDirectory(resultsPath + "Raw Data" + File.separator(), " foci.txt");
				if (File.exists(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt") != true || fociDataFileList.length == 0) {
					exit("Raw data files missing. Please run 'Count foci and organize data'.");
				}
			}
		}

	/*
	----------------------------------------------------------------------------
		ORGANIZE TOTAL NUCLEAR MEASUREMENT DATA
	----------------------------------------------------------------------------
	*/

		// Start with simple concatenation of all raw focus data combined with respective OBS Unit-wide measurements
		fociDataFileList = getFileListFromDirectory(resultsPath + "Raw Data" + File.separator(), " foci.txt");
		if (fociDataFileList.length > 0 && File.exists(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt")) {

			/*
			----------------------------------------------------------------------------
				START BY CONCATENATING ALL THE RAW DATA INTO ONE FILE
			----------------------------------------------------------------------------
			*/

			fociDataFileList = Array.sort(fociDataFileList);

			allDataFile = File.open(resultsPath + "Ch " + activeChannel + " All Data.txt");
			nuclearMeasurements = File.openAsString(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt");
			nuclearMeasurements = split(nuclearMeasurements, "\n");
			nuclearMeasurements = Array.slice(nuclearMeasurements, 1, nuclearMeasurements.length);

			// the first block of headers below is identical to those in the Nuclear Measurements above (line 305-ish). If one of these is changed, then the other must be changed too!
			// the second block of headers below is identical to those in Focus Counter Core.ijm. If one of these is changed, then the other must be changed too! Also, the number of 'null's below must be changed if the length of the headers changes! Also, the field in line 551-ish must be changed!
			print(allDataFile,
				"Obs Unit\t" +
				"AreaBg\t" +
				"IntDenBg\t" +
				"Focus Area\t" +
				"Focus Avg Int\t" +
				"Focus Int\t" +
				"Focus Upper Dec\t" +
				"Unused\t" +
				"Unused\t" +

				"Unused\t" +
				"Unused\t" +
				"Unused\t" +
				"Unused\t" +
				"Unused\t" +
				"Unused\t" +
				"Unused\t" +
				"Unused"
				);
			for (i=0; i<fociDataFileList.length; i++) {
				nextLineBlock01 = nuclearMeasurements[i];
				dataFile = File.openAsString(resultsPath + "Raw Data" + File.separator() + fociDataFileList[i]);
				dataFile = split(dataFile, "\n");
				dataFile = Array.slice(dataFile, 1, dataFile.length);
				if (dataFile.length > 0) {
					for (j=0; j<dataFile.length; j++) {
						nextLineBlock02 = dataFile[j];
						nextLine = nextLineBlock01 + "\t" + nextLineBlock02;
						print(allDataFile, nextLine);
					}
				} else {
					nextLineBlock02 = 	"null\t" +
										"null\t" +
										"null\t" +
										"null\t" +
										"null\t" +
										"null\t" +
										"null\t" +
										"null";
					nextLine = nextLineBlock01 + "\t" + nextLineBlock02;
					print(allDataFile, nextLine);
				}
				showStatus("(1 of 2) Concatenate all data in this channel");
				showProgress((i + 1) / fociDataFileList.length);
			}
			File.close(allDataFile);

			/*
			----------------------------------------------------------------------------
				NOW RUN THROUGH THE CAT'd FILE AND ASSIGN FOCUS COUNTS TO EACH OBS UNIT
			----------------------------------------------------------------------------
			*/

			imageIndex = File.openAsString(getWorkingPaths("imageIndexFile"));
			imageIndex = split(imageIndex, "\n");
			imageIndex = Array.slice(imageIndex, 1, imageIndex.length);
			imageIndex = Array.sort(imageIndex);

			groupLabels = File.openAsString(getWorkingPaths("groupLabelsFile"));
			groupLabels = split(groupLabels, "\n");
			groupLabels = Array.slice(groupLabels, 1, groupLabels.length);
			groupLabels = Array.sort(groupLabels);
			if (groupLabels.length == 0) {
				exit("Group labels.txt and Image index.txt must\nbe populated before the data can be\norganized. Please open these files\nin Excel and assign each image to a\nlabeled group before organizing data.");
			}

			countsFile = File.open(resultsPath + "Ch " + activeChannel + " Focus counts.txt");
			allDataFile = File.openAsString(resultsPath + "Ch " + activeChannel + " All Data.txt");
			allDataFile = split(allDataFile, "\n");
			allDataFile = Array.slice(allDataFile, 1, allDataFile.length);
			allDataFile = Array.sort(allDataFile);
			print(countsFile, "OBS Unit\tFoci");

			counter = 0;
			for (i=0; i<allDataFile.length; i++) {
				obsUnitInDataFile = getFieldFromTdf(allDataFile[i], 1, false);
				image = replace(obsUnitInDataFile, "-[0-9]{2}$", "");
				if (i < allDataFile.length - 1) {
					nextObsUnitInDataFile = getFieldFromTdf(allDataFile[i + 1], 1, false);
				} else {
					nextObsUnitInDataFile = "end of file";
				}
				if (obsUnitInDataFile == nextObsUnitInDataFile) {
					// keep going until we reach the end of a block of data for the same Obs Unit
					counter++; // this does not count the last focus in an OBS UNIT block!
				} else {
					if (counter == 0) {
						// The line below must be changed if the headers were changed! (see lines 496-ish and 305-ish).
						focusArea = getFieldFromTdf(allDataFile[i], 10, true);
						if (isNaN(focusArea) != true) {
							counter++;
						}
					} else {
						for (j=0; j<imageIndex.length; j++) {
							if (image == getFieldFromTdf(imageIndex[j], 1, false)) {
								groupNumber = getFieldFromTdf(imageIndex[j], 2, true);
								for (k=0; k<groupLabels.length; k++) {
									group = getFieldFromTdf(groupLabels[k], 1, true);
									if (group == groupNumber) {
										groupName = getFieldFromTdf(groupLabels[k], 2, false);
										k = groupLabels.length;
									}
								}
								j = imageIndex.length;
							}
						}
						counter++;
					}
					print(countsFile, obsUnitInDataFile + "\t" + counter);
					counter = 0;
				}
				showStatus("(2 of 2) Assign focus counts to all Obs Units");
				showProgress((i + 1) / allDataFile.length);
			}
			File.close(countsFile);

			/*
			----------------------------------------------------------------------------
				NOW ASSEMBLE THE ABOVE DATA INTO KALEIDAGRAPH-FRIENDLY INPUT
			----------------------------------------------------------------------------
			*/



		} else {
			exit("Data organization requires a 'Nuclear measurements.txt' file and at least one '*foci.txt' file.");
		}

		// Exit here for now just to make sure that the above code works

		exit("Done.");

		/*
		----------------------------------------------------------------------------





			ALL THIS SHIT BELOW WILL PROBABLY END UP GETTING REPLACED WITH MORE EFFICIENT CODE





		----------------------------------------------------------------------------
		*/

		imageIndex = File.openAsString(getWorkingPaths("imageIndexFile"));
		imageIndex = split(imageIndex, "\n");
		imageIndex = Array.slice(imageIndex, 1, imageIndex.length);

		groupLabels = File.openAsString(getWorkingPaths("groupLabelsFile"));
		groupLabels = split(groupLabels, "\n");
		groupLabels = Array.slice(groupLabels, 1, groupLabels.length);

		nuclearMeasurements = File.openAsString(resultsPath + "Raw Data" + File.separator() + "Nuclear measurements.txt");
		nuclearMeasurements = split(nuclearMeasurements, "\n");
		nuclearMeasurements = Array.slice(nuclearMeasurements, 1, nuclearMeasurements.length);

		nuclearGroup = newArray();
		nuclearIntensity = newArray();

		for (i=0; i<nuclearMeasurements.length; i++) {
			image = getFieldFromTdf(nuclearMeasurements[i], 1, false);
			image = replace(image, "-[0-9]{2}$", "");
			for (j=0; j<imageIndex.length; j++) {
				if (image == getFieldFromTdf(imageIndex[j], 1, false)) {
					group = getFieldFromTdf(imageIndex[j], 2, true);
					j = imageIndex.length;
				}
			}
			intensity = getFieldFromTdf(nuclearMeasurements[i], 3, true);

			nuclearGroup = Array.concat(nuclearGroup, group);
			nuclearIntensity = Array.concat(nuclearIntensity, intensity);
		}

		groupLengths = newArray;
		for (i=0; i<groupLabels.length; i++) {
			counter = 0;
			groupNumber = getFieldFromTdf(groupLabels[i], 1, true);
			for (j=0; j<nuclearGroup.length; j++) {
				if (groupNumber == nuclearGroup[j]) {
					counter++;
				}
			}
			groupLengths = Array.concat(groupLengths, counter);
		}

		shortestObsUnitGroup = 0;
		longestObsUnitGroup = 0;
		for (i=0; i<groupLengths.length; i++) {
			if (groupLengths[i] > 0) {
				if (groupLengths[i] > longestObsUnitGroup) {
					longestObsUnitGroup = groupLengths[i];
				} else if (shortestObsUnitGroup > 0) {
					if (groupLengths[i] < shortestObsUnitGroup) {
						shortestObsUnitGroup = groupLengths[i];
					}
				} else if (shortestObsUnitGroup == 0) {
					shortestObsUnitGroup = groupLengths[i];
				}
			}
		}

		string = "";
		for (i=0; i<groupLabels.length; i++) {
			string = string + getFieldFromTdf(groupLabels[i], 2, false) + "\t";
		}

		nuclearIntFile = File.open(resultsPath + "Total Nuclear Intensity.txt");
		print(nuclearIntFile, string);
		File.close(nuclearIntFile);

		position = 0;
		do {
			intString = "";
			noDataCounts = 0;
			for (i=0; i<groupLabels.length; i++) {
				group = getFieldFromTdf(groupLabels[i], 1, true);
				startPosition = -1;
				for (j=0; j<nuclearGroup.length; j++) {
					testGroup = parseInt(nuclearGroup[j]);
					if (testGroup == group) {
						startPosition = j;
						j = nuclearGroup.length;
					}
				}
				if (startPosition == -1 || startPosition + position > nuclearGroup.length - 1) {
					intString = intString + "\t";
					noDataCounts++;
				} else {
					if (parseInt(nuclearGroup[startPosition + position]) != group) {
						intString = intString + "\t";
						noDataCounts++;
					} else {
						intString = intString + nuclearIntensity[startPosition + position] + "\t";
					}
				}
			}

			nuclearIntFileExisting = File.openAsString(resultsPath + "Total Nuclear Intensity.txt");
			nuclearIntFile = File.open(resultsPath + "Total Nuclear Intensity.txt");
			print(nuclearIntFile, nuclearIntFileExisting);
			print(nuclearIntFile, intString);
			File.close(nuclearIntFile);

			position++;
			showStatus("Creating data files...");
			showProgress(position / longestObsUnitGroup);
		} while (noDataCounts < groupLabels.length && position < shortestObsUnitGroup);

	/*
	----------------------------------------------------------------------------
		ORGANIZE FOCUS MEASUREMENT DATA
	----------------------------------------------------------------------------
	*/

		fociDataFileList = getFileListFromDirectory(resultsPath + "Raw Data" + File.separator(), " foci.txt");

		groupDataCounts = newArray(); // array of group numbers corresponding to the array below
		obsUnitDataCounts = newArray(); // array of obs unit numbers corresponding to the array below
		dataCounts = newArray();

		groupData = newArray(); // array of group numbers corresponding to the four data arrays below
		obsUnitData = newArray(); // array of obs unit numbers corresponding to the four data arrays below
		areaData = newArray();
		avgIntData = newArray();
		intData = newArray();
		upperDecData = newArray();

		group = 0;
		obsUnitCounter = 1;
		for (i=0; i<fociDataFileList.length; i++) {
			prevGroup = group;
			image = replace(fociDataFileList[i], "-[0-9]{2} foci.txt", "");
			for (j=0; j<imageIndex.length; j++) {
				if (image == getFieldFromTdf(imageIndex[j], 1, false)) {
					group = getFieldFromTdf(imageIndex[j], 2, true);
					j = imageIndex.length;
				}
			}
			if (group > prevGroup) {
				obsUnitCounter = 1;
			} else {
				obsUnitCounter++;
			}
			groupDataCounts = Array.concat(groupDataCounts, group);
			dataFile = File.openAsString(resultsPath + "Raw Data" + File.separator() + fociDataFileList[i]);
			dataFile = split(dataFile, "\n");
			dataFile = Array.slice(dataFile, 1, dataFile.length);
			focusCounter = 0;
			for (j=0; j<dataFile.length; j++) {
				areaDatum = getFieldFromTdf(dataFile[j], 1, false);
				avgIntDatum = getFieldFromTdf(dataFile[j], 2, false);
				intDatum = getFieldFromTdf(dataFile[j], 3, false);
				upperDecDatum = getFieldFromTdf(dataFile[j], 4, false);
				if (lengthOf(areaDatum) > 0) {
					focusCounter++;
					groupData = Array.concat(groupData, group);
					obsUnitData = Array.concat(obsUnitData, obsUnitCounter);
					areaData = Array.concat(areaData, areaDatum);
					avgIntData = Array.concat(avgIntData, avgIntDatum);
					intData = Array.concat(intData, intDatum);
					upperDecData = Array.concat(upperDecData, upperDecDatum);
				}
			}
			dataCounts = Array.concat(dataCounts, focusCounter);
			obsUnitDataCounts = Array.concat(obsUnitDataCounts, obsUnitCounter);
		}

		longestFociGroup = 0;
		for (i=0; i<groupLabels.length; i++) {
			counter = 0;
			group = getFieldFromTdf(groupLabels[i], 1, true);
			for (j=0; j<groupData.length; j++) {
				if (group == groupData[j]) {
					counter++;
				}
			}
			if (counter > longestFociGroup) {
				longestFociGroup = counter;
			}
		}

		string = "";
		for (i=0; i<groupLabels.length; i++) {
			string = string + getFieldFromTdf(groupLabels[i], 2, false) + "\t";
		}
		countsFile = File.open(resultsPath + "Counts.txt");
		print(countsFile, string);
		File.close(countsFile);
		areaDataFile = File.open(resultsPath + "Area.txt");
		print(areaDataFile, string);
		File.close(areaDataFile);
		avgIntDataFile = File.open(resultsPath + "Avg Int.txt");
		print(avgIntDataFile, string);
		File.close(avgIntDataFile);
		intDataFile = File.open(resultsPath + "Int.txt");
		print(intDataFile, string);
		File.close(intDataFile);
		upperDecDataFile = File.open(resultsPath + "Upper Dec.txt");
		print(upperDecDataFile, string);
		File.close(upperDecDataFile);

		position = 0;
		do {
			countString = "";
			areaString = "";
			avgIntString = "";
			intString = "";
			upperDecString = "";
			noDataCounts = 0;
			noCountCounts = 0;
			for (i=0; i<groupLabels.length; i++) {
				group = getFieldFromTdf(groupLabels[i], 1, true);

				countStartPosition = -1;
				for (j=0; j<groupDataCounts.length; j++) {
					testGroup = parseInt(groupDataCounts[j]);
					if (testGroup == group) {
						countStartPosition = j;
						j = groupDataCounts.length;
					}
				}
				if (countStartPosition == -1 || countStartPosition + position > groupDataCounts.length - 1) {
					countString = countString + "\t";
					noCountCounts++;
				} else {
					if (parseInt(groupDataCounts[countStartPosition + position]) != group || parseInt(obsUnitDataCounts[countStartPosition + position]) > shortestObsUnitGroup) {
						countString = countString + "\t";
						noCountCounts++;						
					} else {
						countString = countString + dataCounts[countStartPosition + position] + "\t";
					}
				}

				startPosition = -1;
				for (j=0; j<groupData.length; j++) {
					testGroup = parseInt(groupData[j]);
					if (testGroup == group) {
						startPosition = j;
						j = groupData.length;
					}
				}
				if (startPosition == -1 || startPosition + position > groupData.length - 1) {
					areaString = areaString + "\t";
					avgIntString = avgIntString + "\t";
					intString = intString + "\t";
					upperDecString = upperDecString + "\t";
					noDataCounts++;
				} else {
					if (parseInt(groupData[startPosition + position]) != group || parseInt(obsUnitData[startPosition + position]) > shortestObsUnitGroup) {
						areaString = areaString + "\t";
						avgIntString = avgIntString + "\t";
						intString = intString + "\t";
						upperDecString = upperDecString + "\t";
						noDataCounts++;
					} else {
						areaString = areaString + areaData[startPosition + position] + "\t";
						avgIntString = avgIntString + avgIntData[startPosition + position] + "\t";
						intString = intString + intData[startPosition + position] + "\t";
						upperDecString = upperDecString + upperDecData[startPosition + position] + "\t";
					}	
				}
			}

			countsFileExisting = File.openAsString(resultsPath + "Counts.txt");
			countsFile = File.open(resultsPath + "Counts.txt");
			print(countsFile, countsFileExisting);
			print(countsFile, countString);
			File.close(countsFile);
			areaDataFileExisting = File.openAsString(resultsPath + "Area.txt");
			areaDataFile = File.open(resultsPath + "Area.txt");
			print(areaDataFile, areaDataFileExisting);
			print(areaDataFile, areaString);
			File.close(areaDataFile);
			avgIntDataFileExisting = File.openAsString(resultsPath + "Avg Int.txt");
			avgIntDataFile = File.open(resultsPath + "Avg Int.txt");
			print(avgIntDataFile, avgIntDataFileExisting);
			print(avgIntDataFile, avgIntString);
			File.close(avgIntDataFile);
			intDataFileExisting = File.openAsString(resultsPath + "Int.txt");
			intDataFile = File.open(resultsPath + "Int.txt");
			print(intDataFile, intDataFileExisting);
			print(intDataFile, intString);
			File.close(intDataFile);
			upperDecDataFileExisting = File.openAsString(resultsPath + "Upper Dec.txt");
			upperDecDataFile = File.open(resultsPath + "Upper Dec.txt");
			print(upperDecDataFile, upperDecDataFileExisting);
			print(upperDecDataFile, upperDecString);
			File.close(upperDecDataFile);

			showStatus("Creating data files...");
			showProgress(position / longestFociGroup);
			position++;

		} while (noDataCounts < groupLabels.length || noCountCounts < groupLabels.length);

		showStatus("Done counting foci.");
	}
}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

function extractImage(imageIndex, obsUnitIndex) {
	imageList = getFileListFromDirectory(workingPath, imageType);
	imageName = imageList[imageIndex];
	imageName = substring(imageName, 0, indexOf(imageName, imageType));
	imageZipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	imageZipListNoExt = newArray();
	for (i=0; i<imageZipList.length; i++) {
		append = substring(imageZipList[i], 0, indexOf(imageZipList[i], ".zip"));
		imageZipListNoExt = Array.concat(imageZipListNoExt, append);
	}
	imageZipIndex = -1;
	for (i=0; i<imageZipListNoExt.length; i++) {
		value = toString(imageZipListNoExt[i]);
		if (imageName == value) {
			imageZipIndex = i;
		}
	}
	roiManager("Reset");
	roiManager("Open", obsUnitRoiPath + toString(imageZipList[imageZipIndex]));

	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Convert To Tiff.ijm", workingPath + imageList[imageIndex] + "|" + imageType + "|" + zSeriesOption);
	open(getDirectory("temp") + "Converted To Tiff.tif");
	deleted = File.delete(getDirectory("temp") + "Converted To Tiff.tif");
	getDimensions(width, height, channels, slices, frames);
	Stack.setPosition(activeChannel, 1, 1);
	run("Select All");
	run("Copy");
	newImage("Extracted Channel", "16-bit black", width, height, 1, 1, 1);
	run("Paste");
	saveAs("Tiff", getDirectory("temp") + "Extracted Channel.tif");
	run("Close All");

	open(getDirectory("temp") + "Extracted Channel.tif");
	deleted = File.delete(getDirectory("temp") + "Extracted Channel.tif");
	roiManager("Select", obsUnitIndex);
	getSelectionBounds(x, y, width, height);
	run("Copy");
	newImage("Extracted Image.tif", "16-bit black", width, height, 1);
	run("Paste");
	run("Fire");
	setMinAndMax(parseInt(retrieveConfiguration(2, 3 + 5 * (activeChannel - 1))), parseInt(retrieveConfiguration(2, 4 + 5 * (activeChannel - 1))));
	saveAs("Tiff", getDirectory("temp") + "extractedImage.tif");
	run("Close All");
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
	if (File.exists(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Global configuration.txt") == true) {
		runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Global Configurator.ijm", pathArg);
		retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
		deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
		retrieved = split(retrieved, "\n");
		return retrieved[0];
	} else {
		exit("Global configuration not found.");
	}
}

function retrieveConfiguration(blockIndex, lineIndex) {
	runMacro(getDirectory("plugins") + "BB Macros" + File.separator() + "Clonogenics Modules" + File.separator() + "Clonogenics Configurator.ijm", "retrieve|" + blockIndex + "|" + lineIndex);
	retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
	deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
	retrieved = split(retrieved, "\n");
	return retrieved[0];
}