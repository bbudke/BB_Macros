/*
	This script inverts the pixel values and lookup table for all images
	    in a user-specified directory.
*/


/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Invert images" {
	setBatchMode(true);
	workingPath = getDirectory(
		"Choose the directory in which image files are located:"
		);
	imageExtension = ".tif";
	imageList = getFileListFromDirectory(workingPath, imageExtension);
	for (i = 0; i < imageList.length; i++) {
		open(imageList[i]);
		run("Invert");
		run("Invert LUT");
		saveAs(
			"Tiff",
			workingPath + File.separator() + imageList[i]
			);
		cleanup();
		print(ImageList[i] + " inverted.");
	}
	print(
		imageList.length +
		" files were inverted."
		);
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