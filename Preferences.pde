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
      //set parentFolderPath to first line of text
      parentFolderPath = pPreferences[0];

      // Split full path into components
      parentFolderName = split(parentFolderPath, '/');

      // Extract the last folder name for display
      folderName = parentFolderName[parentFolderName.length - 1];

      // If on state 0 (e.g., startup screen), show confirm controller
      if (state == 0) {
        showController("confirm", true);
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
