/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Colocalization" {

	setBatchMode(true);

	/*
	 * Get the channels for colocalization and make sure that the user
	 * made a valid selection.
	 * Channel X is the channel containing foci to be colocalized to foci
	 * areas in Channel Y, which is used to create a mask to check for
	 * colocalization. In other words, we will check to see if the foci
	 * in Channel X colocalize with the foci in Channel Y.
	 */
	nChannels = retrieveConfiguration(0, 1);
	channelChoices = newArray();
	channelChoicesPrint = newArray();
	for (i = 1; i <= nChannels; i++) {
		channelChoices = Array.concat(channelChoices, toString(i, 0));
	}

	/*
	Dialog.create("Channel 'x' ('x' colocalized to 'y')");
	Dialog.addChoice("Channel: ", channelChoices);
	Dialog.show();
	channelX = Dialog.getChoice();
	
	Dialog.create("Channel 'y' ('x' colocalized to 'y')");
	Dialog.addChoice("Channel: ", channelChoices);
	Dialog.show();
	channelY = Dialog.getChoice();
	*/
	channelX = 2;
	channelY = 3;

	if (channelX == channelY) {
		exit("The two channels used for\ncolocalization must be different.");
	}

	/*
	 * Make sure that all the files needed for colocalization are present,
	 * starting with the OBS UNIT ROI files, which will be used to loop through
	 * the observational units, and then the actual ROI zip files containing the
	 * focus ROIs.
	 */
	analysisPath = getWorkingPaths("analysisPath");
	obsUnitRoiPath = getWorkingPaths("obsUnitRoiPath");

	zipList = getFileListFromDirectory(obsUnitRoiPath, ".zip");
	if (zipList.length < 1) {
		exit("No OBS UNIT ROI data found.");
	}
	zipListNoExt = newArray();
	for (i=0; i<zipList.length; i++) {
		append = substring(zipList[i], 0, indexOf(zipList[i], ".zip"));
		zipListNoExt = Array.concat(zipListNoExt, append);
	}

	channelXFociPath = analysisPath + "Channel " + channelX + " Results" + File.separator() + "Raw Data" + File.separator();
	channelYFociPath = analysisPath + "Channel " + channelY + " Results" + File.separator() + "Raw Data" + File.separator();
	if (!File.exists(channelXFociPath)) {
		exit("No data for Channel " + channelX + " found.");
	}
	if (!File.exists(channelYFociPath)) {
		exit("No data for Channel " + channelY + " found.");
	}

	/*
	 * The list of OBS UNIT ROI zip files corresponds to the list of scored images.
	 * Go through each OBS UNIT ROI zip file. Start by counting up the total number of
	 * OBS UNIT ROIs in the current zip file. For each OBS UNIT ROI, check in the
	 * Channel X and Y Foci folders to see if there is are corresponding foci.zip
	 * files for the current scored image and OBS UNIT; if one or both of the foci.zip
	 * does not exist, then it is assumed that the focus counter scored zero foci for
	 * the channel(s) and zero colocalized foci will be returned and we continue.
	 * If both foci.zip files are present, then in a dummy image having the same size
	 * as the OBS UNIT ROI area, fill with 0-values (black), and create a mask of
	 * 255-values (white) corresponding to foci marked as "PASS". If there are no foci
	 * marked as "PASS", then there are no valid foci for Channel Y, zero colocalization
	 * is returned, and we continue. Otherwise, reset the ROI manager, open the foci.zip
	 * file for Channel X, loop through the foci list, and for each "PASS" focus ROI,
	 * increment a counter for total foci in this OBS UNIT, measure the RawIntDen of the
	 * focus ROI, and if it's greater than 0, increment another counter for colocalized
	 * foci. Save these values an expanding array as tab-delimited lines of text.
	 */
	run("Set Measurements...", "area shape integrated redirect=None decimal=3");
	run("Overlay Options...", "stroke=green width=0 fill=none");
	results = newArray();
	resultsHeader = "OBS Unit\tChannel " + channelX + " foci\tChannel " + channelY + " foci\tChannel " + channelX + " avg focal circ\tChannel " + channelY + " avg focal circ\tCh " + channelX + " colocalized to Ch " + channelY; 
	for (i = 0; i < zipList.length; i++) {
		cleanup();
		newImage("Dummy", "8-bit black", 1388, 1040, 1);
		roiManager("Reset");
		roiManager("Open", obsUnitRoiPath + zipList[i]);
		obsUnits = newArray();
		for (j = 0; j < roiManager("Count"); j++) {
			roiManager("Select", j);
			name = Roi.getName();
			if (indexOf(name, "OBS UNIT") != -1) {
				obsUnits = Array.concat(obsUnits, name);
			}
		}
		if (obsUnits.length < 1) {
			exit("No OBS UNIT indices found in " + zipList[i]);
		}
		cleanup();
		for (j = 0; j < obsUnits.length; j++) {
			newImage("Dummy", "8-bit black", 1388, 1040, 1);
			roiManager("Reset");
			roiManager("Open", obsUnitRoiPath + zipList[i]);
			Xfoci = 0;
			XCirc = newArray();
			Yfoci = 0;
			YCirc = newArray();
			XYfociColocalized = 0;

			for (k = 0; k < roiManager("Count"); k++) {
				roiManager("Select", k);
				name = Roi.getName();
				if (indexOf(name, obsUnits[j]) != -1) {
					k = roiManager("Count");
				}
			}

			obsUnit = Roi.getName();
			obsUnit = substring(obsUnit, lengthOf("OBS UNIT "), lengthOf(obsUnit));
			run("Crop");

			if (File.exists(channelXFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip")) {
				roiManager("Reset");
				roiManager("Open", channelXFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip");
				for (k = 0; k < roiManager("Count"); k++) {
					roiManager("Select", k);
					name = Roi.getName();
					if (indexOf(name, "PASS") != -1) {
						Xfoci++;
					}
				}
			}
			if (File.exists(channelYFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip")) {
				roiManager("Reset");
				roiManager("Open", channelYFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip");
				for (k = 0; k < roiManager("Count"); k++) {
					roiManager("Select", k);
					name = Roi.getName();
					if (indexOf(name, "PASS") != -1) {
						Yfoci++;
					}
				}
			}

			if (
				!File.exists(channelXFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip") ||
				!File.exists(channelYFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip")
				) {
				// do nothing; there are no colocalizing foci because at least one channel had no foci
			} else {
				roiManager("Reset");
				roiManager("Open", channelYFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip");
				for (k = 0; k < roiManager("Count"); k++) {
					roiManager("Select", k);
					name = Roi.getName();
					if (indexOf(name, "FAIL") != -1) {
						run("Set...", "value=0");
					} else {
						run("Measure");
						YCirc = Array.concat(YCirc, getResult("Circ."));
						run("Set...", "value=255");
					}
				}
				if (Yfoci < 1) {
					// do nothing; there were no foci in Channel Y that passed
				} else {
					roiManager("Reset");
					roiManager("Open", channelXFociPath + zipListNoExt[i] + "-" + obsUnit + " foci.zip");
					for (k = 0; k < roiManager("Count"); k++) {
						roiManager("Select", k);
						name = Roi.getName();
						if (indexOf(name, "FAIL") != -1) {
							// do nothing; this focus does not pass
						} else {
							run("Add Selection...");
							run("Measure");
							XCirc = Array.concat(XCirc, getResult("Circ."));
							colocalizedInt = getResult("RawIntDen");
							if (colocalizedInt > 0) {
								XYfociColocalized++;
							}
						}
					}
				}
			}

			if (XCirc.length > 0) {
				sum = 0;
				for (k = 0; k < XCirc.length; k++) {
					sum += XCirc[k];
				}
				XCircAvg = sum / XCirc.length;
			} else {
				XCircAvg = "NA";
			}

			if (YCirc.length > 0) {
				sum = 0;
				for (k = 0; k < YCirc.length; k++) {
					sum += YCirc[k];
				}
				YCircAvg = sum / YCirc.length;
			} else {
				YCircAvg = "NA";
			}

//			waitForUser("X foci: " + Xfoci + ", Y foci: " + Yfoci + ", X col to Y: " + XYfociColocalized + ", " + toString(XYfociColocalized / Xfoci, 3));
			thisResult = zipListNoExt[i] + "-" + obsUnit + "\t" + Xfoci + "\t" + Yfoci + "\t" + XCircAvg + "\t" + YCircAvg + "\t" + XYfociColocalized;
			results = Array.concat(results, thisResult);
			cleanup();
		} // end of OBS Unit loop for this image
		cleanup();
		showProgress(i / (zipList.length - 1));
	} // end of loop for the images
	outputFile = File.open(analysisPath + "Ch " + channelX + " to Ch " + channelY + " colocalization.txt");
	print(outputFile, resultsHeader);
	for (i = 0; i < results.length; i++) {
		print(outputFile, results[i]);
	}
	File.close(outputFile);

} // end of macro "Colocalization"

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