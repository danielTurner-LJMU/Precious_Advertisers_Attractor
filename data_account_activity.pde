String subFolderLogin = "/security_and_login_information";
String dataFileNameLogin = "account_activity.json"; //name of the JSON file

JSONObject dataFileLogin;
JSONArray accountActivity;

//Variables used to calculate and draw timestamps across as set of horizontal lines
long startDate, endDate; //store first and last dates of activity
long dateSpread; //total distance bewteen dates
float dateCut; //modulo operator for working out line return
float dateScale; //scale factor converting date spread to line length

float border = 100;
int numRows = 10;
float rowGap;
float yOffset;
float lineLength, totalLineLength;
float loginLineX1, loginLineX2;

//-------- OBJECT CREATION ----------//
DataObjectLogin[] dataObjectsLogin;


//-------- TARGET PROPERTIES --------//
float targetActivateChance = 0.995;

void loadDataLogin() {

  String fullDataPath = parentFolderPath + subFolderLogin + "/" + dataFileNameLogin;
  dataFileLogin = loadJSONObject(fullDataPath);

  extractDataLogin();
}

void extractDataLogin() {

  accountActivity = dataFileLogin.getJSONArray("account_activity_v2");
  dataObjectsLogin = new DataObjectLogin[accountActivity.size()];

  for (int i = 0; i < accountActivity.size(); i++) {
    JSONObject thisActivity = accountActivity.getJSONObject(i);
    String action = thisActivity.getString("action");
    long timestamp = thisActivity.getLong("timestamp");
    dataObjectsLogin[i] = new DataObjectLogin(i, action, timestamp);
  }

  startDate = dataObjectsLogin[dataObjectsLogin.length-1].timeStamp;
  endDate = dataObjectsLogin[0].timeStamp;

  //println("start date = " + startDate + "\n" + "end date = " + endDate);
}

///-------------------- LOGIN OBJECT --------------------------///
class DataObjectLogin
{
  int ID;
  String action;
  long timeStamp;
  float zeroDate;//store date zero'd out against start date

  //Target Properties

  PVector location = new PVector(0, 0);
  float attraction;
  boolean active = true;
  boolean hideMe = false;

  float r; //radius of shape



  DataObjectLogin(int id, String act, long time) {

    ID = id;
    action = act;
    timeStamp = time;

    r = 30;
    attraction = random(1, 100);
  }

  void initDraw() {

    zeroDate = timeStamp - startDate;
    // println("ID = " + ID + " time = " + timeStamp + " action = " + action);
  }

  void activate() {

    float value = random(1);
    //println(value);
    if (value > targetActivateChance) {
      active = !active;
      attraction = random(1, 100);
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
  }

  void drawLogin() {

    if (active) {
      pg.fill(250, 106, 248);
    } else {
      pg.fill(150);
    }

    if (hideMe) {
      pg.fill(0, 0, 248);
    }

    if (!hideMe) {
      pg.noStroke();
      pg.circle(location.x, location.y, r);
    }
  }
}

void calculateLoginLine() {

  //calculate spacing between rows
  rowGap = (pg.height-(border*2))/numRows;

  loginLineX1 = border;
  loginLineX2 = pg.width - border;

  lineLength = loginLineX2 - loginLineX1;
  totalLineLength = lineLength * numRows;

  dateSpread = endDate - startDate;
  dateScale = totalLineLength/dateSpread;
  dateCut = dateSpread/numRows;
}

void drawLoginLine() {

  //Lines require offseting to centre vertically
  yOffset = border+(rowGap/2);
  pg.stroke(0);
  //draw guide lines
  for (int i = 0; i < numRows; i++) {
    float yBasePos = i*rowGap;
    pg.line(loginLineX1, yBasePos + yOffset, loginLineX2, yBasePos + yOffset);
  }
}
