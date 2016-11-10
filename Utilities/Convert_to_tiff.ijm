var image_type_extensions = newArray(".tif",
                                     ".zvi",
                                     ".lsm");
var z_series_choices = newArray("Do nothing",
                                "Flatten (MAX)",
                                "Flatten (SUM)");

var temp_directory_utilities = getDirectory("temp") +
                               "BB_macros" + File.separator() +
                               "Utilities" + File.separator();

/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Convert_to_tiff" {
    // Expected argument is a pipe character-separated array as a string:
    //   i.e. 'path_to_image|image_type|z_series_option'

    if (!File.exists(getDirectory("temp") +
                     "BB_macros")) {
        File.makeDirectory(getDirectory("temp") +
                           "BB_macros");
    }
    if (!File.exists(getDirectory("temp") +
                     "BB_macros" + File.separator() +
                     "Utilities")) {
        File.makeDirectory(getDirectory("temp") +
                           "BB_macros" + File.separator() +
                           "Utilities");
    }

    args            = getArgument();
    args            = split(args, "|");
    path_to_image   = args[0];
    image_type      = args[1];
    z_series_option = args[2];

    title = File.getName(path_to_image);
    title = substring(title, 0, indexOf(title, image_type));

    setBatchMode(true);
    run("Close All");

    if (image_type == ".tif") {

        open(path_to_image);
        getDimensions(width, height, channels, slices, frames);
        if (frames != 1) {
            exit("Time-lapse images are not currently supported.");
        }
        saveAs("Tiff", temp_directory_utilities + "convert_to_tiff_temp.tif");
        run("Close All");

    } else if (image_type == ".zvi") {
        // ZVI files open as a separate image for each channel.
        //   This returns a single TIFF where each image from
        //   the ZVI file is a channel in the TIFF.
        open(path_to_image);
        selectImage(1);
        getDimensions(width, height, channels, slices, frames);
        if (frames != 1) {
            exit("Time-lapse images are not currently supported.");
        }
        n_channels = nImages();
        if (z_series_option == "Do nothing") {
            newImage("convert_to_tiff_temp", "16-bit black", width, height, n_channels, slices, 1);
            for (i = 1; i <= n_channels; i++) {
                for (j = 1; j <= slices; j++) {
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
            newImage("convert_to_tiff_temp", "16-bit black", width, height, n_channels, 1, 1);
            for (i = 1 ; i <= n_channels; i++) {
                selectImage(i);
                if (z_series_option == "Flatten (MAX)") {
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
        saveAs("Tiff", temp_directory_utilities + "convert_to_tiff_temp.tif");
        run("Close All");

    } else if (image_type == ".lsm") {

        open(path_to_image);
        getDimensions(width, height, channels, slices, frames);
        if (frames != 1) {
            exit("Time-lapse images are not currently supported.");
        }
        if (z_series_option == "Do nothing") {
            newImage("convert_to_tiff_temp", "16-bit black", width, height, channels, slices, 1);
            for (i = 1; i <= channels; i++) {
                for (j = 1; j <= slices; j++) {
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
            newImage("convert_to_tiff_temp", "16-bit black", width, height, channels, 1, 1);
            selectImage(1);
            if (z_series_option == "Flatten (MAX)") {
                run("Z Project...", "projection=[Max Intensity]");
            } else {
                run("Z Project...", "projection=[Sum Slices]");
            }
            for (i = 1 ; i <= channels; i++) {
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
        saveAs("Tiff", temp_directory_utilities + "convert_to_tiff_temp.tif");
        run("Close All");

    } else {

        exit(image_type + " is not currently supported by Convert_to_tiff.ijm.");
    }

}