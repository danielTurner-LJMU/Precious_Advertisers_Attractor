import java.lang.reflect.Field;

String subFolderLogin = "/security_and_login_information";
String dataFileNameLogin = "account_activity.json"; //name of the JSON file

JSONObject dataFileLogin;
JSONArray accountActivity;

//Variables used to calculate and draw timestamps across as set of horizontal lines
long startDate, endDate; //store first and last dates of activity
long dateSpread; //total distance bewteen dates
float dateCut; //modulo operator for working out line return
float dateScale; //scale factor converting date spread to line length

float border = 10;
float borderAsPixels = 0;

int numRows = 10;
float rowGap;
float yOffset;
float lineLength, totalLineLength;
float loginLineX1, loginLineX2;

//-------- OBJECT CREATION ----------//
DataObjectLogin[] dataObjectsLogin;


//-------- TARGET PROPERTIES --------//
float targetActivateChance = 0.995;
float targetRadius = 30;
float targetOpacity = 150;
boolean drawCity = false;
boolean drawIP = false;
boolean drawCookie = false;
boolean drawAction = false;
boolean drawDate = false;

void loadDataLogin() {

  String fullDataPath = parentFolderPath + subFolderLogin + "/" + dataFileNameLogin;
  dataFileLogin = loadJSONObject(fullDataPath);

  extractDataLogin();
}

void extractDataLogin() {

  accountActivity = dataFileLogin.getJSONArray("account_activity_v2");
  dataObjectsLogin = new DataObjectLogin[accountActivity.size()];

  /*The lines below extract the 'key' names from the individual JSON objects.
   It uses object 1 from the JSON array as a template */
  JSONObject accActivity1 = accountActivity.getJSONObject(0);
  String[] myKeys = (String[]) accActivity1.keys().toArray(new String[accActivity1.size()]);
  printArray(myKeys);

  for (int i = 0; i < accountActivity.size(); i++) {
    JSONObject thisActivity = accountActivity.getJSONObject(i);
    String action = thisActivity.getString("action");
    String siteName = thisActivity.getString("site_name");
    String city = thisActivity.getString("city");
    String country = thisActivity.getString("country");
    String ip = thisActivity.getString("ip_address");
    String cookie = thisActivity.getString("datr_cookie");
    long timestamp = thisActivity.getLong("timestamp");
    dataObjectsLogin[i] = new DataObjectLogin(i, action, siteName, city, country, ip, cookie, timestamp);
  }

  startDate = dataObjectsLogin[dataObjectsLogin.length-1].timeStamp;
  endDate = dataObjectsLogin[0].timeStamp;




  /*
  ** Examples below show howe to access all different entries for various fields of data
   ** They use the getUniqueFieldValues(obj, variable(field)) method to extract them from the objects
   String[] uniqueActions = getUniqueFieldValues(dataObjectsLogin, "action");
   String[] uniqueSites = getUniqueFieldValues(dataObjectsLogin, "siteName");
   String[] uniqueCities = getUniqueFieldValues(dataObjectsLogin, "city");
   String[] uniqueIPs = getUniqueFieldValues(dataObjectsLogin, "IP");
   
   println("Unique actions:");
   for (String action : uniqueActions) println(action);
   println("site names:");
   for (String siteName : uniqueSites) println(siteName);
   println("city names:");
   for (String city : uniqueCities) println(city);
   println("IP Addresses:");
   for (String IP : uniqueIPs) println(IP);
   */

  //println("start date = " + startDate + "\n" + "end date = " + endDate);
}

/**
 * Returns an array of unique String values from a specified field
 * in an array of DataObjectLogin instances.
 *
 * This method uses reflection to access the field dynamically by name.
 *
 * @param objects   An array of DataObjectLogin instances to search through.
 * @param fieldName The name of the String field to extract (e.g., "action", "city").
 * @return          An array of unique String values found in the specified field.
 */
String[] getUniqueFieldValues(DataObjectLogin[] objects, String fieldName) {
  HashSet<String> uniqueValues = new HashSet<String>();

  for (DataObjectLogin obj : objects) {
    try {
      // Use reflection to get the value of the field
      Field field = obj.getClass().getDeclaredField(fieldName);
      field.setAccessible(true); // allow access to private fields if needed
      Object value = field.get(obj);

      if (value instanceof String) {
        uniqueValues.add((String) value);
      }
    }
    catch (Exception e) {
      println("Error accessing field: " + fieldName);
    }
  }

  return uniqueValues.toArray(new String[0]);
}

///-------------------- LOGIN OBJECT --------------------------///
class DataObjectLogin
{
  int ID;
  String action, siteName, city, country, IP, datr_cookie, date;
  long timeStamp;
  float zeroDate;//store date zero'd out against start date

  //Target Properties

  PVector location = new PVector(0, 0);
  float attraction;
  boolean active = true;
  boolean hideMe = false;

  float radiusMultiplier;
  float r; //total shape radius



  DataObjectLogin(int id, String act, String site, String c, String place, String ip, String cookie, long time ) {

    ID = id;
    action = act;
    timeStamp = time;
    siteName = site;
    city = c;
    country = place;
    IP = ip;
    datr_cookie = cookie;

    //convert timestamp to dates
    Date tempDate = convertDate(time);
    date = tempDate.toString();

    radiusMultiplier = random(0.1, 2);
    r = targetRadius*radiusMultiplier;
    attraction = random(1, 100);
  }

  void initDraw() {

    zeroDate = timeStamp - startDate;
    // println("ID = " + ID + " time = " + timeStamp + " action = " + action);
  }

  void activate() {

    if (!hideMe) {
      float value = random(1);
      //println(value);

      if (value > targetActivateChance) {
        active = !active;
        attraction = random(1, 100);
      }
    } else {
      active = false;
    }
  }

  void update() {
    long minDateVal = (long) cp5.getController("timeRange").getArrayValue(0);
    long maxDateVal = (long) cp5.getController("timeRange").getArrayValue(1);

    //hide and deactivate if the data is outside the date range
    if (timeStamp < minDateVal || timeStamp > maxDateVal) {
      active = false;
      hideMe = true;
      //println(ID + "hiding");
    } else {
      hideMe = false;
    }


    zeroDate = timeStamp - startDate;
    location.x = ((zeroDate%dateCut)*dateScale) + loginLineX1;
    location.y = (int(zeroDate/dateCut)*rowGap)+yOffset;

    //update radius
    r = targetRadius*radiusMultiplier;
  }

  void drawLogin() {

    pg.pushMatrix();
    pg.translate(location.x, location.y);

    //draw ring round circle
    //if (!hideMe) {
    //  pg.strokeWeight(0.5);

    //  pg.stroke(0);
    //  pg.noFill();
    //  pg.circle(0, 0, r+10);
    //}

    if (active) {
      pg.fill(250, 106, 248, targetOpacity);
    } else {
      pg.fill(150, targetOpacity);
    }

    //if (hideMe) {
    //  pg.fill(0, 0, 248);
    //}

    if (!hideMe) {

      pg.noStroke();
      pg.circle(0, 0, r);
      textSize(12);
      float yLoc = -(r*0.5);//((ID*10)%r) - (r*0.5);x
      pg.fill(0);
      if (drawCity) {
        pg.text(city +", " + country, (r*0.5)+5, yLoc);
        yLoc+=14;
      }
      if (drawIP) {
        pg.text(IP, (r*0.5)+5, yLoc);
        yLoc+=14;
      }
      if (drawCookie) {
        if (datr_cookie != null) {
          pg.text(datr_cookie, (r*0.5)+5, yLoc);
          yLoc+=14;
        }
      }
      if (drawDate) {
        pg.text(date, (r*0.5)+5, yLoc);
        yLoc+=14;
      }
      if (drawAction) {
        pg.text(action, (r*0.5)+5, yLoc);
        yLoc+=14;
      }
    }

    pg.popMatrix();
  }
}
