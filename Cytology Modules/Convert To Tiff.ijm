var imageTypeExtensions = newArray(".tif", ".zvi", ".lsm");
var zSeriesChoices = newArray("Do nothing", "Flatten (MAX)", "Flatten (SUM)");

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Convert To Tiff" {
	// Expected argument is a pipe character-separated array as a string:
	// i.e. 'pathToImage|imageType|zSeriesOption'

	args = getArgument();
	args = split(args, "|");
	pathToImage = args[0];
	imageType = args[1];
	zSeriesOption = args[2];

	title = File.getName(pathToImage);
	title = substring(title, 0, indexOf(title, imageType));

	setBatchMode(true);
	run("Close All");

	if (imageType == ".tif") {

		open(pathToImage);
		getDimensions(width, height, channels, slices, frames);
		if (frames != 1) {
			exit("Time-lapse images are not currently supported.");
		}
		saveAs("Tiff", getDirectory("temp") + "Converted To Tiff.tif");
		run("Close All");

	} else if (imageType == ".zvi") {

		open(pathToImage);
		selectImage(1);
		getDimensions(width, height, channels, slices, frames);
		if (frames != 1) {
			exit("Time-lapse images are not currently supported.");
		}
		nChannels = nImages();
		if (zSeriesOption == "Do nothing") {
			newImage("Converted To Tiff", "16-bit black", width, height, nChannels, slices, 1);
			for (i=1; i<=nChannels; i++) {
				for (j=1; j<=slices; j++) {
					selectImage(i);
					Stack.setPosition(1, j, 1);
					run("Select All");
					run("Copy");
					selectImage(nImages());
					Stack.setPosition(i, j, 1);
					run("Paste");
				}
				run("Grays");
			}
		} else {
			newImage("Converted To Tiff", "16-bit black", width, height, nChannels, 1, 1);
			for (i=1; i<=nChannels; i++) {
				selectImage(i);
				if (zSeriesOption == "Flatten (MAX)") {
					run("Z Project...", "projection=[Max Intensity]");
				} else {
					run("Z Project...", "projection=[Sum Slices]");
				}
				selectImage(nImages());
				run("Select All");
				run("Copy");
				close();
				selectImage(nImages());
				Stack.setPosition(i, 1, 1);
				run("Paste");
				run("Grays");
			}
		}
		saveAs("Tiff", getDirectory("temp") + "Converted To Tiff.tif");
		run("Close All");

	} else if (imageType == ".lsm") {

		open(pathToImage);
		getDimensions(width, height, channels, slices, frames);
		if (frames != 1) {
			exit("Time-lapse images are not currently supported.");
		}
		if (zSeriesOption == "Do nothing") {
			newImage("Converted To Tiff", "16-bit black", width, height, channels, slices, 1);
			for (i=1; i<=channels; i++) {
				for (j=1; j<=slices; j++) {
					selectImage(1);
					Stack.setPosition(i, j, 1);
					run("Select All");
					run("Copy");
					selectImage(nImages());
					Stack.setPosition(i, j, 1);
					run("Paste");
				}
				run("Grays");
			}
		} else {
			newImage("Converted To Tiff", "16-bit black", width, height, channels, 1, 1);
			selectImage(1);
			if (zSeriesOption == "Flatten (MAX)") {
				run("Z Project...", "projection=[Max Intensity]");
			} else {
				run("Z Project...", "projection=[Sum Slices]");
			}
			for (i=1; i<=channels; i++) {
				selectImage(nImages());
				Stack.setPosition(i, 1, 1);
				run("Select All");
				run("Copy");
				selectImage(nImages());
				Stack.setPosition(i, 1, 1);
				run("Paste");
				run("Grays");
			}
		}
		saveAs("Tiff", getDirectory("temp") + "Converted To Tiff.tif");
		run("Close All");

	} else {

		exit(imageType + " is not currently supported by Convert To Tiff.ijm.");
	}

}