var wd_cmds = newMenu(
	"Working Directory Menu Tool",
	newArray("Set working directory",
			 "Show working directory"));
var temp_directory = getDirectory("temp") +
	                 "BB_macros" + File.separator() +
	                 "Fibers" + File.separator();

/*
--------------------------------------------------------------------------------
	MACRO BUTTONS
--------------------------------------------------------------------------------
*/

macro "Fibers Frontend Startup" {
	requires("1.51g");
	run("Install...", "install=[" + getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Fibers.ijm]");

	if (!File.exists(getDirectory("temp") +
		             "BB_macros")) {
		File.makeDirectory(getDirectory("temp") +
			               "BB_macros");
	}
	if (!File.exists(getDirectory("temp") +
		             "BB_macros" + File.separator() +
		             "Fibers")) {
		File.makeDirectory(getDirectory("temp") +
			               "BB_macros" + File.separator() +
			               "Fibers");
	}
}

macro "Working Directory Menu Tool - C037L02f2L5270L70c0Lc0f2L020cLf2fcL0cfc" {
	cmd = getArgument();
	if (cmd == "Set working directory") {
		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Fibers_modules" + File.separator() +
			"Global_configurator_fibers.ijm", "create");
	} else if (cmd == "Show working directory") {
		if (!File.exists(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Fibers_modules" + File.separator() +
			"Global_configuration_fibers.txt")) {
			showStatus("Working directory has not been set.");
		} else {
			working_path = get_working_paths("working_path");
			working_path = substring(working_path, 0, lengthOf(working_path) - 1);
			working_path = split(working_path, File.separator());
			showStatus(".." + File.separator() +
				working_path[working_path.length - 2] + File.separator() +
				working_path[working_path.length - 1] + File.separator() +
				" loaded.");
		}
	} else {
		exit(cmd + " is not recongnized as\n" +
			 "a valid argument for Working Directory Menu Tool.");
	}
}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

// Runs the global configurator macro, which writes the resulting path
//     to a text file in the temp directory. This result is read back and
//     returned by the function and the temp file is deleted.
function get_working_paths(path_arg) {
	valid_path_args = newArray("working_path",
							   "analysis_path",
							   "obs_unit_ROI_path",
							   "analysis_setup_file");
	valid_arg = false;
	for (i = 0; i < valid_path_args.length; i++) {
		if (matches(path_arg, valid_path_args[i])) {
			valid_arg = true;
			i = valid_path_args.length;
		}
	}
	if (!valid_arg) {
		exit(path_arg + " is not recognized as\n" +
			 "a valid argument for get_working_paths.");
	}
	if (File.exists(getDirectory("plugins") +
		            "BB_macros" + File.separator() +
		            "Fibers_modules" + File.separator() +
		            "Global_configuration_fibers.txt") == true) {
		runMacro(getDirectory("plugins") +
			     "BB_macros" + File.separator() +
			     "Fibers_modules" + File.separator() +
			     "Global_configurator_fibers.ijm", path_arg);
		retrieved = File.openAsString(temp_directory + "Global_configurator_fibers_temp.txt");
		deleted = File.delete(temp_directory + "Global_configurator_fibers_temp.txt");
		retrieved = split(retrieved, "\n");
		return retrieved[0];
	} else {
		exit("Global configuration not found.");
	}
}