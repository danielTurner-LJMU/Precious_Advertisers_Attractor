// parentFolderPath is the path that is selected by the user.

String subFolderAd = "/ads_information"; //sub Folder we want to access
String dataFileNameAd = "advertisers_using_your_activity_or_information.json"; //name of the JSON file

JSONObject dataFileAd;  // Full JSON object loaded from file
JSONArray advertisers;  // JSON array of individual advertisers


//-------- OBJECT CREATION ----------//
DataObjectAd[] dataObjectsAd;     // Array to store advertiser objects

boolean drawTail = false;          //Show/hide all lines
int historyLength = 200;          // Number of points stored in trail history
boolean randomLineWeight = false;  // Toggle for randomised line thickness

//controls for attraction behaviour of X objects.
//by default the pick random max speeds and forces but this can be changed
//so their behaviour is uniform. When uniform, the user can control the
//maximum speed and maximum force for the steering behaviour.

//boolean fixedSpeed = false;    // Use uniform speed and force for all objects?
//float fixedMaxSpeed = 8;       // Fixed max speed (if enabled)
//float fixedMaxForce = 0.1;     // Fixed max force (if enabled)

boolean drawX = true;           //show/hide all X's
boolean sqCaps = false;         //draw with square/rounded caps
float xScale = 2;               //size of x's
float xThickness = 8;           //stroke weight for X's
int numXToDrawAtStart= 50;      //set the number of X's to draw in the initial phase

boolean xWhite = false;         //draw X's white/black
color xColor = color(0, 0, 0);  //colour to draw X's

boolean drawAdNames = false;    // Toggle to draw advertiser names as text
boolean drawAdBlocks = false;   // Draw block behind Advert Names
float textPadding = 8;          // Padding for advertiser name drawn next to x
float innerPad = 4;             // Padding between rectangle and text

//**** Line variables
boolean colourLine = true;      // Toggle coloured/black lines
color[] palette = {#F229AC, #04B2D9, #F2CB05}; //Line colour palette
float strokeThick = 1;          // Base stroke weight
int step = 1;                   // Distance between vertices on tail line
color pdfBlack = color(0, 150); // Semi-transparent black for PDF export to risograph

//Checking for rollovers
DataObjectLogin hoveredLogin = null;

void loadDataAd() {

  // Build path to JSON file and load
  String fullDataPath = parentFolderPath + subFolderAd + "/" + dataFileNameAd;
  dataFileAd = loadJSONObject(fullDataPath);
  extractDataAd(); // Parse the JSON into objects
}

void extractDataAd() {

  //--------------------------------------------------//
  ///////**** Individual Entry 'keys'****//////////

  //    "advertiser_name": "Some Advertiser",
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

  if (dataFileAd.hasKey("custom_audiences_all_types_v2")) {
    // Access array by known key in JSON file
    advertisers = dataFileAd.getJSONArray("custom_audiences_all_types_v2");
    dataObjectsAd = new DataObjectAd[advertisers.size()];

    for (int i = 0; i < advertisers.size(); i++) {
      JSONObject thisAdvertiser = advertisers.getJSONObject(i);

      // Extract required fields from JSON entry
      String advertiserName = thisAdvertiser.getString("advertiser_name");
      advertiserName = fixEncoding(advertiserName);
      Boolean visit = thisAdvertiser.getBoolean("has_in_person_store_visit");
      Boolean remarket = thisAdvertiser.getBoolean("has_remarketing_custom_audience");
      Boolean hasCustomerFile = thisAdvertiser.getBoolean("has_data_file_custom_audience");

      // Create new advertiser object
      dataObjectsAd[i] = new DataObjectAd(i, advertiserName, visit, remarket, hasCustomerFile);
    }
  } else if (dataFileAd.hasKey("label_values")) {
    JSONArray labelValues = dataFileAd.getJSONArray("label_values");

    // First pass - count total entries so you can size the array
    int totalEntries = 0;
    for (int i = 0; i < labelValues.size(); i++) {
      totalEntries += labelValues.getJSONObject(i).getJSONArray("vec").size();
    }
    //println("number of JSON Objects = " + totalEntries);

    dataObjectsAd = new DataObjectAd[totalEntries]; // Now initialised correctly

    // Second pass - populate the array
    int index = 0;
    for (int i = 0; i < labelValues.size(); i++) {
      JSONArray vec = labelValues.getJSONObject(i).getJSONArray("vec");
      for (int j = 0; j < vec.size(); j++) {
        //Check encoding of string for Unicode errors
        String name = vec.getJSONObject(j).getString("value");
        String advertiserName = fixEncoding(name);
        dataObjectsAd[index] = new DataObjectAd(index, advertiserName);
        index++;
      }
    }
  } else {
    println("Unrecognised ad data format — no matching key found");
    // Set advertisers to an empty array so the rest of the program doesn't crash
    dataObjectsAd = new DataObjectAd[0];
  }
}

//Find Unicode encoding errors and fix - most are related to non-latin fonts so don't display but gets rid of long strings.
String fixEncoding(String input) {
  try {
    byte[] bytes = input.getBytes("ISO-8859-1"); // Convert back to raw bytes

    //println(input + " converted to: " + new String(bytes, "UTF-8"));
    return new String(bytes, "UTF-8");            // Re-read as UTF-8
  }
  catch (Exception e) {
    return input; // If it fails, return the original string unchanged
  }
}

///-------------------- ADVERTISER OBJECT --------------------------///

class DataObjectAd
{
  // Basic Info
  int ID;
  String mySiteName;
  boolean myVisit, myRemarket, myCustomerFile;
  boolean drawMe;


  //Vehicle Properties for Advertisers
  ArrayList<PVector> history = new ArrayList<PVector>();  //array to store vectors of past locations
  PVector location = new PVector(0, 0);
  PVector velocity, acceleration;
  //float maxSpeed, maxForce;
  float myMaxSpeed, myMaxForce;

  // Visual + Drawing Settings
  float theta = 0;          //rotation of x
  float newR, newR2;        // Used for scaling & spacing of sdvertiser text
  float r;                  //radius of x shape
  int cVal;                 // Index for colour palette
  color myColor;            // Colour selected from palette
  float randomStrokeThick;   //randomised strokeWeight for when 'randomLineWeight' = true

  //Performace enhancement - Changing number of target searches to set number of frames instead of every frame
  int targetRefreshCounter = 0;
  DataObjectLogin cachedTarget = null;
  float cachedTextWidth = 0;

  //original JSON data format
  DataObjectAd(int id, String siteName, boolean visit, boolean remarket, boolean customerFile) {

    ID = id;
    mySiteName = siteName;
    myVisit = visit;
    myRemarket = remarket;
    myCustomerFile = customerFile;

    //start only draws certain number of advertisers to show motion.
    //can be very laggy when data has huge number of advertsiers
    if (id < numXToDrawAtStart) {
      drawMe = true;
    } else {
      drawMe = false;
    }
  }

  // New format - name only, booleans default to false
  DataObjectAd(int id, String siteName) {
    ID = id;
    mySiteName = siteName;
    myCustomerFile = false;
    myRemarket = false;
    myVisit = false;

    //start only draws certain number of advertisers to show motion.
    //can be very laggy when data has huge number of advertsiers
    if (id < numXToDrawAtStart) {
      drawMe = true;
    } else {
      drawMe = false;
    }
  }

  // Initiate advertiser objects
  void initDraw() {

    PVector spawn = getRandomOffscreenPosition(spawnBorder);
    location.x = spawn.x;
    location.y = spawn.y;

    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    myMaxSpeed = random(4, 30);
    myMaxForce = random(0.01, 0.2);

    //maxSpeed = myMaxSpeed;
    //maxForce = myMaxForce;

    r = 5.0;

    newR = r * xScale;
    newR2 = newR*2;

    //pick a random colour from the palette
    cVal = (int)random(palette.length);
    myColor = palette[cVal];

    //initialise the random weight to 1
    randomStrokeThick = 1;

    //clear the arraylist storing previous points
    history.clear();
  }

  void changeSpeed() {
    // Switch between fixed or random (personal) speed/force
    //if (fixedSpeed) {
    //  maxSpeed = fixedMaxSpeed;
    //  maxForce = fixedMaxForce;
    //} else {
    //  maxSpeed = myMaxSpeed;
    //  maxForce = myMaxForce;
    //}
  }

  // Update Movement and Trail
  void update() {
    velocity.add(acceleration);
    velocity.limit(myMaxSpeed);
    location.add(velocity);
    acceleration.mult(0);

    theta = velocity.heading() + PI/2;


    history.add(location.copy());
    if (history.size() > historyLength) {
      // With this - subList().clear() is a single operation
      if (history.size() > historyLength) {
        history.subList(0, history.size() - historyLength).clear();
      }
    }
  }

  //Seek Closest Active Login Object
  void findTarget() {

    targetRefreshCounter++;
    if (targetRefreshCounter % 10 != 0 && cachedTarget != null) {
      seek(cachedTarget.active ? cachedTarget.location : new PVector(pg.width/2, pg.height/2));
      return;
    }

    // Set initial closest distance to a very large number
    float closestDistance = Float.MAX_VALUE;

    // Store the closest login target found (initially none)
    DataObjectLogin closestTarget = null;

    // Loop through all login data objects
    for (DataObjectLogin login : dataObjectsLogin) {

      // Skip any login objects that are not currently active
      if (!login.active) continue;

      // Calculate the distance between this advertiser and the active login object
      float d = PVector.dist(location, login.location);

      // If this is the closest one so far, store it
      if (d < closestDistance) {
        closestDistance = d;
        closestTarget = login;
      }
    }

    // Cache the result
    cachedTarget = closestTarget;
    targetRefreshCounter = 0;

    // If no active login objects were found, seek the centre of the canvas
    if (closestTarget == null) {
      seek(new PVector(pg.width / 2, pg.height / 2));
    } else {

      // Otherwise, seek the closest active login object's location
      seek(closestTarget.location);
    }
  }

  // Steering behavior to move towards the target
  void seek(PVector target) {

    PVector desired = PVector.sub(target, location);
    desired.setMag(myMaxSpeed);
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(myMaxForce);
    applyForce(steer);
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  //Draw trailing lines
  void drawAdLines() {
    if (drawTail) {
      pg.beginShape();

      //Check if we are exporting a PDF. If so set the stroke colour to black, semi-transparent
      //As this is for riso-reproduction this will allow for some multiplying of colour within
      //each colour layer/PDF page.
      if (pg == pgPDF) {
        if (colourLine) {      //if we are drawing coloured lines
          pg.stroke(pdfBlack);
        } else {               //if we are drawing black lines
          pg.stroke(0);
        }
      } else {
        pg.stroke(myColor);
      }

      if (randomLineWeight) {
        pg.strokeWeight(randomStrokeThick);
      } else {
        pg.strokeWeight(strokeThick);
      }

      pg.noFill();
      for (int i = 0; i < history.size(); i+=step) {
        PVector v = history.get(i);
        pg.curveVertex(v.x, v.y);
      }

      //these two are needed to take the path right up to the vehicle
      pg.curveVertex(location.x, location.y);
      pg.curveVertex(location.x, location.y);
      pg.endShape();
    }
  }

  //Randomise stroke weight
  void randomiseWeight() {
    randomStrokeThick = random(strokeThick*0.2, strokeThick);
  }

  // Draw just the X shape - seperated from rect/text drawing to help with PDF layer separation
  void drawAdX() {
    if (!drawX) return;
    pg.pushMatrix();
    pg.translate(location.x, location.y);
    pg.rotate(theta);
    newR = r * xScale;
    pg.stroke(xColor);
    pg.strokeWeight(xThickness);
    pg.line(-newR, -newR, newR, newR);
    pg.line(newR, -newR, -newR, newR);
    pg.popMatrix();
  }

  // Draw just the label (rect + text) - seperated to help with PDF layer separation
  void drawAdLabel(float baseline, float ascent, float textHeight, color rectColor, color textColor, boolean drawRect) {
    if (!drawAdNames) return;
    pg.pushMatrix();
    pg.translate(location.x, location.y);
    pg.rotate(theta);

    newR = r * xScale;
    float rightEdge = abs(newR * cos(theta)) + abs(newR * sin(theta));
    rightEdge += xThickness / 2.0;
    float textX = rightEdge + textPadding;

    float rectX = textX - innerPad;
    float rectY = baseline - ascent - innerPad;
    float rectW = cachedTextWidth + (innerPad * 2.0);
    float rectH = textHeight + (innerPad * 2.0);

    pg.pushMatrix();
    pg.rotate(-theta);
    pg.rectMode(CORNER);
    pg.noStroke();

    if (drawRect && drawAdBlocks) {
      pg.fill(rectColor);
      pg.rect(rectX, rectY, rectW, rectH);
    }

    pg.fill(textColor);
    pg.text(mySiteName, textX, baseline);

    pg.popMatrix();
    pg.popMatrix();
  }
}

//-------- SPAWN LOCATION OUTSIDE CANVAS ----------//
//return random locations outside of the canvas edge
int spawnBorder = 50;

PVector getRandomOffscreenPosition(int border) {

  int side = int(random(4));  // 0=top, 1=right, 2=bottom, 3=left

  float x = 0;
  float y = 0;

  switch (side) {

  case 0: // TOP
    x = random(pg.width);
    y = random(-spawnBorder, 0);
    break;

  case 1: // RIGHT
    x = random(pg.width, pg.width + spawnBorder);
    y = random(pg.height);
    break;

  case 2: // BOTTOM
    x = random(pg.width);
    y = random(pg.height, pg.height + spawnBorder);
    break;

  case 3: // LEFT
    x = random(-spawnBorder, 0);
    y = random(pg.height);
    break;
  }

  return new PVector(x, y);
}
