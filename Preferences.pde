/// --- PREFERENCE FILES AND DATA PATH VARIABLES --- ///

PrintWriter output; //preferences file writer.
String prefFilePath = "preciousPrefs.txt";
String[] pPreferences = {""}; //String array to store preferences if the file exists.

String parentFolderPath; //stores abosolute path to parent data folder
//stores each folder name in path as an array
//This is used to extract the final folder name
//for on screen display to the user.
String[] parentFolderName;
String folderName;

//Load or create a preferences file in the 'data' folder
void initPreferences() {

  //check if file exists
  boolean fileExists = doesFileExist(prefFilePath);

  if (!fileExists) { //if not open a new file to write to
    output = createWriter(dataPath(prefFilePath));
  } else { //if yes, load the first line and store the folder path
    pPreferences = loadStrings(dataPath(prefFilePath));
    if (pPreferences.length > 0) { //check there is a line of text in the file
      parentFolderPath = pPreferences[0]; //set parentFolderPath to first line of text
      parentFolderName = split(parentFolderPath, '/'); //split full path into array
      folderName = parentFolderName[parentFolderName.length - 1];

      if (state == 0) {
        showController("confirm", true);

        //printArray(parentFolderName);
        // println(parentFolderName.length);
      }
    }
  }
}

boolean doesFileExist(String filePath) {
  return new File(dataPath(filePath)).exists();
}


//function for storing folder path
void folderSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    parentFolderPath = selection.getAbsolutePath(); //store path to parent folder

    //checks if we are creating a new preferences file or updating an existing one.
    if (output == null) { //if file exists, update the text line
      println("saving Strings.....");
      saveStrings(dataPath(prefFilePath), new String[]{parentFolderPath});
    } else { //if a new file has been created, store the path and close file
      output.println(parentFolderPath);
      output.flush();
      output.close();
    }
    parentFolderName = split(parentFolderPath, '/');
    folderName = parentFolderName[parentFolderName.length - 1];
    //printArray(parentFolderName);
    if (state == 0) {
      showController("confirm", true);
    }
  }
}
