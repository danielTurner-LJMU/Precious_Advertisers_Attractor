/**
 * data_advertisers.pde
 *
 * Loads and parses the Facebook advertiser JSON data export.
 * Handles two known JSON formats from Facebook's data download.
 *
 * Defines DataObjectAd: a steered vehicle that seeks active login
 * locations on the canvas, drawing trailing lines and X markers.
 * Each object represents one advertiser that has used the account
 * holder's data or activity.
 */

// parentFolderPath is the path that is selected by the user.
String subFolderAd = "/ads_information"; //sub Folder we want to access
String dataFileNameAd = "advertisers_using_your_activity_or_information.json"; //name of the JSON file

JSONObject dataFileAd;  // Full JSON object loaded from file
JSONArray advertisers;  // JSON array of individual advertisers

float pointsDist = 0.1; //Trying to sort Jagged Lines

//-------- OBJECT CREATION ----------//
DataObjectAd[] dataObjectsAd;     // Array to store advertiser objects

boolean drawTail = false;          //Show/hide all lines
int historyLength = 200;          // Number of points stored in trail history
boolean randomLineWeight = false;  // Toggle for randomised line thickness

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

  /*
 * Facebook has changed the format of this JSON file over time, so two formats are handled here.
   *
   * Format 1 — "custom_audiences_all_types_v2" (older export):
   *   A flat array of advertiser objects, each containing the advertiser name plus
   *   three booleans describing how your data was used (remarketing, customer file,
   *   in-person visit). These are passed to the full DataObjectAd constructor.
   *
   * Format 2 — "label_values" (newer export):
   *   A nested structure where advertisers are grouped inside labelled arrays ("vec").
   *   Only the advertiser name is available, so a simpler DataObjectAd constructor is used.
   *   A first pass counts the total entries before the array can be initialised,
   *   as Processing requires a fixed array size upfront.
   *
   * If neither key is found, an empty array is created to prevent the program from crashing.
   */
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

  // Update Movement and Trail
  void update() {
    velocity.add(acceleration);
    velocity.limit(myMaxSpeed);
    location.add(velocity);
    acceleration.mult(0);

    theta = velocity.heading() + PI/2;


    history.add(location.copy());
    if (history.size() > historyLength) {
      // SIngle operation to clear history - subList().clear()
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

  void drawAdLines() {
  if (!drawTail || history.size() < 2) return;

  color lineColor;
  if (pg == pgPDF) {
    lineColor = colourLine ? pdfBlack : color(0);
  } else {
    lineColor = colourLine ? myColor : color(0);
  }

  float hw = (randomLineWeight ? randomStrokeThick : strokeThick) * 0.5;

  // Build point list using distance threshold
  float minPointDist = 2.0;
  ArrayList<PVector> pts = new ArrayList<PVector>();
  PVector lastAdded = history.get(0);
  pts.add(lastAdded);

  for (int i = 1; i < history.size(); i++) {
    PVector v = history.get(i);
    if (PVector.dist(lastAdded, v) >= minPointDist) {
      pts.add(v);
      lastAdded = v;
    }
  }
  pts.add(location.copy());

  if (pts.size() < 2) return;

  // Build left and right edge arrays
  ArrayList<PVector> left  = new ArrayList<PVector>();
  ArrayList<PVector> right = new ArrayList<PVector>();

  for (int i = 0; i < pts.size(); i++) {
    PVector tangent;
    if (i == 0) {
      tangent = PVector.sub(pts.get(1), pts.get(0));
    } else if (i == pts.size() - 1) {
      tangent = PVector.sub(pts.get(i), pts.get(i - 1));
    } else {
      PVector t1 = PVector.sub(pts.get(i), pts.get(i - 1));
      PVector t2 = PVector.sub(pts.get(i + 1), pts.get(i));
      tangent = PVector.add(t1, t2);
    }
    tangent.normalize();
    PVector perp = new PVector(-tangent.y, tangent.x);
    left.add(PVector.add(pts.get(i), PVector.mult(perp, hw)));
    right.add(PVector.sub(pts.get(i), PVector.mult(perp, hw)));
  }

  // Clamp inner edge vertices on tight curves to prevent self-intersection
// Clamp inner edge vertices on tight curves to prevent self-intersection
for (int i = 1; i < pts.size() - 1; i++) {
  PVector prev = pts.get(i - 1);
  PVector curr = pts.get(i);
  PVector next = pts.get(i + 1);

  PVector t1 = PVector.sub(curr, prev).normalize();
  PVector t2 = PVector.sub(next, curr).normalize();

  // Cross product determines turn direction
  float cross = t1.x * t2.y - t1.y * t2.x;
  
  // Dot product tells us how sharp the turn is
  // -1 = complete reversal, 0 = 90 degrees, 1 = straight
  float dot = t1.dot(t2);

  // Only clamp if turn is sharp enough to cause self-intersection
  // i.e. curve radius < hw
  float segLen = PVector.dist(prev, curr);
  if (dot < 0 && segLen < hw * 2) {
    if (cross > 0) {
      left.set(i, curr.copy());  // left is inner edge
    } else {
      right.set(i, curr.copy()); // right is inner edge
    }
  }
}

  pg.noStroke();
  pg.fill(lineColor);

  if (sqCaps) {
    // Square caps — project rectangles at each end as part of single shape
    PVector startTangent = PVector.sub(pts.get(0), pts.get(min(3, pts.size()-1))).normalize();
    PVector endTangent   = PVector.sub(pts.get(pts.size()-1), pts.get(max(0, pts.size()-4))).normalize();

    PVector sl = PVector.add(left.get(0),  PVector.mult(startTangent, hw));
    PVector sr = PVector.add(right.get(0), PVector.mult(startTangent, hw));
    PVector el = PVector.add(left.get(left.size()-1),   PVector.mult(endTangent, hw));
    PVector er = PVector.add(right.get(right.size()-1), PVector.mult(endTangent, hw));

    pg.beginShape();
    pg.vertex(sl.x, sl.y);
    pg.vertex(sr.x, sr.y);
    for (int i = 0; i < right.size(); i++) {
      pg.vertex(right.get(i).x, right.get(i).y);
    }
    pg.vertex(er.x, er.y);
    pg.vertex(el.x, el.y);
    for (int i = left.size() - 1; i >= 0; i--) {
      pg.vertex(left.get(i).x, left.get(i).y);
    }
    pg.endShape(CLOSE);

  } else {
    // Round caps — single closed shape with bezier semicircles at each end
    float k = hw * 0.5523;

    PVector startTangent = PVector.sub(pts.get(0), pts.get(min(3, pts.size()-1))).normalize();
    PVector endTangent   = PVector.sub(pts.get(pts.size()-1), pts.get(max(0, pts.size()-4))).normalize();

    PVector sLeft  = left.get(0);
    PVector sRight = right.get(0);
    PVector sh1    = PVector.add(sLeft,  PVector.mult(startTangent, k * 2));
    PVector sh2    = PVector.add(sRight, PVector.mult(startTangent, k * 2));

    PVector eLeft  = left.get(left.size()-1);
    PVector eRight = right.get(right.size()-1);
    PVector eh1    = PVector.add(eLeft,  PVector.mult(endTangent, k * 2));
    PVector eh2    = PVector.add(eRight, PVector.mult(endTangent, k * 2));

    pg.beginShape();
    pg.vertex(sLeft.x, sLeft.y);
    for (int i = 1; i < left.size(); i++) {
      pg.vertex(left.get(i).x, left.get(i).y);
    }
    pg.bezierVertex(
      eh1.x, eh1.y,
      eh2.x, eh2.y,
      eRight.x, eRight.y
    );
    for (int i = right.size() - 2; i >= 0; i--) {
      pg.vertex(right.get(i).x, right.get(i).y);
    }
    pg.bezierVertex(
      sh2.x, sh2.y,
      sh1.x, sh1.y,
      sLeft.x, sLeft.y
    );
    pg.endShape(CLOSE);
  }
}

  //void drawAdLines() {
  //  if (!drawTail || history.size() < 2) return;

  //  if (pg == pgPDF) {
  //    if (colourLine) {
  //      pg.stroke(pdfBlack);
  //    } else {
  //      pg.stroke(0);
  //    }
  //  } else {
  //    pg.stroke(myColor);
  //  }

  //  if (randomLineWeight) {
  //    pg.strokeWeight(randomStrokeThick);
  //  } else {
  //    pg.strokeWeight(strokeThick);
  //  }

  //  pg.noFill();

  //  //float minDist = strokeThick * pointsDist; // minimum distance between points

  //  // Build filtered list - skip points too close OR causing sharp direction reversal
  //  ArrayList<PVector> filtered = new ArrayList<PVector>();
  //  PVector last = history.get(0);
  //  filtered.add(last);
  //  PVector lastDir = null;

  //  for (int i = step; i < history.size(); i += step) {
  //    PVector v = history.get(i);
  //    PVector dir = PVector.sub(v, last);

  //    //if (PVector.dist(last, v) >= strokeThick * pointsDist) {
  //      if (lastDir != null) {
  //        float angle = PVector.angleBetween(lastDir, dir);
  //        if (angle < radians(120)) {
  //          filtered.add(v);
  //          last = v;
  //          lastDir = dir;
  //        }
  //      } else {
  //        filtered.add(v);
  //        last = v;
  //        lastDir = dir;
  //      }
  //    //}
  //  }
  //  filtered.add(location.copy());

  //  if (filtered.size() < 4) return;

  //  // Project phantom start point BEHIND the first point
  //  PVector p0 = filtered.get(0);
  //  PVector p1 = filtered.get(1);
  //  PVector startTangent = PVector.sub(p0, p1);
  //  PVector phantomStart = PVector.add(p0, startTangent);

  //  // Project phantom end point BEYOND the last point
  //  PVector pLast = filtered.get(filtered.size()-1);
  //  PVector pPrev = filtered.get(filtered.size()-2);
  //  PVector endTangent = PVector.sub(pLast, pPrev);
  //  PVector phantomEnd = PVector.add(pLast, endTangent);

  //  pg.beginShape();
  //  pg.curveVertex(phantomStart.x, phantomStart.y);
  //  for (PVector v : filtered) {
  //    pg.curveVertex(v.x, v.y);
  //  }
  //  pg.curveVertex(phantomEnd.x, phantomEnd.y);
  //  pg.endShape();
  //}

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
