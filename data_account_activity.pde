import java.lang.reflect.Field; // Used for reflection to access object fields dynamically

// File path and name for login activity data
String subFolderLogin = "/security_and_login_information";
String dataFileNameLogin = "account_activity.json"; //name of the JSON file

// JSON objects to store and parse login activity
JSONObject dataFileLogin;
JSONArray accountActivity;

//Variables used to calculate and draw timestamps across as set of horizontal lines
long startDate, endDate;    //store first and last dates of activity
long dateSpread;            //total distance bewteen dates
float dateCut;              //modulo operator for working out line return
float dateScale;            //scale factor converting date spread to line length

//Layout parameters
float border = 25;
float borderAsPixels = 0;

int numRows = 18;            // Number of rows in the timeline view
float rowGap;                // Gap between rows
float yOffset;               // Vertical offset for layout
float lineLength, totalLineLength;
float loginLineX1, loginLineX2; // X-coordinates for start and end of login line

//-------- OBJECT CREATION ----------//
DataObjectLogin[] dataObjectsLogin;  // Array to store each login as an object


//-------- TARGET PROPERTIES --------//
float targetActivateChance = 0.995;  // Probability of a target being (de)activated
float targetRadius = 1;             // Default radius of target shapes
float targetOpacity = 150;           // Opacity of the visual circles
int safeCount = 1;                   // Base number of visits - used for scaling circles
int maxLocationCount = 0;            //Maximum number of activity from a location calculated lower down
float minVisualRadius = 2;           // Minimum circle radius for small counts
float maxVisualRadius = 50;          // Maximum radius for largest counts

//-------- HASH MAPS: For storing data totals ----------//
HashMap<String, Integer> locationCounts = new HashMap<String, Integer>();
HashMap<String, Integer> ipCounts = new HashMap<String, Integer>();
HashMap<String, Integer> platformCounts = new HashMap<String, Integer>();
HashMap<String, Integer> actionCounts = new HashMap<String, Integer>();

// Flags for drawing additional data
//boolean drawCity = false;
//boolean drawIP = false;
//boolean drawPlatform = false;
//boolean drawAction = false;
//boolean drawDate = false;

// Load JSON login data and parse it
void loadDataLogin() {

  String fullDataPath = parentFolderPath + subFolderLogin + "/" + dataFileNameLogin;
  dataFileLogin = loadJSONObject(fullDataPath); // Load JSON from file
  extractDataLogin(); // Parse the JSON into objects
}

// Parse login data and initialize data objects
void extractDataLogin() {

  accountActivity = dataFileLogin.getJSONArray("account_activity_v2");
  dataObjectsLogin = new DataObjectLogin[accountActivity.size()];

  // Use the first entry to extract keys (field names) for reference/debugging
  JSONObject accActivity1 = accountActivity.getJSONObject(0);
  String[] myKeys = (String[]) accActivity1.keys().toArray(new String[accActivity1.size()]);
  //printArray(myKeys);

  // Loop through each login entry and extract data
  for (int i = 0; i < accountActivity.size(); i++) {
    JSONObject thisActivity = accountActivity.getJSONObject(i);
    String action = thisActivity.getString("action");
    String siteName = thisActivity.getString("site_name");
    String city = thisActivity.getString("city");
    String country = thisActivity.getString("country");
    String ip = thisActivity.getString("ip_address");
    String userAgent = thisActivity.getString("user_agent"); // Raw platform string
    String platformInfo = extractBetweenParentheses(userAgent); // Extract OS info from user agent

    // Precompute location key to match HashMap
    String locationKey = city + ", " + country;

    long timestamp = thisActivity.getLong("timestamp");

    //Check Unicode errors
    city = fixEncoding(city);
    // Combine city + country into one location key
    String location = city + ", " + country;

    // Update aggregate counts
    incrementMap(locationCounts, location);
    String groupedIP = normaliseIP(ip); //check and group IPv6
    incrementMap(ipCounts, groupedIP);
    incrementMap(platformCounts, platformInfo);
    incrementMap(actionCounts, action);

    // Create a new DataObjectLogin with extracted data
    dataObjectsLogin[i] = new DataObjectLogin(i, action, siteName, city, country, groupedIP, platformInfo, timestamp);
  }

  // Define the start and end dates based on first and last entries
  startDate = dataObjectsLogin[dataObjectsLogin.length-1].timeStamp;
  endDate = dataObjectsLogin[0].timeStamp;

  //Add location count for each location to the objects
  for (int i = 0; i < dataObjectsLogin.length; i++) {
    DataObjectLogin obj = dataObjectsLogin[i];
    obj.locationCount = locationCounts.get(obj.locationKey);
  }

  //find largest location count
  for (int count : locationCounts.values()) {
    if (count > maxLocationCount) maxLocationCount = count;
  }

  /*
  // Example code for extracting unique values from the data using reflection
   String[] uniqueActions = getUniqueFieldValues(dataObjectsLogin, "action");
   String[] uniqueSites = getUniqueFieldValues(dataObjectsLogin, "siteName");
   String[] uniqueCities = getUniqueFieldValues(dataObjectsLogin, "city");
   String[] uniqueIPs = getUniqueFieldValues(dataObjectsLogin, "IP");
   
   println("Unique actions:");
   for (String action : uniqueActions) println(action);
   */

  // ------- **** HashMap Printouts **** --------- //
  //for (String loc : locationCounts.keySet()) {
  //  println(loc + " : " + locationCounts.get(loc));
  //}

  //for (String ip : ipCounts.keySet()) {
  //  println(ip + " : " + ipCounts.get(ip));
  //}

  //  for (String platform : platformCounts.keySet()) {
  //  println(platform + " : " + platformCounts.get(platform));
  //}
}

// Extracts the text inside the first pair of parentheses in a string (e.g., OS from user agent)
String extractBetweenParentheses(String input) {
  if (input == null || input.isEmpty()) return "No Platform Info";

  int start = input.indexOf('(');
  int end = input.indexOf(')', start);

  if (start != -1 && end != -1 && end > start) {
    return input.substring(start + 1, end); // Extract text between '(' and ')'
  } else {
    return "No Platform Info"; // Return an empty string if no valid parentheses found
  }
}

//Check if IP is IPv6 or 4. IPv6 are more fragemnted so this checks first 4 blocks and groups them if they are the same.
//If IPv4 - simply returns IP address
String normaliseIP(String ip) {

  if (ip == null) return "unknown";

  // Detect IPv6
  if (ip.contains(":")) {

    String[] parts = ip.split(":");

    // Only group if at least 4 blocks exist
    if (parts.length >= 4) {
      return parts[0] + ":" + parts[1] + ":" + parts[2] + ":" + parts[3];
    }
  }

  // Otherwise assume IPv4
  return ip;
}

// Updates HashMaps
void incrementMap(HashMap<String, Integer> map, String key) {
  map.put(key, map.getOrDefault(key, 0) + 1);
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
      Field field = obj.getClass().getDeclaredField(fieldName); // Access field by name
      field.setAccessible(true); // allow access to private fields if needed
      Object value = field.get(obj); // Get value from object

      if (value instanceof String) {
        uniqueValues.add((String) value); // Store in set if it's a string
      }
    }
    catch (Exception e) {
      println("Error accessing field: " + fieldName); // Handle reflection errors
    }
  }

  return uniqueValues.toArray(new String[0]); // Convert set to array
}

///-------------------- LOGIN OBJECT --------------------------///

// Class representing one login entry as an object
class DataObjectLogin
{
  int ID;
  String action, siteName, city, country, IP, platformInfo, date;
  String locationKey;
  long timeStamp;
  float zeroDate; // Timestamp normalized against start date

  // Target behavior and visual properties
  PVector location = new PVector(0, 0); // Position on canvas
  float attraction;
  boolean active = true;
  boolean hideMe = false;

  int locationCount = 0; //the number of times a location was stored - passed from HashMap
  float radiusMultiplier;  // Used to vary circle sizes
  float r; //total shape radius

  // Constructor that initializes all data fields
  DataObjectLogin(int id, String act, String site, String c, String place, String ip, String pInfo, long time ) {

    ID = id;
    action = act;
    timeStamp = time;
    siteName = site;
    city = c;
    country = place;
    IP = ip;
    platformInfo = pInfo;

    // Precompute location key
    locationKey = city + ", " + country;

    // Convert timestamp into readable date
    Date tempDate = convertDate(time);
    date = tempDate.toString();
  }

  // Prepare object for visual layout by calculating relative date
  void initDraw() {
    zeroDate = timeStamp - startDate;

    // Make sure locationCount >= 1 for log
    float safeCount = max(locationCount, 1);
    radiusMultiplier = log(safeCount) / log(maxLocationCount); // log-normalized to [0,1]
    r = minVisualRadius + radiusMultiplier * (maxVisualRadius - minVisualRadius);//Map normalized value to radius range
    r = r * targetRadius;  // targetRadius from slider
    attraction = random(1, 100);
  }

  // Randomly toggle activity state based on chance (if not hidden)
  void activate() {
    if (!hideMe) {
      float value = random(1);
      if (value > targetActivateChance) {
        active = !active;
        attraction = random(1, 100);
      }
    } else {
      active = false;
    }
  }

  // Update position and visibility based on date range and layout
  void update() {
    long minDateVal = (long) cp5.getController("timeRange").getArrayValue(0);
    long maxDateVal = (long) cp5.getController("timeRange").getArrayValue(1);

    //hide and deactivate if the data is outside the date range
    if (timeStamp < minDateVal || timeStamp > maxDateVal) {
      active = false;
      hideMe = true;
    } else {
      hideMe = false;
    }

    zeroDate = timeStamp - startDate;

    // Calculate location using modulo for horizontal wrap and vertical row
    location.x = ((zeroDate%dateCut)*dateScale) + loginLineX1;
    location.y = (int(zeroDate/dateCut)*rowGap)+yOffset;


    r = minVisualRadius + radiusMultiplier * (maxVisualRadius - minVisualRadius);
    r *= targetRadius;
  }

  // Draw the visual representation of a login/activity
  void drawLogin() {

    pg.pushMatrix();
    pg.translate(location.x, location.y);

    /* debugging sections allows you to see which logins are activated */
    //if (active) {
    //  pg.noStroke();
    //  pg.fill(250, 106, 248, targetOpacity);
    //} else {
    //  pg.noFill();//fill(150, targetOpacity);
    //  pg.strokeWeight(4);
    //  pg.stroke(250, 106, 248, targetOpacity);
    // }

    // Set fill color depending on export mode: PDF is for Riso so greyscale
    if (pg == pgPDF) {
      pg.fill(0, targetOpacity);
    } else {
      pg.fill(250, 106, 248, targetOpacity);
    }

    // Only draw if not hidden
    if (!hideMe) {
      pg.noStroke();
      pg.circle(0, 0, r);
    }

    pg.popMatrix();
  }

}

//Check for mouseOver
boolean isMouseOverLogin(DataObjectLogin obj, float mx, float my) {
  PVector buf = screenToBuffer(mx, my);
  float d = dist(buf.x, buf.y, obj.location.x, obj.location.y);
  return d <= obj.r / 2.0;
}
