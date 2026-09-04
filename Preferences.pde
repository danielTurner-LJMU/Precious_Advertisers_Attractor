/**
 * Preferences.pde
 *
 * Handles saving and loading of user preferences — specifically the path
 * to the selected Facebook data folder, which is persisted between sessions
 * in a local text file (preciousPrefs.txt).
 */

/// --- PREFERENCE FILES AND DATA PATH VARIABLES --- ///

PrintWriter output; // Preferences file writer (for saving settings)
String prefFilePath = "preciousPrefs.txt"; // Name of the preferences file
String[] pPreferences = {""}; //String array to store preferences if the file exists.

String parentFolderPath; // Absolute path to the parent data folder

// Array used to store each folder name in the path (for display purposes)
// Used to extract the final folder name for on-screen display to user
String[] parentFolderName;
String folderName;

// Initializes preferences: either loads existing one or creates for a new one in the 'data' folder
void initPreferences() {

  // Check if preferences file exists
  boolean fileExists = doesFileExist(prefFilePath);

  if (!fileExists) {
    // File does not exist — create a new writer for it
    output = createWriter(dataPath(prefFilePath));
  } else {
    //if yes, load the first line and store the folder path
    pPreferences = loadStrings(dataPath(prefFilePath));

    if (pPreferences.length > 0) { //check there is a line of text in the file
      String rememberedPath = pPreferences[0];

      // The remembered folder may no longer be there — an external drive that
      // is not plugged in, a folder moved or renamed, or a path saved under a
      // different user account on a previous machine, which is the case that
      // found this. Only the FILE was being checked, never the folder it
      // names, so a stale path still offered CONFIRM and sent the program on
      // to read JSON out of somewhere that does not exist.
      File rememberedFolder = new File(rememberedPath);

      if (rememberedFolder.exists() && rememberedFolder.isDirectory()) {
        //set parentFolderPath to first line of text
        parentFolderPath = rememberedPath;

        // Split full path into components
        parentFolderName = split(parentFolderPath, '/');

        // Extract the last folder name for display
        folderName = parentFolderName[parentFolderName.length - 1];

        // If on state 0 (e.g., startup screen), show confirm controller
        if (state == 0) {
          showController("confirm", true);
        }
      } else {
        // Behave exactly as if no preference had been saved: leave
        // parentFolderPath unset, leave CONFIRM hidden, and let the participant
        // choose a folder. Selecting one overwrites the stale entry, so this
        // recovers itself without anyone editing the file by hand. Said out
        // loud in the console rather than failing silently, so the reason is
        // visible if the program is opened and appears to have forgotten.
        println("Saved data folder is no longer available:");
        println("  " + rememberedPath);
        println("Please select the data folder again.");
      }
    }
  }
}

// Utility function: checks if a file exists
boolean doesFileExist(String filePath) {
  return new File(dataPath(filePath)).exists();
}


// Handles user folder selection via file dialog
void folderSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());

    //store path to parent folder
    parentFolderPath = selection.getAbsolutePath();

    //checks if we are creating a new preferences file or updating an existing one.
    if (output == null) {
      // If file already existed, update it directly with new path
      saveStrings(dataPath(prefFilePath), new String[]{parentFolderPath});
    } else {
      //if a new file has been created, store the path and close file
      output.println(parentFolderPath);
      output.flush();
      output.close();
    }
    
    // Update folder display name
    parentFolderName = split(parentFolderPath, '/');
    folderName = parentFolderName[parentFolderName.length - 1];
    
    // Show confirm GUI controller if at startup
    if (state == 0) {
      showController("confirm", true);
    }
  }
}
