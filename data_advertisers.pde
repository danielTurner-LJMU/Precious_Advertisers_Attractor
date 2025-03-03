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

  //Vehicle Properties for Advertisers
  //array to store vectors of past locations
  ArrayList<PVector> history = new ArrayList<PVector>();

  PVector location = new PVector(0, 0);
  PVector velocity;
  PVector acceleration;
  float maxSpeed;
  float maxForce;

  float r; //radius of shape

  color myColor;


  DataObjectAd(int id, String siteName) {

    ID = id;
    mySiteName = siteName;

    drawMe = false;
  }

  void initDraw() {

    drawMe = true;

    location.x = random(pg.width);
    location.y = random(pg.height);

    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    maxSpeed = 8;
    maxForce = 0.1;

    r = 5.0;

    myColor = #000000;
    //println("initialised" + ID);
  }
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    location.add(velocity);
    acceleration.mult(0);

    history.add(location.get());
    if (history.size() > 300) {
      history.remove(0);
    }
  }

  void findTarget() {

    float distance = 99999;
    float tempDist = 99999;
    DataObjectLogin t = dataObjectsLogin[0];//targets.get(0);

    for (DataObjectLogin i : dataObjectsLogin) {

      //println("target No = " + i.ID;
      if (i.active) {
        tempDist = PVector.dist(location, i.location);
      }
      if (distance == 99999) {
        distance = tempDist;
      } else {

        if (tempDist < distance) {

          //println("ACTIVE = " + i.ID + " tempDist = " + tempDist);
          distance = tempDist;
          t = i;
        }
      }
    }

    seek(t.location);
    //maxForce = t.attraction*0.001;
    //println(t.ID);
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

  void drawAd() {

    pg.beginShape();

    pg.stroke(myColor);
    pg.strokeWeight(1);//strokeThick);
    pg.noFill();
    //int step = ceil(strokeThick/2);
    //println(step);
    //for (PVector v : history) {
    for (int i = 0; i < history.size(); i++) {//i+=step){
      PVector v = history.get(i);
      pg.vertex(v.x, v.y);//curveVertex(v.x, v.y);
    }
    pg.endShape();

    float theta = velocity.heading() + PI/2;

    pg.fill(175);
    pg.stroke(0);
    pg.pushMatrix();
    pg.translate(location.x, location.y);
    pg.rotate(theta);
    //pg.beginShape();
    pg.line(-r, -r, r, r);//vertex(0, -r*2);
     pg.line(r, -r, -r, r);
    //pg.vertex(-r, r*2);
    //pg.vertex(r, r*2);
    //pg.endShape(CLOSE);
    pg.popMatrix();

    //pg.pushMatrix();
    //pg.translate(posX, posY);
    //pg.line(-15, -15, 15, 15);
    //pg.line(15, -15, -15, 15);
    //pg.popMatrix();
  }
}
