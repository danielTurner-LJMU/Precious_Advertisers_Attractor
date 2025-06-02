//parentFolderPath is the path that is selected by the user.

String subFolderAd = "/ads_information"; //sub Folder we want to access
String dataFileNameAd = "advertisers_using_your_activity_or_information.json"; //name of the JSON file

JSONObject dataFileAd;
JSONArray advertisers;

//-------- OBJECT CREATION ----------//
DataObjectAd[] dataObjectsAd;

boolean drawTail = true;
int historyLength = 300;

boolean fixedSpeed = false;
float fixedMaxSpeed = 8;
float fixedMaxForce = 0.1;

boolean drawX = true;
boolean sqCaps = false;
float xScale = 1;
float xThickness = 1;

color xColor = color(0, 0, 0);

boolean drawAdNames = false;

//**** Line thickness variables
color[] palette = {#F25CA2, #F229AC, #04B2D9, #F2CB05, #F2B705}; //colours to pick for line colour
float strokeThick = 1;
int step = 1;

void loadDataAd() {

  //compile path to required data file and load
  String fullDataPath = parentFolderPath + subFolderAd + "/" + dataFileNameAd;
  dataFileAd = loadJSONObject(fullDataPath);

  //get individual objects
  extractDataAd();
}

void extractDataAd() {

  //--------------------------------------------------//
  ///////**** individual entry 'keys'****//////////

  //    "advertiser_name": "Naked Wines UK",
  //    "has_data_file_custom_audience": true,
  //    "has_remarketing_custom_audience": false,
  //    "has_in_person_store_visit": false
  //--------------------------------------------------//

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
    Boolean visit = thisAdvertiser.getBoolean("has_in_person_store_visit");
    Boolean remarket = thisAdvertiser.getBoolean("has_remarketing_custom_audience");
    Boolean hasCustomerFile = thisAdvertiser.getBoolean("has_data_file_custom_audience");
    dataObjectsAd[i] = new DataObjectAd(i, advertiserName, visit, remarket, hasCustomerFile);
    //println(advertiserName);
  }
}

///-------------------- ADVERTISER OBJECT --------------------------///

class DataObjectAd
{
  int ID;
  String mySiteName;
  boolean myVisit;
  boolean myRemarket;
  boolean myCustomerFile;
  boolean drawMe;


  //Vehicle Properties for Advertisers
  //array to store vectors of past locations
  ArrayList<PVector> history = new ArrayList<PVector>();

  PVector location = new PVector(0, 0);
  PVector velocity;
  PVector acceleration;
  float maxSpeed;
  float maxForce;
  float myMaxSpeed;
  float myMaxForce;

  float r; //radius of shape

  color myColor; ///**** NOT USED AT MOMENT *** available in case a data property can be used e.g. re-marketing.


  DataObjectAd(int id, String siteName, boolean visit, boolean remarket, boolean customerFile) {

    ID = id;
    mySiteName = siteName;
    myVisit = visit;
    myRemarket = remarket;
    myCustomerFile = customerFile;

    drawMe = false;
  }

  void initDraw() {

    drawMe = true;

    location.x = random(pg.width);
    location.y = random(pg.height);

    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    myMaxSpeed = random(4, 15);
    myMaxForce = random(0.01, 0.1);

    maxSpeed = myMaxSpeed;
    maxForce = myMaxForce;

    r = 5.0;

    //Removing this for now - idea to set colour based on data from advertiser
    //none of mine have it as of yet.
    //if ((myVisit)||(myRemarket)) {
    //  myColor = color(255, 0, 0);
    //} else {

    //  myColor = #000000;
    //}

    //pick a random colour from the palette
    int cVal = (int)random(palette.length);
    myColor = palette[cVal];

    //clear the arraylist storing previous points
    history.clear();
    //println("initialised" + ID);
  }

  void changeSpeed() {

    if (fixedSpeed) {
      maxSpeed = fixedMaxSpeed;
      maxForce = fixedMaxForce;
    } else {
      maxSpeed = myMaxSpeed;
      maxForce = myMaxForce;
    }

    //println(ID + " - " + maxSpeed);
  }

  void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    location.add(velocity);
    acceleration.mult(0);

    history.add(location.copy());
    if (history.size() > historyLength) {
      int range = history.size() - historyLength;
      for (int i = 0; i < range; i++) {
        if (i < history.size()) {
          history.remove(i);
        }
      }
    }
  }

  void findTarget() {

    float distance = 99999;
    float tempDist = 99999;
    DataObjectLogin t = dataObjectsLogin[0];

    for (DataObjectLogin i : dataObjectsLogin) {

      if (i.active) {
        tempDist = PVector.dist(location, i.location);
      }

      if (tempDist < distance) {
        distance = tempDist;
        t = i;
      }
    }

    if (tempDist == 99999) { //if no active targets are available
      seek(new PVector(pg.width/2, pg.height/2));
    } else {
      seek(t.location);
    }
  }

  void seek(PVector target) {

    PVector desired = PVector.sub(target, location);
    desired.setMag(maxSpeed);
    PVector steer = PVector.sub(desired, velocity);

    steer.limit(maxForce);

    applyForce(steer);
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  void drawAd(float textCentreY) {

    if (drawTail) {
      pg.beginShape();

      pg.stroke(myColor);
      pg.strokeWeight(strokeThick);
      pg.noFill();
      //int step = ceil(strokeThick/2);
      //println(step);
      //for (PVector v : history) {
      for (int i = 0; i < history.size(); i+=step) {
        PVector v = history.get(i);
        pg.curveVertex(v.x, v.y);//vertex(v.x, v.y);//
      }
      pg.curveVertex(location.x, location.y);
      pg.curveVertex(location.x, location.y);
      pg.endShape();
    }



    float theta = velocity.heading() + PI/2;
    float newR = r * xScale;
    float newR2 = newR*2;

    pg.pushMatrix();
    pg.translate(location.x, location.y);
    pg.rotate(theta);

    if (drawX) {
      //-------- Move These to main draw loop to set once - i.e. rather than for every object-------/////
      if (sqCaps) {
        pg.strokeCap(PROJECT);
      } else {
        pg.strokeCap(ROUND);
      }
      pg.fill(175);
      pg.stroke(xColor);
      pg.strokeWeight(xThickness);
      //----------------------------------------------------------------------------------/////

      pg.line(-newR, -newR, newR, newR);
      pg.line(newR, -newR, -newR, newR);
      //if (myCustomerFile) {
      //  pg.stroke(255);
      //  pg.strokeWeight(xThickness/10);
      //  pg.line(-newR/2, -newR/2, newR/2, newR/2);
      //  pg.line(newR/2, -newR/2, -newR/2, newR/2);
      //}
    }
    if (drawAdNames) {
      pg.fill(0);
      pg.rotate(-theta);
      pg.text(mySiteName, sqrt(newR2*newR2)-(newR/4)+(xThickness/2), textCentreY);
    }
    pg.popMatrix();
  }
}
