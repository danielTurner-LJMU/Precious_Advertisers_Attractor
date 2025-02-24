//parentFolderPath is the path that is selected by the user.

String subFolderAd = "/ads_information"; //sub Folder we want to access
String dataFileNameAd = "advertisers_using_your_activity_or_information.json"; //name of the JSON file

JSONObject dataFileAd;
JSONArray advertisers;

//-------- OBJECT CREATION ----------//
DataObjectAd[] dataObjectsAd;

void loadDataAd() {

  //compile path to required data file and load
  String fullDataPath = parentFolderPath + subFolderAd + "/" + dataFileNameAd;
  dataFileAd = loadJSONObject(fullDataPath);

  //get individual objects
  extractDataAd();
}

void extractDataAd() {

  /*The line below extracts the 'key' names from the JSON object.
   this is a way of finding all the arrays within this object without
   having to manually trawl through the file. As we can only access the data
   by knowing the 'key' name it is a useful function */

  //String[] myKeys = (String[]) dataFileLogin.keys().toArray(new String[dataFileLogin.size()]);
  //printArray(myKeys);

  advertisers = dataFileAd.getJSONArray("custom_audiences_all_types_v2");
  dataObjectsAd = new DataObjectAd[advertisers.size()];

  for (int i = 0; i < advertisers.size(); i++) {
    JSONObject thisAdvertiser = advertisers.getJSONObject(i);
    String advertiserName = thisAdvertiser.getString("advertiser_name");
    dataObjectsAd[i] = new DataObjectAd(i, advertiserName);
    //println(advertiserName);
  }
}

///-------------------- ADVERTISER OBJECT --------------------------///

class DataObjectAd
{
  int ID;
  String mySiteName;
  boolean drawMe;
  float posX, posY; //postion for objects



  DataObjectAd(int id, String siteName) {

    ID = id;
    mySiteName = siteName;

    drawMe = false;
  }

  void initDraw() {

    posX = random(pg.width);
    posY = random(pg.height);
    drawMe = true;

    //println("initialised" + ID);
  }
  void update() {
  }

  void drawAd() {

    pg.pushMatrix();
    pg.translate(posX, posY);
    pg.line(-15, -15, 15, 15);
    pg.line(15, -15, -15, 15);
    pg.popMatrix();
  }
}
